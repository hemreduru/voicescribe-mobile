import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
// ignore_for_file: avoid_slow_async_io
import 'package:path_provider/path_provider.dart';
import 'package:voicescribe_mobile/data/services/transcription_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/use_cases/repair_stale_recordings.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

enum ModelBootstrapState { bootstrapping, ready, failed }

sealed class BootstrapEvent {
  const BootstrapEvent();
}

final class BootstrapStarted extends BootstrapEvent {
  const BootstrapStarted();
}

final class BootstrapRetried extends BootstrapEvent {
  const BootstrapRetried();
}

class BootstrapState {
  const BootstrapState({
    this.modelState = ModelBootstrapState.bootstrapping,
    this.errorMessage,
    this.initialized = false,
  });

  final ModelBootstrapState modelState;
  final String? errorMessage;
  final bool initialized;

  bool get isReady => initialized && modelState == ModelBootstrapState.ready;

  BootstrapState copyWith({
    ModelBootstrapState? modelState,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? initialized,
  }) {
    return BootstrapState(
      modelState: modelState ?? this.modelState,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      initialized: initialized ?? this.initialized,
    );
  }
}

class BootstrapBloc extends Bloc<BootstrapEvent, BootstrapState> {
  BootstrapBloc({
    required TranscriptRepository transcriptRepository,
    required TranscriptionService transcriptionService,
  }) : _transcriptRepository = transcriptRepository,
       _transcriptionService = transcriptionService,
       super(const BootstrapState()) {
    on<BootstrapStarted>(_onStarted);
    on<BootstrapRetried>(_onRetried);
  }

  final TranscriptRepository _transcriptRepository;
  final TranscriptionService _transcriptionService;

  Future<void> _onStarted(
    BootstrapStarted event,
    Emitter<BootstrapState> emit,
  ) async {
    await _bootstrap(emit);
  }

  Future<void> _onRetried(
    BootstrapRetried event,
    Emitter<BootstrapState> emit,
  ) async {
    await _bootstrap(emit);
  }

  Future<void> _bootstrap(Emitter<BootstrapState> emit) async {
    emit(
      state.copyWith(
        modelState: ModelBootstrapState.bootstrapping,
        clearErrorMessage: true,
      ),
    );
    try {
      final snapshot = await _transcriptRepository.loadSnapshot();
      // Cutoff for the orphan-file sweep below: the sweep runs unawaited after
      // the app is ready, so any chunk file written *after* this snapshot (a
      // recording the user started right away) is unknown to it and must not
      // be treated as an orphan.
      final snapshotLoadedAt = DateTime.now();

      // Apply the persisted transcription language so the very first
      // recording already uses the user's choice.
      _transcriptionService.setTranscriptionLanguage(
        snapshot.preferences.transcriptionLanguage,
      );
      await RepairStaleRecordingsUseCase(
        _transcriptRepository,
      ).execute(snapshot);
      // Fetch the latest server data into cache in the background — the app is
      // offline-first, so becoming usable must never wait on the network (a
      // slow server would otherwise hold the splash screen for up to the full
      // HTTP timeout). The snapshot stream delivers the refreshed data.
      unawaited(
        _transcriptRepository.refresh().catchError((Object error) {
          AppLogger.warning('[Bootstrap] Background refresh failed: $error');
        }),
      );
      emit(
        state.copyWith(
          modelState: ModelBootstrapState.ready,
          initialized: true,
          clearErrorMessage: true,
        ),
      );
      // Best-effort housekeeping: deleting orphaned chunk audio must never
      // gate the app becoming usable, so run it after the app is ready and
      // don't await it (a slow/stuck filesystem can't wedge startup).
      unawaited(_cleanupOrphanChunkFiles(snapshot, before: snapshotLoadedAt));
    } catch (error) {
      emit(
        state.copyWith(
          modelState: ModelBootstrapState.failed,
          initialized: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _cleanupOrphanChunkFiles(
    TranscriptSnapshot snapshot, {
    required DateTime before,
  }) async {
    final knownPaths = <String>{
      for (final chunk in snapshot.chunks)
        if (chunk.audioPath != null && chunk.audioPath!.isNotEmpty)
          chunk.audioPath!,
    };
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final chunksDir = Directory('${docsDir.path}/voicescribe_chunks');
      if (!await chunksDir.exists()) {
        return;
      }
      await for (final entity in chunksDir.list()) {
        if (entity is! File || knownPaths.contains(entity.path)) {
          continue;
        }
        // A file newer than the snapshot belongs to a recording that started
        // after it was taken — not an orphan. It gets re-evaluated (against a
        // fresh snapshot) on the next launch.
        try {
          final modifiedAt = await entity.lastModified();
          if (!modifiedAt.isBefore(before)) {
            continue;
          }
        } catch (_) {
          continue; // Stat failed; leave the file alone.
        }
        try {
          await entity.delete();
        } catch (error, stackTrace) {
          AppLogger.warning(
            '[Bootstrap] Failed to delete orphan chunk file: ${entity.path}',
            error,
            stackTrace,
          );
        }
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        '[Bootstrap] Orphan chunk cleanup failed',
        error,
        stackTrace,
      );
    }
  }
}
