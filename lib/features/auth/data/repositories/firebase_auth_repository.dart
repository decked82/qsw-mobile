import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_data_source.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({required this._dataSource});

  final AuthDataSource _dataSource;

  @override
  Stream<AuthUser?> get authStateChanges => _dataSource.authStateChanges;

  @override
  AuthUser? get currentUser => _dataSource.currentUser;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _dataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() {
    return _dataSource.signOut();
  }
}
