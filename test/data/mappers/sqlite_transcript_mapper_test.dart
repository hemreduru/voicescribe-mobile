import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/mappers/sqlite_transcript_mapper.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

void main() {
  test('SQLite mapper round-trips transcript rows', () {
    final now = DateTime.parse('2026-04-26T12:00:00.000Z');
    final transcript = Transcript(
      id: 'local-1',
      localId: 'local-1',
      title: 'Demo',
      durationSeconds: 12,
      status: TranscriptStatus.completed,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
      remoteId: 'remote-1',
      syncStatus: SyncStatus.synced,
    );

    final decoded = SqliteTranscriptMapper.transcriptFromRow(
      SqliteTranscriptMapper.transcriptToRow(transcript),
    );

    expect(decoded.id, transcript.id);
    expect(decoded.title, 'Demo');
    expect(decoded.status, TranscriptStatus.completed);
    expect(decoded.remoteId, 'remote-1');
    expect(decoded.syncStatus, SyncStatus.synced);
  });

  test('TranscriptStatus no longer maps legacy speaker statuses', () {
    expect(
      TranscriptStatus.fromKey('speaker_analysis_completed'),
      TranscriptStatus.empty,
    );
    expect(
      TranscriptStatus.fromKey('speaker_analysis_pending'),
      TranscriptStatus.empty,
    );
  });

  test('preferences normalize unsupported values', () {
    final preferences = SqliteTranscriptMapper.preferencesFromSettings(const {
      'themeMode': 'sepia',
      'localePreference': 'de',
      'summaryProvider': 'remote',
      'summaryLength': 'huge',
      'transcriptionModel': 'mega',
    });

    expect(preferences.themeMode, 'system');
    expect(preferences.localePreference, 'system');
    expect(preferences.summaryProvider, 'local');
    expect(preferences.summaryLength, 'medium');
    expect(preferences.transcriptionModel, 'base');
  });
}
