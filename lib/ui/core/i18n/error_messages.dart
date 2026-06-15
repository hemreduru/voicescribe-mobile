import 'package:voicescribe_mobile/domain/models/app_error.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';

/// Maps an [AppErrorCode] to the active locale's user-facing message. Services
/// throw coded exceptions; only this UI-side mapping decides the wording.
extension AppErrorCodeL10n on AppErrorCode {
  String localized(AppLocalizations l10n) {
    return switch (this) {
      AppErrorCode.authRequired => l10n.errAuthRequired,
      AppErrorCode.micPermissionRequired => l10n.errMicPermissionRequired,
      AppErrorCode.storageFull => l10n.errStorageFull,
      AppErrorCode.summaryEmptyTranscript => l10n.errSummaryEmptyTranscript,
      AppErrorCode.summaryLocalFailed => l10n.errSummaryLocalFailed,
      AppErrorCode.summaryTimeout => l10n.errSummaryTimeout,
      AppErrorCode.summaryNotSynced => l10n.errSummaryNotSynced,
      AppErrorCode.summaryAuthRequired => l10n.errSummaryAuthRequired,
      AppErrorCode.summaryOffline => l10n.errSummaryOffline,
      AppErrorCode.summaryServerError => l10n.errSummaryServerError,
      AppErrorCode.summaryInvalidResponse => l10n.errSummaryInvalidResponse,
      AppErrorCode.summaryEmptyResponse => l10n.errSummaryEmptyResponse,
      AppErrorCode.summaryGeneric => l10n.errSummaryGeneric,
      AppErrorCode.chatEmptyQuestion => l10n.errChatEmptyQuestion,
      AppErrorCode.chatTimeout => l10n.errChatTimeout,
      AppErrorCode.chatLocalFailed => l10n.errChatLocalFailed,
      AppErrorCode.chatEmptyAnswer => l10n.errChatEmptyAnswer,
      AppErrorCode.chatLoadFailed => l10n.errChatLoadFailed,
      AppErrorCode.chatSendFailed => l10n.errChatSendFailed,
      AppErrorCode.settingsActionFailed => l10n.errSettingsActionFailed,
      AppErrorCode.settingsSyncFailed => l10n.errSettingsSyncFailed,
      AppErrorCode.settingsModelDownloadFailed =>
        l10n.errSettingsModelDownloadFailed,
    };
  }
}
