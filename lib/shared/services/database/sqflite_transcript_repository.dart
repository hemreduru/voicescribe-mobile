import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/database/database_provider.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';

class SqfliteTranscriptRepository implements TranscriptRepository {
  final DatabaseProvider _dbProvider = DatabaseProvider();

  @override
  Future<PersistedTranscriptState> load() async {
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
    final processingJobsData = await db.query(
      'processing_jobs',
      where: 'deletedAt IS NULL',
      orderBy: 'createdAt DESC',
    );
    final settingsData = await db.query('settings');

    final settingsMap = {
      for (final entry in settingsData)
        entry['key']! as String: entry['value']! as String,
    };

    final transcripts = transcriptsData.map(Transcript.fromJson).toList();
    final allChunks = chunksData.map(TranscriptChunk.fromJson).toList();
    final summaries = summariesData.map(Summary.fromJson).toList();
    final processingJobs = processingJobsData
        .map(ProcessingJob.fromJson)
        .toList();

    return PersistedTranscriptState(
      transcripts: transcripts,
      currentTranscript: null,
      currentChunks: const [],
      allChunks: allChunks,
      summaries: summaries,
      processingJobs: processingJobs,
      summaryProvider: settingsMap['summaryProvider'] ?? 'local',
      summaryLength: settingsMap['summaryLength'] ?? 'medium',
      themeMode: settingsMap['themeMode'] ?? 'system',
      localePreference: settingsMap['localePreference'] ?? 'system',
    );
  }

  @override
  Future<void> saveTranscript(Transcript transcript) async {
    final db = await _dbProvider.database;
    final map = transcript.toJson();
    await db.insert(
      'transcripts',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    await db.update(
      'processing_jobs',
      {
        'deletedAt': now,
        'syncStatus': SyncStatus.pending.key,
        'updatedAt': now,
      },
      where: 'transcriptId = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {
    final db = await _dbProvider.database;
    await db.insert(
      'transcript_chunks',
      chunk.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveSummary(Summary summary) async {
    final db = await _dbProvider.database;
    await db.insert(
      'summaries',
      summary.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveProcessingJob(ProcessingJob job) async {
    final db = await _dbProvider.database;
    await db.insert(
      'processing_jobs',
      job.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteProcessingJob(String id) async {
    final db = await _dbProvider.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'processing_jobs',
      {
        'deletedAt': now,
        'syncStatus': SyncStatus.pending.key,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    final db = await _dbProvider.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
