import 'package:voicescribe_mobile/domain/models/app_error.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';

/// Marker for summary errors the UI can surface safely (no class names or
/// stack traces). [code] is mapped to the active locale by the UI; [message]
/// is the log-friendly description.
abstract interface class SummaryFailure {
  String get message;
  AppErrorCode get code;
}

/// Single, fixed summary format sent to the backend. The app no longer exposes a
/// short/medium/long choice; "medium" maps to a rich-but-not-bloated summary
/// (short exec summary + all decisions + all action items + open questions). The
/// backend still expects a `length` field, so this constant preserves that
/// contract while keeping the choice out of the UI.
const String kFixedSummaryLength = 'medium';

// Kept as an interface so app state can inject the cloud summary engine.
// ignore: one_member_abstracts
abstract class SummaryService {
  Future<Summary> generate({
    required Transcript transcript,
    required String transcriptText,
    required String provider,
  });
}
