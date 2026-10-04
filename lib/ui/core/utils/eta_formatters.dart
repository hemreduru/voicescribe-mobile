import 'package:voicescribe_mobile/l10n/app_localizations.dart';

/// Humanizes a remaining-time estimate into a localized, rounded phrase like
/// "1 minute" / "30 seconds" — paired with the `etaRemaining` frame to read
/// "~1 minute left". Rounds sub-minute values to the nearest 5s so the label
/// doesn't jitter every second.
String humanizeEtaUnit(AppLocalizations l10n, Duration remaining) {
  final seconds = remaining.inSeconds;
  if (seconds < 60) {
    final rounded = (seconds / 5).round() * 5;
    return l10n.etaUnitSeconds(rounded < 5 ? 5 : rounded);
  }
  if (seconds < 3600) {
    return l10n.etaUnitMinutes((seconds / 60).round());
  }
  return l10n.etaUnitHours((seconds / 3600).round());
}
