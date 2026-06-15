import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
// ignore_for_file: avoid_slow_async_io
import 'package:path_provider/path_provider.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
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

/// Flips [BootstrapState.onboardingComplete] after the wizard finishes so the
/// router stops redirecting to `/onboarding` and lands on the app.
final class BootstrapOnboardingCompleted extends BootstrapEvent {
  const BootstrapOnboardingCompleted();
}

/// Re-arms onboarding (e.g. "Replay intro" from Settings) so the router routes
/// back to the wizard. Pairs with persisting `hasSeenOnboarding = false`.
final class BootstrapOnboardingReset extends BootstrapEvent {
  const BootstrapOnboardingReset();
}

final class _BootstrapProgressChanged extends BootstrapEvent {
  const _BootstrapProgressChanged(this.progress);

  final ModelDownloadProgress progress;
}

class BootstrapState {
  const BootstrapState({
    this.modelState = ModelBootstrapState.bootstrapping,
    this.selectedModelKey = 'base',
    this.downloadProgress,
    this.errorMessage,
    this.initialized = false,
    this.onboardingComplete = true,
  });

  final ModelBootstrapState modelState;
  final String selectedModelKey;
  final ModelDownloadProgress? downloadProgress;
  final String? errorMessage;
  final bool initialized;

  /// Whether the first-run wizard has been completed. Defaults true so we never
  /// flash onboarding before preferences load; set from the persisted
  /// `hasSeenOnboarding` flag once the snapshot is read.
  final bool onboardingComplete;

  bool get isReady => initialized && modelState == ModelBootstrapState.ready;

  BootstrapState copyWith({
    ModelBootstrapState? modelState,
    String? selectedModelKey,
    ModelDownloadProgress? downloadProgress,
    bool clearDownloadProgress = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? initialized,
    bool? onboardingComplete,
  }) {
    return BootstrapState(
      modelState: modelState ?? this.modelState,
      selectedModelKey: selectedModelKey ?? this.selectedModelKey,
      downloadProgress: clearDownloadProgress
          ? null
          : downloadProgress ?? this.downloadProgress,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      initialized: initialized ?? this.initialized,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
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
    on<BootstrapOnboardingCompleted>(_onOnboardingCompleted);
    on<BootstrapOnboardingReset>(_onOnboardingReset);
    on<_BootstrapProgressChanged>(_onProgressChanged);
    _progressSubscription = _transcriptionService.downloadProgress.listen(
      (progress) => add(_BootstrapProgressChanged(progress)),
    );
  }

  final TranscriptRepository _transcriptRepository;
  final TranscriptionService _transcriptionService;
  StreamSubscription<ModelDownloadProgress>? _progressSubscription;

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

  void _onProgressChanged(
    _BootstrapProgressChanged event,
    Emitter<BootstrapState> emit,
  ) {
    emit(state.copyWith(downloadProgress: event.progress));
  }

  void _onOnboardingCompleted(
    BootstrapOnboardingCompleted event,
    Emitter<BootstrapState> emit,
  ) {
    emit(state.copyWith(onboardingComplete: true));
  }

  void _onOnboardingReset(
    BootstrapOnboardingReset event,
    Emitter<BootstrapState> emit,
  ) {
    emit(state.copyWith(onboardingComplete: false));
  }

  Future<void> _bootstrap(Emitter<BootstrapState> emit) async {
    emit(
      state.copyWith(
        modelState: ModelBootstrapState.bootstrapping,
        clearDownloadProgress: true,
        clearErrorMessage: true,
      ),
    );
    try {
      final snapshot = await _transcriptRepository.loadSnapshot();
      // Surface whether the first-run wizard still needs to show, so the router
      // can gate on it the moment bootstrap reports ready.
      emit(
        state.copyWith(
          onboardingComplete: snapshot.preferences.hasSeenOnboarding,
        ),
      );
      // Cutoff for the orphan-file sweep below: the sweep runs unawaited after
      // the app is ready, so any chunk file written *after* this snapshot (a
      // recording the user started right away) is unknown to it and must not
      // be treated as an orphan.
      final snapshotLoadedAt = DateTime.now();

      // Apply the persisted transcription language before the model loads so
      // the very first recording already uses the user's choice.
      _transcriptionService.setTranscriptionLanguage(
        snapshot.preferences.transcriptionLanguage,
      );
      // Honor the persisted model; selectModel safely falls back to base when
      // the chosen model is too heavy for this device.
      await _transcriptionService.selectModel(
        whisperModelFromKey(snapshot.preferences.transcriptionModel),
      );
      await RepairStaleRecordingsUseCase(
        _transcriptRepository,
      ).execute(snapshot);
      // Non-blocking: if the persisted model isn't downloaded yet (e.g. an
      // interrupted switch left only a `.part`), boot on an already-downloaded
      // model instead of locking the app on the splash re-downloading it.
      await _transcriptionService.ensureUsableModel();
      // Persist whatever model actually loaded so Settings reflects reality and
      // the next launch doesn't try to re-download the missing one all over.
      final activeModelKey = AppPreferences.normalizeTranscriptionModel(
        _transcriptionService.currentModelKey,
      );
      if (activeModelKey != snapshot.preferences.transcriptionModel) {
        await _transcriptRepository.savePreferences(
          snapshot.preferences.copyWith(transcriptionModel: activeModelKey),
        );
      }
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
          selectedModelKey: _transcriptionService.currentModelKey,
          initialized: true,
          clearDownloadProgress: true,
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
          clearDownloadProgress: true,
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

  @override
  Future<void> close() async {
    await _progressSubscription?.cancel();
    return super.close();
  }
}
