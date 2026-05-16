import 'dart:async';
import 'dart:convert';
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
  static const String _lastPullAtSettingKey = 'sync.lastPullAt';

  Future<void> start({
    required AccessTokenProvider accessTokenProvider,
    SyncCompletionCallback? onSyncComplete,
  }) async {
    _accessTokenProvider = accessTokenProvider;
    _onSyncComplete = onSyncComplete;
    await triggerSyncIfOnline();
    _startPeriodicSync();
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen((
      event,
    ) async {
      if (_isOnline(event)) {
        _consecutiveFailureCount = 0;
        await triggerSyncIfOnline();
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
    if (_syncInProgress) {
      return;
    }
    if (_consecutiveFailureCount >= _circuitBreakerThreshold) {
      AppLogger.debug(
        'Sync circuit breaker open ($_consecutiveFailureCount failures).',
      );
      return;
    }
    if (!await _hasInternet()) {
      return;
    }
    await _syncCycle();
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
      unawaited(triggerSyncIfOnline());
    });
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
        (rows) => rows.isNotEmpty,
      );

      if (hasPushChanges) {
        await _markBatchSyncing(db, pushBatch.idsByTable);
        final pushResponse = await _httpClient.postJson(
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
      await _onSyncComplete?.call();
      AppLogger.debug('Sync cycle completed successfully.');
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
          if (entry.key == 'transcripts') 'updatedAt': now,
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
    required Database db,
    required String responseBody,
    required _PushBatch pushBatch,
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
        await db.update(
          table,
          {
            'remoteId': _toText(appliedRow['remote_id']),
            'syncStatus': SyncStatus.synced.key,
            'syncError': null,
            'lastSyncedAt': _toText(appliedRow['updated_at']) ?? now,
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

  Future<void> _pullAndMerge({
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

    var appliedCount = 0;
    var skippedCount = 0;
    for (final table in syncTables) {
      final rows = _rowsFromDynamicList(data[table]);
      for (final row in rows) {
        final decision = await _mergePolicy.decideMergeForRow(
          db: db,
          table: table,
          serverRow: row,
        );
        switch (decision) {
          case MergeDecision.insertNew:
          case MergeDecision.updateFromServer:
            await _payloadMapper.applyServerRow(db: db, table: table, row: row);
            appliedCount++;
          case MergeDecision.keepLocal:
            skippedCount++;
        }
      }
    }

    AppLogger.debug(
      'Pull merge: applied=$appliedCount, skipped=$skippedCount.',
    );
    final serverTime =
        _toText(data['serverTime']) ?? DateTime.now().toIso8601String();
    await _writeSetting(db, _lastPullAtSettingKey, serverTime);
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
