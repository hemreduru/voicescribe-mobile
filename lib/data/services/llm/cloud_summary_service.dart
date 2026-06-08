import 'package:uuid/uuid.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/utils/locale_utils.dart';

/// Thrown when a cloud summary cannot be produced (offline, not synced, auth, or
/// a backend error). The UI surfaces [message] to the user.
class CloudSummaryException implements Exception, SummaryFailure {
  const CloudSummaryException(this.message);

  @override
  final String message;

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
  }) async {
    final remoteId = transcript.remoteId;
    if (remoteId == null || remoteId.trim().isEmpty) {
      throw const CloudSummaryException(
        'Bu kayıt henüz eşitlenmedi. İnternete bağlanıp eşitledikten sonra '
        'bulut özetini tekrar deneyin.',
      );
    }

    final token = _tokenProvider()?.trim();
    if (token == null || token.isEmpty) {
      throw const CloudSummaryException(
        'Bulut özeti için giriş yapmış olmanız gerekiyor.',
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
          'Bağlantı yok. Yerel özete geçin veya çevrimiçi olunca tekrar deneyin.',
        );
      }
      throw const CloudSummaryException(
        'Özet şu an oluşturulamadı. Lütfen biraz sonra tekrar deneyin.',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw const CloudSummaryException('Sunucudan geçersiz yanıt alındı.');
    }
    final map = data.map((key, value) => MapEntry(key.toString(), value));

    final summaryText = (map['summary_text'] ?? '').toString();
    if (summaryText.trim().isEmpty) {
      throw const CloudSummaryException('Sunucu boş bir özet döndürdü.');
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
