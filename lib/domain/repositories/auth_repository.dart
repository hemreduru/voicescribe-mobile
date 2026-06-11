import 'package:voicescribe_mobile/domain/models/domain.dart';

abstract class AuthRepository {
  Stream<AuthSessionState?> watchSession();

  AuthSessionState? currentSession();

  Future<AuthSessionState?> restoreSession();

  Future<AuthSessionState> login({
    required String email,
    required String password,
  });

  Future<AuthSessionState> register({
    required String email,
    required String password,
  });

  Future<void> logout();

  /// Drops the local session without calling the backend — used when the
  /// server already rejected the token (401/403). Unlike [logout], this never
  /// touches cached transcript data, so unsynced work survives a forced
  /// re-login.
  Future<void> expireSession();
}
