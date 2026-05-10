import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/database/database_provider.dart';
import 'package:voicescribe_mobile/shared/utils/env_config.dart';

typedef AccessTokenProvider = Future<String?> Function();

class SyncQueueService {
  SyncQueueService({
    DatabaseProvider? databaseProvider,
    Connectivity? connectivity,
  }) : _databaseProvider = databaseProvider ?? DatabaseProvider(),
       _connectivity = connectivity ?? Connectivity();

  final DatabaseProvider _databaseProvider;
  final Connectivity _connectivity;

  StreamSubscription<dynamic>? _connectivitySubscription;
  AccessTokenProvider? _accessTokenProvider;
  bool _syncInProgress = false;
  Timer? _syncDebounceTimer;
  int _consecutiveFailureCount = 0;

  static const Duration _defaultSyncDebounce = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(minutes: 2);
  static const String _lastPullAtSettingKey = 'sync.lastPullAt';

  Future<void> start({required AccessTokenProvider accessTokenProvider}) async {
    _accessTokenProvider = accessTokenProvider;
    await triggerSyncIfOnline();
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen((
      event,
    ) async {
      if (_isOnline(event)) {
        await triggerSyncIfOnline();
      }
    });
  }

  Future<void> dispose() async {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = null;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  void scheduleSync({Duration delay = _defaultSyncDebounce}) {
    if (_accessTokenProvider == null) {
      return;
    }
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(delay, () {
      unawaited(triggerSyncIfOnline());
    });
  }

  Future<void> triggerSyncIfOnline() async {
    if (_syncInProgress) return;
    if (!await _hasInternet()) return;
    await _syncCycle();
  }

  Future<void> _syncCycle() async {
    final accessTokenProvider = _accessTokenProvider;
    if (accessTokenProvider == null) {
      return;
    }
    final token = await accessTokenProvider();
    if (token == null || token.isEmpty) {
      return;
    }

    final db = await _databaseProvider.database;
    _syncInProgress = true;
    try {
      final pushBatch = await _buildPushBatch(db);
      final hasPushChanges = pushBatch.payload.values.any(
        (value) => value.isNotEmpty,
      );

      if (hasPushChanges) {
        await _markBatchSyncing(db, pushBatch.idsByTable);

        final pushResponse = await _postJson(
          url: '${EnvConfig.apiBaseUrl}/api/v1/sync/push',
          token: token,
          payload: pushBatch.payload,
        );

        if (pushResponse.statusCode >= 200 && pushResponse.statusCode < 300) {
          await _applyPushResponse(
            db: db,
            responseBody: pushResponse.body,
            pushBatch: pushBatch,
          );
        } else {
          await _markBatchFailed(
            db: db,
            idsByTable: pushBatch.idsByTable,
            error: 'push_http_${pushResponse.statusCode}: ${pushResponse.body}',
          );
        }
      }

      await _pullAndMerge(db: db, token: token);
      _consecutiveFailureCount = 0;
    } catch (error) {
      _consecutiveFailureCount += 1;
      await _markAnySyncingAsFailed(db: db, error: error.toString());
      scheduleSync(delay: _retryDelayFor(_consecutiveFailureCount));
    } finally {
      _syncInProgress = false;
    }
  }

  Future<_PushBatch> _buildPushBatch(Database db) async {
    final payload = <String, List<Map<String, Object?>>>{};
    final idsByTable = <String, Set<String>>{};
    final clientToLocalByTable = <String, Map<String, String>>{};

    for (final config in _syncConfigs) {
      final rows = await db.query(
        config.table,
        where: 'syncStatus IN (?, ?)',
        whereArgs: [SyncStatus.pending.key, SyncStatus.failed.key],
      );
      final mapped = <Map<String, Object?>>[];
      final ids = <String>{};
      final clientToLocal = <String, String>{};

      for (final raw in rows) {
        final row = Map<String, Object?>.from(raw);
        final localId = _toText(row['id']);
        if (localId == null || localId.isEmpty) {
          continue;
        }
        ids.add(localId);
        final payloadRow = config.toPayload(row);
        final clientLocalId = _toText(payloadRow['client_local_id']);
        if (clientLocalId != null && clientLocalId.isNotEmpty) {
          clientToLocal[clientLocalId] = localId;
        }
        mapped.add(payloadRow);
      }

      payload[config.table] = mapped;
      idsByTable[config.table] = ids;
      clientToLocalByTable[config.table] = clientToLocal;
    }

    return _PushBatch(
      payload: payload,
      idsByTable: idsByTable,
      clientToLocalByTable: clientToLocalByTable,
    );
  }

  Future<void> _markBatchSyncing(
    Database db,
    Map<String, Set<String>> idsByTable,
  ) async {
    final now = DateTime.now().toIso8601String();
    for (final entry in idsByTable.entries) {
      final ids = entry.value.toList(growable: false);
      if (ids.isEmpty) {
        continue;
      }
      final placeholders = List.filled(ids.length, '?').join(', ');
      await db.update(
        entry.key,
        {
          'syncStatus': SyncStatus.syncing.key,
          'syncError': null,
          if (_hasUpdatedAtColumn(entry.key)) 'updatedAt': now,
        },
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    }
  }

  Future<void> _markBatchFailed({
    required Database db,
    required Map<String, Set<String>> idsByTable,
    required String error,
  }) async {
    final now = DateTime.now().toIso8601String();
    for (final entry in idsByTable.entries) {
      final ids = entry.value.toList(growable: false);
      if (ids.isEmpty) {
        continue;
      }
      final placeholders = List.filled(ids.length, '?').join(', ');
      await db.update(
        entry.key,
        {
          'syncStatus': SyncStatus.failed.key,
          'syncError': error,
          if (_hasUpdatedAtColumn(entry.key)) 'updatedAt': now,
        },
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    }
  }

  Future<void> _markAnySyncingAsFailed({
    required Database db,
    required String error,
  }) async {
    final now = DateTime.now().toIso8601String();
    for (final table in _syncTables) {
      await db.update(
        table,
        {
          'syncStatus': SyncStatus.failed.key,
          'syncError': error,
          if (_hasUpdatedAtColumn(table)) 'updatedAt': now,
        },
        where: 'syncStatus = ?',
        whereArgs: [SyncStatus.syncing.key],
      );
    }
  }

  Future<void> _applyPushResponse({
    required Database db,
    required String responseBody,
    required _PushBatch pushBatch,
  }) async {
    final now = DateTime.now().toIso8601String();
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, Object?>) {
      await _markBatchFailed(
        db: db,
        idsByTable: pushBatch.idsByTable,
        error: 'invalid_push_response',
      );
      return;
    }

    final data = decoded['data'];
    if (data is! Map<String, Object?>) {
      await _markBatchFailed(
        db: db,
        idsByTable: pushBatch.idsByTable,
        error: 'missing_push_data',
      );
      return;
    }

    final appliedByTable =
        (data['applied'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), _rowsFromDynamicList(value)),
        ) ??
        const <String, List<Map<String, Object?>>>{};

    final conflicts = _rowsFromDynamicList(data['conflicts']);
    final handledIds = <String, Set<String>>{
      for (final table in _syncTables) table: <String>{},
    };

    for (final entry in appliedByTable.entries) {
      final table = entry.key;
      final config = _syncConfigsByTable[table];
      if (config == null) {
        continue;
      }
      for (final appliedRow in entry.value) {
        final clientLocalId = _toText(appliedRow['client_local_id']);
        if (clientLocalId == null || clientLocalId.isEmpty) {
          continue;
        }
        final localId =
            pushBatch.clientToLocalByTable[table]?[clientLocalId] ?? '';
        if (localId.isEmpty) {
          continue;
        }
        handledIds[table]!.add(localId);
        await _updateRowById(
          db: db,
          table: table,
          id: localId,
          values: {
            'remoteId': _toText(appliedRow['remote_id']),
            'syncStatus': SyncStatus.synced.key,
            'syncError': null,
            'lastSyncedAt': _toText(appliedRow['updated_at']) ?? now,
          },
        );
      }
    }

    for (final conflict in conflicts) {
      final table = _toText(conflict['table']);
      final clientLocalId = _toText(conflict['client_local_id']);
      if (table == null || clientLocalId == null) {
        continue;
      }
      final localId = pushBatch.clientToLocalByTable[table]?[clientLocalId];
      if (localId == null || localId.isEmpty) {
        continue;
      }
      handledIds[table]?.add(localId);
      await _updateRowById(
        db: db,
        table: table,
        id: localId,
        values: {
          'syncStatus': SyncStatus.failed.key,
          'syncError': _toText(conflict['reason']) ?? 'server_conflict',
        },
      );
    }

    for (final table in _syncTables) {
      final allIds = pushBatch.idsByTable[table] ?? const <String>{};
      final tableHandled = handledIds[table] ?? const <String>{};
      final unhandled = allIds.where((id) => !tableHandled.contains(id));
      for (final localId in unhandled) {
        await _updateRowById(
          db: db,
          table: table,
          id: localId,
          values: {
            'syncStatus': SyncStatus.failed.key,
            'syncError': 'push_unhandled',
          },
        );
      }
    }
  }

  Future<void> _pullAndMerge({
    required Database db,
    required String token,
  }) async {
    final since = await _readSetting(db, _lastPullAtSettingKey);
    final response = await _postJson(
      url: '${EnvConfig.apiBaseUrl}/api/v1/sync/pull',
      token: token,
      payload: {
        if (since != null && since.isNotEmpty) 'since': since,
        'tables': _syncTables,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('pull_http_${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Invalid sync pull response payload.');
    }
    final data = decoded['data'];
    if (data is! Map<String, Object?>) {
      throw const FormatException('Missing data in sync pull response.');
    }

    for (final config in _syncConfigs) {
      final rows = _rowsFromDynamicList(data[config.table]);
      for (final row in rows) {
        await config.applyServerRow(db, row);
      }
    }

    final serverTime =
        _toText(data['serverTime']) ?? DateTime.now().toIso8601String();
    await _writeSetting(db, _lastPullAtSettingKey, serverTime);
  }

  Future<void> _updateRowById({
    required Database db,
    required String table,
    required String id,
    required Map<String, Object?> values,
  }) async {
    await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> _readSetting(Database db, String key) async {
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _toText(rows.first['value']);
  }

  Future<void> _writeSetting(Database db, String key, String value) async {
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Duration _retryDelayFor(int failureCount) {
    final exponent = math.min(failureCount, 5);
    final seconds = math.pow(2, exponent).toInt();
    final jitterMs = (failureCount % 3 + 1) * 250;
    final candidate = Duration(seconds: seconds, milliseconds: jitterMs);
    if (candidate > _maxRetryDelay) {
      return _maxRetryDelay;
    }
    return candidate;
  }

  Future<_HttpResult> _postJson({
    required String url,
    required String token,
    required Map<String, Object?> payload,
  }) async {
    final uri = Uri.parse(url);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(uri).timeout(
        const Duration(seconds: 10),
      );
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write(jsonEncode(payload));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await utf8.decoder.bind(response).join().timeout(
        const Duration(seconds: 20),
      );
      return _HttpResult(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> _hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  bool _isOnline(dynamic value) {
    if (value is ConnectivityResult) {
      return value != ConnectivityResult.none;
    }
    if (value is List<ConnectivityResult>) {
      return value.any((item) => item != ConnectivityResult.none);
    }
    return false;
  }

  static List<Map<String, Object?>> _rowsFromDynamicList(Object? value) {
    if (value is! List) {
      return const <Map<String, Object?>>[];
    }
    return value
        .whereType<Map<Object?, Object?>>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }

  static String? _toText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _toInt(Object? value, {int defaultValue = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static double _toDouble(Object? value, {double defaultValue = 0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static bool _hasUpdatedAtColumn(String table) {
    return table == 'transcripts' || table == 'processing_jobs';
  }
}

const _syncTables = <String>[
  'transcripts',
  'transcript_chunks',
  'speakers',
  'summaries',
  'processing_jobs',
];

final _syncConfigs = <_SyncTableConfig>[
  _SyncTableConfig(
    table: 'transcripts',
    toPayload: (row) {
      final localId =
          SyncQueueService._toText(row['localId'] ?? row['id']) ?? '';
      return {
        'id': SyncQueueService._toText(row['id']),
        'local_id': localId,
        'localId': localId,
        'client_local_id': localId,
        'clientLocalId': localId,
        'title': row['title'],
        'duration_seconds': SyncQueueService._toInt(row['durationSeconds']),
        'durationSeconds': SyncQueueService._toInt(row['durationSeconds']),
        'status_key': row['statusKey'],
        'statusKey': row['statusKey'],
        'recorded_at': row['recordedAt'],
        'recordedAt': row['recordedAt'],
        'updated_at': row['updatedAt'],
        'updatedAt': row['updatedAt'],
        'deleted_at': row['deletedAt'],
        'deletedAt': row['deletedAt'],
      };
    },
    applyServerRow: _applyTranscriptServerRow,
  ),
  _SyncTableConfig(
    table: 'transcript_chunks',
    toPayload: (row) {
      final localId = SyncQueueService._toText(row['id']) ?? '';
      return {
        'id': localId,
        'client_local_id': localId,
        'clientLocalId': localId,
        'transcript_client_local_id': SyncQueueService._toText(
          row['transcriptId'],
        ),
        'transcriptClientLocalId': SyncQueueService._toText(
          row['transcriptId'],
        ),
        'speaker_client_local_id': SyncQueueService._toText(row['speakerId']),
        'speakerClientLocalId': SyncQueueService._toText(row['speakerId']),
        'chunk_index': SyncQueueService._toInt(row['chunkIndex']),
        'chunkIndex': SyncQueueService._toInt(row['chunkIndex']),
        'text': row['text'],
        'speaker_label': row['speakerLabel'],
        'speakerLabel': row['speakerLabel'],
        'speaker_confidence': row['speakerConfidence'],
        'speakerConfidence': row['speakerConfidence'],
        'speaker_analysis_status': row['speakerAnalysisStatus'],
        'speakerAnalysisStatus': row['speakerAnalysisStatus'],
        'start_time': SyncQueueService._toDouble(row['startTime']),
        'startTime': SyncQueueService._toDouble(row['startTime']),
        'end_time': SyncQueueService._toDouble(row['endTime']),
        'endTime': SyncQueueService._toDouble(row['endTime']),
        'confidence': row['confidence'],
        'deleted_at': row['deletedAt'],
        'deletedAt': row['deletedAt'],
      };
    },
    applyServerRow: _applyTranscriptChunkServerRow,
  ),
  _SyncTableConfig(
    table: 'speakers',
    toPayload: (row) {
      final localId = SyncQueueService._toText(row['id']) ?? '';
      final embeddingValue = row['embedding'];
      Object? embedding;
      if (embeddingValue is String && embeddingValue.isNotEmpty) {
        try {
          embedding = jsonDecode(embeddingValue);
        } catch (_) {
          embedding = embeddingValue;
        }
      } else {
        embedding = embeddingValue;
      }
      return {
        'id': localId,
        'client_local_id': localId,
        'clientLocalId': localId,
        'name': row['name'],
        'embedding': embedding,
        'recordings': SyncQueueService._toInt(row['recordings']),
        'has_voice_sample': SyncQueueService._toInt(row['hasVoiceSample']) == 1,
        'hasVoiceSample': SyncQueueService._toInt(row['hasVoiceSample']) == 1,
        'is_user_named': SyncQueueService._toInt(row['isUserNamed']) == 1,
        'isUserNamed': SyncQueueService._toInt(row['isUserNamed']) == 1,
        'deleted_at': row['deletedAt'],
        'deletedAt': row['deletedAt'],
      };
    },
    applyServerRow: _applySpeakerServerRow,
  ),
  _SyncTableConfig(
    table: 'summaries',
    toPayload: (row) {
      final localId = SyncQueueService._toText(row['id']) ?? '';
      return {
        'id': localId,
        'client_local_id': localId,
        'clientLocalId': localId,
        'transcript_client_local_id': SyncQueueService._toText(
          row['transcriptId'],
        ),
        'transcriptClientLocalId': SyncQueueService._toText(
          row['transcriptId'],
        ),
        'provider_key': row['providerKey'],
        'providerKey': row['providerKey'],
        'model': row['model'],
        'summary_text': row['summaryText'],
        'summaryText': row['summaryText'],
        'token_count': row['tokenCount'],
        'tokenCount': row['tokenCount'],
        'processing_time_ms': row['processingTimeMs'],
        'processingTimeMs': row['processingTimeMs'],
        'deleted_at': row['deletedAt'],
        'deletedAt': row['deletedAt'],
      };
    },
    applyServerRow: _applySummaryServerRow,
  ),
  _SyncTableConfig(
    table: 'processing_jobs',
    toPayload: (row) {
      final localId = SyncQueueService._toText(row['id']) ?? '';
      return {
        'id': localId,
        'client_local_id': localId,
        'clientLocalId': localId,
        'transcript_client_local_id': SyncQueueService._toText(
          row['transcriptId'],
        ),
        'transcriptClientLocalId': SyncQueueService._toText(
          row['transcriptId'],
        ),
        'type': row['type'],
        'status': row['status'],
        'last_processed_chunk_index': SyncQueueService._toInt(
          row['lastProcessedChunkIndex'],
        ),
        'lastProcessedChunkIndex': SyncQueueService._toInt(
          row['lastProcessedChunkIndex'],
        ),
        'retry_count': SyncQueueService._toInt(row['retryCount']),
        'retryCount': SyncQueueService._toInt(row['retryCount']),
        'error': row['error'],
        'updated_at': row['updatedAt'],
        'updatedAt': row['updatedAt'],
        'deleted_at': row['deletedAt'],
        'deletedAt': row['deletedAt'],
      };
    },
    applyServerRow: _applyProcessingJobServerRow,
  ),
];

final _syncConfigsByTable = {
  for (final config in _syncConfigs) config.table: config,
};

class _SyncTableConfig {
  const _SyncTableConfig({
    required this.table,
    required this.toPayload,
    required this.applyServerRow,
  });

  final String table;
  final Map<String, Object?> Function(Map<String, Object?> row) toPayload;
  final Future<void> Function(Database db, Map<String, Object?> row)
  applyServerRow;
}

class _PushBatch {
  const _PushBatch({
    required this.payload,
    required this.idsByTable,
    required this.clientToLocalByTable,
  });

  final Map<String, List<Map<String, Object?>>> payload;
  final Map<String, Set<String>> idsByTable;
  final Map<String, Map<String, String>> clientToLocalByTable;
}

Future<void> _applyTranscriptServerRow(
  Database db,
  Map<String, Object?> row,
) async {
  final remoteId = SyncQueueService._toText(row['remote_id'] ?? row['id']);
  final clientLocalId = SyncQueueService._toText(
    row['client_local_id'] ?? row['local_id'],
  );
  String? localId;

  if (remoteId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'transcripts',
      where: 'remoteId = ?',
      whereArgs: [remoteId],
    );
  }
  if ((localId == null || localId.isEmpty) && clientLocalId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'transcripts',
      where: 'localId = ? OR id = ?',
      whereArgs: [clientLocalId, clientLocalId],
    );
  }

  final effectiveLocalId =
      localId ??
      clientLocalId ??
      (remoteId == null ? null : 'remote-transcript-$remoteId');
  if (effectiveLocalId == null) {
    return;
  }

  final now = DateTime.now().toIso8601String();
  final values = <String, Object?>{
    'id': effectiveLocalId,
    'localId': clientLocalId ?? effectiveLocalId,
    'userId': SyncQueueService._toText(row['user_id']),
    'remoteId': remoteId,
    'title': SyncQueueService._toText(row['title']),
    'durationSeconds': SyncQueueService._toInt(row['duration_seconds']),
    'statusKey': _normalizeServerTranscriptStatusKey(
      SyncQueueService._toText(row['status_key']) ??
          SyncQueueService._toText(row['statusKey']),
    ),
    'recordedAt': SyncQueueService._toText(row['recorded_at']),
    'createdAt': SyncQueueService._toText(row['created_at']) ?? now,
    'updatedAt': SyncQueueService._toText(row['updated_at']) ?? now,
    'syncStatus': SyncStatus.synced.key,
    'lastSyncedAt': SyncQueueService._toText(row['last_synced_at']) ?? now,
    'syncError': null,
    'deletedAt': SyncQueueService._toText(row['deleted_at']),
  };

  await db.insert(
    'transcripts',
    values,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> _applyTranscriptChunkServerRow(
  Database db,
  Map<String, Object?> row,
) async {
  final remoteId = SyncQueueService._toText(row['remote_id'] ?? row['id']);
  final clientLocalId = SyncQueueService._toText(row['client_local_id']);
  String? localId;

  if (remoteId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'transcript_chunks',
      where: 'remoteId = ?',
      whereArgs: [remoteId],
    );
  }
  if ((localId == null || localId.isEmpty) && clientLocalId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'transcript_chunks',
      where: 'id = ?',
      whereArgs: [clientLocalId],
    );
  }

  final transcriptRemoteId = SyncQueueService._toText(row['transcript_id']);
  if (transcriptRemoteId == null) {
    return;
  }
  final transcriptLocalId = await _findFirstId(
    db: db,
    table: 'transcripts',
    where: 'remoteId = ?',
    whereArgs: [transcriptRemoteId],
  );
  if (transcriptLocalId == null) {
    return;
  }

  String? speakerLocalId;
  final speakerRemoteId = SyncQueueService._toText(row['speaker_id']);
  if (speakerRemoteId != null) {
    speakerLocalId = await _findFirstId(
      db: db,
      table: 'speakers',
      where: 'remoteId = ?',
      whereArgs: [speakerRemoteId],
    );
  }

  final now = DateTime.now().toIso8601String();
  final effectiveLocalId =
      localId ??
      clientLocalId ??
      (remoteId == null ? null : 'remote-chunk-$remoteId');
  if (effectiveLocalId == null) {
    return;
  }

  await db.insert('transcript_chunks', {
    'id': effectiveLocalId,
    'transcriptId': transcriptLocalId,
    'remoteId': remoteId,
    'chunkIndex': SyncQueueService._toInt(row['chunk_index']),
    'text': SyncQueueService._toText(row['text']) ?? '',
    'audioPath': null,
    'recordedAt': null,
    'startTime': SyncQueueService._toDouble(row['start_time']),
    'endTime': SyncQueueService._toDouble(row['end_time']),
    'speakerId': speakerLocalId,
    'speakerLabel': SyncQueueService._toText(row['speaker_label']),
    'speakerConfidence': row['speaker_confidence'],
    'speakerAnalysisStatus':
        SyncQueueService._toText(row['speaker_analysis_status']) ?? 'pending',
    'confidence': row['confidence'],
    'transcriptionError': null,
    'syncStatus': SyncStatus.synced.key,
    'lastSyncedAt': SyncQueueService._toText(row['last_synced_at']) ?? now,
    'syncError': null,
    'deletedAt': SyncQueueService._toText(row['deleted_at']),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<void> _applySpeakerServerRow(
  Database db,
  Map<String, Object?> row,
) async {
  final remoteId = SyncQueueService._toText(row['remote_id'] ?? row['id']);
  final clientLocalId = SyncQueueService._toText(row['client_local_id']);
  String? localId;

  if (remoteId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'speakers',
      where: 'remoteId = ?',
      whereArgs: [remoteId],
    );
  }
  if ((localId == null || localId.isEmpty) && clientLocalId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'speakers',
      where: 'id = ?',
      whereArgs: [clientLocalId],
    );
  }

  final effectiveLocalId =
      localId ??
      clientLocalId ??
      (remoteId == null ? null : 'remote-speaker-$remoteId');
  if (effectiveLocalId == null) {
    return;
  }

  final embedding = row['embedding'];
  final now = DateTime.now().toIso8601String();
  await db.insert('speakers', {
    'id': effectiveLocalId,
    'userId': SyncQueueService._toText(row['user_id']),
    'remoteId': remoteId,
    'name': SyncQueueService._toText(row['name']) ?? 'Konuşmacı',
    'embedding': embedding is String ? embedding : jsonEncode(embedding ?? []),
    'recordings': SyncQueueService._toInt(row['recordings']),
    'hasVoiceSample':
        (row['has_voice_sample'] == true || row['hasVoiceSample'] == true)
        ? 1
        : 0,
    'isUserNamed': (row['is_user_named'] == true || row['isUserNamed'] == true)
        ? 1
        : 0,
    'createdAt': SyncQueueService._toText(row['created_at']) ?? now,
    'syncStatus': SyncStatus.synced.key,
    'lastSyncedAt': SyncQueueService._toText(row['last_synced_at']) ?? now,
    'syncError': null,
    'deletedAt': SyncQueueService._toText(row['deleted_at']),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<void> _applySummaryServerRow(
  Database db,
  Map<String, Object?> row,
) async {
  final remoteId = SyncQueueService._toText(row['remote_id'] ?? row['id']);
  final clientLocalId = SyncQueueService._toText(row['client_local_id']);
  String? localId;

  if (remoteId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'summaries',
      where: 'remoteId = ?',
      whereArgs: [remoteId],
    );
  }
  if ((localId == null || localId.isEmpty) && clientLocalId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'summaries',
      where: 'id = ?',
      whereArgs: [clientLocalId],
    );
  }

  final transcriptRemoteId = SyncQueueService._toText(row['transcript_id']);
  if (transcriptRemoteId == null) {
    return;
  }
  final transcriptLocalId = await _findFirstId(
    db: db,
    table: 'transcripts',
    where: 'remoteId = ?',
    whereArgs: [transcriptRemoteId],
  );
  if (transcriptLocalId == null) {
    return;
  }

  final effectiveLocalId =
      localId ??
      clientLocalId ??
      (remoteId == null ? null : 'remote-summary-$remoteId');
  if (effectiveLocalId == null) {
    return;
  }

  final now = DateTime.now().toIso8601String();
  await db.insert('summaries', {
    'id': effectiveLocalId,
    'transcriptId': transcriptLocalId,
    'remoteId': remoteId,
    'providerKey': SyncQueueService._toText(row['provider_key']) ?? 'local',
    'model': SyncQueueService._toText(row['model']) ?? 'local-default',
    'summaryText': SyncQueueService._toText(row['summary_text']) ?? '',
    'tokenCount': row['token_count'],
    'processingTimeMs': row['processing_time_ms'],
    'createdAt': SyncQueueService._toText(row['created_at']) ?? now,
    'syncStatus': SyncStatus.synced.key,
    'lastSyncedAt': SyncQueueService._toText(row['last_synced_at']) ?? now,
    'syncError': null,
    'deletedAt': SyncQueueService._toText(row['deleted_at']),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<void> _applyProcessingJobServerRow(
  Database db,
  Map<String, Object?> row,
) async {
  final remoteId = SyncQueueService._toText(row['remote_id'] ?? row['id']);
  final clientLocalId = SyncQueueService._toText(row['client_local_id']);
  String? localId;

  if (remoteId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'processing_jobs',
      where: 'remoteId = ?',
      whereArgs: [remoteId],
    );
  }
  if ((localId == null || localId.isEmpty) && clientLocalId != null) {
    localId = await _findFirstId(
      db: db,
      table: 'processing_jobs',
      where: 'id = ?',
      whereArgs: [clientLocalId],
    );
  }

  String? transcriptLocalId;
  final transcriptRemoteId = SyncQueueService._toText(row['transcript_id']);
  if (transcriptRemoteId != null) {
    transcriptLocalId = await _findFirstId(
      db: db,
      table: 'transcripts',
      where: 'remoteId = ?',
      whereArgs: [transcriptRemoteId],
    );
  }

  final effectiveLocalId =
      localId ??
      clientLocalId ??
      (remoteId == null ? null : 'remote-job-$remoteId');
  if (effectiveLocalId == null) {
    return;
  }

  final now = DateTime.now().toIso8601String();
  await db.insert('processing_jobs', {
    'id': effectiveLocalId,
    'transcriptId': transcriptLocalId,
    'remoteId': remoteId,
    'type': SyncQueueService._toText(row['type']) ?? 'sync',
    'status': SyncQueueService._toText(row['status']) ?? 'pending',
    'lastProcessedChunkIndex': SyncQueueService._toInt(
      row['last_processed_chunk_index'],
    ),
    'retryCount': SyncQueueService._toInt(row['retry_count']),
    'error': SyncQueueService._toText(row['error']),
    'createdAt': SyncQueueService._toText(row['created_at']) ?? now,
    'updatedAt': SyncQueueService._toText(row['updated_at']) ?? now,
    'syncStatus': SyncStatus.synced.key,
    'lastSyncedAt': SyncQueueService._toText(row['last_synced_at']) ?? now,
    'syncError': null,
    'deletedAt': SyncQueueService._toText(row['deleted_at']),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<String?> _findFirstId({
  required Database db,
  required String table,
  required String where,
  required List<Object?> whereArgs,
}) async {
  final rows = await db.query(
    table,
    columns: const ['id'],
    where: where,
    whereArgs: whereArgs,
    limit: 1,
  );
  if (rows.isEmpty) {
    return null;
  }
  return SyncQueueService._toText(rows.first['id']);
}

String _normalizeServerTranscriptStatusKey(String? key) {
  switch (key) {
    case 'recording':
      return TranscriptStatus.recording.key;
    case 'processing':
    case 'transcribing':
      return TranscriptStatus.transcribing.key;
    case 'transcription_completed':
      return TranscriptStatus.transcriptionCompleted.key;
    case 'speaker_analysis_pending':
      return TranscriptStatus.speakerAnalysisPending.key;
    case 'speaker_analysis_running':
      return TranscriptStatus.speakerAnalysisRunning.key;
    case 'speaker_analysis_completed':
      return TranscriptStatus.speakerAnalysisCompleted.key;
    case 'failed':
    case 'transcription_error':
      return TranscriptStatus.transcriptionError.key;
    case 'completed':
      return TranscriptStatus.speakerAnalysisCompleted.key;
    default:
      return TranscriptStatus.transcriptionCompleted.key;
  }
}

class _HttpResult {
  const _HttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
