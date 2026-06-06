import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

/// Keeps the app process alive (via an Android foreground service) while
/// long-running transcription work continues *after recording has stopped* —
/// e.g. a 1-hour recording whose `small`-model transcription takes much longer
/// than the recording itself. Without it, Android may freeze/kill the process
/// once the app is backgrounded, stalling the transcription backlog.
///
/// During active recording the `record` plugin already runs its own
/// (microphone) foreground service, so this one is only needed for the
/// post-stop transcription tail.
///
/// Note: this is a best-effort guarantee. Aggressive OEM battery managers
/// (notably MIUI/Xiaomi) may still kill a backgrounded foreground service, and
/// Android 15 caps `dataSync` services at 6h/24h. The launch-time recovery of
/// un-transcribed chunks remains the hard guarantee that no audio is lost.
abstract class BackgroundWorkService {
  /// One-time setup of notification channel + options. Safe to call repeatedly.
  Future<void> init();

  /// Ensure the foreground service is running with the given notification copy.
  Future<void> ensureRunning({required String title, required String text});

  /// Stop the foreground service if it is running.
  Future<void> stop();
}

/// No-op implementation for tests and platforms without a foreground service.
class NoopBackgroundWorkService implements BackgroundWorkService {
  const NoopBackgroundWorkService();

  @override
  Future<void> init() async {}

  @override
  Future<void> ensureRunning({
    required String title,
    required String text,
  }) async {}

  @override
  Future<void> stop() async {}
}

/// Android implementation backed by `flutter_foreground_task`. A no-op on every
/// other platform.
class ForegroundBackgroundWorkService implements BackgroundWorkService {
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized || !Platform.isAndroid) {
      return;
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'voicescribe_transcription',
        channelName: 'Transcription',
        channelDescription: 'Keeps transcription running in the background.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      // We only need the process kept alive while the main-isolate queue drains
      // (allowWakeLock defaults to true); no periodic task callback is required.
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> ensureRunning({
    required String title,
    required String text,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    await init();
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        return;
      }
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationTitle: title,
        notificationText: text,
      );
    } catch (error, stack) {
      // Never let a foreground-service failure break transcription — it will
      // simply continue (only without the background-survival guarantee).
      AppLogger.error('[Background] start/update failed', error, stack);
    }
  }

  @override
  Future<void> stop() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (error, stack) {
      AppLogger.error('[Background] stop failed', error, stack);
    }
  }
}
