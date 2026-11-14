import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/auth/data/data_sources/auth_data_source.dart';
import 'package:qsw_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:qsw_mobile/features/auth/domain/entities/auth_user.dart';

class FakeAuthDataSource implements AuthDataSource {
  AuthUser? user;

  bool signInCalled = false;
  bool signOutCalled = false;

  String? receivedEmail;
  String? receivedPassword;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(user);

  @override
  AuthUser? get currentUser => user;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    receivedEmail = email;
    receivedPassword = password;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    user = null;
  }
}

void main() {
  late FakeAuthDataSource dataSource;
  late FirebaseAuthRepository repository;

  setUp(() {
    dataSource = FakeAuthDataSource();
    repository = FirebaseAuthRepository(dataSource: dataSource);
  });

  test('returns current authenticated user', () {
    const user = AuthUser(uid: 'test-uid', email: 'test@example.com');

    dataSource.user = user;

    expect(repository.currentUser, user);
  });

  test('emits current authentication state', () async {
    const user = AuthUser(uid: 'test-uid', email: 'test@example.com');

    dataSource.user = user;

    await expectLater(repository.authStateChanges, emits(user));
  });

  test('emits null when user is not authenticated', () async {
    await expectLater(repository.authStateChanges, emits(isNull));
  });

  test('delegates sign in to data source', () async {
    await repository.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    );

    expect(dataSource.signInCalled, isTrue);
    expect(dataSource.receivedEmail, 'test@example.com');
    expect(dataSource.receivedPassword, 'password123');
  });

  test('delegates sign out to data source', () async {
    await repository.signOut();

    expect(dataSource.signOutCalled, isTrue);
  });
}
