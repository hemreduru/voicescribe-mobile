import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

class TranscriptApiClient {
  const TranscriptApiClient();

  /// Fetches the full transcript list from the server.
  /// Returns the raw `data` list on success, throws on failure.
  Future<List<Map<String, Object?>>> fetchTranscripts({
    required String token,
  }) async {
    final response = await request(
      method: 'GET',
      path: '/api/v1/transcripts',
      token: token,
    );
    if (!response.isSuccess) {
      if (response.isNetworkFailure) {
        throw const TranscriptFetchException(
          'Network unavailable while fetching transcripts.',
        );
      }
      throw TranscriptFetchException(
        'Failed to fetch transcripts: ${response.message ?? 'HTTP ${response.statusCode}'}',
      );
    }

    final data = response.data;
    if (data is! List) {
      throw const TranscriptFetchException(
        'Invalid transcript list response: data is not a list.',
      );
    }

    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key?.toString() ?? '', value),
          ),
        )
        .toList(growable: false);
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
      AppLogger.debug('Transcript API request: $method $uri');
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
        'Transcript API response: $method $uri -> ${response.statusCode}'
        '${message == null ? '' : ' ($message)'}',
      );

      final rawData = parsed?['data'];
      // Preserve Lists and Maps so callers can handle both shapes.
      final data = rawData is List || rawData is Map ? rawData : null;

      return ApiResponse(
        statusCode: response.statusCode,
        success: rawSuccess is bool ? rawSuccess : null,
        message: message,
        data: data,
      );
    } on SocketException catch (error) {
      AppLogger.warning('Transcript API socket error: $method $uri', error);
      return ApiResponse(
        statusCode: 0,
        success: false,
        message:
            'Cannot reach backend API (${error.osError?.message ?? error.message}).',
      );
    } on HandshakeException catch (error) {
      AppLogger.warning('Transcript API TLS error: $method $uri', error);
      return ApiResponse(
        statusCode: 0,
        success: false,
        message:
            'TLS handshake failed while connecting backend API (${error.message}).',
      );
    } on HttpException catch (error) {
      AppLogger.warning('Transcript API HTTP error: $method $uri', error);
      return ApiResponse(statusCode: 0, success: false, message: error.message);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Transcript API unexpected error: $method $uri',
        error,
        stackTrace,
      );
      return ApiResponse(
        statusCode: 0,
        success: false,
        message: 'Unexpected transcript API error (${error.runtimeType}).',
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
  final Object? data;

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

class TranscriptFetchException implements Exception {
  const TranscriptFetchException(this.message);

  final String message;

  @override
  String toString() => 'TranscriptFetchException: $message';
}
