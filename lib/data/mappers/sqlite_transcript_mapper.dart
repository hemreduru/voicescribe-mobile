import 'package:voicescribe_mobile/domain/models/domain.dart';

/// Maps between domain models and sqflite rows. DB schema uses camelCase
/// (see `DatabaseProvider`); no snake_case fallback is needed.
class SqliteTranscriptMapper {
  const SqliteTranscriptMapper._();

  static Transcript transcriptFromRow(Map<String, Object?> row) {
    final createdAt = _readDate(row['createdAt']) ?? DateTime.now();
    return Transcript(
      id: _readString(row['id']) ?? 'local-${createdAt.millisecondsSinceEpoch}',
      localId: _readString(row['localId']) ?? _readString(row['id']) ?? '',
      title: _readString(row['title']),
      durationSeconds: _readInt(row['durationSeconds']),
      status: TranscriptStatus.fromKey(_readString(row['statusKey'])),
      recordedAt: _readDate(row['recordedAt']),
      createdAt: createdAt,
      updatedAt: _readDate(row['updatedAt']) ?? createdAt,
      userId: _readString(row['userId']),
      remoteId: _readString(row['remoteId']),
      syncStatus: SyncStatus.fromKey(_readString(row['syncStatus'])),
      lastSyncedAt: _readDate(row['lastSyncedAt']),
      syncError: _readString(row['syncError']),
      deletedAt: _readDate(row['deletedAt']),
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
      transcriptId: _readString(row['transcriptId']) ?? '',
      chunkIndex: _readInt(row['chunkIndex']),
      text: _readString(row['text']) ?? '',
      audioPath: _readString(row['audioPath']),
      recordedAt: _readDate(row['recordedAt']),
      startTime: _readDouble(row['startTime']),
      endTime: _readDouble(row['endTime']),
      confidence: _readNullableDouble(row['confidence']),
      transcriptionError: _readString(row['transcriptionError']),
      audioLevel: _readNullableDouble(row['audioLevel']),
      remoteId: _readString(row['remoteId']),
      isTranscribed: _readBool(row['isTranscribed']),
      syncStatus: SyncStatus.fromKey(_readString(row['syncStatus'])),
      lastSyncedAt: _readDate(row['lastSyncedAt']),
      syncError: _readString(row['syncError']),
      deletedAt: _readDate(row['deletedAt']),
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
      'isTranscribed': chunk.isTranscribed ? 1 : 0,
      'syncStatus': chunk.syncStatus.key,
      'lastSyncedAt': chunk.lastSyncedAt?.toIso8601String(),
      'syncError': chunk.syncError,
      'deletedAt': chunk.deletedAt?.toIso8601String(),
    };
  }

  static Summary summaryFromRow(Map<String, Object?> row) {
    final createdAt = _readDate(row['createdAt']) ?? DateTime.now();
    return Summary(
      id:
          _readString(row['id']) ??
          'summary-${createdAt.millisecondsSinceEpoch}',
      transcriptId: _readString(row['transcriptId']) ?? '',
      providerKey: _readString(row['providerKey']) ?? 'local',
      model: _readString(row['model']) ?? 'local-default',
      summaryText: _readString(row['summaryText']) ?? '',
      tokenCount: _readNullableInt(row['tokenCount']),
      processingTimeMs: _readNullableInt(row['processingTimeMs']),
      createdAt: createdAt,
      remoteId: _readString(row['remoteId']),
      syncStatus: SyncStatus.fromKey(_readString(row['syncStatus'])),
      lastSyncedAt: _readDate(row['lastSyncedAt']),
      syncError: _readString(row['syncError']),
      deletedAt: _readDate(row['deletedAt']),
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

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = value?.toString().toLowerCase();
    return text == '1' || text == 'true';
  }

  static DateTime? _readDate(Object? value) {
    final text = _readString(value);
    if (text == null) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
