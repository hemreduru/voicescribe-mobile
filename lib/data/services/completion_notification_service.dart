import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

/// Posts a local notification when long-running work finishes **while the app is
/// backgrounded** — "Transcript ready" / "Summary ready" — so the user doesn't
/// have to keep the app open watching it drain.
///
/// Copy is localized in the UI and pushed in via [configure]; the show methods
/// no-op when the app is in the foreground (the user can already see the result)
/// and on non-Android platforms.
abstract class CompletionNotificationService {
  Future<void> init();

  void configure({
    required String transcriptTitle,
    required String transcriptBody,
    required String summaryTitle,
    required String summaryBody,
  });

  Future<void> showTranscriptReady();

  Future<void> showSummaryReady();
}

/// No-op for tests and non-Android platforms.
class NoopCompletionNotificationService
    implements CompletionNotificationService {
  const NoopCompletionNotificationService();

  @override
  Future<void> init() async {}

  @override
  void configure({
    required String transcriptTitle,
    required String transcriptBody,
    required String summaryTitle,
    required String summaryBody,
  }) {}

  @override
  Future<void> showTranscriptReady() async {}

  @override
  Future<void> showSummaryReady() async {}
}

class FlutterLocalCompletionNotificationService
    implements CompletionNotificationService {
  FlutterLocalCompletionNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  String _transcriptTitle = 'VoiceScribe';
  String _transcriptBody = 'Your transcript is ready.';
  String _summaryTitle = 'VoiceScribe';
  String _summaryBody = 'Your summary is ready.';

  static const _channelId = 'voicescribe_completion';
  static const _transcriptNotificationId = 5001;
  static const _summaryNotificationId = 5002;

  @override
  Future<void> init() async {
    if (_initialized || !Platform.isAndroid) {
      return;
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  void configure({
    required String transcriptTitle,
    required String transcriptBody,
    required String summaryTitle,
    required String summaryBody,
  }) {
    _transcriptTitle = transcriptTitle;
    _transcriptBody = transcriptBody;
    _summaryTitle = summaryTitle;
    _summaryBody = summaryBody;
  }

  @override
  Future<void> showTranscriptReady() =>
      _show(_transcriptNotificationId, _transcriptTitle, _transcriptBody);

  @override
  Future<void> showSummaryReady() =>
      _show(_summaryNotificationId, _summaryTitle, _summaryBody);

  Future<void> _show(int id, String title, String body) async {
    if (!Platform.isAndroid) {
      return;
    }
    // Only nudge when the user can't already see the result on screen.
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    try {
      await init();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Ready',
          channelDescription:
              'Notifies when a transcript or summary is ready.',
        ),
      );
      await _plugin.show(id, title, body, details);
    } catch (error, stack) {
      AppLogger.error('[Notify] show failed', error, stack);
    }
  }
}
