import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voicescribe_mobile/data/services/database/database_provider.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_http_client.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late FakeConnectivity connectivity;
  late FakeSyncHttpClient httpClient;
  late SyncQueueService service;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'voicescribe.db');
    await databaseFactory.deleteDatabase(dbPath);
  });

  setUp(() async {
    db = await DatabaseProvider().database;
    await _clearAllTables(db);

    connectivity = FakeConnectivity();
    httpClient = FakeSyncHttpClient(
      pushResult: const SyncHttpResult(
        statusCode: 200,
        body: '{"data":{"applied":{},"conflicts":[]}}',
      ),
      pullResult: const SyncHttpResult(
        statusCode: 200,
        body:
            '{"data":{"serverTime":"2026-05-17T12:00:00Z","transcripts":[],"transcript_chunks":[],"summaries":[]}}',
      ),
    );
    service = SyncQueueService(
      connectivity: connectivity,
      httpClient: httpClient,
    );
    await service.start(accessTokenProvider: () async => 'token');
  });

  tearDown(() async {
    await service.dispose();
    await connectivity.dispose();
    await _clearAllTables(db);
  });

  test(
    'manual sync marks applied local transcript synced and records success event',
    () async {
      await db.insert('transcripts', {
        'id': 'local-1',
        'localId': 'local-1',
        'title': 'Draft',
        'durationSeconds': 10,
        'statusKey': TranscriptStatus.completed.key,
        'createdAt': '2026-05-17T10:00:00Z',
        'updatedAt': '2026-05-17T10:00:00Z',
        'syncStatus': SyncStatus.pending.key,
      });

      httpClient.pushResult = const SyncHttpResult(
        statusCode: 200,
        body:
            '{"data":{"applied":{"transcripts":[{"client_local_id":"local-1","remote_id":"remote-1","updated_at":"2026-05-17T12:00:00Z"}]},"conflicts":[]}}',
      );

      final events = <SyncEvent>[];
      final subscription = service.syncEvents.listen(events.add);
      await service.runManualSync();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subscription.cancel();

      final rows = await db.query(
        'transcripts',
        where: 'id = ?',
        whereArgs: ['local-1'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['syncStatus'], SyncStatus.synced.key);
      expect(rows.first['remoteId'], 'remote-1');
      expect(rows.first['syncError'], isNull);
      expect(rows.first['lastSyncedAt'], isNotNull);

      expect(events.any((e) => e.type == SyncEventType.started), isTrue);
      expect(events.any((e) => e.type == SyncEventType.success), isTrue);
    },
  );

  test('conflict keeps local data and does not delete the row', () async {
    await db.insert('transcripts', {
      'id': 'local-conflict',
      'localId': 'local-conflict',
      'title': 'Keep me',
      'durationSeconds': 10,
      'statusKey': TranscriptStatus.completed.key,
      'createdAt': '2026-05-17T10:00:00Z',
      'updatedAt': '2026-05-17T10:00:00Z',
      'syncStatus': SyncStatus.pending.key,
    });

    httpClient.pushResult = const SyncHttpResult(
      statusCode: 200,
      body:
          '{"data":{"applied":{},"conflicts":[{"table":"transcripts","client_local_id":"local-conflict","reason":"conflict_detected"}]}}',
    );

    await service.runManualSync();

    final rows = await db.query(
      'transcripts',
      where: 'id = ?',
      whereArgs: ['local-conflict'],
    );
    expect(rows, hasLength(1));
    expect(rows.first['syncStatus'], SyncStatus.failed.key);
    expect(rows.first['syncError'], 'conflict_detected');
  });

  // ---------------------------------------------------------------------------
  // Interruption / network-loss resilience (#3): a sync cut short by a dropped
  // connection or a killed app must never lose data or wedge rows in `syncing`
  // — they have to end up retryable and converge once connectivity returns.
  // ---------------------------------------------------------------------------

  String appliedBody(String clientLocalId, String remoteId) =>
      '{"data":{"applied":{"transcripts":[{"client_local_id":"$clientLocalId",'
      '"remote_id":"$remoteId","updated_at":"2026-05-17T12:00:00Z"}]},'
      '"conflicts":[]}}';

  test(
    'a dropped connection mid-push leaves the row failed (retryable), not stuck syncing',
    () async {
      await db.insert('transcripts', {
        'id': 'local-net',
        'localId': 'local-net',
        'title': 'Draft',
        'durationSeconds': 10,
        'statusKey': TranscriptStatus.completed.key,
        'createdAt': '2026-05-17T10:00:00Z',
        'updatedAt': '2026-05-17T10:00:00Z',
        'syncStatus': SyncStatus.pending.key,
      });

      // Connection drops the moment we POST the push. runManualSync surfaces
      // the error, but the row must still be left in a safe, retryable state.
      httpClient.throwOnPushOnce = const SocketException('connection reset');
      await expectLater(
        service.runManualSync(),
        throwsA(isA<SocketException>()),
      );

      final rows = await db.query(
        'transcripts',
        where: 'id = ?',
        whereArgs: ['local-net'],
      );
      expect(rows.first['syncStatus'], SyncStatus.failed.key);
      // The row is still here (no data loss) and will be re-pushed next cycle.
      expect(rows.first['remoteId'], isNull);
    },
  );

  test(
    'a row left in syncing by an interrupted run is recovered and re-pushed to synced',
    () async {
      // Simulates the app being killed after marking the row syncing but before
      // the synced write landed.
      await db.insert('transcripts', {
        'id': 'local-stuck',
        'localId': 'local-stuck',
        'title': 'Interrupted',
        'durationSeconds': 10,
        'statusKey': TranscriptStatus.completed.key,
        'createdAt': '2026-05-17T10:00:00Z',
        'updatedAt': '2026-05-17T10:00:00Z',
        'syncStatus': SyncStatus.syncing.key,
      });

      httpClient.pushResult = SyncHttpResult(
        statusCode: 200,
        body: appliedBody('local-stuck', 'remote-stuck'),
      );

      await service.runManualSync();

      final rows = await db.query(
        'transcripts',
        where: 'id = ?',
        whereArgs: ['local-stuck'],
      );
      expect(rows.first['syncStatus'], SyncStatus.synced.key);
      expect(rows.first['remoteId'], 'remote-stuck');
    },
  );

  test(
    'a previously failed row is retried on the next sync and converges',
    () async {
      await db.insert('transcripts', {
        'id': 'local-failed',
        'localId': 'local-failed',
        'title': 'Retry me',
        'durationSeconds': 10,
        'statusKey': TranscriptStatus.completed.key,
        'createdAt': '2026-05-17T10:00:00Z',
        'updatedAt': '2026-05-17T10:00:00Z',
        'syncStatus': SyncStatus.failed.key,
        'syncError': 'previous network error',
      });

      httpClient.pushResult = SyncHttpResult(
        statusCode: 200,
        body: appliedBody('local-failed', 'remote-failed'),
      );

      await service.runManualSync();

      final rows = await db.query(
        'transcripts',
        where: 'id = ?',
        whereArgs: ['local-failed'],
      );
      expect(rows.first['syncStatus'], SyncStatus.synced.key);
      expect(rows.first['remoteId'], 'remote-failed');
      expect(rows.first['syncError'], isNull);
    },
  );

  test(
    'ttl cleanup removes only soft-deleted expired synced rows; active synced rows are preserved as cache',
    () async {
      final expired = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 61))
          .toIso8601String();
      final fresh = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();

      final audioFile = File(
        p.join(Directory.systemTemp.path, 'voicescribe-sync-test-audio.wav'),
      )..writeAsStringSync('audio');

      // 1. Soft-deleted + expired lastSyncedAt -> SHOULD be cleaned up.
      await db.insert('transcript_chunks', {
        'id': 'chunk-deleted-expired',
        'transcriptId': 'local-a',
        'chunkIndex': 1,
        'text': 'Old deleted',
        'audioPath': audioFile.path,
        'startTime': 0,
        'endTime': 1,
        'syncStatus': SyncStatus.synced.key,
        'lastSyncedAt': expired,
        'deletedAt': expired,
      });

      // 2. Active synced + expired lastSyncedAt -> PRESERVED as offline cache.
      await db.insert('transcript_chunks', {
        'id': 'chunk-active-expired',
        'transcriptId': 'local-a',
        'chunkIndex': 2,
        'text': 'Old active',
        'audioPath': null,
        'startTime': 1,
        'endTime': 2,
        'syncStatus': SyncStatus.synced.key,
        'lastSyncedAt': expired,
      });

      // 3. Soft-deleted + fresh lastSyncedAt -> PRESERVED.
      await db.insert('transcript_chunks', {
        'id': 'chunk-deleted-fresh',
        'transcriptId': 'local-a',
        'chunkIndex': 3,
        'text': 'Fresh deleted',
        'audioPath': null,
        'startTime': 2,
        'endTime': 3,
        'syncStatus': SyncStatus.synced.key,
        'lastSyncedAt': fresh,
        'deletedAt': fresh,
      });

      // 4. Failed -> PRESERVED.
      await db.insert('transcript_chunks', {
        'id': 'chunk-failed',
        'transcriptId': 'local-a',
        'chunkIndex': 4,
        'text': 'Failed',
        'audioPath': null,
        'startTime': 3,
        'endTime': 4,
        'syncStatus': SyncStatus.failed.key,
        'lastSyncedAt': expired,
      });

      await service.runManualSync();

      final deletedExpiredRows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-deleted-expired'],
      );
      final activeExpiredRows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-active-expired'],
      );
      final deletedFreshRows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-deleted-fresh'],
      );
      final failedRows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-failed'],
      );

      // Only soft-deleted + expired should be removed.
      expect(deletedExpiredRows, isEmpty);
      expect(audioFile.existsSync(), isFalse);

      // Active synced (cache), fresh soft-deleted, and failed should stay.
      expect(activeExpiredRows, hasLength(1));
      expect(deletedFreshRows, hasLength(1));
      expect(failedRows, hasLength(1));
    },
  );

  test(
    'sync evicts audio of synced transcribed chunks but keeps unsynced audio',
    () async {
      final syncedAudio = File(
        p.join(Directory.systemTemp.path, 'vs-evict-synced.wav'),
      )..writeAsStringSync('audio');
      final pendingAudio = File(
        p.join(Directory.systemTemp.path, 'vs-evict-pending.wav'),
      )..writeAsStringSync('audio');

      // Synced + transcribed -> audio is dead weight and should be evicted.
      await db.insert('transcript_chunks', {
        'id': 'chunk-synced',
        'transcriptId': 'local-a',
        'chunkIndex': 1,
        'text': 'Done',
        'audioPath': syncedAudio.path,
        'startTime': 0,
        'endTime': 1,
        'isTranscribed': 1,
        'syncStatus': SyncStatus.synced.key,
        'lastSyncedAt': '2026-05-17T10:00:00Z',
      });

      // Unsynced -> audio must be preserved (still needed for push/retry).
      await db.insert('transcript_chunks', {
        'id': 'chunk-pending',
        'transcriptId': 'local-a',
        'chunkIndex': 2,
        'text': '',
        'audioPath': pendingAudio.path,
        'startTime': 1,
        'endTime': 2,
        'isTranscribed': 0,
        'syncStatus': SyncStatus.pending.key,
      });

      await service.runManualSync();

      final syncedRow = (await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-synced'],
      )).first;
      final pendingRow = (await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-pending'],
      )).first;

      expect(syncedRow['audioPath'], isNull);
      expect(syncedRow['text'], 'Done', reason: 'text row kept as cache');
      expect(syncedAudio.existsSync(), isFalse);

      expect(pendingRow['audioPath'], pendingAudio.path);
      expect(pendingAudio.existsSync(), isTrue);

      pendingAudio.deleteSync();
    },
  );

  test(
    'audio is evicted in the SAME cycle a transcribed chunk is first synced (#4)',
    () async {
      // The user's concern: synced audio should leave the phone immediately,
      // not linger to a later sync. A pending+transcribed chunk with audio is
      // pushed, the server applies it, and the eviction must run in the same
      // transaction so the file is gone after a single sync.
      final audio = File(
        p.join(Directory.systemTemp.path, 'vs-evict-fresh.wav'),
      )..writeAsStringSync('audio');

      await db.insert('transcript_chunks', {
        'id': 'chunk-fresh',
        'transcriptId': 'local-a',
        'chunkIndex': 1,
        'text': 'Done',
        'audioPath': audio.path,
        'startTime': 0,
        'endTime': 1,
        'isTranscribed': 1,
        'syncStatus': SyncStatus.pending.key,
      });

      // Server applies the chunk (client_local_id == chunk id).
      httpClient.pushResult = const SyncHttpResult(
        statusCode: 200,
        body:
            '{"data":{"applied":{"transcript_chunks":[{"client_local_id":'
            '"chunk-fresh","remote_id":"remote-chunk","updated_at":'
            '"2026-05-17T12:00:00Z"}]},"conflicts":[]}}',
      );

      await service.runManualSync();

      final row = (await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-fresh'],
      )).first;
      expect(row['syncStatus'], SyncStatus.synced.key);
      expect(row['audioPath'], isNull, reason: 'audio evicted same cycle');
      expect(row['text'], 'Done', reason: 'text kept as offline cache');
      expect(audio.existsSync(), isFalse, reason: 'file deleted from disk');
    },
  );

  test('connectivity restored triggers automatic sync', () async {
    await service.dispose();
    await connectivity.dispose();

    connectivity = FakeConnectivity(initial: const [ConnectivityResult.none]);
    httpClient = FakeSyncHttpClient(
      pushResult: const SyncHttpResult(
        statusCode: 200,
        body:
            '{"data":{"applied":{"transcripts":[{"client_local_id":"local-offline","remote_id":"remote-offline","updated_at":"2026-05-17T12:00:00Z"}]},"conflicts":[]}}',
      ),
      pullResult: const SyncHttpResult(
        statusCode: 200,
        body:
            '{"data":{"serverTime":"2026-05-17T12:00:00Z","transcripts":[],"transcript_chunks":[],"summaries":[]}}',
      ),
    );
    service = SyncQueueService(
      connectivity: connectivity,
      httpClient: httpClient,
    );

    await db.insert('transcripts', {
      'id': 'local-offline',
      'localId': 'local-offline',
      'title': 'Offline',
      'durationSeconds': 4,
      'statusKey': TranscriptStatus.completed.key,
      'createdAt': '2026-05-17T10:00:00Z',
      'updatedAt': '2026-05-17T10:00:00Z',
      'syncStatus': SyncStatus.pending.key,
    });

    await service.start(accessTokenProvider: () async => 'token');

    connectivity.setResults(const [ConnectivityResult.wifi], emit: true);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final rows = await db.query(
      'transcripts',
      where: 'id = ?',
      whereArgs: ['local-offline'],
    );
    expect(rows, hasLength(1));
    expect(rows.first['syncStatus'], SyncStatus.synced.key);
    expect(httpClient.pushCalls, greaterThan(0));
  });

  test(
    'a 401 push invokes onAuthFailure, keeps local data and does not retry',
    () async {
      connectivity = FakeConnectivity();
      httpClient = FakeSyncHttpClient(
        pushResult: const SyncHttpResult(statusCode: 401, body: ''),
        pullResult: const SyncHttpResult(
          statusCode: 200,
          body:
              '{"data":{"serverTime":"2026-05-17T12:00:00Z","transcripts":[],"transcript_chunks":[],"summaries":[]}}',
        ),
      );
      service = SyncQueueService(
        connectivity: connectivity,
        httpClient: httpClient,
      );

      await db.insert('transcripts', {
        'id': 'local-expired',
        'localId': 'local-expired',
        'title': 'Expired token',
        'durationSeconds': 4,
        'statusKey': TranscriptStatus.completed.key,
        'createdAt': '2026-05-17T10:00:00Z',
        'updatedAt': '2026-05-17T10:00:00Z',
        'syncStatus': SyncStatus.pending.key,
      });

      var authFailures = 0;
      await service.start(
        accessTokenProvider: () async => 'dead-token',
        onAuthFailure: () async => authFailures += 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(authFailures, 1);
      // No row was lost; it stays retryable for after the next login.
      final rows = await db.query(
        'transcripts',
        where: 'id = ?',
        whereArgs: ['local-expired'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['syncStatus'], SyncStatus.failed.key);
      // A dead token must not trigger the retry loop: exactly one push.
      expect(httpClient.pushCalls, 1);

      // A manual sync surfaces the auth failure to its caller.
      await expectLater(
        service.runManualSync(),
        throwsA(isA<SyncAuthException>()),
      );
      expect(authFailures, 2);
    },
  );
}

Future<void> _clearAllTables(Database db) async {
  await db.delete('transcript_chunks');
  await db.delete('summaries');
  await db.delete('transcripts');
  await db.delete('settings');
}

class FakeConnectivity implements Connectivity {
  FakeConnectivity({List<ConnectivityResult>? initial})
    : _current = initial ?? const [ConnectivityResult.wifi];

  List<ConnectivityResult> _current;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void setResults(List<ConnectivityResult> results, {bool emit = false}) {
    _current = results;
    if (emit) {
      _controller.add(results);
    }
  }

  Future<void> dispose() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSyncHttpClient extends SyncHttpClient {
  FakeSyncHttpClient({required this.pushResult, required this.pullResult});

  SyncHttpResult pushResult;
  SyncHttpResult pullResult;
  int pushCalls = 0;
  int pullCalls = 0;
  // When set, the next push throws this (simulating a dropped connection
  // mid-sync) and then clears, so a retry can succeed.
  Exception? throwOnPushOnce;

  @override
  Future<SyncHttpResult> postJson({
    required String url,
    required String token,
    required Map<String, Object?> payload,
  }) async {
    if (url.endsWith('/api/v1/sync/push')) {
      pushCalls += 1;
      final error = throwOnPushOnce;
      if (error != null) {
        throwOnPushOnce = null;
        throw error;
      }
      return pushResult;
    }
    if (url.endsWith('/api/v1/sync/pull')) {
      pullCalls += 1;
      return pullResult;
    }
    throw StateError('Unexpected URL: $url');
  }
}
