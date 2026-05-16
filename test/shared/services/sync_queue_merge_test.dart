import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/services/sync/sync_queue_service.dart';

void main() {
  late Database db;
  late SyncQueueService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE transcripts (
        id TEXT PRIMARY KEY,
        localId TEXT,
        remoteId TEXT,
        title TEXT,
        syncStatus TEXT,
        updatedAt TEXT,
        createdAt TEXT
      )
    ''');
    service = SyncQueueService();
  });

  tearDown(() async {
    await db.close();
  });

  test('insertNew: when no local row exists', () async {
    final decision = await service.decideMergeForRow(
      db: db,
      table: 'transcripts',
      serverRow: {'id': 'remote-1', 'updated_at': '2026-05-10T10:00:00Z'},
    );
    expect(decision, MergeDecision.insertNew);
  });

  test(
    'updateFromServer: when local row is synced and server is newer',
    () async {
      await db.insert('transcripts', {
        'id': 'local-1',
        'remoteId': 'remote-1',
        'syncStatus': SyncStatus.synced.key,
        'updatedAt': '2026-05-10T09:00:00Z',
      });

      final decision = await service.decideMergeForRow(
        db: db,
        table: 'transcripts',
        serverRow: {'id': 'remote-1', 'updated_at': '2026-05-10T10:00:00Z'},
      );
      expect(decision, MergeDecision.updateFromServer);
    },
  );

  test(
    'keepLocal: when synced local row is newer or equal to server',
    () async {
      await db.insert('transcripts', {
        'id': 'local-1',
        'remoteId': 'remote-1',
        'syncStatus': SyncStatus.synced.key,
        'updatedAt': '2026-05-10T10:00:00Z',
      });

      final olderDecision = await service.decideMergeForRow(
        db: db,
        table: 'transcripts',
        serverRow: {'id': 'remote-1', 'updated_at': '2026-05-10T09:00:00Z'},
      );
      final equalDecision = await service.decideMergeForRow(
        db: db,
        table: 'transcripts',
        serverRow: {'id': 'remote-1', 'updated_at': '2026-05-10T10:00:00Z'},
      );

      expect(olderDecision, MergeDecision.keepLocal);
      expect(equalDecision, MergeDecision.keepLocal);
    },
  );

  test('keepLocal: when local row is actively syncing', () async {
    await db.insert('transcripts', {
      'id': 'local-1',
      'remoteId': 'remote-1',
      'syncStatus': SyncStatus.syncing.key,
      'updatedAt': '2026-05-10T09:00:00Z',
    });

    final decision = await service.decideMergeForRow(
      db: db,
      table: 'transcripts',
      serverRow: {'id': 'remote-1', 'updated_at': '2026-05-10T10:00:00Z'},
    );
    expect(decision, MergeDecision.keepLocal);
  });

  test('keepLocal: when local row is pending and newer than server', () async {
    await db.insert('transcripts', {
      'id': 'local-1',
      'remoteId': 'remote-1',
      'syncStatus': SyncStatus.pending.key,
      'updatedAt': '2026-05-10T11:00:00Z', // local is newer
    });

    final decision = await service.decideMergeForRow(
      db: db,
      table: 'transcripts',
      serverRow: {
        'id': 'remote-1',
        'updated_at': '2026-05-10T10:00:00Z', // server is older
      },
    );
    expect(decision, MergeDecision.keepLocal);
  });

  test(
    'updateFromServer: when local row is pending but older than server',
    () async {
      await db.insert('transcripts', {
        'id': 'local-1',
        'remoteId': 'remote-1',
        'syncStatus': SyncStatus.pending.key,
        'updatedAt': '2026-05-10T09:00:00Z', // local is older
      });

      final decision = await service.decideMergeForRow(
        db: db,
        table: 'transcripts',
        serverRow: {
          'id': 'remote-1',
          'updated_at': '2026-05-10T10:00:00Z', // server is newer
        },
      );
      expect(decision, MergeDecision.updateFromServer);
    },
  );

  test('matches by localId when remoteId is missing in db', () async {
    await db.insert('transcripts', {
      'id': 'local-1',
      'localId': 'client-uuid-123',
      'syncStatus': SyncStatus.pending.key,
      'updatedAt': '2026-05-10T11:00:00Z',
    });

    final decision = await service.decideMergeForRow(
      db: db,
      table: 'transcripts',
      serverRow: {
        'id': 'new-remote-1',
        'client_local_id': 'client-uuid-123',
        'updated_at': '2026-05-10T10:00:00Z', // server is older
      },
    );
    expect(decision, MergeDecision.keepLocal);
  });
}
