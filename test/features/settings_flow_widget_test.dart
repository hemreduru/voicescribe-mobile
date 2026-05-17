import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/ui/core/router/app_router.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_navigation.dart';
import 'package:voicescribe_mobile/ui/features/auth/bloc/auth_bloc.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';
import 'package:voicescribe_mobile/ui/features/settings/bloc/settings_bloc.dart';
import 'package:voicescribe_mobile/ui/features/settings/views/settings_screen.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_list_bloc.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('settings screen renders account, controls, and logout', (
    tester,
  ) async {
    final fakes = _Fakes();

    await tester.pumpWidget(
      _wrapWithApp(fakes: fakes, child: const SettingsScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Authenticated User'), findsOneWidget);

    expect(find.widgetWithText(AppButton, 'Logout'), findsOneWidget);
  });

  testWidgets('shell navigation exposes settings as the last destination', (
    tester,
  ) async {
    final fakes = _Fakes();
    await tester.pumpWidget(_wrapWithRouterApp(fakes: fakes));
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
      final fakes = _Fakes();
      await tester.pumpWidget(_wrapWithRouterApp(fakes: fakes));
      await _pumpRouter(tester);

      await tester.tap(find.text('Transcript').last);
      await _pumpRouter(tester);

      expect(find.text('Transcript'), findsWidgets);
      expect(find.byType(SettingsScreen), findsNothing);
    },
  );
}

Widget _wrapWithApp({required _Fakes fakes, required Widget child}) {
  return _RepositoryHarness(
    fakes: fakes,
    child: MultiBlocProvider(
      providers: _createBlocProviders(fakes),
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
    ),
  );
}

Widget _wrapWithRouterApp({required _Fakes fakes}) {
  return _RepositoryHarness(
    fakes: fakes,
    child: MultiBlocProvider(
      providers: _createBlocProviders(fakes),
      child: const _RouterAppHarness(),
    ),
  );
}

List<BlocProvider<dynamic>> _createBlocProviders(_Fakes fakes) {
  return [
    BlocProvider<BootstrapBloc>(
      create: (_) => BootstrapBloc(
        transcriptRepository: fakes.transcripts,
        transcriptionService: fakes.transcription,
      )..add(const BootstrapStarted()),
    ),
    BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(
        authRepository: fakes.auth,
        transcriptRepository: fakes.transcripts,
        syncQueueService: fakes.sync,
      )..add(const AuthStarted()),
    ),
    BlocProvider<RecordingBloc>(
      create: (_) => RecordingBloc(
        transcriptRepository: fakes.transcripts,
        recordingService: fakes.recording,
        transcriptionService: fakes.transcription,
        authRepository: fakes.auth,
        syncQueueService: fakes.sync,
      )..add(const RecordingSubscriptionRequested()),
    ),
    BlocProvider<TranscriptListBloc>(
      create: (_) => TranscriptListBloc(
        transcriptRepository: fakes.transcripts,
        syncQueueService: fakes.sync,
      )..add(const TranscriptListSubscriptionRequested()),
    ),
    BlocProvider<SettingsBloc>(
      create: (_) => SettingsBloc(
        transcriptRepository: fakes.transcripts,
        authRepository: fakes.auth,
        syncQueueService: fakes.sync,
      )..add(const SettingsSubscriptionRequested()),
    ),
  ];
}

Future<void> _pumpRouter(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

class _RouterAppHarness extends StatefulWidget {
  const _RouterAppHarness();

  @override
  State<_RouterAppHarness> createState() => _RouterAppHarnessState();
}

class _RouterAppHarnessState extends State<_RouterAppHarness> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= createAppRouter(
      authBloc: context.read<AuthBloc>(),
      bootstrapBloc: context.read<BootstrapBloc>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
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
    );
  }
}

class _RepositoryHarness extends StatelessWidget {
  const _RepositoryHarness({required this.fakes, required this.child});

  final _Fakes fakes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TranscriptRepository>.value(
          value: fakes.transcripts,
        ),
        RepositoryProvider<AuthRepository>.value(value: fakes.auth),
        RepositoryProvider<RecordingService>.value(value: fakes.recording),
        RepositoryProvider<TranscriptionService>.value(
          value: fakes.transcription,
        ),
        RepositoryProvider<SummaryService>.value(value: fakes.summary),
        RepositoryProvider<SyncQueueService>.value(value: fakes.sync),
      ],
      child: child,
    );
  }
}

class _Fakes {
  _Fakes()
    : transcripts = FakeTranscriptRepository(),
      auth = FakeAuthRepository(session: FakeAuthRepository.defaultSession),
      recording = FakeRecordingService(),
      transcription = FakeTranscriptionService(),
      summary = const LocalSummaryService(),
      sync = FakeSyncQueueService();

  final FakeTranscriptRepository transcripts;
  final FakeAuthRepository auth;
  final FakeRecordingService recording;
  final FakeTranscriptionService transcription;
  final LocalSummaryService summary;
  final FakeSyncQueueService sync;
}
