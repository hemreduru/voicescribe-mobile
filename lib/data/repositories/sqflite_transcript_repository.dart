import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/data/mappers/sqlite_transcript_mapper.dart';
import 'package:voicescribe_mobile/data/services/database/database_provider.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_merge_policy.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

class SqfliteTranscriptRepository implements TranscriptRepository {
  SqfliteTranscriptRepository({
    DatabaseProvider? databaseProvider,
    AuthRepository? authRepository,
    TranscriptApiClient? apiClient,
    Connectivity? connectivity,
    SyncMergePolicy? mergePolicy,
  }) : _dbProvider = databaseProvider ?? DatabaseProvider(),
       _authRepository = authRepository,
       _apiClient = apiClient ?? const TranscriptApiClient(),
       _connectivity = connectivity ?? Connectivity(),
       _mergePolicy = mergePolicy ?? const SyncMergePolicy();

  final DatabaseProvider _dbProvider;
  final AuthRepository? _authRepository;
  final TranscriptApiClient _apiClient;
  final Connectivity _connectivity;
  final SyncMergePolicy _mergePolicy;
  final _snapshotController = StreamController<TranscriptSnapshot>.broadcast();
  Timer? _snapshotEmitDebounce;

  /// Burst writes (each recorded chunk lands as saveChunk + saveTranscript,
  /// then again when its transcription completes) are coalesced into one
  /// snapshot reload, instead of re-querying the entire database per write.
  static const Duration _snapshotEmitCoalesce = Duration(milliseconds: 50);

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
  Future<void> refresh() async {
    await _fetchFromServerIfOnline();
    await _emitSnapshot();
  }

  @override
  Future<void> reloadFromCache() => _emitSnapshot();

  @override
  Future<bool> fetchFromServer({required String token}) async {
    try {
      final serverTranscripts = await _apiClient.fetchTranscripts(token: token);
      await _writeServerTranscriptsToCache(serverTranscripts);
      return true;
    } on TranscriptFetchException catch (error) {
      AppLogger.warning(
        '[TranscriptRepository] Server fetch failed: ${error.message}',
      );
      return false;
    } catch (error, stackTrace) {
      AppLogger.error(
        '[TranscriptRepository] Unexpected error during server fetch',
        error,
        stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> clearCache() async {
    final db = await _dbProvider.database;
    // Only drop rows that are safely on the server. Never delete
    // pending/failed/syncing rows — doing so (e.g. on logout while offline)
    // would permanently lose recordings that were never backed up.
    const where = 'syncStatus = ?';
    final whereArgs = [SyncStatus.synced.key];
    await db.delete('transcript_chunks', where: where, whereArgs: whereArgs);
    await db.delete('summaries', where: where, whereArgs: whereArgs);
    await db.delete('transcripts', where: where, whereArgs: whereArgs);
    await _emitSnapshot();
  }

  @override
  Future<void> saveTranscript(Transcript transcript) async {
    final db = await _dbProvider.database;
    await db.insert(
      'transcripts',
      SqliteTranscriptMapper.transcriptToRow(transcript),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleSnapshotEmit();
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
    _scheduleSnapshotEmit();
  }

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {
    final db = await _dbProvider.database;
    await db.insert(
      'transcript_chunks',
      SqliteTranscriptMapper.chunkToRow(chunk),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleSnapshotEmit();
  }

  @override
  Future<void> saveSummary(Summary summary) async {
    final db = await _dbProvider.database;
    await db.insert(
      'summaries',
      SqliteTranscriptMapper.summaryToRow(summary),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleSnapshotEmit();
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
    _scheduleSnapshotEmit();
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
    _scheduleSnapshotEmit();
  }

  Future<void> dispose() async {
    _snapshotEmitDebounce?.cancel();
    await _snapshotController.close();
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<void> _fetchFromServerIfOnline() async {
    if (_authRepository == null) {
      return;
    }
    final session = _authRepository.currentSession();
    if (session == null || !session.isAuthenticated) {
      return;
    }

    try {
      final result = await _connectivity.checkConnectivity();
      // connectivity_plus v7 returns a List<ConnectivityResult>; treat the
      // device as offline only when every reported interface is `none`.
      final offline = result.every(
        (status) => status == ConnectivityResult.none,
      );
      if (offline) {
        return;
      }
    } catch (_) {
      // Connectivity check may fail on some platforms; assume offline.
      return;
    }

    await fetchFromServer(token: session.accessToken);
  }

  Future<void> _writeServerTranscriptsToCache(
    List<Map<String, Object?>> serverTranscripts,
  ) async {
    final db = await _dbProvider.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final transcriptData in serverTranscripts) {
        final remoteId = _toText(transcriptData['remote_id']);
        final localId =
            _toText(transcriptData['local_id']) ??
            _toText(transcriptData['client_local_id']) ??
            remoteId;
        if (localId == null || remoteId == null) {
          continue;
        }

        final statusKey = _toText(transcriptData['status_key']);
        final durationSeconds = _toInt(transcriptData['duration_seconds']);
        final title = _toText(transcriptData['title']);
        final recordedAt = _toText(transcriptData['recorded_at']);
        final createdAt = _toText(transcriptData['created_at']) ?? now;
        final updatedAt = _toText(transcriptData['updated_at']) ?? now;
        final deletedAt = _toText(transcriptData['deleted_at']);

        // Respect local edits: never let the server copy overwrite an
        // unsynced (pending/failed/syncing) local row.
        final writeTranscript = await _shouldWriteServerRow(
          txn,
          'transcripts',
          transcriptData,
        );

        // Write transcript row (cache as synced).
        if (writeTranscript) {
          await txn.insert('transcripts', {
            'id': localId,
            'localId': localId,
            'userId': _toText(transcriptData['user_id']),
            'remoteId': remoteId,
            'title': title,
            'durationSeconds': durationSeconds,
            'statusKey': statusKey ?? 'completed',
            'recordedAt': recordedAt,
            'createdAt': createdAt,
            'updatedAt': updatedAt,
            'syncStatus': SyncStatus.synced.key,
            'lastSyncedAt': now,
            'syncError': null,
            'deletedAt': deletedAt,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Write nested chunks.
        final chunks = _toListOfMaps(transcriptData['chunks']);
        for (final chunkData in chunks) {
          final chunkRemoteId = _toText(chunkData['remote_id']);
          final chunkLocalId =
              _toText(chunkData['client_local_id']) ??
              _toText(chunkData['id']) ??
              chunkRemoteId;
          if (chunkLocalId == null) {
            continue;
          }
          if (!await _shouldWriteServerRow(
            txn,
            'transcript_chunks',
            chunkData,
          )) {
            continue;
          }

          await txn.insert('transcript_chunks', {
            'id': chunkLocalId,
            'transcriptId': localId,
            'remoteId': chunkRemoteId,
            'chunkIndex': _toInt(chunkData['chunk_index']),
            'text': _toText(chunkData['text']) ?? '',
            'audioPath': null,
            'recordedAt': null,
            'startTime': _toDouble(chunkData['start_time']),
            'endTime': _toDouble(chunkData['end_time']),
            'confidence': _toNullableDouble(chunkData['confidence']),
            'transcriptionError': null,
            'audioLevel': null,
            'isTranscribed': 1,
            'syncStatus': SyncStatus.synced.key,
            'lastSyncedAt': now,
            'syncError': null,
            'deletedAt': _toText(chunkData['deleted_at']),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Write nested summaries.
        final summaries = _toListOfMaps(transcriptData['summaries']);
        for (final summaryData in summaries) {
          final summaryRemoteId = _toText(summaryData['remote_id']);
          final summaryLocalId =
              _toText(summaryData['client_local_id']) ??
              _toText(summaryData['id']) ??
              summaryRemoteId;
          if (summaryLocalId == null) {
            continue;
          }
          if (!await _shouldWriteServerRow(txn, 'summaries', summaryData)) {
            continue;
          }

          await txn.insert('summaries', {
            'id': summaryLocalId,
            'transcriptId': localId,
            'remoteId': summaryRemoteId,
            'providerKey': _clientProviderKey(
              _toText(summaryData['provider_key']),
            ),
            'model': _toText(summaryData['model']) ?? 'local-default',
            'summaryText': _toText(summaryData['summary_text']) ?? '',
            'tokenCount': _toNullableInt(summaryData['token_count']),
            'processingTimeMs': _toNullableInt(
              summaryData['processing_time_ms'],
            ),
            'createdAt': _toText(summaryData['created_at']) ?? now,
            'syncStatus': SyncStatus.synced.key,
            'lastSyncedAt': now,
            'syncError': null,
            'deletedAt': _toText(summaryData['deleted_at']),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  /// Returns true when a server row should overwrite the local cache.
  /// Delegates to [SyncMergePolicy] so the `GET /transcripts` hydrate path
  /// shares the exact conflict semantics of the `/sync/pull` path and never
  /// clobbers an unsynced local edit.
  Future<bool> _shouldWriteServerRow(
    DatabaseExecutor db,
    String table,
    Map<String, Object?> serverRow,
  ) async {
    final decision = await _mergePolicy.decideMergeForRow(
      db: db,
      table: table,
      serverRow: serverRow,
    );
    return decision != MergeDecision.keepLocal;
  }

  /// Schedules a coalesced snapshot emission. Multiple writes within the
  /// window produce a single full reload.
  void _scheduleSnapshotEmit() {
    if (_snapshotController.isClosed) {
      return;
    }
    _snapshotEmitDebounce?.cancel();
    _snapshotEmitDebounce = Timer(_snapshotEmitCoalesce, () {
      unawaited(_emitSnapshot());
    });
  }

  Future<void> _emitSnapshot() async {
    if (_snapshotController.isClosed) {
      return;
    }
    _snapshotEmitDebounce?.cancel();
    _snapshotController.add(await loadSnapshot());
  }

  // --------------------------------------------------------------------------
  // JSON helpers for server responses
  // --------------------------------------------------------------------------

  /// Collapse the backend provider key (local | gemini | openai | claude | …)
  /// into the client's two-value space so the summary badge is correct: only
  /// 'local' is on-device, everything else is a cloud provider.
  static String _clientProviderKey(String? serverKey) {
    return (serverKey == null || serverKey == 'local') ? 'local' : 'cloud';
  }

  static String? _toText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  static double _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static List<Map<String, Object?>> _toListOfMaps(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map<Object?, Object?>>()
        .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
        .toList(growable: false);
  }
}
