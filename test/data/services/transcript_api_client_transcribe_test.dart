import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';

/// What the throwaway local server saw for the last request.
class _CapturedRequest {
  late String method;
  late String path;
  late String? authorization;
  late String? contentType;
  late Uint8List body;

  /// Raw body as latin1 so multipart headers can be matched as text while the
  /// binary payload stays byte-for-byte addressable.
  String get bodyText => latin1.decode(body);
}

void main() {
  late HttpServer server;
  late _CapturedRequest captured;
  late int responseStatus;
  late String responseBody;
  late Map<String, String> responseHeaders;
  late TranscriptApiClient client;

  setUp(() async {
    captured = _CapturedRequest();
    responseStatus = 200;
    responseBody = '{"success":true,"message":"ok","data":{"text":"merhaba"}}';
    responseHeaders = {};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.forEach((request) async {
        captured
          ..method = request.method
          ..path = request.uri.path
          ..authorization = request.headers.value(
            HttpHeaders.authorizationHeader,
          )
          ..contentType = request.headers.contentType?.toString();
        final builder = BytesBuilder();
        await for (final chunk in request) {
          builder.add(chunk);
        }
        captured.body = builder.takeBytes();
        request.response.statusCode = responseStatus;
        responseHeaders.forEach(request.response.headers.set);
        request.response.headers.contentType = ContentType.json;
        request.response.write(responseBody);
        await request.response.close();
      }),
    );
    client = TranscriptApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}',
    );
  });

  tearDown(() => server.close(force: true));

  group('TranscriptApiClient.transcribe', () {
    final audio = Uint8List.fromList([82, 73, 70, 70, 0, 255, 128, 7]);

    test('posts multipart with audio, language and prompt plus bearer', () async {
      final response = await client.transcribe(
        audio: audio,
        filename: 'chunk_1.wav',
        token: 'token-abc',
        language: 'en',
        prompt: 'Quarterly review',
      );

      expect(captured.method, 'POST');
      expect(captured.path, '/api/v1/transcribe');
      expect(captured.authorization, 'Bearer token-abc');
      expect(captured.contentType, startsWith('multipart/form-data'));

      final text = captured.bodyText;
      expect(
        text,
        contains('Content-Disposition: form-data; name="language"\r\n\r\nen'),
      );
      expect(
        text,
        contains(
          'Content-Disposition: form-data; name="prompt"\r\n\r\nQuarterly review',
        ),
      );
      expect(text, contains('name="audio"; filename="chunk_1.wav"'));
      expect(text, contains('Content-Type: audio/wav'));
      // The file bytes travel untouched (binary-safe).
      expect(text, contains(latin1.decode(audio)));

      expect(response.isSuccess, isTrue);
      expect((response.data! as Map)['text'], 'merhaba');
    });

    test('omits the prompt part when no prompt is given', () async {
      await client.transcribe(
        audio: audio,
        filename: 'chunk_2.wav',
        token: 'token-abc',
        language: 'tr',
      );

      expect(captured.bodyText, contains('name="language"\r\n\r\ntr'));
      expect(captured.bodyText, isNot(contains('name="prompt"')));
    });

    test('exposes Retry-After seconds on a 429', () async {
      responseStatus = 429;
      responseHeaders = {'Retry-After': '7'};
      responseBody = '{"success":false,"message":"Too Many Attempts."}';

      final response = await client.transcribe(
        audio: audio,
        filename: 'chunk_3.wav',
        token: 'token-abc',
        language: 'tr',
      );

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, 429);
      expect(response.retryAfterSeconds, 7);
      expect(response.message, 'Too Many Attempts.');
    });

    test('ignores a non-numeric Retry-After', () async {
      responseStatus = 429;
      responseHeaders = {'Retry-After': 'Wed, 21 Oct 2026 07:28:00 GMT'};

      final response = await client.transcribe(
        audio: audio,
        filename: 'chunk_4.wav',
        token: 'token-abc',
        language: 'tr',
      );

      expect(response.retryAfterSeconds, isNull);
    });

    test('reports a network failure as statusCode 0', () async {
      await server.close(force: true);

      final response = await client.transcribe(
        audio: audio,
        filename: 'chunk_5.wav',
        token: 'token-abc',
        language: 'tr',
      );

      expect(response.isNetworkFailure, isTrue);
    });
  });
}
