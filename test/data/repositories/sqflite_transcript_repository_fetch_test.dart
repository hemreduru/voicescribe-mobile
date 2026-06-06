import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voicescribe_mobile/data/repositories/sqflite_transcript_repository.dart';
import 'package:voicescribe_mobile/data/services/database/database_provider.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late FakeAuthRepository authRepository;
  late FakeTranscriptApiClient apiClient;
  late SqfliteTranscriptRepository repository;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final provider = DatabaseProvider.test('voicescribe-repo-test.db');
    // Ensure a clean state by deleting any previous test database.
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'voicescribe-repo-test.db');
    await databaseFactory.deleteDatabase(dbPath);

    db = await provider.database;
    await _clearAllTables(db);

    authRepository = FakeAuthRepository(
      session: const AuthSessionState(
        userId: 'user-1',
        email: 'user@test.dev',
        accessToken: 'token',
        refreshToken: null,
        expiresAt: null,
      ),
    );
    apiClient = FakeTranscriptApiClient();
    repository = SqfliteTranscriptRepository(
      databaseProvider: provider,
      authRepository: authRepository,
      apiClient: apiClient,
      connectivity: FakeConnectivity(),
    );
  });

  tearDown(() async {
    await repository.dispose();
  });

  test(
    'fetchFromServer writes transcripts, chunks and summaries to cache',
    () async {
      apiClient.transcripts = [
        {
          'remote_id': '1',
          'local_id': 'local-1',
          'client_local_id': 'local-1',
          'title': 'Server Transcript',
          'duration_seconds': 120,
          'status_key': 'completed',
          'recorded_at': '2026-05-17T10:00:00Z',
          'created_at': '2026-05-17T10:00:00Z',
          'updated_at': '2026-05-17T10:00:00Z',
          'deleted_at': null,
          'chunks': [
            {
              'remote_id': '10',
              'client_local_id': 'local-chunk-1',
              'chunk_index': 1,
              'text': 'Hello world',
              'start_time': 0.0,
              'end_time': 5.0,
              'confidence': 0.95,
              'deleted_at': null,
            },
          ],
          'summaries': [
            {
              'remote_id': '20',
              'client_local_id': 'local-summary-1',
              'provider_key': 'openai',
              'model': 'gpt-4',
              'summary_text': 'A greeting.',
              'token_count': 10,
              'processing_time_ms': 500,
              'created_at': '2026-05-17T10:01:00Z',
              'deleted_at': null,
            },
          ],
        },
      ];

      final result = await repository.fetchFromServer(token: 'token');
      expect(result, isTrue);

      final snapshot = await repository.loadSnapshot();
      expect(snapshot.transcripts, hasLength(1));
      expect(snapshot.transcripts.first.title, 'Server Transcript');
      expect(snapshot.transcripts.first.remoteId, '1');
      expect(snapshot.transcripts.first.syncStatus, SyncStatus.synced);

      expect(snapshot.chunks, hasLength(1));
      expect(snapshot.chunks.first.text, 'Hello world');
      expect(snapshot.chunks.first.syncStatus, SyncStatus.synced);

      expect(snapshot.summaries, hasLength(1));
      expect(snapshot.summaries.first.summaryText, 'A greeting.');
      expect(snapshot.summaries.first.syncStatus, SyncStatus.synced);
    },
  );

  test('fetchFromServer does not overwrite an unsynced local edit', () async {
    // Local pending edit that has NOT been pushed yet.
    await db.insert('transcripts', {
      'id': 'local-1',
      'localId': 'local-1',
      'remoteId': '1',
      'title': 'My local edit',
      'durationSeconds': 120,
      'statusKey': 'completed',
      'createdAt': '2026-05-17T10:00:00Z',
      'updatedAt': '2026-05-17T12:00:00Z', // local is newer
      'syncStatus': SyncStatus.pending.key,
    });

    // Server returns an older copy under the same id.
    apiClient.transcripts = [
      {
        'remote_id': '1',
        'local_id': 'local-1',
        'client_local_id': 'local-1',
        'title': 'Stale server copy',
        'duration_seconds': 120,
        'status_key': 'completed',
        'recorded_at': '2026-05-17T10:00:00Z',
        'created_at': '2026-05-17T10:00:00Z',
        'updated_at': '2026-05-17T10:00:00Z', // server is older
        'deleted_at': null,
      },
    ];

    final result = await repository.fetchFromServer(token: 'token');
    expect(result, isTrue);

    final snapshot = await repository.loadSnapshot();
    expect(snapshot.transcripts, hasLength(1));
    expect(
      snapshot.transcripts.first.title,
      'My local edit',
      reason: 'merge policy must keep the unsynced local edit',
    );
    expect(snapshot.transcripts.first.syncStatus, SyncStatus.pending);
  });

  test(
    'fetchFromServer returns false on network failure without throwing',
    () async {
      apiClient.shouldThrow = true;

      final result = await repository.fetchFromServer(token: 'token');
      expect(result, isFalse);

      final snapshot = await repository.loadSnapshot();
      expect(snapshot.transcripts, isEmpty);
      expect(snapshot.chunks, isEmpty);
      expect(snapshot.summaries, isEmpty);
    },
  );

  test(
    'clearCache drops synced rows but preserves unsynced local data',
    () async {
      // Synced transcript (safely on the server) -> should be cleared.
      await db.insert('transcripts', {
        'id': 'synced-1',
        'localId': 'synced-1',
        'title': 'On server',
        'durationSeconds': 10,
        'statusKey': 'completed',
        'createdAt': '2026-05-17T10:00:00Z',
        'updatedAt': '2026-05-17T10:00:00Z',
        'syncStatus': SyncStatus.synced.key,
      });
      await db.insert('transcript_chunks', {
        'id': 'synced-chunk',
        'transcriptId': 'synced-1',
        'chunkIndex': 1,
        'text': 'Hello',
        'startTime': 0,
        'endTime': 1,
        'syncStatus': SyncStatus.synced.key,
      });

      // Unsynced (pending) transcript -> must survive logout/clearCache so an
      // offline user never loses a recording that was never backed up.
      await db.insert('transcripts', {
        'id': 'pending-1',
        'localId': 'pending-1',
        'title': 'Never backed up',
        'durationSeconds': 10,
        'statusKey': 'completed',
        'createdAt': '2026-05-17T10:00:00Z',
        'updatedAt': '2026-05-17T10:00:00Z',
        'syncStatus': SyncStatus.pending.key,
      });
      await db.insert('transcript_chunks', {
        'id': 'pending-chunk',
        'transcriptId': 'pending-1',
        'chunkIndex': 1,
        'text': 'Keep me',
        'startTime': 0,
        'endTime': 1,
        'syncStatus': SyncStatus.pending.key,
      });

      await repository.clearCache();

      final snapshot = await repository.loadSnapshot();
      expect(
        snapshot.transcripts.map((t) => t.id),
        ['pending-1'],
        reason: 'synced rows cleared, pending row preserved',
      );
      expect(snapshot.chunks.map((c) => c.id), ['pending-chunk']);
    },
  );

  test('refresh fetches from server when online and authenticated', () async {
    apiClient.transcripts = [
      {
        'remote_id': '2',
        'local_id': 'local-2',
        'client_local_id': 'local-2',
        'title': 'Refreshed',
        'duration_seconds': 60,
        'status_key': 'completed',
        'recorded_at': '2026-05-17T11:00:00Z',
        'created_at': '2026-05-17T11:00:00Z',
        'updated_at': '2026-05-17T11:00:00Z',
        'deleted_at': null,
        'chunks': [],
        'summaries': [],
      },
    ];

    await repository.refresh();

    final snapshot = await repository.loadSnapshot();
    expect(snapshot.transcripts, hasLength(1));
    expect(snapshot.transcripts.first.title, 'Refreshed');
  });
}

Future<void> _clearAllTables(Database db) async {
  await db.delete('transcript_chunks');
  await db.delete('summaries');
  await db.delete('transcripts');
  await db.delete('settings');
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session});

  AuthSessionState? session;
  final _controller = StreamController<AuthSessionState?>.broadcast();

  @override
  Stream<AuthSessionState?> watchSession() => _controller.stream;

  @override
  AuthSessionState? currentSession() => session;

  @override
  Future<AuthSessionState?> restoreSession() async {
    _controller.add(session);
    return session;
  }

  @override
  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    session = null;
    _controller.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return const [ConnectivityResult.wifi];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTranscriptApiClient implements TranscriptApiClient {
  FakeTranscriptApiClient();

  List<Map<String, Object?>> transcripts = [];
  bool shouldThrow = false;

  @override
  Future<List<Map<String, Object?>>> fetchTranscripts({
    required String token,
  }) async {
    if (shouldThrow) {
      throw const TranscriptFetchException('Network error');
    }
    return transcripts;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
