import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kStoredSessionKey = 'vs_supabase_session_v1';

class RegistrationPendingVerificationException implements Exception {
  const RegistrationPendingVerificationException();

  @override
  String toString() =>
      'Kayıt tamamlandı. Devam etmek için e-posta adresinizi doğrulayıp giriş yapın.';
}

class AuthSessionState {
  const AuthSessionState({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String userId;
  final String email;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool get isAuthenticated => userId.isNotEmpty && accessToken.isNotEmpty;

  static AuthSessionState? fromSession(Session? session) {
    if (session == null || session.user.id.isEmpty) {
      return null;
    }
    return AuthSessionState(
      userId: session.user.id,
      email: session.user.email ?? '',
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
    );
  }
}

class VoiceScribeAuthService {
  VoiceScribeAuthService({
    SupabaseClient? client,
    FlutterSecureStorage? storage,
  }) : _client = _resolveClient(client),
       _storage = storage ?? const FlutterSecureStorage();

  final SupabaseClient? _client;
  final FlutterSecureStorage _storage;

  static SupabaseClient? _resolveClient(SupabaseClient? explicitClient) {
    if (explicitClient != null) {
      return explicitClient;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<AuthSessionState?> restoreSession() async {
    if (_client == null) {
      return null;
    }
    final current = AuthSessionState.fromSession(_client.auth.currentSession);
    if (current != null) {
      await _persistSession(_client.auth.currentSession);
      return current;
    }

    final raw = await _storage.read(key: _kStoredSessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final response = await _client.auth.recoverSession(raw);
      await _persistSession(response.session);
      return AuthSessionState.fromSession(response.session);
    } catch (_) {
      await _storage.delete(key: _kStoredSessionKey);
      return null;
    }
  }

  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw StateError('Supabase client is not initialized.');
    }
    await _client.auth.signUp(email: email, password: password);

    final immediateState = AuthSessionState.fromSession(
      _client.auth.currentSession,
    );
    if (immediateState != null) {
      await _persistSession(_client.auth.currentSession);
      return immediateState;
    }

    try {
      final loginResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final loginState = AuthSessionState.fromSession(loginResponse.session);
      if (loginState != null) {
        await _persistSession(loginResponse.session);
        return loginState;
      }
    } on AuthException catch (_) {
      // Email verification may be required on Supabase project settings.
    }

    throw const RegistrationPendingVerificationException();
  }

  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw StateError('Supabase client is not initialized.');
    }
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final state = AuthSessionState.fromSession(response.session);
    if (state == null) {
      throw StateError('Supabase session not available after login.');
    }
    await _persistSession(response.session);
    return state;
  }

  Future<void> logout() async {
    if (_client != null) {
      await _client.auth.signOut();
    }
    await _storage.delete(key: _kStoredSessionKey);
  }

  AuthSessionState? currentUser() {
    if (_client == null) {
      return null;
    }
    return AuthSessionState.fromSession(_client.auth.currentSession);
  }

  Future<void> _persistSession(Session? session) async {
    if (session == null) {
      await _storage.delete(key: _kStoredSessionKey);
      return;
    }
    await _storage.write(
      key: _kStoredSessionKey,
      value: jsonEncode(session.toJson()),
    );
  }
}
