import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/services/auth/auth_exception.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, submitting }

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

final class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class _AuthSessionChanged extends AuthEvent {
  const _AuthSessionChanged(this.session);

  final AuthSessionState? session;
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.session,
    this.errorMessage,
    this.passwordlessDebugAuth = false,
  });

  final AuthStatus status;
  final AuthSessionState? session;
  final String? errorMessage;
  final bool passwordlessDebugAuth;

  bool get isResolved => status != AuthStatus.unknown;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && (session?.isAuthenticated ?? false);

  AuthState copyWith({
    AuthStatus? status,
    AuthSessionState? session,
    bool clearSession = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? passwordlessDebugAuth,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      passwordlessDebugAuth:
          passwordlessDebugAuth ?? this.passwordlessDebugAuth,
    );
  }
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required TranscriptRepository transcriptRepository,
    required SyncQueueService syncQueueService,
  }) : _authRepository = authRepository,
       _transcriptRepository = transcriptRepository,
       _syncQueueService = syncQueueService,
       super(AuthState(passwordlessDebugAuth: EnvConfig.isTestEnvironment)) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<_AuthSessionChanged>(_onSessionChanged);
    _sessionSubscription = _authRepository.watchSession().listen(
      (session) => add(_AuthSessionChanged(session)),
    );
  }

  final AuthRepository _authRepository;
  final TranscriptRepository _transcriptRepository;
  final SyncQueueService _syncQueueService;
  StreamSubscription<AuthSessionState?>? _sessionSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final session = await _authRepository.restoreSession();
      await _startSyncIfAuthenticated(session);
      emit(
        state.copyWith(
          status: (session?.isAuthenticated ?? false)
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          session: session,
          clearSession: session == null,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearSession: true,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    await _authenticate(
      emit,
      () => _authRepository.login(
        email: event.email,
        password: _passwordFor(event.password),
      ),
    );
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    await _authenticate(
      emit,
      () => _authRepository.register(
        email: event.email,
        password: _passwordFor(event.password),
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(status: AuthStatus.submitting, clearErrorMessage: true),
    );
    try {
      await _authRepository.logout();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearSession: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  Future<void> _authenticate(
    Emitter<AuthState> emit,
    Future<AuthSessionState> Function() action,
  ) async {
    emit(
      state.copyWith(status: AuthStatus.submitting, clearErrorMessage: true),
    );
    try {
      final session = await action();
      await _startSyncIfAuthenticated(session);
      await _syncQueueService.triggerSyncIfOnline();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> _onSessionChanged(
    _AuthSessionChanged event,
    Emitter<AuthState> emit,
  ) async {
    final session = event.session;
    emit(
      state.copyWith(
        status: (session?.isAuthenticated ?? false)
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        session: session,
        clearSession: session == null,
      ),
    );
  }

  Future<void> _startSyncIfAuthenticated(AuthSessionState? session) async {
    if (session?.isAuthenticated != true) {
      return;
    }
    try {
      await _syncQueueService.start(
        accessTokenProvider: () async =>
            _authRepository.currentSession()?.accessToken,
        onSyncComplete: _transcriptRepository.refresh,
      );
    } catch (_) {
      // Connectivity can be unavailable in tests or unsupported platforms.
    }
  }

  String _passwordFor(String raw) {
    return EnvConfig.isTestEnvironment ? 'debug' : raw;
  }

  String _messageFor(Object error) {
    if (error is VoiceScribeAuthException) {
      return error.message;
    }
    return error.toString();
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    return super.close();
  }
}
