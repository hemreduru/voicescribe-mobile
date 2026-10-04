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
      'Start a new chat to ask questions across all your recordings. Answers are drawn from your own transcripts.';

  @override
  String get chatNeedsRecordingTitle => 'Record something first';

  @override
  String get chatNeedsRecordingMessage =>
      'The assistant answers from your transcripts. Make a recording, then come back to ask about it.';

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
  String get bootstrapMessage => 'Getting things ready...';

  @override
  String get bootstrapFailed => 'Setup failed.';

  @override
  String get retrySetup => 'Retry';

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
  String get summaryProvider => 'Summary Provider';

  @override
  String get autoSummarizeTitle => 'Summarize automatically';

  @override
  String get autoSummarizeDesc =>
      'Create the summary as soon as a recording finishes transcribing, with no extra tap.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingWelcomeTitle => 'Welcome to VoiceScribe';

  @override
  String get onboardingWelcomeBody =>
      'Record anything and get a clean transcript and structured minutes — automatically.';

  @override
  String get onboardingFeatureRecord =>
      'Record and transcribe meetings and notes';

  @override
  String get onboardingFeatureSummary => 'Automatic, structured summaries';

  @override
  String get onboardingFeatureChat => 'Ask questions about your recordings';

  @override
  String get onboardingLanguageTitle => 'Choose your languages';

  @override
  String get onboardingThemeTitle => 'Pick a theme';

  @override
  String get onboardingPermissionsTitle => 'One last thing';

  @override
  String get onboardingPermissionsBody =>
      'VoiceScribe needs the microphone to record, and notifications to let you know when a transcript or summary is ready. Nothing is shared without your action.';

  @override
  String get onboardingAllowAndFinish => 'Allow & get started';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get replayIntroTitle => 'Replay intro';

  @override
  String get replayIntroSubtitle => 'See the welcome walkthrough again';

  @override
  String get transcribingProgressLabel => 'Transcribing';

  @override
  String get statusHelpRecording => 'Recording is in progress.';

  @override
  String get statusHelpProcessing => 'Transcript is being prepared.';

  @override
  String get statusHelpReady => 'Transcript is ready now.';

  @override
  String get statusHelpIssue => 'Needs your attention.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get transcriptReadyTitle => 'Transcript ready';

  @override
  String get transcriptReadyBody => 'Your recording has been transcribed.';

  @override
  String get summaryReadyTitle => 'Summary ready';

  @override
  String get summaryReadyBody => 'Your meeting summary is ready.';

  @override
  String get transcriptionSettings => 'Transcription';

  @override
  String get transcriptionSettingsSubtitle =>
      'Choose the language of your recordings.';

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
      'No summary yet. Tap Generate to create structured meeting minutes from this transcript.';

  @override
  String get noSummaryYet => 'No summary generated yet.';

  @override
  String get summaryUnavailable =>
      'Couldn\'t produce a readable summary this time. Tap Generate to try again.';

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
  String get summaryProviderCloudLabel => 'Cloud';

  @override
  String get summaryUnassigned => 'Unassigned';

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
  String get ok => 'OK';

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
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You\'ll need to sign in again to sync. Recordings already on this device stay available.';

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
  String get recordingNotificationContent => 'Recording in progress';

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
  String get errTranscriptionAuthRequired =>
      'Sign in again to transcribe your recording.';

  @override
  String get errTranscriptionRateLimited =>
      'Too many transcription requests right now. Please retry in a moment.';

  @override
  String get errTranscriptionUnavailable =>
      'The transcription service is unavailable right now. Please retry later.';

  @override
  String get errTranscriptionOffline =>
      'No connection. Your audio is saved; retry the transcription when you\'re back online.';

  @override
  String get errTranscriptionGeneric =>
      'Part of the recording could not be transcribed. Tap retry to try again.';

  @override
  String get errSummaryEmptyTranscript =>
      'There is no transcript text to summarize.';

  @override
  String get errSummaryTimeout =>
      'The summary took longer than expected. Please try again.';

  @override
  String get errSummaryNotSynced =>
      'This recording hasn\'t been synced yet. Connect to the internet, sync, then try again.';

  @override
  String get errSummaryAuthRequired =>
      'You need to be signed in to create summaries.';

  @override
  String get errSummaryOffline =>
      'No connection. Retry when you\'re back online.';

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
      'The answer took longer than expected. Please try again.';

  @override
  String get errChatEmptyAnswer =>
      'An empty answer was received. Please try again.';

  @override
  String get errChatLoadFailed => 'The conversation could not be loaded.';

  @override
  String get errChatSendFailed => 'No answer received. Please try again.';

  @override
  String get errSettingsActionFailed =>
      'Something went wrong. Please try again.';

  @override
  String get errSettingsSyncFailed =>
      'Sync failed. Please check your connection and try again.';
}
