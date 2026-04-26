import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:voicescribe_mobile/features/history/history_screen.dart';
import 'package:voicescribe_mobile/features/recording/recording_screen.dart';
import 'package:voicescribe_mobile/features/speaker/speaker_screen.dart';
import 'package:voicescribe_mobile/features/summary/summary_screen.dart';
import 'package:voicescribe_mobile/features/transcript/transcript_screen.dart';
import 'package:voicescribe_mobile/shared/router/app_shell.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const BootstrapGate()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recording',
                builder: (context, state) => const RecordingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transcript',
                builder: (context, state) => const TranscriptScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/summary',
                builder: (context, state) => const SummaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/speaker',
                builder: (context, state) => const SpeakerScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
