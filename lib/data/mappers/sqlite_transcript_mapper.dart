import 'package:voicescribe_mobile/domain/models/domain.dart';

class SqliteTranscriptMapper {
  const SqliteTranscriptMapper._();

  static Transcript transcriptFromRow(Map<String, Object?> row) {
    final createdAt =
        _readDate(row['createdAt'] ?? row['created_at']) ?? DateTime.now();
    return Transcript(
      id: _readString(row['id']) ?? 'local-${createdAt.millisecondsSinceEpoch}',
      localId:
          _readString(row['localId'] ?? row['local_id']) ??
          _readString(row['id']) ??
          '',
      title: _readString(row['title']),
      durationSeconds: _readInt(
        row['durationSeconds'] ?? row['duration_seconds'],
      ),
      status: TranscriptStatus.fromKey(
        _readString(row['statusKey'] ?? row['status_key']),
      ),
      recordedAt: _readDate(row['recordedAt'] ?? row['recorded_at']),
      createdAt: createdAt,
      updatedAt: _readDate(row['updatedAt'] ?? row['updated_at']) ?? createdAt,
      userId: _readString(row['userId'] ?? row['user_id']),
      remoteId: _readString(row['remoteId'] ?? row['remote_id']),
      syncStatus: SyncStatus.fromKey(
        _readString(row['syncStatus'] ?? row['sync_status']),
      ),
      lastSyncedAt: _readDate(row['lastSyncedAt'] ?? row['last_synced_at']),
      syncError: _readString(row['syncError'] ?? row['sync_error']),
      deletedAt: _readDate(row['deletedAt'] ?? row['deleted_at']),
    );
  }

  static Map<String, Object?> transcriptToRow(Transcript transcript) {
    return {
      'id': transcript.id,
      'localId': transcript.localId,
      'title': transcript.title,
      'durationSeconds': transcript.durationSeconds,
      'statusKey': transcript.status.key,
      'recordedAt': transcript.recordedAt?.toIso8601String(),
      'createdAt': transcript.createdAt.toIso8601String(),
      'updatedAt': transcript.updatedAt.toIso8601String(),
      'userId': transcript.userId,
      'remoteId': transcript.remoteId,
      'syncStatus': transcript.syncStatus.key,
      'lastSyncedAt': transcript.lastSyncedAt?.toIso8601String(),
      'syncError': transcript.syncError,
      'deletedAt': transcript.deletedAt?.toIso8601String(),
    };
  }

  static TranscriptChunk chunkFromRow(Map<String, Object?> row) {
    return TranscriptChunk(
      id: _readString(row['id']) ?? '',
      transcriptId:
          _readString(row['transcriptId'] ?? row['transcript_id']) ?? '',
      chunkIndex: _readInt(row['chunkIndex'] ?? row['chunk_index']),
      text: _readString(row['text']) ?? '',
      audioPath: _readString(row['audioPath'] ?? row['audio_path']),
      recordedAt: _readDate(row['recordedAt'] ?? row['recorded_at']),
      startTime: _readDouble(row['startTime'] ?? row['start_time']),
      endTime: _readDouble(row['endTime'] ?? row['end_time']),
      confidence: _readNullableDouble(row['confidence']),
      transcriptionError: _readString(
        row['transcriptionError'] ?? row['transcription_error'],
      ),
      audioLevel: _readNullableDouble(row['audioLevel'] ?? row['audio_level']),
      remoteId: _readString(row['remoteId'] ?? row['remote_id']),
      syncStatus: SyncStatus.fromKey(
        _readString(row['syncStatus'] ?? row['sync_status']),
      ),
      lastSyncedAt: _readDate(row['lastSyncedAt'] ?? row['last_synced_at']),
      syncError: _readString(row['syncError'] ?? row['sync_error']),
      deletedAt: _readDate(row['deletedAt'] ?? row['deleted_at']),
    );
  }

  static Map<String, Object?> chunkToRow(TranscriptChunk chunk) {
    return {
      'id': chunk.id,
      'transcriptId': chunk.transcriptId,
      'chunkIndex': chunk.chunkIndex,
      'text': chunk.text,
      'audioPath': chunk.audioPath,
      'recordedAt': chunk.recordedAt?.toIso8601String(),
      'startTime': chunk.startTime,
      'endTime': chunk.endTime,
      'confidence': chunk.confidence,
      'transcriptionError': chunk.transcriptionError,
      'audioLevel': chunk.audioLevel,
      'remoteId': chunk.remoteId,
      'syncStatus': chunk.syncStatus.key,
      'lastSyncedAt': chunk.lastSyncedAt?.toIso8601String(),
      'syncError': chunk.syncError,
      'deletedAt': chunk.deletedAt?.toIso8601String(),
    };
  }

  static Summary summaryFromRow(Map<String, Object?> row) {
    final createdAt =
        _readDate(row['createdAt'] ?? row['created_at']) ?? DateTime.now();
    return Summary(
      id:
          _readString(row['id']) ??
          'summary-${createdAt.millisecondsSinceEpoch}',
      transcriptId:
          _readString(row['transcriptId'] ?? row['transcript_id']) ?? '',
      providerKey:
          _readString(row['providerKey'] ?? row['provider_key']) ?? 'local',
      model: _readString(row['model']) ?? 'local-default',
      summaryText: _readString(row['summaryText'] ?? row['summary_text']) ?? '',
      tokenCount: _readNullableInt(row['tokenCount'] ?? row['token_count']),
      processingTimeMs: _readNullableInt(
        row['processingTimeMs'] ?? row['processing_time_ms'],
      ),
      createdAt: createdAt,
      remoteId: _readString(row['remoteId'] ?? row['remote_id']),
      syncStatus: SyncStatus.fromKey(
        _readString(row['syncStatus'] ?? row['sync_status']),
      ),
      lastSyncedAt: _readDate(row['lastSyncedAt'] ?? row['last_synced_at']),
      syncError: _readString(row['syncError'] ?? row['sync_error']),
      deletedAt: _readDate(row['deletedAt'] ?? row['deleted_at']),
    );
  }

  static Map<String, Object?> summaryToRow(Summary summary) {
    return {
      'id': summary.id,
      'transcriptId': summary.transcriptId,
      'providerKey': summary.providerKey,
      'model': summary.model,
      'summaryText': summary.summaryText,
      'tokenCount': summary.tokenCount,
      'processingTimeMs': summary.processingTimeMs,
      'createdAt': summary.createdAt.toIso8601String(),
      'remoteId': summary.remoteId,
      'syncStatus': summary.syncStatus.key,
      'lastSyncedAt': summary.lastSyncedAt?.toIso8601String(),
      'syncError': summary.syncError,
      'deletedAt': summary.deletedAt?.toIso8601String(),
    };
  }

  static AppPreferences preferencesFromSettings(Map<String, String> settings) {
    return AppPreferences(
      summaryProvider: AppPreferences.normalizeSummaryProvider(
        settings['summaryProvider'] ?? 'local',
      ),
      summaryLength: AppPreferences.normalizeSummaryLength(
        settings['summaryLength'] ?? 'medium',
      ),
      themeMode: AppPreferences.normalizeThemeMode(
        settings['themeMode'] ?? 'system',
      ),
      localePreference: AppPreferences.normalizeLocalePreference(
        settings['localePreference'] ?? 'system',
      ),
      transcriptionModel: AppPreferences.normalizeTranscriptionModel(
        settings['transcriptionModel'] ?? 'base',
      ),
    );
  }

  static Map<String, String> preferencesToSettings(AppPreferences preferences) {
    return {
      'summaryProvider': preferences.summaryProvider,
      'summaryLength': preferences.summaryLength,
      'themeMode': preferences.themeMode,
      'localePreference': preferences.localePreference,
      'transcriptionModel': preferences.transcriptionModel,
    };
  }

  static String? _readString(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  static double _readDouble(Object? value) {
    return _readNullableDouble(value) ?? 0;
  }

  static double? _readNullableDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _readDate(Object? value) {
    final text = _readString(value);
    if (text == null) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
