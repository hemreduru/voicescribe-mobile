import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/router/app_router.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/utils/env_config.dart';
import 'package:voicescribe_mobile/shared/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.initialize();

  // Handle uncaught framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    talker.handle(details.exception, details.stack);
  };

  // Handle uncaught asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  runApp(
    ProviderScope(
      observers: [TalkerRiverpodObserver(talker: talker)],
      child: const VoiceScribeApp(),
    ),
  );
}

class VoiceScribeApp extends ConsumerWidget {
  const VoiceScribeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
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
