import 'package:flutter/foundation.dart';

enum TranscriptStatus {
  recording('recording'),
  transcribing('transcribing'),
  completed('completed'),
  transcriptionError('transcription_error'),
  empty('empty');

  const TranscriptStatus(this.key);

  final String key;

  static TranscriptStatus fromKey(String? key) {
    return TranscriptStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => TranscriptStatus.empty,
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
  });

  factory Transcript.fromJson(Map<String, Object?> json) {
    final createdAt = _readDate(json['createdAt']) ?? DateTime.now();
    return Transcript(
      id:
          _readString(json['id']) ??
          'local-${createdAt.millisecondsSinceEpoch}',
      localId: _readString(json['localId']) ?? _readString(json['id']) ?? '',
      title: _readString(json['title']),
      durationSeconds: _readInt(json['durationSeconds']),
      status: TranscriptStatus.fromKey(_readString(json['statusKey'])),
      recordedAt: _readDate(json['recordedAt']),
      createdAt: createdAt,
      updatedAt: _readDate(json['updatedAt']) ?? createdAt,
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
    required this.speakerLabel,
    required this.confidence,
    required this.transcriptionError,
  });

  factory TranscriptChunk.fromJson(Map<String, Object?> json) {
    return TranscriptChunk(
      id: _readString(json['id']) ?? '',
      transcriptId: _readString(json['transcriptId']) ?? '',
      chunkIndex: _readInt(json['chunkIndex']),
      text: _readString(json['text']) ?? '',
      audioPath: _readString(json['audioPath']),
      recordedAt: _readDate(json['recordedAt']),
      startTime: _readDouble(json['startTime']),
      endTime: _readDouble(json['endTime']),
      speakerLabel: _readString(json['speakerLabel']),
      confidence: _readNullableDouble(json['confidence']),
      transcriptionError: _readString(json['transcriptionError']),
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
  final String? speakerLabel;
  final double? confidence;
  final String? transcriptionError;

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
    String? speakerLabel,
    bool clearSpeakerLabel = false,
    double? confidence,
    bool clearConfidence = false,
    String? transcriptionError,
    bool clearTranscriptionError = false,
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
      speakerLabel: clearSpeakerLabel
          ? null
          : speakerLabel ?? this.speakerLabel,
      confidence: clearConfidence ? null : confidence ?? this.confidence,
      transcriptionError: clearTranscriptionError
          ? null
          : transcriptionError ?? this.transcriptionError,
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
      'speakerLabel': speakerLabel,
      'confidence': confidence,
      'transcriptionError': transcriptionError,
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
  });

  factory Summary.fromJson(Map<String, Object?> json) {
    final createdAt = _readDate(json['createdAt']) ?? DateTime.now();
    return Summary(
      id:
          _readString(json['id']) ??
          'summary-${createdAt.millisecondsSinceEpoch}',
      transcriptId: _readString(json['transcriptId']) ?? '',
      providerKey: _readString(json['providerKey']) ?? 'local',
      model: _readString(json['model']) ?? 'local-default',
      summaryText: _readString(json['summaryText']) ?? '',
      tokenCount: _readNullableInt(json['tokenCount']),
      processingTimeMs: _readNullableInt(json['processingTimeMs']),
      createdAt: createdAt,
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
    };
  }
}

@immutable
class SpeakerProfile {
  const SpeakerProfile({
    required this.id,
    required this.name,
    required this.embedding,
    required this.createdAt,
    this.recordings = 0,
    this.hasVoiceSample = false,
  });

  factory SpeakerProfile.fromJson(Map<String, Object?> json) {
    final createdAt = _readDate(json['createdAt']) ?? DateTime.now();
    final embedding = json['embedding'] is List<Object?>
        ? (json['embedding']! as List<Object?>).map(_readDouble).toList()
        : const <double>[];
    return SpeakerProfile(
      id:
          _readString(json['id']) ??
          'speaker-${createdAt.millisecondsSinceEpoch}',
      name: _readString(json['name']) ?? 'Speaker',
      embedding: embedding,
      createdAt: createdAt,
      recordings: _readInt(json['recordings']),
      hasVoiceSample: _readBool(json['hasVoiceSample']),
    );
  }

  final String id;
  final String name;
  final List<double> embedding;
  final DateTime createdAt;
  final int recordings;
  final bool hasVoiceSample;

  SpeakerProfile copyWith({
    String? id,
    String? name,
    List<double>? embedding,
    DateTime? createdAt,
    int? recordings,
    bool? hasVoiceSample,
  }) {
    return SpeakerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
      recordings: recordings ?? this.recordings,
      hasVoiceSample: hasVoiceSample ?? this.hasVoiceSample,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'embedding': embedding,
      'createdAt': createdAt.toIso8601String(),
      'recordings': recordings,
      'hasVoiceSample': hasVoiceSample,
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
    required this.speakers,
    required this.summaries,
    required this.summaryProvider,
    required this.summaryLength,
    required this.speakerRecognitionEnabled,
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
      speakers: _readList(
        json['speakers'],
      ).map(SpeakerProfile.fromJson).toList(),
      summaries: _readList(json['summaries']).map(Summary.fromJson).toList(),
      summaryProvider: _readString(json['summaryProvider']) ?? 'local',
      summaryLength: _readString(json['summaryLength']) ?? 'medium',
      speakerRecognitionEnabled: _readBool(
        json['speakerRecognitionEnabled'],
        defaultValue: true,
      ),
    );
  }

  factory PersistedTranscriptState.empty() {
    return const PersistedTranscriptState(
      transcripts: [],
      currentTranscript: null,
      currentChunks: [],
      allChunks: [],
      speakers: [],
      summaries: [],
      summaryProvider: 'local',
      summaryLength: 'medium',
      speakerRecognitionEnabled: true,
    );
  }

  final List<Transcript> transcripts;
  final Transcript? currentTranscript;
  final List<TranscriptChunk> currentChunks;
  final List<TranscriptChunk> allChunks;
  final List<SpeakerProfile> speakers;
  final List<Summary> summaries;
  final String summaryProvider;
  final String summaryLength;
  final bool speakerRecognitionEnabled;

  Map<String, Object?> toJson() {
    return {
      'transcripts': transcripts.map((item) => item.toJson()).toList(),
      'currentTranscript': currentTranscript?.toJson(),
      'currentChunks': currentChunks.map((item) => item.toJson()).toList(),
      'allChunks': allChunks.map((item) => item.toJson()).toList(),
      'speakers': speakers.map((item) => item.toJson()).toList(),
      'summaries': summaries.map((item) => item.toJson()).toList(),
      'summaryProvider': summaryProvider,
      'summaryLength': summaryLength,
      'speakerRecognitionEnabled': speakerRecognitionEnabled,
    };
  }
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

bool _readBool(Object? value, {bool defaultValue = false}) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().toLowerCase();
  if (text == null) {
    return defaultValue;
  }
  if (text == 'true' || text == '1') {
    return true;
  }
  if (text == 'false' || text == '0') {
    return false;
  }
  return defaultValue;
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
