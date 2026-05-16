import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SyncHttpResult {
  const SyncHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class SyncHttpClient {
  const SyncHttpClient();

  Future<SyncHttpResult> postJson({
    required String url,
    required String token,
    required Map<String, Object?> payload,
  }) async {
    final uri = Uri.parse(url);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write(jsonEncode(payload));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 20));
      return SyncHttpResult(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }
}
