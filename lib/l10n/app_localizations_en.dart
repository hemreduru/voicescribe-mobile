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
  String get account => 'Account';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get systemStatus => 'System Status';

  @override
  String get summaryProvider => 'Summary Provider';

  @override
  String get summaryLength => 'Summary Length';

  @override
  String get summaryPreferences =>
      'Manage where summaries run and how much detail they include.';

  @override
  String get preferences => 'More Settings';

  @override
  String get billingPlans => 'Billing & Plans';

  @override
  String get notifications => 'Notifications';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get userId => 'User ID';

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
  String get statusTranscriptionCompleted => 'Transcription done';

  @override
  String get statusSpeakerAnalysisPending => 'Speaker analysis pending';

  @override
  String get statusSpeakerAnalysisRunning => 'Speaker analysis running';

  @override
  String get statusSpeakerAnalysisCompleted => 'Completed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusTranscriptionError => 'Error';

  @override
  String get statusEmpty => 'Empty';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusIssue => 'Needs attention';

  @override
  String get all => 'All';

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

  @override
  String get authTitle => 'Authentication';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Password';

  @override
  String get authenticatedUser => 'Authenticated User';

  @override
  String get authVerifyEmail =>
      'Registration completed. Verify your email address, then log in.';

  @override
  String get modelSetupRequired => 'Model setup required';

  @override
  String get modelSetupContinueMessage =>
      'Model must be downloaded before continuing.';

  @override
  String get modelDownloadFailed => 'Model download failed. Please try again.';

  @override
  String get modelDownloading => 'Downloading model...';

  @override
  String modelDownloadingPercent(Object percent) {
    return 'Downloading model $percent%';
  }

  @override
  String get calibrate => 'Calibrate';

  @override
  String speakerThreshold(Object value) {
    return 'Threshold: $value';
  }

  @override
  String profilesCount(Object count) {
    return '$count profiles';
  }

  @override
  String recordingsCount(Object count) {
    return '$count recordings';
  }

  @override
  String get deleteRecordingsTitle => 'Delete recordings?';

  @override
  String deleteRecordingsMessage(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings will be deleted safely.',
      one: 'This recording will be deleted safely.',
    );
    return '$_temp0';
  }

  @override
  String chunksCount(Object count) {
    return '$count chunks';
  }

  @override
  String get calibrationSkipped =>
      'Calibration skipped: not enough labeled audio chunks.';

  @override
  String calibrationCompleted(Object threshold) {
    return 'Calibration completed: $threshold';
  }

  @override
  String calibrationFailed(Object error) {
    return 'Calibration failed: $error';
  }

  @override
  String get speakerFallback => 'Speaker';
}
