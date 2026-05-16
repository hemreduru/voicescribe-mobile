import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
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

final class _BootstrapProgressChanged extends BootstrapEvent {
  const _BootstrapProgressChanged(this.progress);

  final ModelDownloadProgress progress;
}

class BootstrapState {
  const BootstrapState({
    this.modelState = ModelBootstrapState.bootstrapping,
    this.downloadProgress,
    this.errorMessage,
    this.initialized = false,
  });

  final ModelBootstrapState modelState;
  final ModelDownloadProgress? downloadProgress;
  final String? errorMessage;
  final bool initialized;

  bool get isReady => initialized && modelState == ModelBootstrapState.ready;

  BootstrapState copyWith({
    ModelBootstrapState? modelState,
    ModelDownloadProgress? downloadProgress,
    bool clearDownloadProgress = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? initialized,
  }) {
    return BootstrapState(
      modelState: modelState ?? this.modelState,
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

  Future<void> _bootstrap(Emitter<BootstrapState> emit) async {
    emit(
      state.copyWith(
        modelState: ModelBootstrapState.bootstrapping,
        clearErrorMessage: true,
      ),
    );
    try {
      final snapshot = await _transcriptRepository.loadSnapshot();
      await RepairStaleRecordingsUseCase(
        _transcriptRepository,
      ).execute(snapshot);
      await _transcriptionService.ensureModel();
      await _transcriptRepository.refresh();
      emit(
        state.copyWith(
          modelState: ModelBootstrapState.ready,
          initialized: true,
          clearErrorMessage: true,
        ),
      );
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

  @override
  Future<void> close() async {
    await _progressSubscription?.cancel();
    return super.close();
  }
}
