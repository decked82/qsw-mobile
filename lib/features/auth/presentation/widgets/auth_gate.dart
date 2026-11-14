import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/repositories/auth_repository.dart';
import '../pages/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.authRepository,
    required this.child,
    super.key,
  });

  final AuthRepository authRepository;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _streamKey = 0;

  void _retry() {
    setState(() {
      _streamKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      key: ValueKey(_streamKey),
      stream: widget.authRepository.authStateChanges,
      initialData: widget.authRepository.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context);

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(l10n.authStateError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('auth_gate_retry_button'),
                      onPressed: _retry,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return LoginPage(authRepository: widget.authRepository);
        }

        return widget.child;
      },
    );
  }
}
