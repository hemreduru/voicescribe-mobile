import 'dart:async';

import 'package:voicescribe_mobile/data/services/auth/auth_api_client.dart';
import 'package:voicescribe_mobile/data/services/auth/secure_session_storage.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';

class VoiceScribeAuthRepository implements AuthRepository {
  VoiceScribeAuthRepository({
    AuthApiClient? apiClient,
    SecureSessionStorage? sessionStorage,
  }) : _apiClient = apiClient ?? const AuthApiClient(),
       _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final AuthApiClient _apiClient;
  final SecureSessionStorage _sessionStorage;
  final _sessionController = StreamController<AuthSessionState?>.broadcast();
  AuthSessionState? _cachedSession;

  @override
  Stream<AuthSessionState?> watchSession() => _sessionController.stream;

  @override
  AuthSessionState? currentSession() => _cachedSession;

  @override
  Future<AuthSessionState?> restoreSession() async {
    final stored = await _sessionStorage.read();
    if (stored == null || !stored.isAuthenticated) {
      await _setSession(null);
      return null;
    }

    final verified = await _apiClient.verifySession(stored);
    if (verified == null || !verified.isAuthenticated) {
      await _setSession(null);
      return null;
    }
    await _setSession(verified);
    return verified;
  }

  @override
  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) async {
    final session = await _apiClient.login(email: email, password: password);
    await _setSession(session);
    return session;
  }

  @override
  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) async {
    final session = await _apiClient.register(email: email, password: password);
    await _setSession(session);
    return session;
  }

  @override
  Future<void> logout() async {
    final token = _cachedSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      await _apiClient.logout(token);
    }
    await _setSession(null);
  }

  Future<void> dispose() async {
    await _sessionController.close();
  }

  Future<void> _setSession(AuthSessionState? session) async {
    _cachedSession = session;
    if (session == null) {
      await _sessionStorage.clear();
    } else {
      await _sessionStorage.write(session);
    }
    if (!_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }
}
