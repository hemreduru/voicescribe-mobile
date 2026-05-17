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

  test(
    'ttl cleanup removes only expired synced rows and preserves failed rows',
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

      await db.insert('transcript_chunks', {
        'id': 'chunk-expired',
        'transcriptId': 'local-a',
        'chunkIndex': 1,
        'text': 'Old',
        'audioPath': audioFile.path,
        'startTime': 0,
        'endTime': 1,
        'syncStatus': SyncStatus.synced.key,
        'lastSyncedAt': expired,
      });

      await db.insert('transcript_chunks', {
        'id': 'chunk-fresh',
        'transcriptId': 'local-a',
        'chunkIndex': 2,
        'text': 'Fresh',
        'audioPath': null,
        'startTime': 1,
        'endTime': 2,
        'syncStatus': SyncStatus.synced.key,
        'lastSyncedAt': fresh,
      });

      await db.insert('transcript_chunks', {
        'id': 'chunk-failed',
        'transcriptId': 'local-a',
        'chunkIndex': 3,
        'text': 'Failed',
        'audioPath': null,
        'startTime': 2,
        'endTime': 3,
        'syncStatus': SyncStatus.failed.key,
        'lastSyncedAt': expired,
      });

      await service.runManualSync();

      final expiredRows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-expired'],
      );
      final freshRows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-fresh'],
      );
      final failedRows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['chunk-failed'],
      );

      expect(expiredRows, isEmpty);
      expect(freshRows, hasLength(1));
      expect(failedRows, hasLength(1));
      expect(audioFile.existsSync(), isFalse);
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

  @override
  Future<SyncHttpResult> postJson({
    required String url,
    required String token,
    required Map<String, Object?> payload,
  }) async {
    if (url.endsWith('/api/v1/sync/push')) {
      pushCalls += 1;
      return pushResult;
    }
    if (url.endsWith('/api/v1/sync/pull')) {
      pullCalls += 1;
      return pullResult;
    }
    throw StateError('Unexpected URL: $url');
  }
}
