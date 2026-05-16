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
}
