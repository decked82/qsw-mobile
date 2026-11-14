import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/core/localization/app_localizations.dart';
import 'package:qsw_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:qsw_mobile/features/auth/domain/exceptions/auth_exception.dart';
import 'package:qsw_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:qsw_mobile/features/auth/presentation/pages/login_page.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? signInError;
  String? receivedEmail;
  String? receivedPassword;
  int signInCalls = 0;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    receivedEmail = email;
    receivedPassword = password;

    if (signInError != null) {
      throw signInError!;
    }
  }

  @override
  Future<void> signOut() async {}
}

Widget _testApp(AuthRepository repository) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en'), Locale('ko'), Locale('ru')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: LoginPage(authRepository: repository),
  );
}

void main() {
  testWidgets('shows validation errors and does not call repository', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(_testApp(repository));
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('submits trimmed email and password', (tester) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      '  user@example.com  ',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(repository.receivedEmail, 'user@example.com');
    expect(repository.receivedPassword, 'secret123');
    expect(find.byKey(const Key('login_error_message')), findsNothing);
  });

  testWidgets('shows localized invalid credentials error', (tester) async {
    final repository = _FakeAuthRepository()
      ..signInError = const AuthException('invalid-credential');

    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
  });

  testWidgets('shows not configured error', (tester) async {
    final repository = _FakeAuthRepository()
      ..signInError = const AuthException('auth-not-configured');

    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Authentication is not configured.'), findsOneWidget);
  });
}
