/// Machine-readable codes for user-facing failures.
///
/// Services throw exceptions carrying one of these instead of a hardcoded
/// string in a fixed language; the UI layer maps the code to the active
/// locale via `AppErrorCodeL10n.localized` (lib/ui/core/i18n). Raw messages
/// on the exceptions remain for logs only.
enum AppErrorCode {
  // Recording
  authRequired,
  micPermissionRequired,
  storageFull,

  // Summary
  summaryEmptyTranscript,
  summaryLocalFailed,
  summaryTimeout,
  summaryNotSynced,
  summaryAuthRequired,
  summaryOffline,
  summaryServerError,
  summaryInvalidResponse,
  summaryEmptyResponse,
  summaryGeneric,

  // Chat
  chatEmptyQuestion,
  chatTimeout,
  chatLocalFailed,
  chatEmptyAnswer,
  chatLoadFailed,
  chatSendFailed,
}
