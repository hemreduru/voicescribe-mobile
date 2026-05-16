import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:voicescribe_mobile/data/services/auth/auth_exception.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

class AuthApiClient {
  const AuthApiClient();

  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) {
    return authenticate(
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
    return authenticate(
      path: '/api/v1/auth/login',
      payload: {'email': email, 'password': password},
    );
  }

  Future<AuthSessionState> authenticate({
    required String path,
    required Map<String, Object?> payload,
  }) async {
    final response = await request(
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
    return AuthSessionState(
      userId: userId,
      email: _toText(userMap?['email']) ?? '',
      accessToken: accessToken,
      refreshToken: _toText(sessionMap?['refreshToken']),
      expiresAt: expiresInSeconds == null
          ? null
          : DateTime.now().add(Duration(seconds: expiresInSeconds)),
    );
  }

  Future<AuthSessionState?> verifySession(AuthSessionState session) async {
    final response = await request(
      method: 'GET',
      path: '/api/v1/auth/me',
      token: session.accessToken,
    );
    if (response.isNetworkFailure) {
      AppLogger.warning(
        'Keeping stored auth session because backend API is unreachable.',
      );
      return session;
    }
    if (!response.isSuccess) {
      if (!response.isUnauthorized) {
        AppLogger.warning(
          'Keeping stored auth session after backend verification returned '
          '${response.statusCode}.',
        );
        return session;
      }
      return null;
    }

    final userMap = _toMap(response.data?['user']);
    return session.copyWith(
      userId: _toText(userMap?['id']) ?? session.userId,
      email: _toText(userMap?['email']) ?? session.email,
    );
  }

  Future<void> logout(String token) async {
    if (token.isEmpty) {
      return;
    }
    await request(
      method: 'POST',
      path: '/api/v1/auth/logout',
      payload: const <String, Object?>{},
      token: token,
    );
  }

  Future<ApiResponse> request({
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
          parsed = _toMap(jsonDecode(body));
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

      return ApiResponse(
        statusCode: response.statusCode,
        success: rawSuccess is bool ? rawSuccess : null,
        message: message,
        data: _toMap(parsed?['data']),
      );
    } on SocketException catch (error) {
      AppLogger.warning('Auth socket error: $method $uri', error);
      return ApiResponse(
        statusCode: 0,
        success: false,
        message:
            'Cannot reach backend API (${error.osError?.message ?? error.message}).',
      );
    } on HandshakeException catch (error) {
      AppLogger.warning('Auth TLS error: $method $uri', error);
      return ApiResponse(
        statusCode: 0,
        success: false,
        message:
            'TLS handshake failed while connecting backend API (${error.message}).',
      );
    } on HttpException catch (error) {
      AppLogger.warning('Auth HTTP error: $method $uri', error);
      return ApiResponse(statusCode: 0, success: false, message: error.message);
    } catch (error, stackTrace) {
      AppLogger.error('Auth unexpected error: $method $uri', error, stackTrace);
      return ApiResponse(
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

class ApiResponse {
  const ApiResponse({
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
