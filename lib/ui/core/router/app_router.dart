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
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _fadePage(const BootstrapGate(), state),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _fadePage(const AuthScreen(), state),
      ),
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

CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    child: child,
  );
}

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(List<Stream<dynamic>> streams) {
    _subscriptions = streams
        .map((stream) => stream.distinct().listen((_) => notifyListeners()))
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
