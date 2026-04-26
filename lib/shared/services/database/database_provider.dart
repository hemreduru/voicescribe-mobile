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

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transcripts (
        id TEXT PRIMARY KEY,
        localId TEXT,
        title TEXT,
        durationSeconds INTEGER,
        statusKey TEXT,
        recordedAt TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE transcript_chunks (
        id TEXT PRIMARY KEY,
        transcriptId TEXT,
        chunkIndex INTEGER,
        text TEXT,
        audioPath TEXT,
        recordedAt TEXT,
        startTime REAL,
        endTime REAL,
        speakerLabel TEXT,
        confidence REAL,
        transcriptionError TEXT,
        syncStatus TEXT DEFAULT 'pending',
        FOREIGN KEY (transcriptId) REFERENCES transcripts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE summaries (
        id TEXT PRIMARY KEY,
        transcriptId TEXT,
        providerKey TEXT,
        model TEXT,
        summaryText TEXT,
        tokenCount INTEGER,
        processingTimeMs INTEGER,
        createdAt TEXT,
        syncStatus TEXT DEFAULT 'pending',
        FOREIGN KEY (transcriptId) REFERENCES transcripts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE speakers (
        id TEXT PRIMARY KEY,
        name TEXT,
        embedding TEXT,
        recordings INTEGER,
        hasVoiceSample INTEGER,
        createdAt TEXT,
        syncStatus TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }
}
