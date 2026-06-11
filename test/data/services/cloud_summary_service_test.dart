import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/llm/cloud_summary_service.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

class _FakeApiClient extends TranscriptApiClient {
  _FakeApiClient(this._response);

  final ApiResponse _response;
  Map<String, Object?>? lastPayload;
  String? lastPath;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, Object?>? payload,
    String? token,
    Duration? readTimeout,
  }) async {
    lastPath = path;
    lastPayload = payload;
    return _response;
  }
}

Transcript _transcript({String? remoteId}) {
  final now = DateTime.now();
  return Transcript(
    id: 'local-1',
    localId: 'local-1',
    title: 'Toplantı',
    durationSeconds: 600,
    status: TranscriptStatus.completed,
    recordedAt: now,
    createdAt: now,
    updatedAt: now,
    remoteId: remoteId,
  );
}

void main() {
  group('CloudSummaryService', () {
    test(
      'posts to the remote transcript and returns a cloud summary',
      () async {
        final json = jsonEncode({'title': 'Özet', 'decisions': <Object?>[]});
        final client = _FakeApiClient(
          ApiResponse(
            statusCode: 201,
            success: true,
            data: {
              'summary_text': json,
              'model': 'gemini-1.5-flash',
              'token_count': 321,
              'processing_time_ms': 1200,
              'remote_id': '99',
            },
          ),
        );
        final service = CloudSummaryService(
          apiClient: client,
          tokenProvider: () => 'token-abc',
        );

        final summary = await service.generate(
          transcript: _transcript(remoteId: '42'),
          transcriptText: 'Toplantı metni.',
          provider: 'cloud',
        );

        expect(client.lastPath, '/api/v1/transcripts/42/summaries');
        expect(summary.providerKey, 'cloud');
        expect(summary.model, 'gemini-1.5-flash');
        expect(summary.summaryText, json);
        expect(summary.tokenCount, 321);
        expect(summary.processingTimeMs, 1200);
        // The local id is sent so a later sync push updates the same row.
        expect(client.lastPayload?['client_local_id'], summary.id);
        // The fixed length is still sent to preserve the backend contract.
        expect(client.lastPayload?['length'], 'medium');
      },
    );

    test('throws when the transcript is not synced yet', () async {
      final service = CloudSummaryService(
        apiClient: _FakeApiClient(const ApiResponse(statusCode: 0)),
        tokenProvider: () => 'token-abc',
      );

      expect(
        () => service.generate(
          transcript: _transcript(),
          transcriptText: 'metin',
          provider: 'cloud',
        ),
        throwsA(isA<CloudSummaryException>()),
      );
    });

    test('throws a network message on connection failure', () async {
      final service = CloudSummaryService(
        apiClient: _FakeApiClient(
          const ApiResponse(statusCode: 0, success: false),
        ),
        tokenProvider: () => 'token-abc',
      );

      await expectLater(
        service.generate(
          transcript: _transcript(remoteId: '42'),
          transcriptText: 'metin',
          provider: 'cloud',
        ),
        throwsA(
          isA<CloudSummaryException>().having(
            (e) => e.message,
            'message',
            contains('Bağlantı yok'),
          ),
        ),
      );
    });

    test('throws when not authenticated', () async {
      final service = CloudSummaryService(
        apiClient: _FakeApiClient(const ApiResponse(statusCode: 201)),
        tokenProvider: () => null,
      );

      expect(
        () => service.generate(
          transcript: _transcript(remoteId: '42'),
          transcriptText: 'metin',
          provider: 'cloud',
        ),
        throwsA(isA<CloudSummaryException>()),
      );
    });
  });
}
