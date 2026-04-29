part of '../app_controller.dart';

class AuthFlow {
  const AuthFlow();

  Future<void> register(
    AppController app, {
    required String email,
    required String password,
  }) async {
    app._authSession = await app._authService.register(
      email: email,
      password: password,
    );
    app._authResolved = true;
    app._notify();
    await app._ensureSyncStarted();
    await app.ensureModelReady();
    await app._safeTriggerSync();
  }

  Future<void> login(
    AppController app, {
    required String email,
    required String password,
  }) async {
    app._authSession = await app._authService.login(
      email: email,
      password: password,
    );
    app._authResolved = true;
    app._notify();
    await app._ensureSyncStarted();
    await app.ensureModelReady();
    await app._safeTriggerSync();
  }

  Future<void> logout(AppController app) async {
    await app._authService.logout();
    app._authSession = null;
    app._authResolved = true;
    app._notify();
  }

  Future<void> restoreSession(AppController app) async {
    app._authSession = await app._authService.restoreSession();
    app._authResolved = true;
    app._notify();
  }

  void ensureAuthenticated(AppController app) {
    if (app.isAuthenticated) {
      return;
    }
    throw StateError('Authentication is required.');
  }
}
