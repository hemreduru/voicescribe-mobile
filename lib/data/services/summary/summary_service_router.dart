import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

/// Dispatches summary generation to the local on-device engine or the cloud
/// backend based on the user's `summaryProvider` preference ('local'/'cloud').
///
/// Keeping the routing here means `GenerateSummaryUseCase` and the detail bloc
/// stay unaware of which engine runs — they already pass the chosen provider.
class SummaryServiceRouter implements SummaryService {
  const SummaryServiceRouter({
    required SummaryService local,
    required SummaryService cloud,
  }) : _local = local,
       _cloud = cloud;

  final SummaryService _local;
  final SummaryService _cloud;

  @override
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
    required String length,
  }) {
    final engine = AppPreferences.normalizeSummaryProvider(provider) == 'cloud'
        ? _cloud
        : _local;
    return engine.generate(
      transcript: transcript,
      transcriptText: transcriptText,
      provider: provider,
      length: length,
    );
  }
}
