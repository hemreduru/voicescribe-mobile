import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 2,
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
        speakerId TEXT,
        speakerLabel TEXT,
        speakerConfidence REAL,
        speakerAnalysisStatus TEXT DEFAULT 'pending',
        confidence REAL,
        transcriptionError TEXT,
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
      CREATE TABLE speakers (
        id TEXT PRIMARY KEY,
        userId TEXT,
        remoteId TEXT,
        name TEXT,
        embedding TEXT,
        recordings INTEGER,
        hasVoiceSample INTEGER,
        isUserNamed INTEGER,
        createdAt TEXT,
        syncStatus TEXT DEFAULT 'pending',
        lastSyncedAt TEXT,
        syncError TEXT,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE processing_jobs (
        id TEXT PRIMARY KEY,
        transcriptId TEXT,
        remoteId TEXT,
        type TEXT,
        status TEXT,
        lastProcessedChunkIndex INTEGER,
        retryCount INTEGER,
        error TEXT,
        createdAt TEXT,
        updatedAt TEXT,
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
    await _addColumnIfMissing(db, 'transcript_chunks', 'speakerId', 'TEXT');
    await _addColumnIfMissing(
      db,
      'transcript_chunks',
      'speakerConfidence',
      'REAL',
    );
    await _addColumnIfMissing(
      db,
      'transcript_chunks',
      'speakerAnalysisStatus',
      "TEXT DEFAULT 'pending'",
    );
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

    await _addColumnIfMissing(db, 'speakers', 'userId', 'TEXT');
    await _addColumnIfMissing(db, 'speakers', 'remoteId', 'TEXT');
    await _addColumnIfMissing(db, 'speakers', 'isUserNamed', 'INTEGER');
    await _addColumnIfMissing(
      db,
      'speakers',
      'syncStatus',
      "TEXT DEFAULT 'pending'",
    );
    await _addColumnIfMissing(db, 'speakers', 'lastSyncedAt', 'TEXT');
    await _addColumnIfMissing(db, 'speakers', 'syncError', 'TEXT');
    await _addColumnIfMissing(db, 'speakers', 'deletedAt', 'TEXT');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS processing_jobs (
        id TEXT PRIMARY KEY,
        transcriptId TEXT,
        remoteId TEXT,
        type TEXT,
        status TEXT,
        lastProcessedChunkIndex INTEGER,
        retryCount INTEGER,
        error TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus TEXT DEFAULT 'pending',
        lastSyncedAt TEXT,
        syncError TEXT,
        deletedAt TEXT,
        FOREIGN KEY (transcriptId) REFERENCES transcripts (id) ON DELETE CASCADE
      )
    ''');
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
