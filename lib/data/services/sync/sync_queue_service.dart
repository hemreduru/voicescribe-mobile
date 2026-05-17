import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/data/services/database/database_provider.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_http_client.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_merge_policy.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_payload_mapper.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

typedef AccessTokenProvider = Future<String?> Function();
typedef SyncCompletionCallback = Future<void> Function();

enum SyncTrigger {
  auto('auto'),
  manual('manual'),
  connectivity('connectivity'),
  refresh('refresh');

  const SyncTrigger(this.key);

  final String key;
}

enum SyncEventType { started, success, failure }

class SyncMetrics {
  const SyncMetrics({
    required this.pushed,
    required this.pulled,
    required this.kept,
    required this.cleaned,
  });

  const SyncMetrics.empty() : this(pushed: 0, pulled: 0, kept: 0, cleaned: 0);

  final int pushed;
  final int pulled;
  final int kept;
  final int cleaned;

  int get totalChanged => pushed + pulled + cleaned;
}

class SyncEvent {
  const SyncEvent({
    required this.type,
    required this.trigger,
    required this.occurredAt,
    required this.metrics,
    this.error,
  });

  final SyncEventType type;
  final SyncTrigger trigger;
  final DateTime occurredAt;
  final SyncMetrics metrics;
  final String? error;
}

class SyncQueueService {
  SyncQueueService({
    DatabaseProvider? databaseProvider,
    Connectivity? connectivity,
    SyncHttpClient? httpClient,
    SyncMergePolicy? mergePolicy,
    SyncPayloadMapper? payloadMapper,
  }) : _databaseProvider = databaseProvider ?? DatabaseProvider(),
       _connectivity = connectivity ?? Connectivity(),
       _httpClient = httpClient ?? const SyncHttpClient(),
       _mergePolicy = mergePolicy ?? const SyncMergePolicy(),
       _payloadMapper = payloadMapper ?? const SyncPayloadMapper();

  final DatabaseProvider _databaseProvider;
  final Connectivity _connectivity;
  final SyncHttpClient _httpClient;
  final SyncMergePolicy _mergePolicy;
  final SyncPayloadMapper _payloadMapper;

  final _syncEventsController = StreamController<SyncEvent>.broadcast();

  StreamSubscription<dynamic>? _connectivitySubscription;
  AccessTokenProvider? _accessTokenProvider;
  SyncCompletionCallback? _onSyncComplete;
  bool _syncInProgress = false;
  Timer? _syncDebounceTimer;
  Timer? _periodicSyncTimer;
  int _consecutiveFailureCount = 0;

  static const Duration _defaultSyncDebounce = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(minutes: 2);
  static const Duration _periodicSyncInterval = Duration(minutes: 5);
  static const int _circuitBreakerThreshold = 3;
  static const Duration _cacheTtl = Duration(minutes: 60);

  static const String _lastPullAtSettingKey = 'sync.lastPullAt';
  static const String _lastSuccessAtSettingKey = 'sync.lastSuccessAt';

  Stream<SyncEvent> get syncEvents => _syncEventsController.stream;

  Future<void> start({
    required AccessTokenProvider accessTokenProvider,
    SyncCompletionCallback? onSyncComplete,
  }) async {
    _accessTokenProvider = accessTokenProvider;
    _onSyncComplete = onSyncComplete;
    await triggerSyncIfOnline(force: true);
    _startPeriodicSync();
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen((
      event,
    ) async {
      if (_isOnline(event)) {
        _consecutiveFailureCount = 0;
        await triggerSyncIfOnline(
          trigger: SyncTrigger.connectivity,
          force: true,
        );
      }
    });
  }

  Future<void> dispose() async {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    await _syncEventsController.close();
  }

  void scheduleSync({
    Duration delay = _defaultSyncDebounce,
    SyncTrigger trigger = SyncTrigger.auto,
  }) {
    if (_accessTokenProvider == null) {
      return;
    }
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(delay, () {
      unawaited(triggerSyncIfOnline(trigger: trigger, force: true));
    });
  }

  Future<void> triggerSyncIfOnline({
    SyncTrigger trigger = SyncTrigger.auto,
    bool force = false,
  }) {
    return _runSync(trigger: trigger, force: force, throwOnFailure: false);
  }

  Future<void> runManualSync({SyncTrigger trigger = SyncTrigger.manual}) {
    return _runSync(trigger: trigger, force: true, throwOnFailure: true);
  }

  Future<DateTime?> readLastSuccessfulSyncAt() async {
    final db = await _databaseProvider.database;
    final value = await _readSetting(db, _lastSuccessAtSettingKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  @visibleForTesting
  Future<MergeDecision> decideMergeForRow({
    required Database db,
    required String table,
    required Map<String, Object?> serverRow,
  }) {
    return _mergePolicy.decideMergeForRow(
      db: db,
      table: table,
      serverRow: serverRow,
    );
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
      unawaited(triggerSyncIfOnline(force: true));
    });
  }

  Future<void> _runSync({
    required SyncTrigger trigger,
    required bool force,
    required bool throwOnFailure,
  }) async {
    if (_syncInProgress) {
      return;
    }

    final accessTokenProvider = _accessTokenProvider;
    if (accessTokenProvider == null) {
      if (throwOnFailure) {
        throw StateError('Sync is not configured.');
      }
      return;
    }

    final token = (await accessTokenProvider())?.trim();
    if (token == null || token.isEmpty) {
      if (throwOnFailure) {
        throw StateError('Authentication is required for sync.');
      }
      return;
    }

    if (_consecutiveFailureCount >= _circuitBreakerThreshold && !force) {
      AppLogger.debug(
        'Sync circuit breaker open ($_consecutiveFailureCount failures).',
      );
      return;
    }

    if (!await _hasInternet()) {
      const error = 'No internet connection.';
      _emitEvent(
        SyncEvent(
          type: SyncEventType.failure,
          trigger: trigger,
          occurredAt: DateTime.now(),
          metrics: const SyncMetrics.empty(),
          error: error,
        ),
      );
      if (throwOnFailure) {
        throw StateError(error);
      }
      return;
    }

    _syncInProgress = true;
    _emitEvent(
      SyncEvent(
        type: SyncEventType.started,
        trigger: trigger,
        occurredAt: DateTime.now(),
        metrics: const SyncMetrics.empty(),
      ),
    );

    final db = await _databaseProvider.database;
    try {
      final stats = await _syncCycle(db: db, token: token);
      _consecutiveFailureCount = 0;
      await _writeSetting(
        db,
        _lastSuccessAtSettingKey,
        DateTime.now().toIso8601String(),
      );
      await _onSyncComplete?.call();
      _emitEvent(
        SyncEvent(
          type: SyncEventType.success,
          trigger: trigger,
          occurredAt: DateTime.now(),
          metrics: stats,
        ),
      );
      AppLogger.debug('Sync cycle completed successfully.');
    } catch (error) {
      _consecutiveFailureCount += 1;
      await _markAnySyncingAsFailed(db: db, error: error.toString());
      scheduleSync(delay: _retryDelayFor(_consecutiveFailureCount));
      _emitEvent(
        SyncEvent(
          type: SyncEventType.failure,
          trigger: trigger,
          occurredAt: DateTime.now(),
          metrics: const SyncMetrics.empty(),
          error: error.toString(),
        ),
      );
      if (throwOnFailure) {
        rethrow;
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<SyncMetrics> _syncCycle({
    required Database db,
    required String token,
  }) async {
    // Recover rows left in syncing after app/process interruptions.
    await _markAnySyncingAsFailed(db: db, error: 'interrupted_previous_sync');

    final pushBatch = await _buildPushBatch(db);
    final stats = _SyncWorkStats();
    SyncHttpResult? pushResponse;

    final hasPushChanges = pushBatch.payload.values.any(
      (rows) => rows.isNotEmpty,
    );
    if (hasPushChanges) {
      await _markBatchSyncing(db, pushBatch.idsByTable);
      pushResponse = await _httpClient.postJson(
        url: '${EnvConfig.apiBaseUrl}/api/v1/sync/push',
        token: token,
        payload: pushBatch.payload,
      );
    }

    final pullPayload = await _fetchPullPayload(db: db, token: token);
    late final _CleanupResult cleanupResult;
    await db.transaction((txn) async {
      if (hasPushChanges) {
        final response = pushResponse;
        if (response == null) {
          throw StateError('push_response_missing');
        }
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _applyPushResponse(
            db: txn,
            responseBody: response.body,
            pushBatch: pushBatch,
            stats: stats,
          );
        } else {
          await _markBatchFailed(
            db: txn,
            idsByTable: pushBatch.idsByTable,
            error: 'push_http_${response.statusCode}: ${response.body}',
          );
        }
      }
      await _mergePulledRows(txn: txn, pullPayload: pullPayload, stats: stats);
      await _writeSetting(txn, _lastPullAtSettingKey, pullPayload.serverTime);
      cleanupResult = await _cleanupExpiredSyncedRows(
        txn: txn,
        now: DateTime.now(),
      );
      stats.cleaned += cleanupResult.idsByTable.values.fold<int>(
        0,
        (sum, ids) => sum + ids.length,
      );
    });
    await _cleanupChunkAudioFiles(cleanupResult.chunkAudioPaths);

    return stats.toMetrics();
  }

  Future<_PullPayload> _fetchPullPayload({
    required Database db,
    required String token,
  }) async {
    final since = await _readSetting(db, _lastPullAtSettingKey);
    final response = await _httpClient.postJson(
      url: '${EnvConfig.apiBaseUrl}/api/v1/sync/pull',
      token: token,
      payload: {
        if (since != null && since.isNotEmpty) 'since': since,
        'tables': syncTables,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('pull_http_${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid sync pull response payload.');
    }

    final data = decoded['data'];
    if (data is! Map) {
      throw const FormatException('Missing data in sync pull response.');
    }

    final rowsByTable = <String, List<Map<String, Object?>>>{
      for (final table in syncTables) table: _rowsFromDynamicList(data[table]),
    };

    return _PullPayload(
      rowsByTable: rowsByTable,
      serverTime:
          _toText(data['serverTime']) ?? DateTime.now().toIso8601String(),
    );
  }

  Future<void> _mergePulledRows({
    required DatabaseExecutor txn,
    required _PullPayload pullPayload,
    required _SyncWorkStats stats,
  }) async {
    for (final table in syncTables) {
      final rows =
          pullPayload.rowsByTable[table] ?? const <Map<String, Object?>>[];
      for (final row in rows) {
        final decision = await _mergePolicy.decideMergeForRow(
          db: txn,
          table: table,
          serverRow: row,
        );
        switch (decision) {
          case MergeDecision.insertNew:
          case MergeDecision.updateFromServer:
            await _payloadMapper.applyServerRow(
              db: txn,
              table: table,
              row: row,
            );
            stats.pulled += 1;
          case MergeDecision.keepLocal:
            stats.kept += 1;
        }
      }
    }
  }

  Future<_PushBatch> _buildPushBatch(Database db) async {
    final payload = <String, List<Map<String, Object?>>>{};
    final idsByTable = <String, Set<String>>{};
    final clientToLocalByTable = <String, Map<String, String>>{};

    for (final table in syncTables) {
      final rows = await db.query(
        table,
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
        final payloadRow = _payloadMapper.toPayload(table, row);
        final clientLocalId = _toText(payloadRow['client_local_id']);
        if (clientLocalId != null && clientLocalId.isNotEmpty) {
          clientToLocal[clientLocalId] = localId;
        }
        mapped.add(payloadRow);
      }

      payload[table] = mapped;
      idsByTable[table] = ids;
      clientToLocalByTable[table] = clientToLocal;
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
          if (entry.key == 'transcripts') 'updatedAt': now,
        },
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    }
  }

  Future<void> _markBatchFailed({
    required DatabaseExecutor db,
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
          if (entry.key == 'transcripts') 'updatedAt': now,
        },
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    }
  }

  Future<void> _markAnySyncingAsFailed({
    required DatabaseExecutor db,
    required String error,
  }) async {
    final now = DateTime.now().toIso8601String();
    for (final table in syncTables) {
      await db.update(
        table,
        {
          'syncStatus': SyncStatus.failed.key,
          'syncError': error,
          if (table == 'transcripts') 'updatedAt': now,
        },
        where: 'syncStatus = ?',
        whereArgs: [SyncStatus.syncing.key],
      );
    }
  }

  Future<void> _applyPushResponse({
    required DatabaseExecutor db,
    required String responseBody,
    required _PushBatch pushBatch,
    required _SyncWorkStats stats,
  }) async {
    final now = DateTime.now().toIso8601String();
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map) {
      await _markBatchFailed(
        db: db,
        idsByTable: pushBatch.idsByTable,
        error: 'invalid_push_response',
      );
      return;
    }

    final data = decoded['data'];
    if (data is! Map) {
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
      for (final table in syncTables) table: <String>{},
    };

    for (final entry in appliedByTable.entries) {
      final table = entry.key;
      if (!syncTables.contains(table)) {
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
        stats.pushed += 1;
        await db.update(
          table,
          {
            'remoteId': _toText(appliedRow['remote_id']),
            'syncStatus': SyncStatus.synced.key,
            'syncError': null,
            'lastSyncedAt': now,
          },
          where: 'id = ?',
          whereArgs: [localId],
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
      await db.update(
        table,
        {
          'syncStatus': SyncStatus.failed.key,
          'syncError': _toText(conflict['reason']) ?? 'server_conflict',
        },
        where: 'id = ?',
        whereArgs: [localId],
      );
    }

    for (final table in syncTables) {
      final allIds = pushBatch.idsByTable[table] ?? const <String>{};
      final tableHandled = handledIds[table] ?? const <String>{};
      final unhandled = allIds.where((id) => !tableHandled.contains(id));
      for (final localId in unhandled) {
        await db.update(
          table,
          {'syncStatus': SyncStatus.failed.key, 'syncError': 'push_unhandled'},
          where: 'id = ?',
          whereArgs: [localId],
        );
      }
    }
  }

  Future<_CleanupResult> _cleanupExpiredSyncedRows({
    required DatabaseExecutor txn,
    required DateTime now,
  }) async {
    final cutoffDate = now.toUtc().subtract(_cacheTtl);
    final cleanedIds = <String, Set<String>>{
      for (final table in syncTables) table: <String>{},
    };
    final chunkAudioPaths = <String>{};

    for (final table in syncTables) {
      final columns = table == 'transcript_chunks'
          ? const ['id', 'audioPath', 'lastSyncedAt', 'deletedAt']
          : const ['id', 'lastSyncedAt', 'deletedAt'];
      final rows = await txn.query(
        table,
        columns: columns,
        where:
            'syncStatus = ? AND (deletedAt IS NOT NULL OR lastSyncedAt IS NOT NULL)',
        whereArgs: [SyncStatus.synced.key],
      );
      final expiredRows = rows.where((row) {
        final deletedAt = _toText(row['deletedAt']);
        if (deletedAt != null) {
          return true;
        }
        final lastSyncedAtStr = _toText(row['lastSyncedAt']);
        if (lastSyncedAtStr == null) {
          return false;
        }
        final lastSyncedAt = DateTime.tryParse(lastSyncedAtStr);
        if (lastSyncedAt == null) {
          return false;
        }
        return lastSyncedAt.toUtc().isBefore(cutoffDate);
      }).toList();
      final ids = expiredRows
          .map((row) => _toText(row['id']))
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      if (ids.isEmpty) {
        continue;
      }
      final placeholders = List.filled(ids.length, '?').join(', ');
      if (table == 'transcript_chunks') {
        for (final row in expiredRows) {
          final audioPath = _toText(row['audioPath']);
          if (audioPath != null && audioPath.isNotEmpty) {
            chunkAudioPaths.add(audioPath);
          }
        }
      }
      await txn.delete(
        table,
        where: 'id IN ($placeholders)',
        whereArgs: ids.toList(),
      );
      cleanedIds[table] = ids;
    }

    return _CleanupResult(
      idsByTable: cleanedIds,
      chunkAudioPaths: chunkAudioPaths,
    );
  }

  Future<void> _cleanupChunkAudioFiles(Set<String> audioPaths) async {
    if (audioPaths.isEmpty) {
      return;
    }

    for (final audioPath in audioPaths) {
      final file = File(audioPath);
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Best-effort cleanup; file deletion failures should not fail sync.
      }
    }
  }

  Future<String?> _readSetting(DatabaseExecutor db, String key) async {
    final rows = await db.query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _toText(rows.first['value']);
  }

  Future<void> _writeSetting(
    DatabaseExecutor db,
    String key,
    String value,
  ) async {
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
    return candidate > _maxRetryDelay ? _maxRetryDelay : candidate;
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

  List<Map<String, Object?>> _rowsFromDynamicList(Object? value) {
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

  String? _toText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  void _emitEvent(SyncEvent event) {
    if (_syncEventsController.isClosed) {
      return;
    }
    _syncEventsController.add(event);
  }
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

class _SyncWorkStats {
  int pushed = 0;
  int pulled = 0;
  int kept = 0;
  int cleaned = 0;

  SyncMetrics toMetrics() {
    return SyncMetrics(
      pushed: pushed,
      pulled: pulled,
      kept: kept,
      cleaned: cleaned,
    );
  }
}

class _PullPayload {
  const _PullPayload({required this.rowsByTable, required this.serverTime});

  final Map<String, List<Map<String, Object?>>> rowsByTable;
  final String serverTime;
}

class _CleanupResult {
  const _CleanupResult({
    required this.idsByTable,
    required this.chunkAudioPaths,
  });

  final Map<String, Set<String>> idsByTable;
  final Set<String> chunkAudioPaths;
}
