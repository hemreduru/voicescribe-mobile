import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voicescribe_mobile/data/services/database/database_provider.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_payload_mapper.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  const mapper = SyncPayloadMapper();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = p.join(await getDatabasesPath(), 'voicescribe.db');
    await databaseFactory.deleteDatabase(dbPath);
  });

  setUp(() async {
    db = await DatabaseProvider().database;
    await db.delete('transcript_chunks');
    await db.delete('transcripts');
    await db.insert('transcripts', {
      'id': 'local-t1',
      'localId': 'local-t1',
      'remoteId': 'r-t1',
      'statusKey': TranscriptStatus.completed.key,
      'createdAt': '2026-05-17T10:00:00Z',
      'updatedAt': '2026-05-17T10:00:00Z',
      'syncStatus': SyncStatus.synced.key,
    });
  });

  test(
    'a pulled chunk with text is marked transcribed (not reset to 0)',
    () async {
      // Simulates the sync pull echoing back a chunk the client already pushed:
      // ConflictAlgorithm.replace must not drop the transcribed flag, or the
      // transcript would look like it still has pending work.
      await mapper.applyServerRow(
        db: db,
        table: 'transcript_chunks',
        row: {
          'remote_id': 'r-c1',
          'client_local_id': 'local-c1',
          'transcript_client_local_id': 'local-t1',
          'chunk_index': 1,
          'text': 'Merhaba dünya',
          'start_time': 0,
          'end_time': 2,
        },
      );

      final rows = await db.query(
        'transcript_chunks',
        where: 'id = ?',
        whereArgs: ['local-c1'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['isTranscribed'], 1);
      expect(rows.first['text'], 'Merhaba dünya');
      expect(rows.first['syncStatus'], SyncStatus.synced.key);
    },
  );
}
