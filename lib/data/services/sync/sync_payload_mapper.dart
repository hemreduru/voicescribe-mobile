import 'package:sqflite/sqflite.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

const syncTables = <String>['transcripts', 'transcript_chunks', 'summaries'];

class SyncPayloadMapper {
  const SyncPayloadMapper();

  Map<String, Object?> toPayload(String table, Map<String, Object?> row) {
    return switch (table) {
      'transcripts' => _transcriptPayload(row),
      'transcript_chunks' => _chunkPayload(row),
      'summaries' => _summaryPayload(row),
      _ => const <String, Object?>{},
    };
  }

  Future<void> applyServerRow({
    required DatabaseExecutor db,
    required String table,
    required Map<String, Object?> row,
  }) async {
    switch (table) {
      case 'transcripts':
        await _applyTranscriptServerRow(db, row);
      case 'transcript_chunks':
        await _applyTranscriptChunkServerRow(db, row);
      case 'summaries':
        await _applySummaryServerRow(db, row);
    }
  }

  Map<String, Object?> _transcriptPayload(Map<String, Object?> row) {
    final localId = _toText(row['localId'] ?? row['id']) ?? '';
    return {
      'id': _toText(row['id']),
      'local_id': localId,
      'localId': localId,
      'client_local_id': localId,
      'clientLocalId': localId,
      'title': row['title'],
      'duration_seconds': _toInt(row['durationSeconds']),
      'durationSeconds': _toInt(row['durationSeconds']),
      'status_key': row['statusKey'],
      'statusKey': row['statusKey'],
      'recorded_at': row['recordedAt'],
      'recordedAt': row['recordedAt'],
      'updated_at': row['updatedAt'],
      'updatedAt': row['updatedAt'],
      'deleted_at': row['deletedAt'],
      'deletedAt': row['deletedAt'],
    };
  }

  Map<String, Object?> _chunkPayload(Map<String, Object?> row) {
    final localId = _toText(row['id']) ?? '';
    return {
      'id': localId,
      'client_local_id': localId,
      'clientLocalId': localId,
      'transcript_client_local_id': _toText(row['transcriptId']),
      'transcriptClientLocalId': _toText(row['transcriptId']),
      'chunk_index': _toInt(row['chunkIndex']),
      'chunkIndex': _toInt(row['chunkIndex']),
      'text': row['text'],
      'start_time': _toDouble(row['startTime']),
      'startTime': _toDouble(row['startTime']),
      'end_time': _toDouble(row['endTime']),
      'endTime': _toDouble(row['endTime']),
      'confidence': row['confidence'],
      'deleted_at': row['deletedAt'],
      'deletedAt': row['deletedAt'],
    };
  }

  Map<String, Object?> _summaryPayload(Map<String, Object?> row) {
    final localId = _toText(row['id']) ?? '';
    return {
      'id': localId,
      'client_local_id': localId,
      'clientLocalId': localId,
      'transcript_client_local_id': _toText(row['transcriptId']),
      'transcriptClientLocalId': _toText(row['transcriptId']),
      'provider_key': row['providerKey'],
      'providerKey': row['providerKey'],
      'model': row['model'],
      'summary_text': row['summaryText'],
      'summaryText': row['summaryText'],
      'token_count': row['tokenCount'],
      'tokenCount': row['tokenCount'],
      'processing_time_ms': row['processingTimeMs'],
      'processingTimeMs': row['processingTimeMs'],
      'deleted_at': row['deletedAt'],
      'deletedAt': row['deletedAt'],
    };
  }

  Future<void> _applyTranscriptServerRow(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final remoteId = _toText(row['remote_id'] ?? row['id']);
    final clientLocalId = _toText(row['client_local_id'] ?? row['local_id']);
    var localId = await _findLocalId(
      db: db,
      table: 'transcripts',
      remoteId: remoteId,
      clientLocalId: clientLocalId,
      clientColumn: 'localId',
    );

    localId ??=
        clientLocalId ??
        (remoteId == null ? null : 'remote-transcript-$remoteId');
    if (localId == null) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    await db.insert('transcripts', {
      'id': localId,
      'localId': clientLocalId ?? localId,
      'userId': _toText(row['user_id']),
      'remoteId': remoteId,
      'title': _toText(row['title']),
      'durationSeconds': _toInt(row['duration_seconds']),
      'statusKey': _normalizeTranscriptStatusKey(
        _toText(row['status_key'] ?? row['statusKey']),
      ),
      'recordedAt': _toText(row['recorded_at']),
      'createdAt': _toText(row['created_at']) ?? now,
      'updatedAt': _toText(row['updated_at']) ?? now,
      'syncStatus': SyncStatus.synced.key,
      'lastSyncedAt': now,
      'syncError': null,
      'deletedAt': _toText(row['deleted_at']),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _applyTranscriptChunkServerRow(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final remoteId = _toText(row['remote_id'] ?? row['id']);
    final clientLocalId = _toText(row['client_local_id']);
    var localId = await _findLocalId(
      db: db,
      table: 'transcript_chunks',
      remoteId: remoteId,
      clientLocalId: clientLocalId,
      clientColumn: 'id',
    );

    final transcriptLocalId = await _resolveTranscriptLocalId(db, row);
    if (transcriptLocalId == null) {
      return;
    }

    localId ??=
        clientLocalId ?? (remoteId == null ? null : 'remote-chunk-$remoteId');
    if (localId == null) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    await db.insert('transcript_chunks', {
      'id': localId,
      'transcriptId': transcriptLocalId,
      'remoteId': remoteId,
      'chunkIndex': _toInt(row['chunk_index'] ?? row['chunkIndex']),
      'text': _toText(row['text']) ?? '',
      'audioPath': null,
      'recordedAt': null,
      'startTime': _toDouble(row['start_time']),
      'endTime': _toDouble(row['end_time']),
      'confidence': row['confidence'],
      'transcriptionError': null,
      'syncStatus': SyncStatus.synced.key,
      'lastSyncedAt': now,
      'syncError': null,
      'deletedAt': _toText(row['deleted_at']),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _applySummaryServerRow(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final remoteId = _toText(row['remote_id'] ?? row['id']);
    final clientLocalId = _toText(row['client_local_id']);
    var localId = await _findLocalId(
      db: db,
      table: 'summaries',
      remoteId: remoteId,
      clientLocalId: clientLocalId,
      clientColumn: 'id',
    );

    final transcriptLocalId = await _resolveTranscriptLocalId(db, row);
    if (transcriptLocalId == null) {
      return;
    }

    localId ??=
        clientLocalId ?? (remoteId == null ? null : 'remote-summary-$remoteId');
    if (localId == null) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    await db.insert('summaries', {
      'id': localId,
      'transcriptId': transcriptLocalId,
      'remoteId': remoteId,
      'providerKey': _toText(row['provider_key']) ?? 'local',
      'model': _toText(row['model']) ?? 'local-default',
      'summaryText': _toText(row['summary_text']) ?? '',
      'tokenCount': row['token_count'],
      'processingTimeMs': row['processing_time_ms'],
      'createdAt': _toText(row['created_at']) ?? now,
      'syncStatus': SyncStatus.synced.key,
      'lastSyncedAt': now,
      'syncError': null,
      'deletedAt': _toText(row['deleted_at']),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> _resolveTranscriptLocalId(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final transcriptRemoteId = _toText(row['transcript_id']);
    if (transcriptRemoteId != null) {
      final byRemote = await _findFirstId(
        db: db,
        table: 'transcripts',
        where: 'remoteId = ?',
        whereArgs: [transcriptRemoteId],
      );
      if (byRemote != null) {
        return byRemote;
      }
    }
    final clientLocalId = _toText(
      row['transcript_client_local_id'] ?? row['transcriptClientLocalId'],
    );
    if (clientLocalId == null) {
      return null;
    }
    return _findFirstId(
      db: db,
      table: 'transcripts',
      where: 'localId = ? OR id = ?',
      whereArgs: [clientLocalId, clientLocalId],
    );
  }

  Future<String?> _findLocalId({
    required DatabaseExecutor db,
    required String table,
    required String? remoteId,
    required String? clientLocalId,
    required String clientColumn,
  }) async {
    if (remoteId != null) {
      final localId = await _findFirstId(
        db: db,
        table: table,
        where: 'remoteId = ?',
        whereArgs: [remoteId],
      );
      if (localId != null) {
        return localId;
      }
    }
    if (clientLocalId == null) {
      return null;
    }
    return _findFirstId(
      db: db,
      table: table,
      where: '$clientColumn = ? OR id = ?',
      whereArgs: [clientLocalId, clientLocalId],
    );
  }

  Future<String?> _findFirstId({
    required DatabaseExecutor db,
    required String table,
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final rows = await db.query(
      table,
      columns: const ['id'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _toText(rows.first['id']);
  }

  String _normalizeTranscriptStatusKey(String? key) {
    return switch (key) {
      'recording' => TranscriptStatus.recording.key,
      'processing' || 'transcribing' => TranscriptStatus.transcribing.key,
      'transcription_completed' => TranscriptStatus.transcriptionCompleted.key,
      'failed' ||
      'transcription_error' => TranscriptStatus.transcriptionError.key,
      'completed' => TranscriptStatus.completed.key,
      _ => TranscriptStatus.transcriptionCompleted.key,
    };
  }

  String? _toText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int _toInt(Object? value, {int defaultValue = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  double _toDouble(Object? value, {double defaultValue = 0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }
}
