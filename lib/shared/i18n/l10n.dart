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
    case 'completed':
      return l10n.statusCompleted;
    case 'transcription_error':
      return l10n.statusTranscriptionError;
    default:
      return l10n.statusEmpty;
  }
}
