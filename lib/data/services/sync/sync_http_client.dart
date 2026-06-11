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
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      // Write the body as explicit UTF-8 bytes. `request.write` would otherwise
      // encode with latin1 (dart:io's default when the content-type carries no
      // charset), which throws "Contains invalid characters" on Turkish text
      // like 'ı'/'İ' (outside latin1) — silently blocking sync of TR content.
      // Set Content-Length explicitly (avoids chunked transfer-encoding for the
      // request body) and write the bytes.
      final bodyBytes = utf8.encode(jsonEncode(payload));
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);
      // Scale the window with the upload size (~1 s per 32 KB on top of the
      // 15 s base, capped at 2 min) so a large-but-progressing push over a
      // slow uplink isn't cut off mid-transfer.
      final uploadSeconds = 15 + (bodyBytes.length ~/ (32 * 1024));
      final response = await request.close().timeout(
        Duration(seconds: uploadSeconds > 120 ? 120 : uploadSeconds),
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
