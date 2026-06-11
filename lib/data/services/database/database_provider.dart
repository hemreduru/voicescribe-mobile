import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

class DatabaseProvider {
  factory DatabaseProvider() => _instance;

  DatabaseProvider._internal({String dbName = 'voicescribe.db'})
    : _dbName = dbName;

  /// Creates a non-singleton test instance with a custom database name.
  /// Use this in tests to avoid colliding with the production singleton.
  factory DatabaseProvider.test(String dbName) =>
      DatabaseProvider._internal(dbName: dbName);

  static final DatabaseProvider _instance = DatabaseProvider._internal();

  final String _dbName;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Foreign keys are intentionally NOT declared/enforced (sqflite leaves
  // PRAGMA foreign_keys off by default). Enabling them with ON DELETE CASCADE
  // would let a hard delete of a synced transcript cascade away *unsynced*
  // chunk rows — exactly the data loss clearCache()'s synced-only filter
  // guards against. Row lifecycles are managed explicitly per table instead.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transcripts (
        id TEXT PRIMARY KEY,
        localId TEXT,
        userId TEXT,
        remoteId TEXT,
        title TEXT,
        durationSeconds INTEGER,
        statusKey TEXT,
        recordedAt TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus TEXT DEFAULT 'pending',
        lastSyncedAt TEXT,
        syncError TEXT,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transcript_chunks (
        id TEXT PRIMARY KEY,
        transcriptId TEXT,
        remoteId TEXT,
        chunkIndex INTEGER,
        text TEXT,
        audioPath TEXT,
        recordedAt TEXT,
        startTime REAL,
        endTime REAL,
        confidence REAL,
        transcriptionError TEXT,
        audioLevel REAL,
        isTranscribed INTEGER DEFAULT 0,
        syncStatus TEXT DEFAULT 'pending',
        lastSyncedAt TEXT,
        syncError TEXT,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE summaries (
        id TEXT PRIMARY KEY,
        transcriptId TEXT,
        remoteId TEXT,
        providerKey TEXT,
        model TEXT,
        summaryText TEXT,
        tokenCount INTEGER,
        processingTimeMs INTEGER,
        createdAt TEXT,
        syncStatus TEXT DEFAULT 'pending',
        lastSyncedAt TEXT,
        syncError TEXT,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await _createIndexes(db);
  }

  /// Indexes for the hot query paths: per-transcript chunk lookups, sync-queue
  /// scans (`syncStatus IN (...)`), and the merge policy's per-pulled-row
  /// `remoteId`/`localId` probes — all full table scans without these.
  Future<void> _createIndexes(Database db) async {
    const indexes = {
      'idx_chunks_transcriptId': 'transcript_chunks (transcriptId)',
      'idx_chunks_syncStatus': 'transcript_chunks (syncStatus)',
      'idx_chunks_remoteId': 'transcript_chunks (remoteId)',
      'idx_transcripts_remoteId': 'transcripts (remoteId)',
      'idx_transcripts_localId': 'transcripts (localId)',
      'idx_transcripts_syncStatus': 'transcripts (syncStatus)',
      'idx_summaries_transcriptId': 'summaries (transcriptId)',
      'idx_summaries_syncStatus': 'summaries (syncStatus)',
      'idx_summaries_remoteId': 'summaries (remoteId)',
    };
    for (final entry in indexes.entries) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS ${entry.key} ON ${entry.value}',
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateV2ToV3(db);
    }
    if (oldVersion < 4) {
      await _migrateV3ToV4(db);
    }
    if (oldVersion < 5) {
      await _migrateV4ToV5(db);
    }
    if (oldVersion < 6) {
      await _migrateV5ToV6(db);
    }
    if (oldVersion < 7) {
      await _migrateV6ToV7(db);
    }
    if (oldVersion < 8) {
      await _migrateV7ToV8(db);
    }
  }

  Future<void> _migrateV7ToV8(Database db) async {
    await _createIndexes(db);
  }

  Future<void> _migrateV6ToV7(Database db) async {
    await _addColumnIfMissing(
      db,
      'transcript_chunks',
      'isTranscribed',
      'INTEGER DEFAULT 0',
    );
    // Backfill: chunks that already have text or a transcriptionError were
    // processed by the old code path — mark them as transcribed so the
    // status aggregation doesn't pin completed transcripts to "transcribing".
    await db.execute('''
      UPDATE transcript_chunks
      SET isTranscribed = 1
      WHERE (text IS NOT NULL AND text != '')
         OR (transcriptionError IS NOT NULL AND transcriptionError != '')
    ''');
  }

  Future<void> _migrateV4ToV5(Database db) async {
    await _addColumnIfMissing(db, 'transcript_chunks', 'audioLevel', 'REAL');
  }

  Future<void> _migrateV5ToV6(Database db) async {
    // Historical no-op: `audioLevel` was already added in v5. The v6 bump was
    // reserved for a separate change that landed elsewhere; the step is kept
    // so devices that already ran v5 remain on a monotonic version number.
    // (`_addColumnIfMissing` is idempotent, so re-running is harmless.)
    await _addColumnIfMissing(db, 'transcript_chunks', 'audioLevel', 'REAL');
  }

  Future<void> _migrateV3ToV4(Database db) async {
    await _normalizeLegacySpeakerStatuses(db);
    await db.execute('DROP TABLE IF EXISTS processing_jobs');
  }

  Future<void> _migrateV2ToV3(Database db) async {
    await db.execute('DROP TABLE IF EXISTS speakers');
    await _normalizeLegacySpeakerStatuses(db);
  }

  Future<void> _normalizeLegacySpeakerStatuses(Database db) async {
    await db.update(
      'transcripts',
      {'statusKey': TranscriptStatus.completed.key},
      where: 'statusKey = ?',
      whereArgs: ['speaker_analysis_completed'],
    );
    await db.update(
      'transcripts',
      {'statusKey': TranscriptStatus.transcriptionCompleted.key},
      where: 'statusKey IN (?, ?)',
      whereArgs: ['speaker_analysis_pending', 'speaker_analysis_running'],
    );
  }

  Future<void> _migrateV1ToV2(Database db) async {
    await _addColumnIfMissing(db, 'transcripts', 'userId', 'TEXT');
    await _addColumnIfMissing(db, 'transcripts', 'remoteId', 'TEXT');
    await _addColumnIfMissing(
      db,
      'transcripts',
      'syncStatus',
      "TEXT DEFAULT 'pending'",
    );
    await _addColumnIfMissing(db, 'transcripts', 'lastSyncedAt', 'TEXT');
    await _addColumnIfMissing(db, 'transcripts', 'syncError', 'TEXT');
    await _addColumnIfMissing(db, 'transcripts', 'deletedAt', 'TEXT');

    await _addColumnIfMissing(db, 'transcript_chunks', 'remoteId', 'TEXT');
    await _addColumnIfMissing(
      db,
      'transcript_chunks',
      'syncStatus',
      "TEXT DEFAULT 'pending'",
    );
    await _addColumnIfMissing(db, 'transcript_chunks', 'lastSyncedAt', 'TEXT');
    await _addColumnIfMissing(db, 'transcript_chunks', 'syncError', 'TEXT');
    await _addColumnIfMissing(db, 'transcript_chunks', 'deletedAt', 'TEXT');

    await _addColumnIfMissing(db, 'summaries', 'remoteId', 'TEXT');
    await _addColumnIfMissing(
      db,
      'summaries',
      'syncStatus',
      "TEXT DEFAULT 'pending'",
    );
    await _addColumnIfMissing(db, 'summaries', 'lastSyncedAt', 'TEXT');
    await _addColumnIfMissing(db, 'summaries', 'syncError', 'TEXT');
    await _addColumnIfMissing(db, 'summaries', 'deletedAt', 'TEXT');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String columnDefinition,
  ) async {
    final exists = await _hasColumn(db, table, column);
    if (exists) {
      return;
    }
    await db.execute('ALTER TABLE $table ADD COLUMN $column $columnDefinition');
  }

  Future<bool> _hasColumn(Database db, String table, String column) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.any((row) => row['name'] == column);
  }
}
