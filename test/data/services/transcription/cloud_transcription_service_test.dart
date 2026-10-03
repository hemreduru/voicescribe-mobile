import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/data/services/transcription/cloud_transcription_service.dart';
import 'package:voicescribe_mobile/data/services/transcription_service.dart';
import 'package:voicescribe_mobile/domain/models/app_error.dart';

class _Call {
  const _Call({
    required this.audio,
    required this.filename,
    required this.token,
    required this.language,
    required this.prompt,
  });

  final Uint8List audio;
  final String filename;
  final String token;
  final String language;
  final String? prompt;
}

/// Scripted backend: each call pops the next response; the last one repeats.
class _FakeApiClient extends TranscriptApiClient {
  _FakeApiClient(this.responses);

  final List<ApiResponse> responses;
  final List<_Call> calls = [];

  @override
  Future<ApiResponse> transcribe({
    required Uint8List audio,
    required String filename,
    required String token,
    required String language,
    String? prompt,
  }) async {
    calls.add(
      _Call(
        audio: audio,
        filename: filename,
        token: token,
        language: language,
        prompt: prompt,
      ),
    );
    final index = calls.length - 1;
    return responses[index < responses.length ? index : responses.length - 1];
  }
}

ApiResponse _ok(String text) => ApiResponse(
  statusCode: 200,
  success: true,
  message: 'ok',
  data: {'text': text},
);

ApiResponse _status(int code, {int? retryAfter}) => ApiResponse(
  statusCode: code,
  success: false,
  message: 'HTTP $code',
  retryAfterSeconds: retryAfter,
);

const _networkFailure = ApiResponse(
  statusCode: 0,
  success: false,
  message: 'Cannot reach backend API.',
);

void main() {
  late Directory tempDir;
  late String chunkPath;
  late List<Duration> delays;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cloud_stt_test');
    final file = File('${tempDir.path}/chunk_1.wav');
    await file.writeAsBytes([1, 2, 3, 4]);
    chunkPath = file.path;
    delays = [];
  });

  tearDown(() => tempDir.delete(recursive: true));

  CloudTranscriptionService build(
    TranscriptApiClient client, {
    String? token = 'token-abc',
  }) {
    return CloudTranscriptionService(
      apiClient: client,
      tokenProvider: () => token,
      delay: (duration) async => delays.add(duration),
    );
  }

  Future<TranscriptionException> failureOf(
    CloudTranscriptionService service,
  ) async {
    try {
      await service.transcribeChunk(chunkPath);
    } on TranscriptionException catch (error) {
      return error;
    }
    fail('Expected a TranscriptionException');
  }

  group('CloudTranscriptionService', () {
    test('uploads the chunk and returns the trimmed text', () async {
      final client = _FakeApiClient([_ok('  merhaba dünya \n')]);
      final service = build(client);

      final result = await service.transcribeChunk(chunkPath);

      expect(result.text, 'merhaba dünya');
      expect(client.calls, hasLength(1));
      expect(client.calls.single.audio, [1, 2, 3, 4]);
      expect(client.calls.single.filename, 'chunk_1.wav');
      expect(client.calls.single.token, 'token-abc');
      expect(client.calls.single.language, 'tr');
      expect(delays, isEmpty);
    });

    test('an empty transcript (silence) is a success, not a failure', () async {
      final service = build(_FakeApiClient([_ok('')]));

      final result = await service.transcribeChunk(chunkPath);

      expect(result.text, isEmpty);
    });

    test('sends the language preference and maps auto to tr', () async {
      final client = _FakeApiClient([_ok('a'), _ok('b'), _ok('c')]);
      final service = build(client);

      service.setTranscriptionLanguage('en');
      await service.transcribeChunk(chunkPath);
      service.setTranscriptionLanguage('auto');
      await service.transcribeChunk(chunkPath);

      expect(client.calls.map((call) => call.language), ['en', 'tr']);
    });

    test('429 honors Retry-After then succeeds', () async {
      final client = _FakeApiClient([
        _status(429, retryAfter: 3),
        _ok('tamam'),
      ]);
      final service = build(client);

      final result = await service.transcribeChunk(chunkPath);

      expect(result.text, 'tamam');
      expect(client.calls, hasLength(2));
      expect(delays, [const Duration(seconds: 3)]);
    });

    test('429 without Retry-After falls back to exponential backoff', () async {
      final client = _FakeApiClient([_status(429), _status(429), _ok('tamam')]);
      final service = build(client);

      await service.transcribeChunk(chunkPath);

      expect(delays, [const Duration(seconds: 2), const Duration(seconds: 4)]);
    });

    test('429 exhausts after 3 retries and surfaces a typed failure', () async {
      final client = _FakeApiClient([_status(429, retryAfter: 1)]);
      final service = build(client);

      final error = await failureOf(service);

      expect(error.code, AppErrorCode.transcriptionRateLimited);
      expect(client.calls, hasLength(4));
      expect(delays, hasLength(3));
    });

    test('a very large Retry-After is capped', () async {
      final client = _FakeApiClient([_status(429, retryAfter: 3600), _ok('x')]);
      final service = build(client);

      await service.transcribeChunk(chunkPath);

      expect(delays.single, lessThanOrEqualTo(const Duration(minutes: 1)));
    });

    test('502 is retried with backoff then fails as unavailable', () async {
      final client = _FakeApiClient([_status(502)]);
      final service = build(client);

      final error = await failureOf(service);

      expect(error.code, AppErrorCode.transcriptionUnavailable);
      expect(client.calls, hasLength(4));
      expect(delays, [
        const Duration(seconds: 2),
        const Duration(seconds: 4),
        const Duration(seconds: 8),
      ]);
    });

    test('503 then success recovers', () async {
      final client = _FakeApiClient([_status(503), _ok('geldi')]);
      final service = build(client);

      final result = await service.transcribeChunk(chunkPath);

      expect(result.text, 'geldi');
      expect(client.calls, hasLength(2));
    });

    test('network errors are retried then fail as offline', () async {
      final client = _FakeApiClient([_networkFailure]);
      final service = build(client);

      final error = await failureOf(service);

      expect(error.code, AppErrorCode.transcriptionOffline);
      expect(client.calls, hasLength(4));
    });

    test('401 fails immediately without retrying', () async {
      final client = _FakeApiClient([_status(401)]);
      final service = build(client);

      final error = await failureOf(service);

      expect(error.code, AppErrorCode.transcriptionAuthRequired);
      expect(client.calls, hasLength(1));
      expect(delays, isEmpty);
    });

    test('a missing session token fails without calling the backend', () async {
      final client = _FakeApiClient([_ok('never')]);
      final service = build(client, token: null);

      final error = await failureOf(service);

      expect(error.code, AppErrorCode.transcriptionAuthRequired);
      expect(client.calls, isEmpty);
    });

    test('422 fails immediately as a generic failure', () async {
      final client = _FakeApiClient([_status(422)]);
      final service = build(client);

      final error = await failureOf(service);

      expect(error.code, AppErrorCode.transcriptionGeneric);
      expect(client.calls, hasLength(1));
    });

    test('a 200 without data.text is a generic failure', () async {
      final client = _FakeApiClient([
        const ApiResponse(statusCode: 200, success: true, data: {'other': 1}),
      ]);
      final service = build(client);

      final error = await failureOf(service);

      expect(error.code, AppErrorCode.transcriptionGeneric);
      expect(client.calls, hasLength(1));
    });

    test('an unreadable chunk file is a generic failure', () async {
      final client = _FakeApiClient([_ok('never')]);
      final service = build(client);

      try {
        await service.transcribeChunk('${tempDir.path}/missing.wav');
        fail('Expected a TranscriptionException');
      } on TranscriptionException catch (error) {
        expect(error.code, AppErrorCode.transcriptionGeneric);
      }
      expect(client.calls, isEmpty);
    });

    test('chunks are uploaded one at a time, in submission order', () async {
      final firstGate = Completer<void>();
      final order = <String>[];
      final client = _GatedApiClient(firstGate.future, order);
      final service = build(client);
      final secondPath = '${tempDir.path}/chunk_2.wav';
      await File(secondPath).writeAsBytes([9]);

      final first = service.transcribeChunk(chunkPath);
      final second = service.transcribeChunk(secondPath);
      while (order.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      // Give a (buggy) concurrent second upload ample time to show up.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(order, ['start chunk_1.wav']);

      firstGate.complete();
      await Future.wait([first, second]);

      expect(order, [
        'start chunk_1.wav',
        'end chunk_1.wav',
        'start chunk_2.wav',
        'end chunk_2.wav',
      ]);
    });

    test('a failed chunk does not block the queue', () async {
      final client = _FakeApiClient([_status(422), _ok('sonraki')]);
      final service = build(client);

      final failed = service.transcribeChunk(chunkPath);
      final next = service.transcribeChunk(chunkPath);

      await expectLater(failed, throwsA(isA<TranscriptionException>()));
      expect((await next).text, 'sonraki');
    });
  });
}

/// Holds the first upload open to prove the second one waits its turn.
class _GatedApiClient extends TranscriptApiClient {
  _GatedApiClient(this._firstGate, this._order);

  final Future<void> _firstGate;
  final List<String> _order;

  @override
  Future<ApiResponse> transcribe({
    required Uint8List audio,
    required String filename,
    required String token,
    required String language,
    String? prompt,
  }) async {
    _order.add('start $filename');
    if (filename == 'chunk_1.wav') {
      await _firstGate;
    }
    _order.add('end $filename');
    return _ok('text of $filename');
  }
}
