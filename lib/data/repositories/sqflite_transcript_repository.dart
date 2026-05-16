import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/data/mappers/sqlite_transcript_mapper.dart';
import 'package:voicescribe_mobile/data/services/database/database_provider.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

class SqfliteTranscriptRepository implements TranscriptRepository {
  SqfliteTranscriptRepository({DatabaseProvider? databaseProvider})
    : _dbProvider = databaseProvider ?? DatabaseProvider();

  final DatabaseProvider _dbProvider;
  final _snapshotController = StreamController<TranscriptSnapshot>.broadcast();

  @override
  Stream<TranscriptSnapshot> watchSnapshot() => _snapshotController.stream;

  @override
  Future<TranscriptSnapshot> loadSnapshot() async {
    final db = await _dbProvider.database;

    final transcriptsData = await db.query(
      'transcripts',
      where: 'deletedAt IS NULL',
      orderBy: 'createdAt DESC',
    );
    final chunksData = await db.query(
      'transcript_chunks',
      where: 'deletedAt IS NULL',
      orderBy: 'chunkIndex ASC',
    );
    final summariesData = await db.query(
      'summaries',
      where: 'deletedAt IS NULL',
      orderBy: 'createdAt DESC',
    );
    final settingsData = await db.query('settings');

    final settingsMap = {
      for (final entry in settingsData)
        entry['key']! as String: entry['value']! as String,
    };

    return TranscriptSnapshot(
      transcripts: transcriptsData
          .map(SqliteTranscriptMapper.transcriptFromRow)
          .toList(),
      chunks: chunksData.map(SqliteTranscriptMapper.chunkFromRow).toList(),
      summaries: summariesData
          .map(SqliteTranscriptMapper.summaryFromRow)
          .toList(),
      preferences: SqliteTranscriptMapper.preferencesFromSettings(settingsMap),
    );
  }

  @override
  Future<void> refresh() => _emitSnapshot();

  @override
  Future<void> saveTranscript(Transcript transcript) async {
    final db = await _dbProvider.database;
    await db.insert(
      'transcripts',
      SqliteTranscriptMapper.transcriptToRow(transcript),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitSnapshot();
  }

  @override
  Future<void> deleteTranscript(String id) async {
    final db = await _dbProvider.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'transcripts',
      {
        'deletedAt': now,
        'syncStatus': SyncStatus.pending.key,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.update(
      'transcript_chunks',
      {'deletedAt': now, 'syncStatus': SyncStatus.pending.key},
      where: 'transcriptId = ?',
      whereArgs: [id],
    );
    await db.update(
      'summaries',
      {'deletedAt': now, 'syncStatus': SyncStatus.pending.key},
      where: 'transcriptId = ?',
      whereArgs: [id],
    );
    await _emitSnapshot();
  }

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {
    final db = await _dbProvider.database;
    await db.insert(
      'transcript_chunks',
      SqliteTranscriptMapper.chunkToRow(chunk),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitSnapshot();
  }

  @override
  Future<void> saveSummary(Summary summary) async {
    final db = await _dbProvider.database;
    await db.insert(
      'summaries',
      SqliteTranscriptMapper.summaryToRow(summary),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitSnapshot();
  }

  @override
  Future<void> deleteSummary(String id) async {
    final db = await _dbProvider.database;
    await db.update(
      'summaries',
      {
        'deletedAt': DateTime.now().toIso8601String(),
        'syncStatus': SyncStatus.pending.key,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _emitSnapshot();
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    final db = await _dbProvider.database;
    for (final entry in SqliteTranscriptMapper.preferencesToSettings(
      preferences,
    ).entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await _emitSnapshot();
  }

  Future<void> dispose() async {
    await _snapshotController.close();
  }

  Future<void> _emitSnapshot() async {
    if (_snapshotController.isClosed) {
      return;
    }
    _snapshotController.add(await loadSnapshot());
  }
}
