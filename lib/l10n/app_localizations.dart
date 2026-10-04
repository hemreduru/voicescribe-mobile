import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'VoiceScribe'**
  String get appName;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiTitle;

  /// No description provided for @aiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask questions about your own recordings'**
  String get aiSubtitle;

  /// No description provided for @chatNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatNewChat;

  /// No description provided for @chatSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get chatSources;

  /// No description provided for @chatThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get chatThinking;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your recordings…'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with your recordings'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your transcripts. Answers cite the recording they came from.'**
  String get chatEmptyMessage;

  /// No description provided for @chatNoSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoSessionsTitle;

  /// No description provided for @chatNoSessionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat to ask questions across all your recordings. Answers are drawn from your own transcripts.'**
  String get chatNoSessionsMessage;

  /// No description provided for @chatNeedsRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Record something first'**
  String get chatNeedsRecordingTitle;

  /// No description provided for @chatNeedsRecordingMessage.
  ///
  /// In en, this message translates to:
  /// **'The assistant answers from your transcripts. Make a recording, then come back to ask about it.'**
  String get chatNeedsRecordingMessage;

  /// No description provided for @chatSelectOrNew.
  ///
  /// In en, this message translates to:
  /// **'Select a conversation or start a new chat.'**
  String get chatSelectOrNew;

  /// No description provided for @chatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This conversation will be permanently deleted.'**
  String get chatDeleteConfirm;

  /// No description provided for @chatUntitled.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatUntitled;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Check your connection and try again.'**
  String get refreshFailed;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @bootstrapTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing VoiceScribe'**
  String get bootstrapTitle;

  /// No description provided for @bootstrapMessage.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready...'**
  String get bootstrapMessage;

  /// No description provided for @bootstrapFailed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed.'**
  String get bootstrapFailed;

  /// No description provided for @retrySetup.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retrySetup;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap the button to start recording'**
  String get tapToRecord;

  /// No description provided for @isRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get isRecording;

  /// No description provided for @recordingPaused.
  ///
  /// In en, this message translates to:
  /// **'Recording paused'**
  String get recordingPaused;

  /// No description provided for @liveTranscript.
  ///
  /// In en, this message translates to:
  /// **'Live Transcript'**
  String get liveTranscript;

  /// No description provided for @recordingStatus.
  ///
  /// In en, this message translates to:
  /// **'Session Status'**
  String get recordingStatus;

  /// No description provided for @sessionNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter session title...'**
  String get sessionNamePlaceholder;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @recentRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recent Recordings'**
  String get recentRecordings;

  /// No description provided for @noRecordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get noRecordings;

  /// No description provided for @searchRecordings.
  ///
  /// In en, this message translates to:
  /// **'Search recordings...'**
  String get searchRecordings;

  /// No description provided for @noTranscriptAvailable.
  ///
  /// In en, this message translates to:
  /// **'Transcript is not available.'**
  String get noTranscriptAvailable;

  /// No description provided for @noMatchingText.
  ///
  /// In en, this message translates to:
  /// **'No matching text found.'**
  String get noMatchingText;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @cloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloud;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually trigger a full push, pull, and cache cleanup.'**
  String get syncSectionSubtitle;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Sync in progress'**
  String get syncInProgress;

  /// No description provided for @syncIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready to sync'**
  String get syncIdle;

  /// No description provided for @lastSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Last sync: Never'**
  String get lastSyncNever;

  /// No description provided for @lastSyncAt.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSyncAt(Object time);

  /// No description provided for @syncBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncBannerTitle;

  /// No description provided for @syncBannerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Everything is up to date.'**
  String get syncBannerSuccess;

  /// No description provided for @syncBannerSuccessWithCounts.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {pushed}, refreshed {pulled}, cleaned {cleaned}'**
  String syncBannerSuccessWithCounts(
    Object pushed,
    Object pulled,
    Object cleaned,
  );

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @summaryProvider.
  ///
  /// In en, this message translates to:
  /// **'Summary Provider'**
  String get summaryProvider;

  /// No description provided for @autoSummarizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Summarize automatically'**
  String get autoSummarizeTitle;

  /// No description provided for @autoSummarizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Create the summary as soon as a recording finishes transcribing, with no extra tap.'**
  String get autoSummarizeDesc;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to VoiceScribe'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Record anything and get a clean transcript and structured minutes — automatically.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingFeatureRecord.
  ///
  /// In en, this message translates to:
  /// **'Record and transcribe meetings and notes'**
  String get onboardingFeatureRecord;

  /// No description provided for @onboardingFeatureSummary.
  ///
  /// In en, this message translates to:
  /// **'Automatic, structured summaries'**
  String get onboardingFeatureSummary;

  /// No description provided for @onboardingFeatureChat.
  ///
  /// In en, this message translates to:
  /// **'Ask questions about your recordings'**
  String get onboardingFeatureChat;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your languages'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a theme'**
  String get onboardingThemeTitle;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'One last thing'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'VoiceScribe needs the microphone to record, and notifications to let you know when a transcript or summary is ready. Nothing is shared without your action.'**
  String get onboardingPermissionsBody;

  /// No description provided for @onboardingAllowAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Allow & get started'**
  String get onboardingAllowAndFinish;

  /// No description provided for @onboardingStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepProgress(int current, int total);

  /// No description provided for @replayIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay intro'**
  String get replayIntroTitle;

  /// No description provided for @replayIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the welcome walkthrough again'**
  String get replayIntroSubtitle;

  /// No description provided for @transcribingProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Transcribing'**
  String get transcribingProgressLabel;

  /// No description provided for @statusHelpRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording is in progress.'**
  String get statusHelpRecording;

  /// No description provided for @statusHelpProcessing.
  ///
  /// In en, this message translates to:
  /// **'Transcript is being prepared.'**
  String get statusHelpProcessing;

  /// No description provided for @statusHelpReady.
  ///
  /// In en, this message translates to:
  /// **'Transcript is ready now.'**
  String get statusHelpReady;

  /// No description provided for @statusHelpIssue.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention.'**
  String get statusHelpIssue;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @transcriptReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcript ready'**
  String get transcriptReadyTitle;

  /// No description provided for @transcriptReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your recording has been transcribed.'**
  String get transcriptReadyBody;

  /// No description provided for @summaryReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary ready'**
  String get summaryReadyTitle;

  /// No description provided for @summaryReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your meeting summary is ready.'**
  String get summaryReadyBody;

  /// No description provided for @transcriptionSettings.
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get transcriptionSettings;

  /// No description provided for @transcriptionSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language of your recordings.'**
  String get transcriptionSettingsSubtitle;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @summarySettings.
  ///
  /// In en, this message translates to:
  /// **'Summary Settings'**
  String get summarySettings;

  /// No description provided for @latestTranscript.
  ///
  /// In en, this message translates to:
  /// **'Latest Transcript'**
  String get latestTranscript;

  /// No description provided for @readyToSummarize.
  ///
  /// In en, this message translates to:
  /// **'Ready to summarize'**
  String get readyToSummarize;

  /// No description provided for @generateSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate Summary'**
  String get generateSummary;

  /// No description provided for @summaryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No summary yet. Tap Generate to create structured meeting minutes from this transcript.'**
  String get summaryPlaceholder;

  /// No description provided for @noSummaryYet.
  ///
  /// In en, this message translates to:
  /// **'No summary generated yet.'**
  String get noSummaryYet;

  /// No description provided for @summaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t produce a readable summary this time. Tap Generate to try again.'**
  String get summaryUnavailable;

  /// No description provided for @summaryExecutiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryExecutiveSummary;

  /// No description provided for @summaryAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get summaryAgenda;

  /// No description provided for @summaryDecisions.
  ///
  /// In en, this message translates to:
  /// **'Decisions'**
  String get summaryDecisions;

  /// No description provided for @summaryActionItems.
  ///
  /// In en, this message translates to:
  /// **'Action Items'**
  String get summaryActionItems;

  /// No description provided for @summaryOpenQuestions.
  ///
  /// In en, this message translates to:
  /// **'Open Questions'**
  String get summaryOpenQuestions;

  /// No description provided for @summaryNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get summaryNotes;

  /// No description provided for @summaryAttendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get summaryAttendees;

  /// No description provided for @summaryAbsentees.
  ///
  /// In en, this message translates to:
  /// **'Absentees'**
  String get summaryAbsentees;

  /// No description provided for @summaryRecorder.
  ///
  /// In en, this message translates to:
  /// **'Recorder'**
  String get summaryRecorder;

  /// No description provided for @summaryNextMeeting.
  ///
  /// In en, this message translates to:
  /// **'Next Meeting'**
  String get summaryNextMeeting;

  /// No description provided for @summaryProviderCloudLabel.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get summaryProviderCloudLabel;

  /// No description provided for @summaryUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get summaryUnassigned;

  /// No description provided for @chunks.
  ///
  /// In en, this message translates to:
  /// **'Chunks'**
  String get chunks;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get unnamed;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required.'**
  String get permissionDenied;

  /// No description provided for @statusRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get statusRecording;

  /// No description provided for @statusTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing'**
  String get statusTranscribing;

  /// No description provided for @statusTranscriptionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Transcription done'**
  String get statusTranscriptionCompleted;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusTranscriptionError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusTranscriptionError;

  /// No description provided for @statusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get statusEmpty;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusIssue.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get statusIssue;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @longest.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get longest;

  /// No description provided for @localBadge.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localBadge;

  /// No description provided for @transcriptBadge.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptBadge;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @summaryGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated {time}'**
  String summaryGeneratedAt(Object time);

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to sync. Recordings already on this device stay available.'**
  String get logoutConfirmMessage;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @authenticatedUser.
  ///
  /// In en, this message translates to:
  /// **'Authenticated User'**
  String get authenticatedUser;

  /// No description provided for @authVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Registration completed. Verify your email address, then log in.'**
  String get authVerifyEmail;

  /// No description provided for @recordingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recordings'**
  String recordingsCount(Object count);

  /// No description provided for @deleteRecordingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recordings?'**
  String get deleteRecordingsTitle;

  /// No description provided for @deleteRecordingsMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This recording will be deleted safely.} other{{count} recordings will be deleted safely.}}'**
  String deleteRecordingsMessage(num count);

  /// No description provided for @chunksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} chunks'**
  String chunksCount(Object count);

  /// No description provided for @transcriptionProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String transcriptionProgressPercent(Object percent);

  /// No description provided for @transcriptionProgressChunks.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total}'**
  String transcriptionProgressChunks(Object completed, Object total);

  /// No description provided for @retryTranscription.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryTranscription;

  /// No description provided for @transcriptionFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed. Tap to retry.'**
  String get transcriptionFailedRetry;

  /// No description provided for @retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get retrying;

  /// No description provided for @statusIconsTitle.
  ///
  /// In en, this message translates to:
  /// **'Status icons'**
  String get statusIconsTitle;

  /// No description provided for @transcriptionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Transcription language'**
  String get transcriptionLanguage;

  /// No description provided for @recordingNotificationContent.
  ///
  /// In en, this message translates to:
  /// **'Recording in progress'**
  String get recordingNotificationContent;

  /// No description provided for @unsyncedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recording not backed up yet} other{{count} recordings not backed up yet}}'**
  String unsyncedCount(int count);

  /// No description provided for @transcribingNotificationContent.
  ///
  /// In en, this message translates to:
  /// **'Preparing transcript'**
  String get transcribingNotificationContent;

  /// No description provided for @etaUnitSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String etaUnitSeconds(int count);

  /// No description provided for @etaUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String etaUnitMinutes(int count);

  /// No description provided for @etaUnitHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String etaUnitHours(int count);

  /// No description provided for @etaRemaining.
  ///
  /// In en, this message translates to:
  /// **'~{time} left'**
  String etaRemaining(String time);

  /// No description provided for @errAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start recording.'**
  String get errAuthRequired;

  /// No description provided for @errMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required.'**
  String get errMicPermissionRequired;

  /// No description provided for @errStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Storage is full. Recording was stopped; free up space and try again.'**
  String get errStorageFull;

  /// No description provided for @errTranscriptionAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to transcribe your recording.'**
  String get errTranscriptionAuthRequired;

  /// No description provided for @errTranscriptionRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many transcription requests right now. Please retry in a moment.'**
  String get errTranscriptionRateLimited;

  /// No description provided for @errTranscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The transcription service is unavailable right now. Please retry later.'**
  String get errTranscriptionUnavailable;

  /// No description provided for @errTranscriptionOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your audio is saved; retry the transcription when you\'re back online.'**
  String get errTranscriptionOffline;

  /// No description provided for @errTranscriptionGeneric.
  ///
  /// In en, this message translates to:
  /// **'Part of the recording could not be transcribed. Tap retry to try again.'**
  String get errTranscriptionGeneric;

  /// No description provided for @errSummaryEmptyTranscript.
  ///
  /// In en, this message translates to:
  /// **'There is no transcript text to summarize.'**
  String get errSummaryEmptyTranscript;

  /// No description provided for @errSummaryTimeout.
  ///
  /// In en, this message translates to:
  /// **'The summary took longer than expected. Please try again.'**
  String get errSummaryTimeout;

  /// No description provided for @errSummaryNotSynced.
  ///
  /// In en, this message translates to:
  /// **'This recording hasn\'t been synced yet. Connect to the internet, sync, then try again.'**
  String get errSummaryNotSynced;

  /// No description provided for @errSummaryAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in to create summaries.'**
  String get errSummaryAuthRequired;

  /// No description provided for @errSummaryOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Retry when you\'re back online.'**
  String get errSummaryOffline;

  /// No description provided for @errSummaryServerError.
  ///
  /// In en, this message translates to:
  /// **'The summary couldn\'t be created right now. Please try again shortly.'**
  String get errSummaryServerError;

  /// No description provided for @errSummaryInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid response.'**
  String get errSummaryInvalidResponse;

  /// No description provided for @errSummaryEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an empty summary.'**
  String get errSummaryEmptyResponse;

  /// No description provided for @errSummaryGeneric.
  ///
  /// In en, this message translates to:
  /// **'The summary could not be created. Please try again.'**
  String get errSummaryGeneric;

  /// No description provided for @errChatEmptyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please type a question.'**
  String get errChatEmptyQuestion;

  /// No description provided for @errChatTimeout.
  ///
  /// In en, this message translates to:
  /// **'The answer took longer than expected. Please try again.'**
  String get errChatTimeout;

  /// No description provided for @errChatEmptyAnswer.
  ///
  /// In en, this message translates to:
  /// **'An empty answer was received. Please try again.'**
  String get errChatEmptyAnswer;

  /// No description provided for @errChatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The conversation could not be loaded.'**
  String get errChatLoadFailed;

  /// No description provided for @errChatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'No answer received. Please try again.'**
  String get errChatSendFailed;

  /// No description provided for @errSettingsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errSettingsActionFailed;

  /// No description provided for @errSettingsSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please check your connection and try again.'**
  String get errSettingsSyncFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
