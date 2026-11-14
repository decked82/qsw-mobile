import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/core/localization/app_localizations.dart';
import 'package:qsw_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:qsw_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:qsw_mobile/features/auth/presentation/widgets/auth_gate.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.controller);

  final StreamController<AuthUser?> controller;

  @override
  Stream<AuthUser?> get authStateChanges => controller.stream;

  @override
  AuthUser? currentUser;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

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
    home: AuthGate(
      authRepository: repository,
      child: const Scaffold(body: Text('Authenticated content')),
    ),
  );
}

void main() {
  testWidgets('shows loading indicator before auth state arrives', (
    tester,
  ) async {
    final controller = StreamController<AuthUser?>();
    final repository = _FakeAuthRepository(controller);

    await tester.pumpWidget(_testApp(repository));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Authenticated content'), findsNothing);

    await controller.close();
  });

  testWidgets('shows login page when user is signed out', (tester) async {
    final controller = StreamController<AuthUser?>();
    final repository = _FakeAuthRepository(controller);

    await tester.pumpWidget(_testApp(repository));
    controller.add(null);
    await tester.pump();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Authenticated content'), findsNothing);

    await controller.close();
  });

  testWidgets('shows child when user is authenticated', (tester) async {
    final controller = StreamController<AuthUser?>();
    final repository = _FakeAuthRepository(controller);

    await tester.pumpWidget(_testApp(repository));
    controller.add(const AuthUser(uid: 'user-1'));
    await tester.pump();

    expect(find.text('Authenticated content'), findsOneWidget);
    expect(find.text('Email'), findsNothing);

    await controller.close();
  });

  testWidgets('shows retry action when auth stream fails', (tester) async {
    final controller = StreamController<AuthUser?>();
    final repository = _FakeAuthRepository(controller);

    await tester.pumpWidget(_testApp(repository));
    controller.addError(Exception('stream failure'));
    await tester.pump();

    expect(find.byKey(const Key('auth_gate_retry_button')), findsOneWidget);

    await controller.close();
  });
}
