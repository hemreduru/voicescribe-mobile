import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain.freezed.dart';

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
    return TranscriptStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => TranscriptStatus.empty,
    );
  }

  /// Aggregates a transcript status from its chunks. Used by both the live
  /// recording flow and stale-recording repair on app start so the two paths
  /// never drift apart.
  static TranscriptStatus deriveFromChunks(List<TranscriptChunk> chunks) {
    if (chunks.isEmpty) {
      return TranscriptStatus.empty;
    }
    final hasPending = chunks.any(
      (chunk) => !chunk.isTranscribed && chunk.transcriptionError == null,
    );
    if (hasPending) {
      return TranscriptStatus.transcribing;
    }
    final hasError = chunks.any(
      (chunk) => (chunk.transcriptionError ?? '').isNotEmpty,
    );
    if (hasError) {
      return TranscriptStatus.transcriptionError;
    }
    return TranscriptStatus.completed;
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

@freezed
abstract class AuthSessionState with _$AuthSessionState {
  const factory AuthSessionState({
    required String userId,
    required String email,
    required String accessToken,
    required String? refreshToken,
    required DateTime? expiresAt,
  }) = _AuthSessionState;

  const AuthSessionState._();

  bool get isAuthenticated => userId.isNotEmpty && accessToken.isNotEmpty;
}

@freezed
abstract class Transcript with _$Transcript {
  const factory Transcript({
    required String id,
    required String localId,
    required String? title,
    required int durationSeconds,
    required TranscriptStatus status,
    required DateTime? recordedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? userId,
    String? remoteId,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    DateTime? lastSyncedAt,
    String? syncError,
    DateTime? deletedAt,
  }) = _Transcript;
}

@freezed
abstract class TranscriptChunk with _$TranscriptChunk {
  const factory TranscriptChunk({
    required String id,
    required String transcriptId,
    required int chunkIndex,
    required String text,
    required String? audioPath,
    required DateTime? recordedAt,
    required double startTime,
    required double endTime,
    required double? confidence,
    required String? transcriptionError,
    double? audioLevel,
    String? remoteId,
    @Default(false) bool isTranscribed,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    DateTime? lastSyncedAt,
    String? syncError,
    DateTime? deletedAt,
  }) = _TranscriptChunk;
}

@freezed
abstract class Summary with _$Summary {
  const factory Summary({
    required String id,
    required String transcriptId,
    required String providerKey,
    required String model,
    required String summaryText,
    required int? tokenCount,
    required int? processingTimeMs,
    required DateTime createdAt,
    String? remoteId,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    DateTime? lastSyncedAt,
    String? syncError,
    DateTime? deletedAt,
  }) = _Summary;
}

@freezed
abstract class AppPreferences with _$AppPreferences {
  const factory AppPreferences({
    @Default('local') String summaryProvider,
    @Default('medium') String summaryLength,
    @Default('system') String themeMode,
    @Default('system') String localePreference,
    @Default('base') String transcriptionModel,
  }) = _AppPreferences;

  const AppPreferences._();

  static String normalizeSummaryProvider(String value) {
    return switch (value) {
      'cloud' => 'cloud',
      _ => 'local',
    };
  }

  static String normalizeSummaryLength(String value) {
    return switch (value) {
      'short' => 'short',
      'long' => 'long',
      _ => 'medium',
    };
  }

  static String normalizeThemeMode(String value) {
    return switch (value) {
      'light' => 'light',
      'dark' => 'dark',
      _ => 'system',
    };
  }

  static String normalizeLocalePreference(String value) {
    return switch (value) {
      'en' => 'en',
      'tr' => 'tr',
      _ => 'system',
    };
  }

  static String normalizeTranscriptionModel(String value) {
    return switch (value) {
      'tiny' => 'tiny',
      'base' => 'base',
      'small' => 'small',
      'medium' => 'medium',
      'large-v3' => 'large-v3',
      'large-v3-turbo' => 'large-v3-turbo',
      'tiny.en' => 'tiny',
      'base.en' => 'base',
      'small.en' => 'small',
      'medium.en' => 'medium',
      _ => 'base',
    };
  }
}

@freezed
abstract class TranscriptSnapshot with _$TranscriptSnapshot {
  const factory TranscriptSnapshot({
    required List<Transcript> transcripts,
    required List<TranscriptChunk> chunks,
    required List<Summary> summaries,
    @Default(AppPreferences()) AppPreferences preferences,
  }) = _TranscriptSnapshot;

  const TranscriptSnapshot._();

  factory TranscriptSnapshot.empty() {
    return const TranscriptSnapshot(transcripts: [], chunks: [], summaries: []);
  }

  List<TranscriptChunk> chunksFor(String transcriptId) {
    final items =
        chunks.where((chunk) => chunk.transcriptId == transcriptId).toList()
          ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    return List.unmodifiable(items);
  }

  Summary? latestSummaryFor(String transcriptId) {
    final items =
        summaries.where((item) => item.transcriptId == transcriptId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.isEmpty ? null : items.first;
  }
}
