part of '../app_controller.dart';

class SyncFlow {
  const SyncFlow();

  Future<void> persist(AppController app, Future<void> operation) async {
    await operation;
    _scheduleSync(app);
  }

  void persistLater(AppController app, Future<void> operation) {
    unawaited(persist(app, operation));
  }

  Future<void> safeTriggerSync(AppController app) async {
    if (!app._syncStarted) {
      return;
    }
    try {
      await app._syncQueueService.triggerSyncIfOnline();
    } catch (_) {
      // no-op fallback when platform channels are unavailable
    }
  }

  Future<void> ensureSyncStarted(AppController app) async {
    if (app._syncStarted) {
      return;
    }
    try {
      await app._syncQueueService.start(
        accessTokenProvider: () async =>
            app._authService.currentUser()?.accessToken,
      );
      app._syncStarted = true;
    } catch (_) {
      // Connectivity plugin may be unavailable in non-widget test contexts.
    }
  }

  void _scheduleSync(AppController app) {
    if (!app._syncStarted) {
      return;
    }
    app._syncQueueService.scheduleSync();
  }
}
