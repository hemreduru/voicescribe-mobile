import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicescribe_mobile/ui/core/router/app_shell.dart';
import 'package:voicescribe_mobile/ui/features/auth/bloc/auth_bloc.dart';
import 'package:voicescribe_mobile/ui/features/auth/views/auth_screen.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';
import 'package:voicescribe_mobile/ui/features/recording/views/recording_screen.dart';
import 'package:voicescribe_mobile/ui/features/settings/views/settings_screen.dart';
import 'package:voicescribe_mobile/ui/features/transcript/views/transcript_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({
  required AuthBloc authBloc,
  required BootstrapBloc bootstrapBloc,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: RouterRefreshNotifier([
      authBloc.stream,
      bootstrapBloc.stream,
    ]),
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/auth';
      final isRootRoute = path == '/';

      if (!bootstrapBloc.state.initialized || !authBloc.state.isResolved) {
        return isRootRoute ? null : '/';
      }

      if (!authBloc.state.isAuthenticated) {
        return isAuthRoute ? null : '/auth';
      }

      if (!bootstrapBloc.state.isReady) {
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
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(List<Stream<dynamic>> streams) {
    _subscriptions = streams
        .map((stream) => stream.listen((_) => notifyListeners()))
        .toList(growable: false);
  }

  late final List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
