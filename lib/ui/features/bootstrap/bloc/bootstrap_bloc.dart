import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
// ignore_for_file: avoid_slow_async_io
import 'package:path_provider/path_provider.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/use_cases/repair_stale_recordings.dart';

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

final class BootstrapTranscriptionModelChanged extends BootstrapEvent {
  const BootstrapTranscriptionModelChanged(this.modelKey);

  final String modelKey;
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
  });

  final ModelBootstrapState modelState;
  final String selectedModelKey;
  final ModelDownloadProgress? downloadProgress;
  final String? errorMessage;
  final bool initialized;

  bool get isReady => initialized && modelState == ModelBootstrapState.ready;

  BootstrapState copyWith({
    ModelBootstrapState? modelState,
    String? selectedModelKey,
    ModelDownloadProgress? downloadProgress,
    bool clearDownloadProgress = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? initialized,
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
    on<BootstrapTranscriptionModelChanged>(_onTranscriptionModelChanged);
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

  Future<void> _onTranscriptionModelChanged(
    BootstrapTranscriptionModelChanged event,
    Emitter<BootstrapState> emit,
  ) async {
    final normalizedModelKey = AppPreferences.normalizeTranscriptionModel(
      event.modelKey,
    );
    emit(
      state.copyWith(
        modelState: ModelBootstrapState.bootstrapping,
        selectedModelKey: normalizedModelKey,
        clearErrorMessage: true,
      ),
    );

    try {
      await _transcriptionService.selectModel(
        whisperModelFromKey(normalizedModelKey),
      );
      await _transcriptionService.ensureModel();
      emit(
        state.copyWith(
          modelState: ModelBootstrapState.ready,
          selectedModelKey: normalizedModelKey,
          initialized: true,
          clearDownloadProgress: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          modelState: ModelBootstrapState.failed,
          selectedModelKey: normalizedModelKey,
          initialized: true,
          clearDownloadProgress: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onProgressChanged(
    _BootstrapProgressChanged event,
    Emitter<BootstrapState> emit,
  ) {
    emit(state.copyWith(downloadProgress: event.progress));
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
      const modelKey = 'base';

      await _transcriptionService.selectModel(whisperModelFromKey(modelKey));
      await RepairStaleRecordingsUseCase(
        _transcriptRepository,
      ).execute(snapshot);
      await _transcriptionService.ensureModel();
      await _transcriptRepository.refresh();
      await _cleanupOrphanChunkFiles(snapshot);
      emit(
        state.copyWith(
          modelState: ModelBootstrapState.ready,
          selectedModelKey: modelKey,
          initialized: true,
          clearDownloadProgress: true,
          clearErrorMessage: true,
        ),
      );
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

  Future<void> _cleanupOrphanChunkFiles(TranscriptSnapshot snapshot) async {
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
        if (entity is File && !knownPaths.contains(entity.path)) {
          try {
            await entity.delete();
          } catch (_) {
            // Best-effort cleanup.
          }
        }
      }
    } catch (_) {
      // Best-effort cleanup; do not fail bootstrap.
    }
  }

  @override
  Future<void> close() async {
    await _progressSubscription?.cancel();
    return super.close();
  }
}
