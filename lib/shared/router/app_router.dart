import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:voicescribe_mobile/features/auth/auth_screen.dart';
import 'package:voicescribe_mobile/features/history/history_screen.dart';
import 'package:voicescribe_mobile/features/recording/recording_screen.dart';
import 'package:voicescribe_mobile/features/summary/summary_screen.dart';
import 'package:voicescribe_mobile/features/transcript/transcript_screen.dart';
import 'package:voicescribe_mobile/shared/router/app_shell.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(Ref ref) {
  final app = ref.read(appControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: app,
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/auth';
      final isRootRoute = path == '/';

      if (!app.isAuthResolved) {
        return isRootRoute ? null : '/';
      }

      if (!app.isAuthenticated) {
        return isAuthRoute ? null : '/auth';
      }

      if (!app.isModelReady) {
        return isAuthRoute ? null : '/auth';
      }

      if (isAuthRoute || isRootRoute) {
        return '/recording';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const BootstrapGate()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
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
        ],
      ),
    ],
  );
}
