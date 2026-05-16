import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

class GenerateSummaryUseCase {
  const GenerateSummaryUseCase({
    required TranscriptRepository repository,
    required SummaryService summaryService,
  }) : _repository = repository,
       _summaryService = summaryService;

  final TranscriptRepository _repository;
  final SummaryService _summaryService;

  Future<Summary?> execute({
    required Transcript transcript,
    required String transcriptText,
    required AppPreferences preferences,
  }) async {
    if (transcriptText.trim().isEmpty) {
      return null;
    }
    final summary = await _summaryService.generate(
      transcript: transcript,
      transcriptText: transcriptText,
      provider: preferences.summaryProvider,
      length: preferences.summaryLength,
    );
    final pending = summary.copyWith(syncStatus: SyncStatus.pending);
    await _repository.saveSummary(pending);
    return pending;
  }
}
