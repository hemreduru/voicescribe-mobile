import 'package:flutter/foundation.dart';

enum TranscriptStatus {
  recording('recording'),
  transcribing('transcribing'),
  completed('completed'),
  transcriptionCompleted('transcription_completed'),
  transcriptionError('transcription_error'),
  empty('empty');

  const TranscriptStatus(this.key);

  final String key;

  static TranscriptStatus fromKey(String? key) {
    return switch (key) {
      'speaker_analysis_completed' => TranscriptStatus.completed,
      'speaker_analysis_pending' ||
      'speaker_analysis_running' => TranscriptStatus.transcriptionCompleted,
      _ => TranscriptStatus.values.firstWhere(
        (status) => status.key == key,
        orElse: () => TranscriptStatus.empty,
      ),
    };
  }
}

enum SyncStatus {
  pending('pending'),
  syncing('syncing'),
  synced('synced'),
  failed('failed');

  const SyncStatus(this.key);

  final String key;

  static SyncStatus fromKey(String? key) {
    return SyncStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => SyncStatus.pending,
    );
  }
}

enum ProcessingJobType {
  sync('sync');

  const ProcessingJobType(this.key);

  final String key;

  static ProcessingJobType fromKey(String? key) {
    return ProcessingJobType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => ProcessingJobType.sync,
    );
  }
}

enum ProcessingJobStatus {
  pending('pending'),
  running('running'),
  completed('completed'),
  failed('failed');

  const ProcessingJobStatus(this.key);

  final String key;

  static ProcessingJobStatus fromKey(String? key) {
    return ProcessingJobStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => ProcessingJobStatus.pending,
    );
  }
}

@immutable
class Transcript {
  const Transcript({
    required this.id,
    required this.localId,
    required this.title,
    required this.durationSeconds,
    required this.status,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.remoteId,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.syncError,
    this.deletedAt,
  });

  factory Transcript.fromJson(Map<String, Object?> json) {
    final createdAt =
        _readDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now();
    return Transcript(
      id:
          _readString(json['id']) ??
          'local-${createdAt.millisecondsSinceEpoch}',
      localId:
          _readString(json['localId'] ?? json['local_id']) ??
          _readString(json['id']) ??
          '',
      title: _readString(json['title']),
      durationSeconds: _readInt(
        json['durationSeconds'] ?? json['duration_seconds'],
      ),
      status: TranscriptStatus.fromKey(
        _readString(json['statusKey'] ?? json['status_key']),
      ),
      recordedAt: _readDate(json['recordedAt'] ?? json['recorded_at']),
      createdAt: createdAt,
      updatedAt:
          _readDate(json['updatedAt'] ?? json['updated_at']) ?? createdAt,
      userId: _readString(json['userId'] ?? json['user_id']),
      remoteId: _readString(json['remoteId'] ?? json['remote_id']),
      syncStatus: SyncStatus.fromKey(
        _readString(json['syncStatus'] ?? json['sync_status']),
      ),
      lastSyncedAt: _readDate(json['lastSyncedAt'] ?? json['last_synced_at']),
      syncError: _readString(json['syncError'] ?? json['sync_error']),
      deletedAt: _readDate(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  final String id;
  final String localId;
  final String? title;
  final int durationSeconds;
  final TranscriptStatus status;
  final DateTime? recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final String? remoteId;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final DateTime? deletedAt;

  Transcript copyWith({
    String? id,
    String? localId,
    String? title,
    bool clearTitle = false,
    int? durationSeconds,
    TranscriptStatus? status,
    DateTime? recordedAt,
    bool clearRecordedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool clearUserId = false,
    String? remoteId,
    bool clearRemoteId = false,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? syncError,
    bool clearSyncError = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Transcript(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      title: clearTitle ? null : title ?? this.title,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      recordedAt: clearRecordedAt ? null : recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: clearUserId ? null : userId ?? this.userId,
      remoteId: clearRemoteId ? null : remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'localId': localId,
      'title': title,
      'durationSeconds': durationSeconds,
      'statusKey': status.key,
      'recordedAt': recordedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'remoteId': remoteId,
      'syncStatus': syncStatus.key,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncError': syncError,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

@immutable
class TranscriptChunk {
  const TranscriptChunk({
    required this.id,
    required this.transcriptId,
    required this.chunkIndex,
    required this.text,
    required this.audioPath,
    required this.recordedAt,
    required this.startTime,
    required this.endTime,
    required this.confidence,
    required this.transcriptionError,
    this.remoteId,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.syncError,
    this.deletedAt,
  });

  factory TranscriptChunk.fromJson(Map<String, Object?> json) {
    return TranscriptChunk(
      id: _readString(json['id']) ?? '',
      transcriptId:
          _readString(json['transcriptId'] ?? json['transcript_id']) ?? '',
      chunkIndex: _readInt(json['chunkIndex'] ?? json['chunk_index']),
      text: _readString(json['text']) ?? '',
      audioPath: _readString(json['audioPath'] ?? json['audio_path']),
      recordedAt: _readDate(json['recordedAt'] ?? json['recorded_at']),
      startTime: _readDouble(json['startTime'] ?? json['start_time']),
      endTime: _readDouble(json['endTime'] ?? json['end_time']),
      confidence: _readNullableDouble(json['confidence']),
      transcriptionError: _readString(
        json['transcriptionError'] ?? json['transcription_error'],
      ),
      remoteId: _readString(json['remoteId'] ?? json['remote_id']),
      syncStatus: SyncStatus.fromKey(
        _readString(json['syncStatus'] ?? json['sync_status']),
      ),
      lastSyncedAt: _readDate(json['lastSyncedAt'] ?? json['last_synced_at']),
      syncError: _readString(json['syncError'] ?? json['sync_error']),
      deletedAt: _readDate(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  final String id;
  final String transcriptId;
  final int chunkIndex;
  final String text;
  final String? audioPath;
  final DateTime? recordedAt;
  final double startTime;
  final double endTime;
  final double? confidence;
  final String? transcriptionError;
  final String? remoteId;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final DateTime? deletedAt;

  TranscriptChunk copyWith({
    String? id,
    String? transcriptId,
    int? chunkIndex,
    String? text,
    String? audioPath,
    bool clearAudioPath = false,
    DateTime? recordedAt,
    bool clearRecordedAt = false,
    double? startTime,
    double? endTime,
    double? confidence,
    bool clearConfidence = false,
    String? transcriptionError,
    bool clearTranscriptionError = false,
    String? remoteId,
    bool clearRemoteId = false,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? syncError,
    bool clearSyncError = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return TranscriptChunk(
      id: id ?? this.id,
      transcriptId: transcriptId ?? this.transcriptId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      text: text ?? this.text,
      audioPath: clearAudioPath ? null : audioPath ?? this.audioPath,
      recordedAt: clearRecordedAt ? null : recordedAt ?? this.recordedAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      confidence: clearConfidence ? null : confidence ?? this.confidence,
      transcriptionError: clearTranscriptionError
          ? null
          : transcriptionError ?? this.transcriptionError,
      remoteId: clearRemoteId ? null : remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'transcriptId': transcriptId,
      'chunkIndex': chunkIndex,
      'text': text,
      'audioPath': audioPath,
      'recordedAt': recordedAt?.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'confidence': confidence,
      'transcriptionError': transcriptionError,
      'remoteId': remoteId,
      'syncStatus': syncStatus.key,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncError': syncError,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

@immutable
class Summary {
  const Summary({
    required this.id,
    required this.transcriptId,
    required this.providerKey,
    required this.model,
    required this.summaryText,
    required this.tokenCount,
    required this.processingTimeMs,
    required this.createdAt,
    this.remoteId,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.syncError,
    this.deletedAt,
  });

  factory Summary.fromJson(Map<String, Object?> json) {
    final createdAt =
        _readDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now();
    return Summary(
      id:
          _readString(json['id']) ??
          'summary-${createdAt.millisecondsSinceEpoch}',
      transcriptId:
          _readString(json['transcriptId'] ?? json['transcript_id']) ?? '',
      providerKey:
          _readString(json['providerKey'] ?? json['provider_key']) ?? 'local',
      model: _readString(json['model']) ?? 'local-default',
      summaryText:
          _readString(json['summaryText'] ?? json['summary_text']) ?? '',
      tokenCount: _readNullableInt(json['tokenCount'] ?? json['token_count']),
      processingTimeMs: _readNullableInt(
        json['processingTimeMs'] ?? json['processing_time_ms'],
      ),
      createdAt: createdAt,
      remoteId: _readString(json['remoteId'] ?? json['remote_id']),
      syncStatus: SyncStatus.fromKey(
        _readString(json['syncStatus'] ?? json['sync_status']),
      ),
      lastSyncedAt: _readDate(json['lastSyncedAt'] ?? json['last_synced_at']),
      syncError: _readString(json['syncError'] ?? json['sync_error']),
      deletedAt: _readDate(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  final String id;
  final String transcriptId;
  final String providerKey;
  final String model;
  final String summaryText;
  final int? tokenCount;
  final int? processingTimeMs;
  final DateTime createdAt;
  final String? remoteId;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final DateTime? deletedAt;

  Summary copyWith({
    String? id,
    String? transcriptId,
    String? providerKey,
    String? model,
    String? summaryText,
    int? tokenCount,
    bool clearTokenCount = false,
    int? processingTimeMs,
    bool clearProcessingTimeMs = false,
    DateTime? createdAt,
    String? remoteId,
    bool clearRemoteId = false,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? syncError,
    bool clearSyncError = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Summary(
      id: id ?? this.id,
      transcriptId: transcriptId ?? this.transcriptId,
      providerKey: providerKey ?? this.providerKey,
      model: model ?? this.model,
      summaryText: summaryText ?? this.summaryText,
      tokenCount: clearTokenCount ? null : tokenCount ?? this.tokenCount,
      processingTimeMs: clearProcessingTimeMs
          ? null
          : processingTimeMs ?? this.processingTimeMs,
      createdAt: createdAt ?? this.createdAt,
      remoteId: clearRemoteId ? null : remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'transcriptId': transcriptId,
      'providerKey': providerKey,
      'model': model,
      'summaryText': summaryText,
      'tokenCount': tokenCount,
      'processingTimeMs': processingTimeMs,
      'createdAt': createdAt.toIso8601String(),
      'remoteId': remoteId,
      'syncStatus': syncStatus.key,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncError': syncError,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

@immutable
@immutable
class ProcessingJob {
  const ProcessingJob({
    required this.id,
    required this.transcriptId,
    required this.type,
    required this.status,
    required this.lastProcessedChunkIndex,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.error,
    this.remoteId,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.syncError,
    this.deletedAt,
  });

  factory ProcessingJob.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    return ProcessingJob(
      id: _readString(json['id']) ?? 'job-${now.millisecondsSinceEpoch}',
      transcriptId:
          _readString(json['transcriptId'] ?? json['transcript_id']) ?? '',
      type: ProcessingJobType.fromKey(_readString(json['type'])),
      status: ProcessingJobStatus.fromKey(_readString(json['status'])),
      lastProcessedChunkIndex: _readInt(
        json['lastProcessedChunkIndex'] ?? json['last_processed_chunk_index'],
      ),
      retryCount: _readInt(json['retryCount'] ?? json['retry_count']),
      error: _readString(json['error']),
      createdAt: _readDate(json['createdAt'] ?? json['created_at']) ?? now,
      updatedAt: _readDate(json['updatedAt'] ?? json['updated_at']) ?? now,
      remoteId: _readString(json['remoteId'] ?? json['remote_id']),
      syncStatus: SyncStatus.fromKey(
        _readString(json['syncStatus'] ?? json['sync_status']),
      ),
      lastSyncedAt: _readDate(json['lastSyncedAt'] ?? json['last_synced_at']),
      syncError: _readString(json['syncError'] ?? json['sync_error']),
      deletedAt: _readDate(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  final String id;
  final String transcriptId;
  final ProcessingJobType type;
  final ProcessingJobStatus status;
  final int lastProcessedChunkIndex;
  final int retryCount;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final DateTime? deletedAt;

  ProcessingJob copyWith({
    String? id,
    String? transcriptId,
    ProcessingJobType? type,
    ProcessingJobStatus? status,
    int? lastProcessedChunkIndex,
    int? retryCount,
    String? error,
    bool clearError = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remoteId,
    bool clearRemoteId = false,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? syncError,
    bool clearSyncError = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ProcessingJob(
      id: id ?? this.id,
      transcriptId: transcriptId ?? this.transcriptId,
      type: type ?? this.type,
      status: status ?? this.status,
      lastProcessedChunkIndex:
          lastProcessedChunkIndex ?? this.lastProcessedChunkIndex,
      retryCount: retryCount ?? this.retryCount,
      error: clearError ? null : error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: clearRemoteId ? null : remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'transcriptId': transcriptId,
      'type': type.key,
      'status': status.key,
      'lastProcessedChunkIndex': lastProcessedChunkIndex,
      'retryCount': retryCount,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'remoteId': remoteId,
      'syncStatus': syncStatus.key,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncError': syncError,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

@immutable
class PersistedTranscriptState {
  const PersistedTranscriptState({
    required this.transcripts,
    required this.currentTranscript,
    required this.currentChunks,
    required this.allChunks,
    required this.summaries,
    required this.processingJobs,
    required this.summaryProvider,
    required this.summaryLength,
    required this.themeMode,
  });

  factory PersistedTranscriptState.fromJson(Map<String, Object?> json) {
    return PersistedTranscriptState(
      transcripts: _readList(
        json['transcripts'],
      ).map(Transcript.fromJson).toList(),
      currentTranscript: json['currentTranscript'] is Map<String, Object?>
          ? Transcript.fromJson(
              json['currentTranscript']! as Map<String, Object?>,
            )
          : null,
      currentChunks: _readList(
        json['currentChunks'],
      ).map(TranscriptChunk.fromJson).toList(),
      allChunks: _readList(
        json['allChunks'],
      ).map(TranscriptChunk.fromJson).toList(),
      summaries: _readList(json['summaries']).map(Summary.fromJson).toList(),
      processingJobs: _readList(
        json['processingJobs'],
      ).map(ProcessingJob.fromJson).toList(),
      summaryProvider: _readString(json['summaryProvider']) ?? 'local',
      summaryLength: _readString(json['summaryLength']) ?? 'medium',
      themeMode: _readThemeMode(json['themeMode']),
    );
  }

  factory PersistedTranscriptState.empty() {
    return const PersistedTranscriptState(
      transcripts: [],
      currentTranscript: null,
      currentChunks: [],
      allChunks: [],
      summaries: [],
      processingJobs: [],
      summaryProvider: 'local',
      summaryLength: 'medium',
      themeMode: 'system',
    );
  }

  final List<Transcript> transcripts;
  final Transcript? currentTranscript;
  final List<TranscriptChunk> currentChunks;
  final List<TranscriptChunk> allChunks;
  final List<Summary> summaries;
  final List<ProcessingJob> processingJobs;
  final String summaryProvider;
  final String summaryLength;
  final String themeMode;

  Map<String, Object?> toJson() {
    return {
      'transcripts': transcripts.map((item) => item.toJson()).toList(),
      'currentTranscript': currentTranscript?.toJson(),
      'currentChunks': currentChunks.map((item) => item.toJson()).toList(),
      'allChunks': allChunks.map((item) => item.toJson()).toList(),
      'summaries': summaries.map((item) => item.toJson()).toList(),
      'processingJobs': processingJobs.map((item) => item.toJson()).toList(),
      'summaryProvider': summaryProvider,
      'summaryLength': summaryLength,
      'themeMode': themeMode,
    };
  }
}

String _readThemeMode(Object? value) {
  return switch (_readString(value)) {
    'light' => 'light',
    'dark' => 'dark',
    _ => 'system',
  };
}

String? _readString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Object? value) {
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

double _readDouble(Object? value) {
  return _readNullableDouble(value) ?? 0;
}

double? _readNullableDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _readDate(Object? value) {
  final text = _readString(value);
  if (text == null) {
    return null;
  }
  return DateTime.tryParse(text);
}

List<Map<String, Object?>> _readList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<dynamic, dynamic>>()
      .map(
        (item) => item.map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      )
      .toList();
}
