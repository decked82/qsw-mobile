import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_movement_sync_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/sync/data/data_sources/remote_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/services/sync_engine.dart';

void main() {
  group('SyncEngine', () {
    test('syncs pending operation successfully', () async {
      final operation = _createOperation(
        id: 1,
        operationId: 'operation-001',
        status: PendingOperationStatus.pending,
        retryCount: 0,
      );

      final repository = FakePendingOperationRepository(
        operations: [operation],
      );
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      expect(remote.syncedOperations, hasLength(1));
      expect(remote.syncedOperations.single.operationId, 'operation-001');

      final result = repository.operations.single;

      expect(result.status, PendingOperationStatus.synced);
      expect(result.retryCount, 0);
      expect(result.lastAttemptAt, isNotNull);
      expect(result.lastError, isNull);
    });

    test('marks operation as failed and increments retry count', () async {
      final operation = _createOperation(
        id: 1,
        operationId: 'operation-001',
        status: PendingOperationStatus.pending,
        retryCount: 2,
      );

      final repository = FakePendingOperationRepository(
        operations: [operation],
      );
      final remote = FakeRemoteSyncDataSource(
        error: Exception('Network unavailable'),
      );

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      final result = repository.operations.single;

      expect(result.status, PendingOperationStatus.failed);
      expect(result.retryCount, 3);
      expect(result.lastAttemptAt, isNotNull);
      expect(result.lastError, contains('Network unavailable'));
    });

    test('continues syncing after one operation fails', () async {
      final first = _createOperation(
        id: 1,
        operationId: 'operation-001',
        status: PendingOperationStatus.pending,
        retryCount: 0,
      );

      final second = _createOperation(
        id: 2,
        operationId: 'operation-002',
        status: PendingOperationStatus.pending,
        retryCount: 0,
      );

      final repository = FakePendingOperationRepository(
        operations: [first, second],
      );
      final remote = SelectiveFailureRemoteSyncDataSource(
        failingOperationId: 'operation-001',
      );

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      expect(repository.operations[0].status, PendingOperationStatus.failed);
      expect(repository.operations[0].retryCount, 1);

      expect(repository.operations[1].status, PendingOperationStatus.synced);
      expect(repository.operations[1].retryCount, 0);

      expect(
        remote.syncedOperations.map((operation) => operation.operationId),
        contains('operation-002'),
      );
    });

    test(
      'continues syncing when setting PROCESSING fails for one operation',
      () async {
        final first = _createOperation(
          id: 1,
          operationId: 'operation-001',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        );
        final second = _createOperation(
          id: 2,
          operationId: 'operation-002',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        );

        final repository =
            FakePendingOperationRepository(operations: [first, second])
              ..statusUpdateFailuresRemaining = {
                PendingOperationStatus.processing: 1,
              };
        final remote = FakeRemoteSyncDataSource();

        final engine = SyncEngine(
          pendingOperationRepository: repository,
          remoteSyncDataSource: remote,
        );

        await engine.syncPendingOperations();

        expect(repository.operations[0].status, PendingOperationStatus.pending);
        expect(repository.operations[1].status, PendingOperationStatus.synced);
        expect(
          remote.syncedOperations.map((operation) => operation.operationId),
          ['operation-002'],
        );
      },
    );

    test('requeues operation when saving SYNCED status fails', () async {
      final operation = _createOperation(
        id: 1,
        operationId: 'operation-001',
        status: PendingOperationStatus.pending,
        retryCount: 2,
      );

      final repository = FakePendingOperationRepository(operations: [operation])
        ..statusUpdateFailuresRemaining = {PendingOperationStatus.synced: 1};
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      expect(remote.syncedOperations, hasLength(1));
      expect(
        repository.operations.single.status,
        PendingOperationStatus.pending,
      );
      expect(repository.operations.single.retryCount, 2);
      expect(
        repository.operations.single.lastError,
        contains('Failed to save SYNCED status'),
      );

      await engine.syncPendingOperations();

      expect(remote.syncedOperations, hasLength(2));
      expect(
        repository.operations.single.status,
        PendingOperationStatus.synced,
      );
      expect(repository.operations.single.retryCount, 2);
    });

    test(
      'recovers operation when saving SYNCED and fallback PENDING both fail',
      () async {
        final operation = _createOperation(
          id: 1,
          operationId: 'operation-recovery',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        );

        final repository =
            FakePendingOperationRepository(operations: [operation])
              ..statusUpdateFailuresRemaining = {
                PendingOperationStatus.synced: 1,
                PendingOperationStatus.pending: 1,
              };

        final remote = FakeRemoteSyncDataSource();

        final engine = SyncEngine(
          pendingOperationRepository: repository,
          remoteSyncDataSource: remote,
        );

        await engine.syncPendingOperations();

        expect(remote.syncedOperations, hasLength(1));
        expect(
          repository.operations.single.status,
          PendingOperationStatus.processing,
        );

        final restartedEngine = SyncEngine(
          pendingOperationRepository: repository,
          remoteSyncDataSource: remote,
        );

        await restartedEngine.syncPendingOperations();

        expect(repository.recoveryCallCount, 2);
        expect(remote.syncedOperations, hasLength(2));
        expect(
          repository.operations.single.status,
          PendingOperationStatus.synced,
        );
      },
    );

    test(
      'automatically recovers PROCESSING after FAILED status save fails',
      () async {
        final operation = _createOperation(
          id: 1,
          operationId: 'operation-failed-status-recovery',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        );
        final repository = FakePendingOperationRepository(
          operations: [operation],
        )..statusUpdateFailuresRemaining = {PendingOperationStatus.failed: 1};
        final remote = CountingFailureRemoteSyncDataSource();
        final engine = SyncEngine(
          pendingOperationRepository: repository,
          remoteSyncDataSource: remote,
          automaticRetry: true,
          initialRetryDelay: const Duration(milliseconds: 5),
          maxRetryDelay: const Duration(milliseconds: 10),
        );

        try {
          await engine.syncPendingOperations();
          await Future<void>.delayed(const Duration(milliseconds: 35));

          expect(repository.recoveryCallCount, greaterThanOrEqualTo(2));
          expect(remote.attemptCount, greaterThanOrEqualTo(2));
          expect(
            repository.operations.single.status,
            PendingOperationStatus.failed,
          );
        } finally {
          engine.dispose();
        }
      },
    );

    test(
      'automatically recovers PROCESSING when SYNCED and PENDING saves fail',
      () async {
        final operation = _createOperation(
          id: 1,
          operationId: 'operation-synced-status-recovery',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        );
        final repository =
            FakePendingOperationRepository(operations: [operation])
              ..statusUpdateFailuresRemaining = {
                PendingOperationStatus.synced: 1,
                PendingOperationStatus.pending: 1,
              };
        final remote = FakeRemoteSyncDataSource();
        final engine = SyncEngine(
          pendingOperationRepository: repository,
          remoteSyncDataSource: remote,
          automaticRetry: true,
          initialRetryDelay: const Duration(milliseconds: 5),
          maxRetryDelay: const Duration(milliseconds: 10),
        );

        try {
          await engine.syncPendingOperations();
          await Future<void>.delayed(const Duration(milliseconds: 35));

          expect(repository.recoveryCallCount, greaterThanOrEqualTo(2));
          expect(remote.syncedOperations.length, greaterThanOrEqualTo(2));
          expect(
            repository.operations.single.status,
            PendingOperationStatus.synced,
          );
        } finally {
          engine.dispose();
        }
      },
    );

    test('automatically retries failed operations with a delay', () async {
      final operation = _createOperation(
        id: 1,
        operationId: 'operation-auto-retry',
        status: PendingOperationStatus.pending,
        retryCount: 0,
      );
      final repository = FakePendingOperationRepository(
        operations: [operation],
      );
      final remote = CountingFailureRemoteSyncDataSource();
      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
        automaticRetry: true,
        initialRetryDelay: const Duration(milliseconds: 5),
        maxRetryDelay: const Duration(milliseconds: 10),
      );

      try {
        await engine.syncPendingOperations();
        await Future<void>.delayed(const Duration(milliseconds: 35));

        expect(remote.attemptCount, greaterThanOrEqualTo(2));
        expect(
          repository.operations.single.status,
          PendingOperationStatus.failed,
        );
        expect(
          repository.operations.single.retryCount,
          greaterThanOrEqualTo(2),
        );
      } finally {
        engine.dispose();
      }
    });

    test('stops processing batches when an operation needs retry', () async {
      final operations = List.generate(
        60,
        (index) => _createOperation(
          id: index + 1,
          operationId: 'operation-${index + 1}',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        ),
      );

      final repository = FakePendingOperationRepository(operations: operations);
      final remote = FakeRemoteSyncDataSource(
        error: StateError('Simulated network failure'),
      );

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      expect(remote.syncedOperations, isEmpty);
      expect(repository.getPendingCallCount, 1);
      expect(
        repository.operations
            .take(50)
            .every(
              (operation) => operation.status == PendingOperationStatus.failed,
            ),
        isTrue,
      );
      expect(
        repository.operations
            .skip(50)
            .every(
              (operation) => operation.status == PendingOperationStatus.pending,
            ),
        isTrue,
      );
    });

    test('respects operation limit', () async {
      final operations = List.generate(
        3,
        (index) => _createOperation(
          id: index + 1,
          operationId: 'operation-00${index + 1}',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        ),
      );

      final repository = FakePendingOperationRepository(operations: operations);
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations(limit: 2);

      expect(remote.syncedOperations, hasLength(2));
      expect(remote.syncedOperations[0].operationId, 'operation-001');
      expect(remote.syncedOperations[1].operationId, 'operation-002');
      expect(repository.getPendingCallCount, 1);
      expect(
        repository.operations
            .singleWhere((operation) => operation.id == 3)
            .status,
        PendingOperationStatus.pending,
      );
    });

    test('processes multiple batches in a single sync call', () async {
      final operations = List.generate(
        120,
        (index) => _createOperation(
          id: index + 1,
          operationId: 'operation-${index + 1}',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        ),
      );

      final repository = FakePendingOperationRepository(operations: operations);
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      expect(remote.syncedOperations, hasLength(120));
      expect(repository.getPendingCallCount, 3);
      expect(
        repository.operations.every(
          (operation) => operation.status == PendingOperationStatus.synced,
        ),
        isTrue,
      );
    });

    test('does nothing when there are no pending operations', () async {
      final repository = FakePendingOperationRepository();
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      expect(remote.syncedOperations, isEmpty);
      expect(repository.statusUpdateCount, 0);
    });

    test('processes failed operations returned by repository', () async {
      final operation = _createOperation(
        id: 1,
        operationId: 'operation-001',
        status: PendingOperationStatus.failed,
        retryCount: 2,
      );

      final repository = FakePendingOperationRepository(
        operations: [operation],
      );
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      final result = repository.operations.single;

      expect(result.status, PendingOperationStatus.synced);
      expect(result.retryCount, 2);
    });

    test('recovers PROCESSING operations before syncing', () async {
      final operation = _createOperation(
        id: 1,
        operationId: 'operation-processing',
        status: PendingOperationStatus.processing,
        retryCount: 0,
      );

      final repository = FakePendingOperationRepository(
        operations: [operation],
      );
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      expect(repository.recoveryCallCount, 1);
      expect(remote.syncedOperations, hasLength(1));
      expect(
        remote.syncedOperations.single.operationId,
        'operation-processing',
      );
      expect(
        repository.operations.single.status,
        PendingOperationStatus.synced,
      );
    });

    test('recovers processing operations only once per engine', () async {
      final repository = FakePendingOperationRepository();
      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: FakeRemoteSyncDataSource(),
      );

      await engine.syncPendingOperations();
      await engine.syncPendingOperations();

      expect(repository.recoveryCallCount, 1);
      expect(repository.getPendingCallCount, 2);
    });

    test('retries recovery after recovery fails', () async {
      final repository = FakePendingOperationRepository()
        ..recoveryFailuresRemaining = 1;
      final remote = FakeRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await expectLater(
        engine.syncPendingOperations(),
        throwsA(isA<StateError>()),
      );

      expect(repository.recoveryCallCount, 1);
      expect(repository.getPendingCallCount, 0);
      expect(remote.syncedOperations, isEmpty);

      await engine.syncPendingOperations();

      expect(repository.recoveryCallCount, 2);
      expect(repository.getPendingCallCount, 1);
    });

    test(
      'writes one Firestore document when saving SYNCED status initially fails',
      () async {
        final operation = _createOperation(
          id: 1,
          operationId: 'operation-firestore-idempotency',
          status: PendingOperationStatus.pending,
          retryCount: 0,
        );
        final movement = Movement(
          id: 1,
          operationId: operation.operationId,
          type: MovementType.move,
          boxNo: 'BOX-001',
          partNo: 'PART-001',
          fromLocation: 'A-01',
          toLocation: 'B-02',
          quantity: 1,
          userId: 'worker-01',
          createdAt: DateTime(2026, 10, 1, 8, 30),
        );
        final firestore = FakeFirebaseFirestore();
        final repository = FakePendingOperationRepository(
          operations: [operation],
        )..statusUpdateFailuresRemaining = {PendingOperationStatus.synced: 1};
        final remote = FirestoreMovementSyncDataSource(
          movementRepository: _IdempotencyMovementRepository(movement),
          firestore: firestore,
        );
        final engine = SyncEngine(
          pendingOperationRepository: repository,
          remoteSyncDataSource: remote,
        );

        await engine.syncPendingOperations();

        expect(
          repository.operations.single.status,
          PendingOperationStatus.pending,
        );
        var snapshot = await firestore.collection('movements').get();
        expect(snapshot.docs, hasLength(1));
        expect(snapshot.docs.single.id, operation.operationId);

        await engine.syncPendingOperations();

        expect(
          repository.operations.single.status,
          PendingOperationStatus.synced,
        );
        snapshot = await firestore.collection('movements').get();
        expect(snapshot.docs, hasLength(1));
        expect(snapshot.docs.single.id, operation.operationId);
        expect(
          snapshot.docs.single.data()['operationId'],
          operation.operationId,
        );
      },
    );

    test('concurrent sync calls share the same future', () async {
      final operation = _createOperation(
        id: 1,
        operationId: 'operation-concurrent',
        status: PendingOperationStatus.pending,
        retryCount: 0,
      );

      final repository = FakePendingOperationRepository(
        operations: [operation],
      );
      final remote = BlockingRemoteSyncDataSource();

      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      final firstSync = engine.syncPendingOperations();
      final secondSync = engine.syncPendingOperations();

      expect(identical(firstSync, secondSync), isTrue);

      remote.completeSync();
      await Future.wait([firstSync, secondSync]);

      expect(repository.recoveryCallCount, 1);
      expect(remote.syncedOperations, hasLength(1));
      expect(
        repository.operations.single.status,
        PendingOperationStatus.synced,
      );
    });
  });
}

PendingOperation _createOperation({
  required int id,
  required String operationId,
  required PendingOperationStatus status,
  required int retryCount,
}) {
  return PendingOperation(
    id: id,
    operationId: operationId,
    type: 'INBOUND',
    entityType: 'MOVEMENT',
    entityId: '$id',
    payload: '{"boxNo":"HSF2609110012","quantity":400}',
    status: status,
    retryCount: retryCount,
    createdAt: DateTime(2026, 9, 24, 10, id),
  );
}

class FakeRemoteSyncDataSource implements RemoteSyncDataSource {
  FakeRemoteSyncDataSource({this.error});

  final Object? error;
  final List<PendingOperation> syncedOperations = [];

  @override
  Future<void> sync(PendingOperation operation) async {
    if (error != null) {
      throw error!;
    }

    syncedOperations.add(operation);
  }
}

class CountingFailureRemoteSyncDataSource implements RemoteSyncDataSource {
  int attemptCount = 0;

  @override
  Future<void> sync(PendingOperation operation) async {
    attemptCount++;
    throw Exception('Network unavailable');
  }
}

class SelectiveFailureRemoteSyncDataSource implements RemoteSyncDataSource {
  SelectiveFailureRemoteSyncDataSource({required this.failingOperationId});

  final String failingOperationId;
  final List<PendingOperation> syncedOperations = [];

  @override
  Future<void> sync(PendingOperation operation) async {
    if (operation.operationId == failingOperationId) {
      throw Exception('Network unavailable');
    }

    syncedOperations.add(operation);
  }
}

class FakePendingOperationRepository implements PendingOperationRepository {
  FakePendingOperationRepository({List<PendingOperation>? operations})
    : operations = List<PendingOperation>.from(operations ?? []);

  final List<PendingOperation> operations;
  int statusUpdateCount = 0;
  int recoveryCallCount = 0;
  int getPendingCallCount = 0;
  int recoveryFailuresRemaining = 0;
  Map<PendingOperationStatus, int> statusUpdateFailuresRemaining = {};

  @override
  Future<PendingOperation?> getById(int id) async {
    for (final operation in operations) {
      if (operation.id == id) {
        return operation;
      }
    }

    return null;
  }

  @override
  Future<PendingOperation?> getByOperationId(String operationId) async {
    for (final operation in operations) {
      if (operation.operationId == operationId) {
        return operation;
      }
    }

    return null;
  }

  @override
  Future<List<PendingOperation>> getPending({int limit = 50}) async {
    getPendingCallCount++;

    return operations
        .where(
          (operation) =>
              operation.status == PendingOperationStatus.pending ||
              operation.status == PendingOperationStatus.failed,
        )
        .take(limit)
        .toList();
  }

  @override
  Future<void> save(PendingOperation operation) async {
    operations.add(operation);
  }

  @override
  Future<void> updateStatus({
    required int id,
    required PendingOperationStatus status,
    DateTime? lastAttemptAt,
    String? lastError,
    int? retryCount,
  }) async {
    statusUpdateCount++;

    final failuresRemaining = statusUpdateFailuresRemaining[status] ?? 0;

    if (failuresRemaining > 0) {
      statusUpdateFailuresRemaining[status] = failuresRemaining - 1;
      throw StateError('Simulated status update failure: $status');
    }

    final index = operations.indexWhere((operation) => operation.id == id);

    if (index == -1) {
      return;
    }

    final current = operations[index];

    operations[index] = PendingOperation(
      id: current.id,
      operationId: current.operationId,
      type: current.type,
      entityType: current.entityType,
      entityId: current.entityId,
      payload: current.payload,
      status: status,
      retryCount: retryCount ?? current.retryCount,
      createdAt: current.createdAt,
      lastAttemptAt: lastAttemptAt ?? current.lastAttemptAt,
      lastError: lastError,
    );
  }

  @override
  Future<void> recoverProcessingOperations() async {
    recoveryCallCount++;

    if (recoveryFailuresRemaining > 0) {
      recoveryFailuresRemaining--;
      throw StateError('Simulated recovery failure');
    }

    for (var i = 0; i < operations.length; i++) {
      final current = operations[i];

      if (current.status != PendingOperationStatus.processing) {
        continue;
      }

      operations[i] = PendingOperation(
        id: current.id,
        operationId: current.operationId,
        type: current.type,
        entityType: current.entityType,
        entityId: current.entityId,
        payload: current.payload,
        status: PendingOperationStatus.pending,
        retryCount: current.retryCount,
        createdAt: current.createdAt,
        lastAttemptAt: current.lastAttemptAt,
        lastError: current.lastError,
      );
    }
  }
}

class BlockingRemoteSyncDataSource implements RemoteSyncDataSource {
  final Completer<void> _completer = Completer<void>();
  final List<PendingOperation> syncedOperations = [];

  void completeSync() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  @override
  Future<void> sync(PendingOperation operation) async {
    syncedOperations.add(operation);
    await _completer.future;
  }
}

class _IdempotencyMovementRepository implements MovementRepository {
  _IdempotencyMovementRepository(this.movement);

  final Movement movement;

  @override
  Future<Movement?> getById(int id) async =>
      movement.id == id ? movement : null;

  @override
  Future<Movement?> getByOperationId(String operationId) async =>
      movement.operationId == operationId ? movement : null;

  @override
  Future<List<Movement>> getByBoxNo(String boxNo) async => [];

  @override
  Future<List<Movement>> getByPartNo(String partNo) async => [];

  @override
  Future<void> save(Movement value) async {}
}
