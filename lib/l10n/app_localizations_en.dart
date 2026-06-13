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
  String get ai => 'AI';

  @override
  String get aiTitle => 'AI Assistant';

  @override
  String get aiSubtitle => 'Ask questions about your own recordings';

  @override
  String get chatNewChat => 'New chat';

  @override
  String get chatSources => 'Sources';

  @override
  String get chatThinking => 'Thinking…';

  @override
  String get chatInputHint => 'Ask about your recordings…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatEmptyTitle => 'Chat with your recordings';

  @override
  String get chatEmptyMessage =>
      'Ask anything about your transcripts. Answers cite the recording they came from.';

  @override
  String get chatNoSessionsTitle => 'No conversations yet';

  @override
  String get chatNoSessionsMessage =>
      'Start a new chat to ask questions across all your recordings.';

  @override
  String get chatSelectOrNew => 'Select a conversation or start a new chat.';

  @override
  String get chatDeleteTitle => 'Delete conversation';

  @override
  String get chatDeleteConfirm =>
      'This conversation will be permanently deleted.';

  @override
  String get chatUntitled => 'New chat';

  @override
  String get refreshFailed =>
      'Couldn\'t refresh. Check your connection and try again.';

  @override
  String get summary => 'Summary';

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
  String get settings => 'Settings';

  @override
  String get openSettings => 'Open settings';

  @override
  String get account => 'Account';

  @override
  String get appearance => 'Appearance';

  @override
  String get sync => 'Sync';

  @override
  String get syncSectionSubtitle =>
      'Manually trigger a full push, pull, and cache cleanup.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncInProgress => 'Sync in progress';

  @override
  String get syncIdle => 'Ready to sync';

  @override
  String get lastSyncNever => 'Last sync: Never';

  @override
  String lastSyncAt(Object time) {
    return 'Last sync: $time';
  }

  @override
  String get syncBannerTitle => 'Synced';

  @override
  String get syncBannerSuccess => 'Everything is up to date.';

  @override
  String syncBannerSuccessWithCounts(
    Object pushed,
    Object pulled,
    Object cleaned,
  ) {
    return 'Uploaded $pushed, refreshed $pulled, cleaned $cleaned';
  }

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
  String get aiLocationTitle => 'Where should AI run?';

  @override
  String get aiLocationLabel => 'AI location';

  @override
  String get aiLocationOnDevice => 'On this phone';

  @override
  String get aiLocationCloud => 'In the cloud';

  @override
  String get aiLocationOnDeviceDesc =>
      'Everything runs on your phone — no internet needed and nothing leaves the device. Needs a powerful phone and a one-time ~1 GB model download. Applies to both summaries and AI chat.';

  @override
  String get aiLocationCloudDesc =>
      'More capable, much faster AI that handles long meetings better. Needs internet and sign-in, and the recording is synced first. Applies to both summaries and AI chat.';

  @override
  String get aiLocationOnDeviceUnavailable =>
      'This phone isn\'t powerful enough for on-device AI — use the cloud instead.';

  @override
  String get summaryPreferences => 'Choose where summaries and AI chat run.';

  @override
  String get transcriptionModelSettings => 'Transcription Model';

  @override
  String get transcriptionModelPreferences =>
      'Choose the on-device model used for speech transcription.';

  @override
  String get recommendedForYourDevice => 'Recommended for your device';

  @override
  String deviceProfileLabel(Object tier) {
    return 'Device profile: $tier';
  }

  @override
  String get deviceTierEntry => 'Entry';

  @override
  String get deviceTierBalanced => 'Balanced';

  @override
  String get deviceTierPerformance => 'Performance';

  @override
  String get deviceTierPremium => 'Premium';

  @override
  String modelDownloadRemaining(Object size) {
    return 'Download: $size';
  }

  @override
  String get modelAlreadyDownloaded => 'Already downloaded';

  @override
  String get modelDownloadSizeUnknown => 'Download size unavailable';

  @override
  String get modelCompatibilityRecommended => 'Recommended';

  @override
  String get modelCompatibilitySupported => 'Supported';

  @override
  String get modelCompatibilityLimited => 'Can be slow on this device';

  @override
  String get modelApplyingSelection => 'Applying selected model...';

  @override
  String get modelTinyDescription =>
      'Fastest option for low-end phones and quick drafts.';

  @override
  String get modelBaseDescription =>
      'Balanced default for everyday transcription.';

  @override
  String get modelSmallDescription =>
      'Better accuracy with moderate device cost.';

  @override
  String get modelMediumDescription => 'Higher accuracy for stronger phones.';

  @override
  String get modelLargeV3Description =>
      'Best overall accuracy, but heavy on memory and battery.';

  @override
  String get modelLargeV3TurboDescription =>
      'Large-class accuracy with faster throughput.';

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
  String summarizingProgress(Object current, Object total) {
    return 'Summarizing… ($current/$total)';
  }

  @override
  String get summaryPlaceholder =>
      'No summary yet. Tap Generate to create structured meeting minutes from this transcript.';

  @override
  String get noSummaryYet => 'No summary generated yet.';

  @override
  String get summaryUnavailable =>
      'Couldn\'t produce a readable summary this time. Tap Generate to try again, or switch to Cloud in Settings.';

  @override
  String get summaryExecutiveSummary => 'Summary';

  @override
  String get summaryAgenda => 'Agenda';

  @override
  String get summaryDecisions => 'Decisions';

  @override
  String get summaryActionItems => 'Action Items';

  @override
  String get summaryOpenQuestions => 'Open Questions';

  @override
  String get summaryNotes => 'Notes';

  @override
  String get summaryAttendees => 'Attendees';

  @override
  String get summaryAbsentees => 'Absentees';

  @override
  String get summaryRecorder => 'Recorder';

  @override
  String get summaryNextMeeting => 'Next Meeting';

  @override
  String get summaryProviderLocalLabel => 'On-device';

  @override
  String get summaryProviderCloudLabel => 'Cloud';

  @override
  String get summaryUnassigned => 'Unassigned';

  @override
  String get localSummaryModel => 'On-device summary model';

  @override
  String get localSummaryModelDownload => 'Download';

  @override
  String get localSummaryModelReady => 'Downloaded';

  @override
  String get localSummaryModelDownloading => 'Downloading…';

  @override
  String get localSummaryModelUnsupported =>
      'On-device summary needs a more capable device. Use Cloud instead.';

  @override
  String get chunks => 'Chunks';

  @override
  String get duration => 'Duration';

  @override
  String get selected => 'Selected';

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
  String get ready => 'Ready';

  @override
  String get pending => 'Pending';

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
  String transcriptionProgressPercent(Object percent) {
    return '$percent%';
  }

  @override
  String transcriptionProgressChunks(Object completed, Object total) {
    return '$completed of $total';
  }

  @override
  String recommendedModelLabel(Object model) {
    return 'Recommended model: $model';
  }

  @override
  String get usingHeavierModelWarning =>
      'You are using a heavier model than recommended. This may cause slow transcription.';

  @override
  String get modelWarningHeavy => 'Heavier than recommended';

  @override
  String get modelWarningSlow => 'May be very slow';

  @override
  String get retryTranscription => 'Retry';

  @override
  String get transcriptionFailedRetry => 'Transcription failed. Tap to retry.';

  @override
  String get retrying => 'Retrying...';

  @override
  String get statusIconsTitle => 'Status icons';

  @override
  String get transcriptionLanguage => 'Transcription language';

  @override
  String get transcriptionModelSize => 'Model size';

  @override
  String get recordingNotificationContent => 'Recording in progress';

  @override
  String get automatic => 'Automatic';

  @override
  String unsyncedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings not backed up yet',
      one: '1 recording not backed up yet',
    );
    return '$_temp0';
  }

  @override
  String get transcribingNotificationContent => 'Preparing transcript';

  @override
  String etaUnitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String etaUnitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String etaUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String etaRemaining(String time) {
    return '~$time left';
  }

  @override
  String get errAuthRequired => 'Sign in to start recording.';

  @override
  String get errMicPermissionRequired => 'Microphone permission is required.';

  @override
  String get errStorageFull =>
      'Storage is full. Recording was stopped; free up space and try again.';

  @override
  String get errSummaryEmptyTranscript =>
      'There is no transcript text to summarize.';

  @override
  String get errSummaryLocalFailed =>
      'The on-device model could not produce a valid summary this time. Try again or switch to the Cloud summary.';

  @override
  String get errSummaryTimeout =>
      'The summary took longer than expected. Try again or use the Cloud summary.';

  @override
  String get errSummaryNotSynced =>
      'This recording hasn\'t been synced yet. Connect to the internet, sync, then retry the cloud summary.';

  @override
  String get errSummaryAuthRequired =>
      'You need to be signed in for cloud summaries.';

  @override
  String get errSummaryOffline =>
      'No connection. Switch to the on-device summary or retry when online.';

  @override
  String get errSummaryServerError =>
      'The summary couldn\'t be created right now. Please try again shortly.';

  @override
  String get errSummaryInvalidResponse =>
      'The server returned an invalid response.';

  @override
  String get errSummaryEmptyResponse => 'The server returned an empty summary.';

  @override
  String get errSummaryGeneric =>
      'The summary could not be created. Please try again.';

  @override
  String get errChatEmptyQuestion => 'Please type a question.';

  @override
  String get errChatTimeout =>
      'The answer took longer than expected. Try again or switch to Cloud mode.';

  @override
  String get errChatLocalFailed =>
      'The on-device AI couldn\'t answer right now. Please try again.';

  @override
  String get errChatEmptyAnswer =>
      'An empty answer was received. Please try again.';

  @override
  String get errChatLoadFailed => 'The conversation could not be loaded.';

  @override
  String get errChatSendFailed => 'No answer received. Please try again.';
}
