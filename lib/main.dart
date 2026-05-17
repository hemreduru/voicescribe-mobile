import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:voicescribe_mobile/data/repositories/sqflite_transcript_repository.dart';
import 'package:voicescribe_mobile/data/repositories/voice_scribe_auth_repository.dart';
import 'package:voicescribe_mobile/data/services/audio_recording_service.dart';
import 'package:voicescribe_mobile/data/services/summary_service.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/repositories/auth_repository.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/ui/core/bloc/voicescribe_bloc_observer.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/router/app_router.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/utils/env_config.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';
import 'package:voicescribe_mobile/ui/core/widgets/global_sync_feedback_host.dart';
import 'package:voicescribe_mobile/ui/features/auth/bloc/auth_bloc.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';
import 'package:voicescribe_mobile/ui/features/recording/bloc/recording_bloc.dart';
import 'package:voicescribe_mobile/ui/features/settings/bloc/settings_bloc.dart';
import 'package:voicescribe_mobile/ui/features/transcript/bloc/transcript_list_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.initialize();
  if (kDebugMode) {
    debugPrint('VoiceScribe API base URL: ${EnvConfig.apiBaseUrl}');
    Bloc.observer = const VoiceScribeBlocObserver();
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    talker.handle(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  runApp(const VoiceScribeRoot());
}

class VoiceScribeRoot extends StatelessWidget {
  const VoiceScribeRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TranscriptRepository>(
          create: (_) => SqfliteTranscriptRepository(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (_) => VoiceScribeAuthRepository(),
        ),
        RepositoryProvider<RecordingService>(
          create: (_) => AudioRecordingService(),
          dispose: (service) => service.dispose(),
        ),
        RepositoryProvider<TranscriptionService>(
          create: (_) => WhisperTranscriptionService(),
          dispose: (service) => service.dispose(),
        ),
        RepositoryProvider<SummaryService>(
          create: (_) => const LocalSummaryService(),
        ),
        RepositoryProvider<SyncQueueService>(
          create: (_) => SyncQueueService(),
          dispose: (service) => service.dispose(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BootstrapBloc>(
            create: (context) => BootstrapBloc(
              transcriptRepository: context.read<TranscriptRepository>(),
              transcriptionService: context.read<TranscriptionService>(),
            )..add(const BootstrapStarted()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
              transcriptRepository: context.read<TranscriptRepository>(),
              syncQueueService: context.read<SyncQueueService>(),
            )..add(const AuthStarted()),
          ),
          BlocProvider<RecordingBloc>(
            create: (context) => RecordingBloc(
              transcriptRepository: context.read<TranscriptRepository>(),
              recordingService: context.read<RecordingService>(),
              transcriptionService: context.read<TranscriptionService>(),
              authRepository: context.read<AuthRepository>(),
              syncQueueService: context.read<SyncQueueService>(),
            )..add(const RecordingSubscriptionRequested()),
          ),
          BlocProvider<TranscriptListBloc>(
            create: (context) => TranscriptListBloc(
              transcriptRepository: context.read<TranscriptRepository>(),
              syncQueueService: context.read<SyncQueueService>(),
            )..add(const TranscriptListSubscriptionRequested()),
          ),
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(
              transcriptRepository: context.read<TranscriptRepository>(),
              authRepository: context.read<AuthRepository>(),
              syncQueueService: context.read<SyncQueueService>(),
            )..add(const SettingsSubscriptionRequested()),
          ),
        ],
        child: const VoiceScribeApp(),
      ),
    );
  }
}

class VoiceScribeApp extends StatefulWidget {
  const VoiceScribeApp({super.key});

  @override
  State<VoiceScribeApp> createState() => _VoiceScribeAppState();
}

class _VoiceScribeAppState extends State<VoiceScribeApp> {
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
    final router = _router!;
    final themeMode = context.select<SettingsBloc, ThemeMode>(
      (bloc) => _themeModeFromKey(bloc.state.preferences.themeMode),
    );
    final locale = context.select<SettingsBloc, Locale?>(
      (bloc) => _localeFromKey(bloc.state.preferences.localePreference),
    );

    return MaterialApp.router(
      routerConfig: router,
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],
      builder: (context, child) {
        return GlobalSyncFeedbackHost(
          syncQueueService: context.read<SyncQueueService>(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  ThemeMode _themeModeFromKey(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Locale? _localeFromKey(String value) {
    return switch (value) {
      'en' => const Locale('en'),
      'tr' => const Locale('tr'),
      _ => null,
    };
  }
}
