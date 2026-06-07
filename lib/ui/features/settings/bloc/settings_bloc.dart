import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/services/llm/llm_model_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsSubscriptionRequested extends SettingsEvent {
  const SettingsSubscriptionRequested();
}

final class SettingsSummaryProviderChanged extends SettingsEvent {
  const SettingsSummaryProviderChanged(this.value);

  final String value;
}

final class SettingsSummaryLengthChanged extends SettingsEvent {
  const SettingsSummaryLengthChanged(this.value);

  final String value;
}

final class SettingsThemeModeChanged extends SettingsEvent {
  const SettingsThemeModeChanged(this.value);

  final String value;
}

final class SettingsLocalePreferenceChanged extends SettingsEvent {
  const SettingsLocalePreferenceChanged(this.value);

  final String value;
}

final class SettingsTranscriptionModelChanged extends SettingsEvent {
  const SettingsTranscriptionModelChanged(this.value);

  final String value;
}

final class SettingsTranscriptionLanguageChanged extends SettingsEvent {
  const SettingsTranscriptionLanguageChanged(this.value);

  final String value;
}

final class SettingsLocalLlmDownloadRequested extends SettingsEvent {
  const SettingsLocalLlmDownloadRequested();
}

final class _SettingsLocalLlmProgressChanged extends SettingsEvent {
  const _SettingsLocalLlmProgressChanged(this.percent);

  final double? percent;
}

final class SettingsLogoutRequested extends SettingsEvent {
  const SettingsLogoutRequested();
}

final class SettingsManualSyncRequested extends SettingsEvent {
  const SettingsManualSyncRequested();
}

final class _SettingsSnapshotChanged extends SettingsEvent {
  const _SettingsSnapshotChanged(this.snapshot);

  final TranscriptSnapshot snapshot;
}

final class _SettingsSessionChanged extends SettingsEvent {
  const _SettingsSessionChanged(this.session);

  final AuthSessionState? session;
}

final class _SettingsSyncEventChanged extends SettingsEvent {
  const _SettingsSyncEventChanged(this.event);

  final SyncEvent event;
}

class SettingsState {
  const SettingsState({
    this.preferences = const AppPreferences(),
    this.session,
    this.loggingOut = false,
    this.syncing = false,
    this.lastSyncAt,
    this.syncErrorMessage,
    this.errorMessage,
    this.modelCatalog = const [],
    this.modelCatalogLoading = false,
    this.modelCatalogErrorMessage,
    this.deviceProfile,
    this.applyingTranscriptionModel = false,
    this.pendingSyncCount = 0,
    this.localLlmEntry,
    this.localLlmDownloading = false,
    this.localLlmDownloadProgress,
    this.localLlmErrorMessage,
  });

  final AppPreferences preferences;
  final AuthSessionState? session;
  final bool loggingOut;
  final bool syncing;
  final DateTime? lastSyncAt;
  final String? syncErrorMessage;
  final String? errorMessage;
  final List<TranscriptionModelCatalogEntry> modelCatalog;
  final bool modelCatalogLoading;
  final String? modelCatalogErrorMessage;
  final DevicePerformanceProfile? deviceProfile;
  final bool applyingTranscriptionModel;

  /// Number of local transcripts not yet backed up to the server. Surfaced so
  /// the user can trust that nothing is stuck unsynced.
  final int pendingSyncCount;

  /// On-device summarization model status (Gemma). Null until resolved.
  final LocalLlmModelCatalogEntry? localLlmEntry;
  final bool localLlmDownloading;
  final double? localLlmDownloadProgress;
  final String? localLlmErrorMessage;

  SettingsState copyWith({
    AppPreferences? preferences,
    AuthSessionState? session,
    bool clearSession = false,
    bool? loggingOut,
    bool? syncing,
    DateTime? lastSyncAt,
    bool clearLastSyncAt = false,
    String? syncErrorMessage,
    bool clearSyncErrorMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<TranscriptionModelCatalogEntry>? modelCatalog,
    bool? modelCatalogLoading,
    String? modelCatalogErrorMessage,
    bool clearModelCatalogErrorMessage = false,
    DevicePerformanceProfile? deviceProfile,
    bool clearDeviceProfile = false,
    bool? applyingTranscriptionModel,
    int? pendingSyncCount,
    LocalLlmModelCatalogEntry? localLlmEntry,
    bool? localLlmDownloading,
    double? localLlmDownloadProgress,
    bool clearLocalLlmDownloadProgress = false,
    String? localLlmErrorMessage,
    bool clearLocalLlmErrorMessage = false,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      session: clearSession ? null : session ?? this.session,
      loggingOut: loggingOut ?? this.loggingOut,
      syncing: syncing ?? this.syncing,
      lastSyncAt: clearLastSyncAt ? null : lastSyncAt ?? this.lastSyncAt,
      syncErrorMessage: clearSyncErrorMessage
          ? null
          : syncErrorMessage ?? this.syncErrorMessage,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      modelCatalog: modelCatalog ?? this.modelCatalog,
      modelCatalogLoading: modelCatalogLoading ?? this.modelCatalogLoading,
      modelCatalogErrorMessage: clearModelCatalogErrorMessage
          ? null
          : modelCatalogErrorMessage ?? this.modelCatalogErrorMessage,
      deviceProfile: clearDeviceProfile
          ? null
          : deviceProfile ?? this.deviceProfile,
      applyingTranscriptionModel:
          applyingTranscriptionModel ?? this.applyingTranscriptionModel,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      localLlmEntry: localLlmEntry ?? this.localLlmEntry,
      localLlmDownloading: localLlmDownloading ?? this.localLlmDownloading,
      localLlmDownloadProgress: clearLocalLlmDownloadProgress
          ? null
          : localLlmDownloadProgress ?? this.localLlmDownloadProgress,
      localLlmErrorMessage: clearLocalLlmErrorMessage
          ? null
          : localLlmErrorMessage ?? this.localLlmErrorMessage,
    );
  }
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required TranscriptRepository transcriptRepository,
    required AuthRepository authRepository,
    required SyncQueueService syncQueueService,
    required TranscriptionService transcriptionService,
    required LocalLlmModelService localLlmModelService,
  }) : _transcriptRepository = transcriptRepository,
       _authRepository = authRepository,
       _syncQueueService = syncQueueService,
       _transcriptionService = transcriptionService,
       _localLlmModelService = localLlmModelService,
       super(const SettingsState()) {
    on<SettingsSubscriptionRequested>(_onSubscriptionRequested);
    on<_SettingsSnapshotChanged>(_onSnapshotChanged);
    on<_SettingsSessionChanged>(_onSessionChanged);
    on<_SettingsSyncEventChanged>(_onSyncEventChanged);
    on<SettingsSummaryProviderChanged>(_onSummaryProviderChanged);
    on<SettingsSummaryLengthChanged>(_onSummaryLengthChanged);
    on<SettingsThemeModeChanged>(_onThemeModeChanged);
    on<SettingsLocalePreferenceChanged>(_onLocalePreferenceChanged);
    on<SettingsTranscriptionModelChanged>(_onTranscriptionModelChanged);
    on<SettingsTranscriptionLanguageChanged>(_onTranscriptionLanguageChanged);
    on<SettingsLocalLlmDownloadRequested>(_onLocalLlmDownloadRequested);
    on<_SettingsLocalLlmProgressChanged>(_onLocalLlmProgressChanged);
    on<SettingsManualSyncRequested>(_onManualSyncRequested);
    on<SettingsLogoutRequested>(_onLogoutRequested);
  }

  final TranscriptRepository _transcriptRepository;
  final AuthRepository _authRepository;
  final SyncQueueService _syncQueueService;
  final TranscriptionService _transcriptionService;
  final LocalLlmModelService _localLlmModelService;
  StreamSubscription<TranscriptSnapshot>? _snapshotSubscription;
  StreamSubscription<AuthSessionState?>? _sessionSubscription;
  StreamSubscription<SyncEvent>? _syncSubscription;
  StreamSubscription<ModelDownloadProgress>? _localLlmProgressSubscription;

  Future<void> _onSubscriptionRequested(
    SettingsSubscriptionRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _syncSubscription?.cancel();
    final snapshot = await _transcriptRepository.loadSnapshot();
    // Apply the persisted transcription language so it is active for the next
    // recording without needing the user to re-open settings.
    _transcriptionService.setTranscriptionLanguage(
      snapshot.preferences.transcriptionLanguage,
    );
    final lastSyncAt = await _syncQueueService.readLastSuccessfulSyncAt();
    emit(
      state.copyWith(
        preferences: snapshot.preferences,
        session: _authRepository.currentSession(),
        clearSession: _authRepository.currentSession() == null,
        lastSyncAt: lastSyncAt,
        pendingSyncCount: _pendingSyncCount(snapshot),
      ),
    );
    await _loadModelCatalog(emit);
    await _loadLocalLlmEntry(emit);
    await _localLlmProgressSubscription?.cancel();
    _localLlmProgressSubscription = _localLlmModelService.downloadProgress.listen(
      (progress) => add(_SettingsLocalLlmProgressChanged(progress.percent)),
    );
    _snapshotSubscription = _transcriptRepository.watchSnapshot().listen(
      (snapshot) => add(_SettingsSnapshotChanged(snapshot)),
    );
    _sessionSubscription = _authRepository.watchSession().listen(
      (session) => add(_SettingsSessionChanged(session)),
    );
    _syncSubscription = _syncQueueService.syncEvents.listen(
      (event) => add(_SettingsSyncEventChanged(event)),
    );
  }

  void _onSnapshotChanged(
    _SettingsSnapshotChanged event,
    Emitter<SettingsState> emit,
  ) {
    emit(
      state.copyWith(
        preferences: event.snapshot.preferences,
        pendingSyncCount: _pendingSyncCount(event.snapshot),
      ),
    );
  }

  int _pendingSyncCount(TranscriptSnapshot snapshot) {
    // Snapshots only contain non-deleted rows, so an un-synced transcript is
    // simply one whose sync status hasn't reached `synced` yet.
    return snapshot.transcripts
        .where((t) => t.syncStatus != SyncStatus.synced)
        .length;
  }

  void _onSessionChanged(
    _SettingsSessionChanged event,
    Emitter<SettingsState> emit,
  ) {
    emit(
      state.copyWith(
        session: event.session,
        clearSession: event.session == null,
      ),
    );
  }

  void _onSyncEventChanged(
    _SettingsSyncEventChanged event,
    Emitter<SettingsState> emit,
  ) {
    switch (event.event.type) {
      case SyncEventType.started:
        if (event.event.trigger == SyncTrigger.manual ||
            event.event.trigger == SyncTrigger.refresh) {
          emit(state.copyWith(syncing: true, clearSyncErrorMessage: true));
        }
      case SyncEventType.success:
        emit(
          state.copyWith(
            syncing: false,
            lastSyncAt: event.event.occurredAt,
            clearSyncErrorMessage: true,
          ),
        );
      case SyncEventType.failure:
        if (event.event.trigger == SyncTrigger.manual ||
            event.event.trigger == SyncTrigger.refresh) {
          emit(
            state.copyWith(
              syncing: false,
              syncErrorMessage: event.event.error ?? 'Sync failed.',
            ),
          );
        }
    }
  }

  Future<void> _onSummaryProviderChanged(
    SettingsSummaryProviderChanged event,
    Emitter<SettingsState> emit,
  ) {
    return _savePreferences(
      emit,
      state.preferences.copyWith(
        summaryProvider: AppPreferences.normalizeSummaryProvider(event.value),
      ),
    );
  }

  Future<void> _onSummaryLengthChanged(
    SettingsSummaryLengthChanged event,
    Emitter<SettingsState> emit,
  ) {
    return _savePreferences(
      emit,
      state.preferences.copyWith(
        summaryLength: AppPreferences.normalizeSummaryLength(event.value),
      ),
    );
  }

  Future<void> _onThemeModeChanged(
    SettingsThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) {
    return _savePreferences(
      emit,
      state.preferences.copyWith(
        themeMode: AppPreferences.normalizeThemeMode(event.value),
      ),
    );
  }

  Future<void> _onLocalePreferenceChanged(
    SettingsLocalePreferenceChanged event,
    Emitter<SettingsState> emit,
  ) {
    return _savePreferences(
      emit,
      state.preferences.copyWith(
        localePreference: AppPreferences.normalizeLocalePreference(event.value),
      ),
    );
  }

  Future<void> _onTranscriptionModelChanged(
    SettingsTranscriptionModelChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final normalized = AppPreferences.normalizeTranscriptionModel(event.value);
    if (normalized == state.preferences.transcriptionModel) {
      return;
    }
    emit(
      state.copyWith(applyingTranscriptionModel: true, clearErrorMessage: true),
    );
    try {
      await _transcriptionService.selectModel(whisperModelFromKey(normalized));
      await _transcriptionService.ensureModel();
      // selectModel may reject a model that's too heavy for the device and stay
      // on the current one, so persist what was actually applied.
      final applied = AppPreferences.normalizeTranscriptionModel(
        _transcriptionService.currentModelKey,
      );
      await _savePreferences(
        emit,
        state.preferences.copyWith(transcriptionModel: applied),
      );
      emit(state.copyWith(applyingTranscriptionModel: false));
      await _loadModelCatalog(emit);
    } catch (error) {
      // A failed switch (e.g. the new model's download failed) must not leave
      // the service pointing at a model with no file on disk. Roll it back to
      // the last persisted (known-good, already-downloaded) model so recording
      // keeps working and the service matches the saved preference.
      try {
        await _transcriptionService.selectModel(
          whisperModelFromKey(state.preferences.transcriptionModel),
        );
        await _transcriptionService.ensureModel();
      } catch (_) {
        // Best effort; nothing more we can safely do here.
      }
      emit(
        state.copyWith(
          applyingTranscriptionModel: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onTranscriptionLanguageChanged(
    SettingsTranscriptionLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final normalized = AppPreferences.normalizeTranscriptionLanguage(
      event.value,
    );
    _transcriptionService.setTranscriptionLanguage(normalized);
    await _savePreferences(
      emit,
      state.preferences.copyWith(transcriptionLanguage: normalized),
    );
  }

  Future<void> _onLogoutRequested(
    SettingsLogoutRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(loggingOut: true, clearErrorMessage: true));
    try {
      await _authRepository.logout();
      emit(
        state.copyWith(
          loggingOut: false,
          clearSession: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(loggingOut: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLocalLlmDownloadRequested(
    SettingsLocalLlmDownloadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.localLlmDownloading) {
      return;
    }
    emit(
      state.copyWith(
        localLlmDownloading: true,
        localLlmDownloadProgress: 0,
        clearLocalLlmErrorMessage: true,
      ),
    );
    try {
      await _localLlmModelService.download();
      emit(
        state.copyWith(
          localLlmDownloading: false,
          clearLocalLlmDownloadProgress: true,
        ),
      );
      await _loadLocalLlmEntry(emit);
    } catch (error) {
      emit(
        state.copyWith(
          localLlmDownloading: false,
          clearLocalLlmDownloadProgress: true,
          localLlmErrorMessage: error.toString(),
        ),
      );
    }
  }

  void _onLocalLlmProgressChanged(
    _SettingsLocalLlmProgressChanged event,
    Emitter<SettingsState> emit,
  ) {
    if (!state.localLlmDownloading) {
      return;
    }
    emit(state.copyWith(localLlmDownloadProgress: event.percent));
  }

  Future<void> _loadLocalLlmEntry(Emitter<SettingsState> emit) async {
    try {
      final entry = await _localLlmModelService.catalogEntry();
      emit(state.copyWith(localLlmEntry: entry));
    } catch (error) {
      emit(state.copyWith(localLlmErrorMessage: error.toString()));
    }
  }

  Future<void> _onManualSyncRequested(
    SettingsManualSyncRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(syncing: true, clearSyncErrorMessage: true));
    try {
      await _syncQueueService.runManualSync();
      final lastSyncAt = await _syncQueueService.readLastSuccessfulSyncAt();
      emit(
        state.copyWith(
          syncing: false,
          lastSyncAt: lastSyncAt,
          clearSyncErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(syncing: false, syncErrorMessage: error.toString()));
    }
  }

  Future<void> _savePreferences(
    Emitter<SettingsState> emit,
    AppPreferences preferences,
  ) async {
    emit(state.copyWith(preferences: preferences, clearErrorMessage: true));
    try {
      await _transcriptRepository.savePreferences(preferences);
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> _loadModelCatalog(Emitter<SettingsState> emit) async {
    emit(
      state.copyWith(
        modelCatalogLoading: true,
        clearModelCatalogErrorMessage: true,
      ),
    );
    try {
      final profile = await _transcriptionService.resolveDeviceProfile();
      final catalog = await _transcriptionService.listModelCatalog();
      emit(
        state.copyWith(
          modelCatalogLoading: false,
          deviceProfile: profile,
          modelCatalog: catalog,
          clearModelCatalogErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          modelCatalogLoading: false,
          modelCatalogErrorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _syncSubscription?.cancel();
    await _localLlmProgressSubscription?.cancel();
    return super.close();
  }
}
