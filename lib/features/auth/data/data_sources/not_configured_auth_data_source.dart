import '../../domain/entities/auth_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import 'auth_data_source.dart';

class NotConfiguredAuthDataSource implements AuthDataSource {
  const NotConfiguredAuthDataSource();

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthException('auth-not-configured');
  }

  @override
  Future<void> signOut() async {}
}
