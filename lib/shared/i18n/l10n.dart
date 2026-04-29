import 'package:flutter/widgets.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizedStatusLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'recording':
      return l10n.statusRecording;
    case 'transcribing':
      return l10n.statusTranscribing;
    case 'transcription_completed':
      return l10n.statusTranscriptionCompleted;
    case 'speaker_analysis_pending':
      return l10n.statusSpeakerAnalysisPending;
    case 'speaker_analysis_running':
      return l10n.statusSpeakerAnalysisRunning;
    case 'speaker_analysis_completed':
      return l10n.statusSpeakerAnalysisCompleted;
    case 'completed':
      return l10n.statusCompleted;
    case 'transcription_error':
      return l10n.statusTranscriptionError;
    default:
      return l10n.statusEmpty;
  }
}
