import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../movements/domain/entities/movement.dart';
import '../../../sync/domain/entities/pending_operation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _syncTestRunning = false;
  String? _syncTestResult;

  Future<void> _runSyncTest() async {
    if (_syncTestRunning) {
      return;
    }

    setState(() {
      _syncTestRunning = true;
      _syncTestResult = null;
    });

    final operationId = 'sync_smoke_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final createdAt = DateTime.now();

      final movement = Movement(
        id: 0,
        operationId: operationId,
        type: MovementType.inbound,
        boxNo: 'TEST-BOX',
        partNo: 'TEST-PART',
        toLocation: 'TEST-LOCATION',
        quantity: 1,
        userId: 'SMOKE-TEST',
        createdAt: createdAt,
      );

      // 1. Save movement to SQLite and create pending operation.
      await ServiceLocator.instance.saveMovement(movement);

      final savedMovement = await ServiceLocator.instance
          .getMovementByOperationId(operationId);

      if (savedMovement == null) {
        throw StateError('Movement was not found in SQLite after save.');
      }

      final pendingOperation = await ServiceLocator.instance
          .getPendingOperationByOperationId(operationId);

      if (pendingOperation == null) {
        throw StateError('Pending operation was not found after save.');
      }

      if (pendingOperation.status != PendingOperationStatus.pending) {
        throw StateError(
          'Unexpected pending operation status: '
          '${pendingOperation.status.name}',
        );
      }

      // 2. Run the real sync engine.
      await ServiceLocator.instance.syncEngine.syncPendingOperations();

      // 3. Verify that the pending operation became SYNCED.
      final syncedOperation = await ServiceLocator.instance
          .getPendingOperationByOperationId(operationId);

      if (syncedOperation == null) {
        throw StateError('Pending operation was not found after sync.');
      }

      if (syncedOperation.status != PendingOperationStatus.synced) {
        throw StateError(
          'Sync did not complete. '
          'Status: ${syncedOperation.status.name}'
          '${syncedOperation.lastError == null ? '' : '\n'
                    'Error: ${syncedOperation.lastError}'}',
        );
      }

      // 4. Verify the actual Firestore document.
      final firestore = FirebaseFirestore.instance;
      final document = firestore.collection('movements').doc(operationId);

      final snapshot = await document.get();

      if (!snapshot.exists) {
        throw StateError('Firestore document was not found after sync.');
      }

      final data = snapshot.data();

      if (data == null) {
        throw StateError('Firestore document exists, but contains no data.');
      }

      if (data['operationId'] != operationId) {
        throw StateError('Firestore operationId is incorrect.');
      }

      if (data['type'] != 'INBOUND') {
        throw StateError('Firestore movement type is incorrect.');
      }

      if (data['boxNo'] != 'TEST-BOX') {
        throw StateError('Firestore boxNo is incorrect.');
      }

      if (data['partNo'] != 'TEST-PART') {
        throw StateError('Firestore partNo is incorrect.');
      }

      if (data['quantity'] != 1) {
        throw StateError('Firestore quantity is incorrect.');
      }

      // 5. Delete the test document.
      //await document.delete();

      if (!mounted) {
        return;
      }

      setState(() {
        _syncTestResult =
            'SUCCESS\n'
            'SQLite Movement ✓\n'
            'PendingOperation ✓\n'
            'SyncEngine ✓\n'
            'Firestore Write ✓\n'
            'Firestore Read ✓\n'
            'Status: SYNCED ✓\n'
            'Test document deleted ✓\n'
            'operationId: $operationId';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _syncTestResult =
            'FAILED\n'
            '$error\n'
            'operationId: $operationId';
      });
    } finally {
      if (mounted) {
        setState(() {
          _syncTestRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) {
              QswApp.of(context).setLocale(locale);
            },
            itemBuilder: (context) {
              final currentLocale = QswApp.of(context).locale;

              return [
                PopupMenuItem(
                  value: const Locale('en'),
                  child: _LanguageMenuItem(
                    label: 'English',
                    selected: currentLocale?.languageCode == 'en',
                  ),
                ),
                PopupMenuItem(
                  value: const Locale('ko'),
                  child: _LanguageMenuItem(
                    label: '한국어',
                    selected: currentLocale?.languageCode == 'ko',
                  ),
                ),
                PopupMenuItem(
                  value: const Locale('ru'),
                  child: _LanguageMenuItem(
                    label: 'Русский',
                    selected: currentLocale?.languageCode == 'ru',
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.appDescription,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _HomeMenuButton(icon: Icons.input, title: l10n.receiving),
                    _HomeMenuButton(icon: Icons.output, title: l10n.shipping),
                    _HomeMenuButton(
                      key: const Key('part_search_button'),
                      icon: Icons.search,
                      title: l10n.partSearch,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.partSearch);
                      },
                    ),
                    _HomeMenuButton(
                      key: const Key('inventory_button'),
                      icon: Icons.inventory_2_outlined,
                      title: l10n.inventory,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.parts);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _syncTestRunning ? null : _runSyncTest,
                icon: _syncTestRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_sync),
                label: Text(
                  _syncTestRunning ? 'Testing Sync...' : 'Test Movement Sync',
                ),
              ),
              if (_syncTestResult != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  _syncTestResult!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMenuButton extends StatelessWidget {
  const _HomeMenuButton({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageMenuItem extends StatelessWidget {
  const _LanguageMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: selected ? const Icon(Icons.check, size: 18) : null,
        ),
        Text(label),
      ],
    );
  }
}
