import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

class DatabaseProvider {
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();
  static final DatabaseProvider _instance = DatabaseProvider._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'voicescribe.db');

    return openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

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
        syncStatus TEXT DEFAULT 'pending',
        lastSyncedAt TEXT,
        syncError TEXT,
        deletedAt TEXT,
        FOREIGN KEY (transcriptId) REFERENCES transcripts (id) ON DELETE CASCADE
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
        deletedAt TEXT,
        FOREIGN KEY (transcriptId) REFERENCES transcripts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
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
  }

  Future<void> _migrateV4ToV5(Database db) async {
    await _addColumnIfMissing(db, 'transcript_chunks', 'audioLevel', 'REAL');
  }

  Future<void> _migrateV5ToV6(Database db) async {
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
