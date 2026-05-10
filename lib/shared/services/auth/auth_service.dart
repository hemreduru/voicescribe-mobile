import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:voicescribe_mobile/shared/utils/env_config.dart';
import 'package:voicescribe_mobile/shared/utils/logger.dart';

const _kStoredSessionKey = 'vs_backend_session_v1';

class VoiceScribeAuthException implements Exception {
  const VoiceScribeAuthException(this.message);

  final String message;

  @override
  String toString() => message;
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

  AuthSessionState copyWith({
    String? userId,
    String? email,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    bool clearRefreshToken = false,
    bool clearExpiresAt = false,
  }) {
    return AuthSessionState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: clearRefreshToken
          ? null
          : refreshToken ?? this.refreshToken,
      expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'email': email,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  static AuthSessionState? fromJson(Object? raw) {
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
}

class VoiceScribeAuthService {
  VoiceScribeAuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  AuthSessionState? _cachedSession;

  Future<AuthSessionState?> restoreSession() async {
    final raw = await _storage.read(key: _kStoredSessionKey);
    if (raw == null || raw.isEmpty) {
      _cachedSession = null;
      return null;
    }

    AuthSessionState? session;
    try {
      final decoded = jsonDecode(raw);
      session = AuthSessionState.fromJson(decoded);
    } catch (_) {
      session = null;
    }
    if (session == null || !session.isAuthenticated) {
      await _storage.delete(key: _kStoredSessionKey);
      _cachedSession = null;
      return null;
    }

    final meResponse = await _request(
      method: 'GET',
      path: '/api/v1/auth/me',
      token: session.accessToken,
    );

    if (meResponse.isNetworkFailure) {
      AppLogger.warning(
        'Keeping stored auth session because backend API is unreachable.',
      );
      _cachedSession = session;
      return session;
    }

    if (!meResponse.isSuccess) {
      if (!meResponse.isUnauthorized) {
        AppLogger.warning(
          'Keeping stored auth session after backend verification returned '
          '${meResponse.statusCode}.',
        );
        _cachedSession = session;
        return session;
      }
      await _storage.delete(key: _kStoredSessionKey);
      _cachedSession = null;
      return null;
    }

    final userMap = _toMap(meResponse.data?['user']);
    final resolved = session.copyWith(
      userId: _toText(userMap?['id']) ?? session.userId,
      email: _toText(userMap?['email']) ?? session.email,
    );
    await _persistSession(resolved);
    _cachedSession = resolved;
    return resolved;
  }

  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) {
    return _authenticate(
      path: '/api/v1/auth/register',
      payload: {
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) {
    return _authenticate(
      path: '/api/v1/auth/login',
      payload: {'email': email, 'password': password},
    );
  }

  Future<void> logout() async {
    final token = _cachedSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      await _request(
        method: 'POST',
        path: '/api/v1/auth/logout',
        payload: const <String, Object?>{},
        token: token,
      );
    }

    _cachedSession = null;
    await _storage.delete(key: _kStoredSessionKey);
  }

  AuthSessionState? currentUser() => _cachedSession;

  Future<AuthSessionState> _authenticate({
    required String path,
    required Map<String, Object?> payload,
  }) async {
    final response = await _request(
      method: 'POST',
      path: path,
      payload: payload,
    );
    if (!response.isSuccess) {
      throw VoiceScribeAuthException(
        response.message ?? 'Authentication failed.',
      );
    }

    final sessionMap = _toMap(response.data?['session']);
    final userMap = _toMap(response.data?['user']);

    final accessToken = _toText(sessionMap?['accessToken']);
    final userId = _toText(userMap?['id']);

    if (accessToken == null || userId == null) {
      throw const VoiceScribeAuthException(
        'Authentication response is incomplete.',
      );
    }

    final expiresInSeconds = _toInt(sessionMap?['expiresIn']);
    final expiresAt = expiresInSeconds == null
        ? null
        : DateTime.now().add(Duration(seconds: expiresInSeconds));

    final state = AuthSessionState(
      userId: userId,
      email: _toText(userMap?['email']) ?? '',
      accessToken: accessToken,
      refreshToken: _toText(sessionMap?['refreshToken']),
      expiresAt: expiresAt,
    );

    await _persistSession(state);
    _cachedSession = state;
    return state;
  }

  Future<void> _persistSession(AuthSessionState state) {
    return _storage.write(
      key: _kStoredSessionKey,
      value: jsonEncode(state.toJson()),
    );
  }

  Future<_ApiResponse> _request({
    required String method,
    required String path,
    Map<String, Object?>? payload,
    String? token,
  }) async {
    final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      AppLogger.debug('Auth request: $method $uri');
      final request = await client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (payload != null) {
        request.write(jsonEncode(payload));
      }

      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 20));

      Map<String, Object?>? parsed;
      if (body.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(body);
          parsed = _toMap(decoded);
        } on FormatException {
          parsed = null;
        }
      }

      final rawSuccess = parsed?['success'];
      final message = _toText(parsed?['message']) ?? _fallbackMessage(body);

      AppLogger.debug(
        'Auth response: $method $uri -> ${response.statusCode}'
        '${message == null ? '' : ' ($message)'}',
      );

      return _ApiResponse(
        statusCode: response.statusCode,
        success: rawSuccess is bool ? rawSuccess : null,
        message: message,
        data: _toMap(parsed?['data']),
      );
    } on SocketException catch (error) {
      AppLogger.warning('Auth socket error: $method $uri', error);
      return _ApiResponse(
        statusCode: 0,
        success: false,
        message:
            'Cannot reach backend API (${error.osError?.message ?? error.message}).',
      );
    } on HandshakeException catch (error) {
      AppLogger.warning('Auth TLS error: $method $uri', error);
      return _ApiResponse(
        statusCode: 0,
        success: false,
        message:
            'TLS handshake failed while connecting backend API (${error.message}).',
      );
    } on HttpException catch (error) {
      AppLogger.warning('Auth HTTP error: $method $uri', error);
      return _ApiResponse(
        statusCode: 0,
        success: false,
        message: error.message,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Auth unexpected error: $method $uri', error, stackTrace);
      return _ApiResponse(
        statusCode: 0,
        success: false,
        message: 'Unexpected auth error (${error.runtimeType}).',
      );
    } finally {
      client.close(force: true);
    }
  }

  static String? _fallbackMessage(String body) {
    final text = body.trim();
    if (text.isEmpty) {
      return null;
    }
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 180) {
      return normalized;
    }
    return '${normalized.substring(0, 180)}...';
  }

  static Map<String, Object?>? _toMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String? _toText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class _ApiResponse {
  const _ApiResponse({
    required this.statusCode,
    this.success,
    this.message,
    this.data,
  });

  final int statusCode;
  final bool? success;
  final String? message;
  final Map<String, Object?>? data;

  bool get isSuccess {
    final httpSuccess = statusCode >= 200 && statusCode < 300;
    final semanticSuccess = success ?? true;
    return httpSuccess && semanticSuccess;
  }

  bool get isNetworkFailure => statusCode == 0;

  bool get isUnauthorized =>
      statusCode == HttpStatus.unauthorized ||
      statusCode == HttpStatus.forbidden;
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
