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

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @bootstrapTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing VoiceScribe'**
  String get bootstrapTitle;

  /// No description provided for @bootstrapMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading on-device Whisper model...'**
  String get bootstrapMessage;

  /// No description provided for @bootstrapFailed.
  ///
  /// In en, this message translates to:
  /// **'Model setup failed.'**
  String get bootstrapFailed;

  /// No description provided for @retrySetup.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retrySetup;

  /// No description provided for @downloadingModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading model'**
  String get downloadingModel;

  /// No description provided for @modelReady.
  ///
  /// In en, this message translates to:
  /// **'AI Ready'**
  String get modelReady;

  /// No description provided for @modelLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading model...'**
  String get modelLoading;

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

  /// No description provided for @short.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get short;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @long.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get long;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

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
  /// **'Summary engine is ready in this Flutter baseline. Connect a local LLM or cloud provider to produce summaries here.'**
  String get summaryPlaceholder;

  /// No description provided for @noSummaryYet.
  ///
  /// In en, this message translates to:
  /// **'No summary generated yet.'**
  String get noSummaryYet;

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

  /// No description provided for @speakerRecognition.
  ///
  /// In en, this message translates to:
  /// **'Speaker Recognition'**
  String get speakerRecognition;

  /// No description provided for @speakerRecognitionDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically identify and label speakers in recordings.'**
  String get speakerRecognitionDesc;

  /// No description provided for @addNewSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Add Speaker'**
  String get addNewSpeaker;

  /// No description provided for @registeredSpeakers.
  ///
  /// In en, this message translates to:
  /// **'Registered Speakers'**
  String get registeredSpeakers;

  /// No description provided for @recordVoiceSample.
  ///
  /// In en, this message translates to:
  /// **'Record voice sample'**
  String get recordVoiceSample;

  /// No description provided for @voiceSampleAvailable.
  ///
  /// In en, this message translates to:
  /// **'Voice sample available'**
  String get voiceSampleAvailable;

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

  /// No description provided for @speakerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Speaker name'**
  String get speakerNameLabel;

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

  /// No description provided for @profileReadyForRecognition.
  ///
  /// In en, this message translates to:
  /// **'Ready for profile recognition'**
  String get profileReadyForRecognition;

  /// No description provided for @addSampleLater.
  ///
  /// In en, this message translates to:
  /// **'Voice sample can be added later'**
  String get addSampleLater;

  /// No description provided for @summaryGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated {time}'**
  String summaryGeneratedAt(Object time);
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
