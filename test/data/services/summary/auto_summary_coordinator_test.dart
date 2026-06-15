import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/summary/auto_summary_coordinator.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

import '../../../helpers/fakes.dart';

/// Counts generations and returns a stored summary so the repository's snapshot
/// reflects "a summary now exists" on the next emit.
class _RecordingSummaryService implements SummaryService {
  int calls = 0;

  @override
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    SummaryProgressCallback? onProgress,
  }) async {
    calls++;
    return Summary(
      id: 'sum-${transcript.id}',
      transcriptId: transcript.id,
      providerKey: 'local',
      model: 'test',
      summaryText: '{"title":"T","executive_summary":["ok"]}',
      tokenCount: null,
      processingTimeMs: 1,
      createdAt: DateTime(2026, 6, 15),
    );
  }
}

Transcript _transcript(
  String id, {
  required TranscriptStatus status,
  String? remoteId,
}) {
  final now = DateTime(2026, 6, 15);
  return Transcript(
    id: id,
    localId: id,
    title: null,
    durationSeconds: 30,
    status: status,
    recordedAt: now,
    createdAt: now,
    updatedAt: now,
    remoteId: remoteId,
  );
}

TranscriptChunk _chunk(String transcriptId, String text) {
  return TranscriptChunk(
    id: '$transcriptId-c1',
    transcriptId: transcriptId,
    chunkIndex: 1,
    text: text,
    audioPath: null,
    recordedAt: DateTime(2026, 6, 15),
    startTime: 0,
    endTime: 30,
    confidence: null,
    transcriptionError: null,
    isTranscribed: true,
  );
}

TranscriptSnapshot _snapshot(
  List<Transcript> transcripts,
  List<TranscriptChunk> chunks, {
  bool autoSummarize = true,
  String provider = 'local',
}) {
  return TranscriptSnapshot(
    transcripts: transcripts,
    chunks: chunks,
    summaries: const [],
    preferences: AppPreferences(
      autoSummarize: autoSummarize,
      summaryProvider: provider,
    ),
  );
}

void main() {
  late FakeTranscriptRepository repo;
  late _RecordingSummaryService summary;
  late FakeCompletionNotificationService notifier;
  late AutoSummaryCoordinator coordinator;

  AutoSummaryCoordinator build({String? token}) {
    return AutoSummaryCoordinator(
      transcriptRepository: repo,
      summaryService: summary,
      localLlmModelService: FakeLocalLlmModelService(downloaded: true),
      tokenProvider: () => token,
      completionNotifications: notifier,
    );
  }

  setUp(() {
    summary = _RecordingSummaryService();
    notifier = FakeCompletionNotificationService();
  });

  tearDown(() async {
    await coordinator.dispose();
    await repo.dispose();
  });

  test('auto-generates a summary when a transcript completes (local)', () async {
    repo = FakeTranscriptRepository(initial: _snapshot(const [], const []));
    coordinator = build()..start();

    repo.snapshot = _snapshot(
      [_transcript('t1', status: TranscriptStatus.completed)],
      [_chunk('t1', 'Hello world. This is the meeting.')],
    );
    repo.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(summary.calls, 1);
    expect(notifier.summaryReadyCount, 1);
  });

  test('does not summarize while still transcribing', () async {
    repo = FakeTranscriptRepository(initial: _snapshot(const [], const []));
    coordinator = build()..start();

    repo.snapshot = _snapshot(
      [_transcript('t1', status: TranscriptStatus.transcribing)],
      [_chunk('t1', 'partial text')],
    );
    repo.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(summary.calls, 0);
  });

  test('respects the autoSummarize=false preference', () async {
    repo = FakeTranscriptRepository(initial: _snapshot(const [], const []));
    coordinator = build()..start();

    repo.snapshot = _snapshot(
      [_transcript('t1', status: TranscriptStatus.completed)],
      [_chunk('t1', 'Hello world.')],
      autoSummarize: false,
    );
    repo.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(summary.calls, 0);
  });

  test('runs only once even across repeated snapshots', () async {
    repo = FakeTranscriptRepository(initial: _snapshot(const [], const []));
    coordinator = build()..start();

    final completed = _snapshot(
      [_transcript('t1', status: TranscriptStatus.completed)],
      [_chunk('t1', 'Hello world.')],
    );
    repo.snapshot = completed;
    repo.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // A second identical emit (e.g. unrelated sync metadata) must not re-run;
    // by now the saved summary is in the snapshot anyway.
    repo.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(summary.calls, 1);
  });

  test('cloud waits until the transcript is synced and a token exists', () async {
    repo = FakeTranscriptRepository(initial: _snapshot(const [], const []));
    coordinator = build(token: 'tok')..start();

    // Completed but not synced (no remoteId) → should not run yet.
    repo.snapshot = _snapshot(
      [_transcript('t1', status: TranscriptStatus.completed)],
      [_chunk('t1', 'Hello world.')],
      provider: 'cloud',
    );
    repo.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(summary.calls, 0);

    // remoteId now present (sync landed) → runs.
    repo.snapshot = _snapshot(
      [
        _transcript('t1', status: TranscriptStatus.completed, remoteId: 'r1'),
      ],
      [_chunk('t1', 'Hello world.')],
      provider: 'cloud',
    );
    repo.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(summary.calls, 1);
  });
}
