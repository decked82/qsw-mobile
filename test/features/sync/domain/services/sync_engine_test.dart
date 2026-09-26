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
    return operations.take(limit).toList();
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
}
