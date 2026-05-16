import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/features/settings/settings_screen.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/shared/models/domain.dart';
import 'package:voicescribe_mobile/shared/router/app_router.dart';
import 'package:voicescribe_mobile/shared/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/shared/services/auth/auth_service.dart';
import 'package:voicescribe_mobile/shared/services/summary_service.dart';
import 'package:voicescribe_mobile/shared/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/shared/services/transcript_repository.dart';
import 'package:voicescribe_mobile/shared/services/whisper_service.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/widgets/app_navigation.dart';

void main() {
  testWidgets('settings screen renders account, controls, and logout', (
    tester,
  ) async {
    final controller = _buildController();
    await controller.bootstrap();

    await tester.pumpWidget(
      _wrapWithApp(controller: controller, child: const SettingsScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Summary Settings'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Appearance'), 240);
    await tester.pump();
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('System Status'), 240);
    await tester.pump();
    expect(find.text('System Status'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Billing & Plans'), 240);
    await tester.pump();
    expect(find.text('Billing & Plans'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Logout'), 240);
    await tester.pump();
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('shell navigation exposes settings as the last destination', (
    tester,
  ) async {
    final controller = _buildController();
    await controller.bootstrap();

    await tester.pumpWidget(_wrapWithRouterApp(controller: controller));
    await _pumpRouter(tester);

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(AppBottomNavigation),
            matching: find.byType(Text),
          ),
        )
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();

    expect(labels, isNotEmpty);
    expect(labels, ['Recording', 'Transcript', 'Settings']);
    expect(labels.last, 'Settings');

    await tester.tap(find.text('Settings').last);
    await _pumpRouter(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets(
    'shell navigation opens transcript screen as middle destination',
    (tester) async {
      final controller = _buildController();
      await controller.bootstrap();

      await tester.pumpWidget(_wrapWithRouterApp(controller: controller));
      await _pumpRouter(tester);

      await tester.tap(find.text('Transcript').last);
      await _pumpRouter(tester);

      expect(find.text('Transcript'), findsWidgets);
      expect(find.byType(SettingsScreen), findsNothing);
    },
  );
}

Widget _wrapWithApp({
  required AppController controller,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [appControllerProvider.overrideWith((ref) => controller)],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],
      home: child,
    ),
  );
}

Widget _wrapWithRouterApp({required AppController controller}) {
  return ProviderScope(
    overrides: [appControllerProvider.overrideWith((ref) => controller)],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(goRouterProvider);
        final themeMode = ref.watch(appThemeModeProvider);

        return MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('tr')],
        );
      },
    ),
  );
}

AppController _buildController() {
  return AppController(
    repository: _FakeRepository(),
    transcriptionService: _FakeTranscriptionService(),
    audioService: _FakeRecordingService(),
    summaryService: const LocalSummaryService(),
    authService: _FakeAuthService(),
    syncQueueService: _FakeSyncQueueService(),
  );
}

Future<void> _pumpRouter(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

class _FakeAuthService extends VoiceScribeAuthService {
  _FakeAuthService();

  static const AuthSessionState _session = AuthSessionState(
    userId: 'user-1',
    email: 'user@test.dev',
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: null,
  );

  @override
  Future<AuthSessionState?> restoreSession() async => _session;

  @override
  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<AuthSessionState> register({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<void> logout() async {}
}

class _FakeRepository implements TranscriptRepository {
  @override
  Future<PersistedTranscriptState> load() async =>
      PersistedTranscriptState.empty();

  @override
  Future<void> saveTranscript(Transcript transcript) async {}

  @override
  Future<void> deleteTranscript(String id) async {}

  @override
  Future<void> saveChunk(TranscriptChunk chunk) async {}

  @override
  Future<void> saveSummary(Summary summary) async {}

  @override
  Future<void> saveProcessingJob(ProcessingJob job) async {}

  @override
  Future<void> deleteProcessingJob(String id) async {}

  @override
  Future<void> saveSetting(String key, String value) async {}
}

class _FakeRecordingService implements RecordingService {
  final _chunks = StreamController<RecordedAudioChunk>.broadcast();
  final _levels = StreamController<double>.broadcast();

  @override
  Stream<RecordedAudioChunk> get chunks => _chunks.stream;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<void> dispose() async {
    await _chunks.close();
    await _levels.close();
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class _FakeSyncQueueService extends SyncQueueService {
  _FakeSyncQueueService();

  @override
  Future<void> start({
    required AccessTokenProvider accessTokenProvider,
    SyncCompletionCallback? onSyncComplete,
  }) async {}

  @override
  Future<void> triggerSyncIfOnline() async {}

  @override
  void scheduleSync({Duration delay = const Duration(seconds: 2)}) {}

  @override
  Future<void> dispose() async {}
}

class _FakeTranscriptionService implements TranscriptionService {
  final _progress = StreamController<ModelDownloadProgress>.broadcast();

  @override
  Stream<ModelDownloadProgress> get downloadProgress => _progress.stream;

  @override
  Future<void> dispose() async {
    await _progress.close();
  }

  @override
  Future<WhisperBootstrapResult> ensureModel() async {
    return const WhisperBootstrapResult(
      path: '/tmp/model',
      downloaded: false,
      loaded: true,
    );
  }

  @override
  Future<TranscriptionResult> transcribeChunk(String audioPath) async =>
      const TranscriptionResult(text: '', segments: []);
}
