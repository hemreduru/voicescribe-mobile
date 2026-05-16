import 'dart:async';

import 'package:bloc/bloc.dart';
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

final class SettingsLogoutRequested extends SettingsEvent {
  const SettingsLogoutRequested();
}

final class _SettingsSnapshotChanged extends SettingsEvent {
  const _SettingsSnapshotChanged(this.snapshot);

  final TranscriptSnapshot snapshot;
}

final class _SettingsSessionChanged extends SettingsEvent {
  const _SettingsSessionChanged(this.session);

  final AuthSessionState? session;
}

class SettingsState {
  const SettingsState({
    this.preferences = const AppPreferences(),
    this.session,
    this.loggingOut = false,
    this.errorMessage,
  });

  final AppPreferences preferences;
  final AuthSessionState? session;
  final bool loggingOut;
  final String? errorMessage;

  SettingsState copyWith({
    AppPreferences? preferences,
    AuthSessionState? session,
    bool clearSession = false,
    bool? loggingOut,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      session: clearSession ? null : session ?? this.session,
      loggingOut: loggingOut ?? this.loggingOut,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required TranscriptRepository transcriptRepository,
    required AuthRepository authRepository,
  }) : _transcriptRepository = transcriptRepository,
       _authRepository = authRepository,
       super(const SettingsState()) {
    on<SettingsSubscriptionRequested>(_onSubscriptionRequested);
    on<_SettingsSnapshotChanged>(_onSnapshotChanged);
    on<_SettingsSessionChanged>(_onSessionChanged);
    on<SettingsSummaryProviderChanged>(_onSummaryProviderChanged);
    on<SettingsSummaryLengthChanged>(_onSummaryLengthChanged);
    on<SettingsThemeModeChanged>(_onThemeModeChanged);
    on<SettingsLocalePreferenceChanged>(_onLocalePreferenceChanged);
    on<SettingsLogoutRequested>(_onLogoutRequested);
  }

  final TranscriptRepository _transcriptRepository;
  final AuthRepository _authRepository;
  StreamSubscription<TranscriptSnapshot>? _snapshotSubscription;
  StreamSubscription<AuthSessionState?>? _sessionSubscription;

  Future<void> _onSubscriptionRequested(
    SettingsSubscriptionRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    await _sessionSubscription?.cancel();
    final snapshot = await _transcriptRepository.loadSnapshot();
    emit(
      state.copyWith(
        preferences: snapshot.preferences,
        session: _authRepository.currentSession(),
        clearSession: _authRepository.currentSession() == null,
      ),
    );
    _snapshotSubscription = _transcriptRepository.watchSnapshot().listen(
      (snapshot) => add(_SettingsSnapshotChanged(snapshot)),
    );
    _sessionSubscription = _authRepository.watchSession().listen(
      (session) => add(_SettingsSessionChanged(session)),
    );
  }

  void _onSnapshotChanged(
    _SettingsSnapshotChanged event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(preferences: event.snapshot.preferences));
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

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    await _sessionSubscription?.cancel();
    return super.close();
  }
}
