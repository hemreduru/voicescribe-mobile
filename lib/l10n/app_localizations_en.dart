// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'VoiceScribe';

  @override
  String get recording => 'Recording';

  @override
  String get transcript => 'Transcript';

  @override
  String get summary => 'Summary';

  @override
  String get history => 'History';

  @override
  String get speaker => 'Speaker';

  @override
  String get bootstrapTitle => 'Preparing VoiceScribe';

  @override
  String get bootstrapMessage => 'Loading on-device Whisper model...';

  @override
  String get bootstrapFailed => 'Model setup failed.';

  @override
  String get retrySetup => 'Retry';

  @override
  String get downloadingModel => 'Downloading model';

  @override
  String get modelReady => 'AI Ready';

  @override
  String get modelLoading => 'Loading model...';

  @override
  String get tapToRecord => 'Tap the button to start recording';

  @override
  String get isRecording => 'Recording';

  @override
  String get recordingPaused => 'Recording paused';

  @override
  String get liveTranscript => 'Live Transcript';

  @override
  String get recordingStatus => 'Session Status';

  @override
  String get sessionNamePlaceholder => 'Enter session title...';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get stop => 'Stop';

  @override
  String get recentRecordings => 'Recent Recordings';

  @override
  String get noRecordings => 'No recordings yet';

  @override
  String get searchRecordings => 'Search recordings...';

  @override
  String get noTranscriptAvailable => 'Transcript is not available.';

  @override
  String get noMatchingText => 'No matching text found.';

  @override
  String get copy => 'Copy';

  @override
  String get export => 'Export';

  @override
  String get edit => 'Edit';

  @override
  String get local => 'Local';

  @override
  String get cloud => 'Cloud';

  @override
  String get short => 'Short';

  @override
  String get medium => 'Medium';

  @override
  String get long => 'Long';

  @override
  String get settings => 'Settings';

  @override
  String get summarySettings => 'Summary Settings';

  @override
  String get latestTranscript => 'Latest Transcript';

  @override
  String get readyToSummarize => 'Ready to summarize';

  @override
  String get generateSummary => 'Generate Summary';

  @override
  String get summaryPlaceholder =>
      'Summary engine is ready in this Flutter baseline. Connect a local LLM or cloud provider to produce summaries here.';

  @override
  String get noSummaryYet => 'No summary generated yet.';

  @override
  String get chunks => 'Chunks';

  @override
  String get duration => 'Duration';

  @override
  String get selected => 'Selected';

  @override
  String get speakerRecognition => 'Speaker Recognition';

  @override
  String get speakerRecognitionDesc =>
      'Automatically identify and label speakers in recordings.';

  @override
  String get addNewSpeaker => 'Add Speaker';

  @override
  String get registeredSpeakers => 'Registered Speakers';

  @override
  String get recordVoiceSample => 'Record voice sample';

  @override
  String get voiceSampleAvailable => 'Voice sample available';

  @override
  String get unnamed => 'Untitled';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get permissionDenied => 'Microphone permission is required.';

  @override
  String get statusRecording => 'Recording';

  @override
  String get statusTranscribing => 'Transcribing';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusTranscriptionError => 'Error';

  @override
  String get statusEmpty => 'Empty';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get longest => 'Longest';

  @override
  String get localBadge => 'Local';

  @override
  String get transcriptBadge => 'Transcript';

  @override
  String get active => 'Active';

  @override
  String get disabled => 'Disabled';

  @override
  String get speakerNameLabel => 'Speaker name';

  @override
  String get ready => 'Ready';

  @override
  String get pending => 'Pending';

  @override
  String get profileReadyForRecognition => 'Ready for profile recognition';

  @override
  String get addSampleLater => 'Voice sample can be added later';

  @override
  String summaryGeneratedAt(Object time) {
    return 'Generated $time';
  }
}
