import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Global test setup, picked up automatically by `flutter test` for every test
/// under `test/`.
///
/// Disables google_fonts runtime fetching so widget tests that build the app
/// theme (Plus Jakarta Sans) don't attempt a network request — they fall back
/// to the default font deterministically instead of throwing.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
