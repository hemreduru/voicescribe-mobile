import 'package:uuid/uuid.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/domain/models/app_error.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/utils/locale_utils.dart';

/// Thrown when a cloud summary cannot be produced (offline, not synced, auth, or
/// a backend error). The UI localizes [code]; [message] is for logs.
class CloudSummaryException implements Exception, SummaryFailure {
  const CloudSummaryException(
    this.message, {
    this.code = AppErrorCode.summaryServerError,
  });

  @override
  final String message;

  @override
  final AppErrorCode code;

  @override
  String toString() => 'CloudSummaryException: $message';
}

/// Generates a summary by asking the backend to run the configured remote LLM
/// (Gemini free tier by default) and returns its structured JSON result.
///
/// The backend decides which provider "cloud" maps to (config-driven), so this
/// client stays provider-agnostic and always tags the result `providerKey: 'cloud'`.
class CloudSummaryService implements SummaryService {
  CloudSummaryService({
    required TranscriptApiClient apiClient,
    required String? Function() tokenProvider,
    Uuid uuid = const Uuid(),
  }) : _apiClient = apiClient,
       _tokenProvider = tokenProvider,
       _uuid = uuid;

  final TranscriptApiClient _apiClient;
  final String? Function() _tokenProvider;
  final Uuid _uuid;

  @override
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    // The cloud backend chunks long transcripts itself, so there is no
    // client-side multi-step progress to report.
    SummaryProgressCallback? onProgress,
  }) async {
    final remoteId = transcript.remoteId;
    if (remoteId == null || remoteId.trim().isEmpty) {
      throw const CloudSummaryException(
        'Transcript has not been synced to the server yet.',
        code: AppErrorCode.summaryNotSynced,
      );
    }

    final token = _tokenProvider()?.trim();
    if (token == null || token.isEmpty) {
      throw const CloudSummaryException(
        'Cloud summary requires an authenticated session.',
        code: AppErrorCode.summaryAuthRequired,
      );
    }

    // Pre-allocate the local row id and send it so a later sync push updates the
    // same backend row instead of creating a duplicate.
    final localId = _uuid.v4();

    final response = await _apiClient.request(
      method: 'POST',
      path: '/api/v1/transcripts/$remoteId/summaries',
      payload: <String, Object?>{
        'transcript_text': transcriptText,
        // Fixed format; the UI no longer offers a length choice. The backend
        // contract still expects this field (see kFixedSummaryLength).
        'length': kFixedSummaryLength,
        'client_local_id': localId,
        // Phone language → summary is written in this language regardless of the
        // transcript's language.
        'locale': deviceLanguageCode(),
        // `provider` intentionally omitted → backend uses its configured default.
      },
      token: token,
      readTimeout: const Duration(seconds: 60),
    );

    if (!response.isSuccess) {
      if (response.isNetworkFailure) {
        throw const CloudSummaryException(
          'No connection to the summary backend.',
          code: AppErrorCode.summaryOffline,
        );
      }
      throw CloudSummaryException(
        'Summary backend error: HTTP ${response.statusCode} '
        '${response.message ?? ''}',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw const CloudSummaryException(
        'Invalid summary response payload.',
        code: AppErrorCode.summaryInvalidResponse,
      );
    }
    final map = data.map((key, value) => MapEntry(key.toString(), value));

    final summaryText = (map['summary_text'] ?? '').toString();
    if (summaryText.trim().isEmpty) {
      throw const CloudSummaryException(
        'Server returned an empty summary.',
        code: AppErrorCode.summaryEmptyResponse,
      );
    }

    return Summary(
      id: localId,
      transcriptId: transcript.id,
      providerKey: 'cloud',
      model: (map['model'] ?? 'cloud-default').toString(),
      summaryText: summaryText,
      tokenCount: _toInt(map['token_count']),
      processingTimeMs: _toInt(map['processing_time_ms']),
      createdAt: DateTime.now(),
      remoteId: map['remote_id']?.toString(),
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
