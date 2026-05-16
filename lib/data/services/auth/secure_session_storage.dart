import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

const _kStoredSessionKey = 'vs_backend_session_v1';

class SecureSessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<AuthSessionState?> read() async {
    final raw = await _storage.read(key: _kStoredSessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return _sessionFromJson(jsonDecode(raw));
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> write(AuthSessionState session) {
    return _storage.write(
      key: _kStoredSessionKey,
      value: jsonEncode(_sessionToJson(session)),
    );
  }

  Future<void> clear() => _storage.delete(key: _kStoredSessionKey);

  AuthSessionState? _sessionFromJson(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final userId = _textOrNull(map['userId']);
    final accessToken = _textOrNull(map['accessToken']);
    if (userId == null || accessToken == null) {
      return null;
    }
    return AuthSessionState(
      userId: userId,
      email: _textOrNull(map['email']) ?? '',
      accessToken: accessToken,
      refreshToken: _textOrNull(map['refreshToken']),
      expiresAt: _dateOrNull(map['expiresAt']),
    );
  }

  Map<String, Object?> _sessionToJson(AuthSessionState session) {
    return {
      'userId': session.userId,
      'email': session.email,
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
      'expiresAt': session.expiresAt?.toIso8601String(),
    };
  }

  String? _textOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _dateOrNull(Object? value) {
    final text = _textOrNull(value);
    if (text == null) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
