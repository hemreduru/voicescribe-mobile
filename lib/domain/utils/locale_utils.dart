import 'dart:io';

/// Resolves the device/app language code (e.g. `tr`, `en`) used to tell the
/// summarizer which language to write the output in — the user's phone language,
/// independent of the transcript's language.
///
/// [Platform.localeName] looks like `tr_TR` / `en-US`; we keep only the language
/// subtag. Falls back to Turkish (the app's primary locale) when unset.
String deviceLanguageCode() {
  final raw = Platform.localeName.trim();
  if (raw.isEmpty) {
    return 'tr';
  }
  final code = raw.split(RegExp(r'[_\-.]')).first.trim().toLowerCase();
  return code.isEmpty ? 'tr' : code;
}
