import 'dart:convert';

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
      orderBy: 'createdAt DESC',
    );
    final chunksData = await db.query(
      'transcript_chunks',
      orderBy: 'chunkIndex ASC',
    );
    final speakersData = await db.query('speakers', orderBy: 'createdAt DESC');
    final summariesData = await db.query(
      'summaries',
      orderBy: 'createdAt DESC',
    );
    final settingsData = await db.query('settings');

    final settingsMap = {
      for (final e in settingsData) e['key']! as String: e['value']! as String,
    };

    final transcripts = transcriptsData.map(Transcript.fromJson).toList();
    final allChunks = chunksData.map(TranscriptChunk.fromJson).toList();
    final speakers = speakersData.map((e) {
      final map = Map<String, Object?>.from(e);
      if (map['embedding'] != null) {
        map['embedding'] = jsonDecode(map['embedding']! as String);
      }
      map['hasVoiceSample'] = (map['hasVoiceSample']! as int) == 1;
      return SpeakerProfile.fromJson(map);
    }).toList();
    final summaries = summariesData.map(Summary.fromJson).toList();

    return PersistedTranscriptState(
      transcripts: transcripts,
      currentTranscript: null,
      currentChunks: const [],
      allChunks: allChunks,
      speakers: speakers,
      summaries: summaries,
      summaryProvider: settingsMap['summaryProvider'] ?? 'local',
      summaryLength: settingsMap['summaryLength'] ?? 'medium',
      speakerRecognitionEnabled:
          (settingsMap['speakerRecognitionEnabled'] ?? 'true') == 'true',
    );
  }

  @override
  Future<void> saveTranscript(Transcript transcript) async {
    final db = await _dbProvider.database;
    await db.insert(
      'transcripts',
      transcript.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTranscript(String id) async {
    final db = await _dbProvider.database;
    await db.delete('transcripts', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'transcript_chunks',
      where: 'transcriptId = ?',
      whereArgs: [id],
    );
    await db.delete('summaries', where: 'transcriptId = ?', whereArgs: [id]);
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
  Future<void> saveSpeaker(SpeakerProfile speaker) async {
    final db = await _dbProvider.database;
    final map = speaker.toJson();
    map['embedding'] = jsonEncode(map['embedding']);
    map['hasVoiceSample'] = speaker.hasVoiceSample ? 1 : 0;
    await db.insert(
      'speakers',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSpeaker(String id) async {
    final db = await _dbProvider.database;
    await db.delete('speakers', where: 'id = ?', whereArgs: [id]);
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
  Future<void> saveSetting(String key, String value) async {
    final db = await _dbProvider.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
