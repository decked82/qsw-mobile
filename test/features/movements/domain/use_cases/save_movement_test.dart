import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/movements/domain/use_cases/save_movement.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/pending_operation_repository.dart';

class _FakeMovementRepository implements MovementRepository {
  Movement? savedMovement;

  @override
  Future<Movement?> getById(int id) async {
    return null;
  }

  @override
  Future<Movement?> getByOperationId(String operationId) async {
    return null;
  }

  @override
  Future<List<Movement>> getByBoxNo(String boxNo) async {
    return [];
  }

  @override
  Future<List<Movement>> getByPartNo(String partNo) async {
    return [];
  }

  @override
  Future<void> save(Movement movement) async {
    savedMovement = movement;
  }
}

class _FakePendingOperationRepository implements PendingOperationRepository {
  PendingOperation? savedOperation;

  @override
  Future<PendingOperation?> getById(int id) async {
    return null;
  }

  @override
  Future<PendingOperation?> getByOperationId(String operationId) async {
    return null;
  }

  @override
  Future<List<PendingOperation>> getPending({int limit = 50}) async {
    return [];
  }

  @override
  Future<void> save(PendingOperation operation) async {
    savedOperation = operation;
  }

  @override
  Future<void> updateStatus({
    required int id,
    required PendingOperationStatus status,
    DateTime? lastAttemptAt,
    String? lastError,
    int? retryCount,
  }) async {}
}

void main() {
  test('saves movement and creates pending operation', () async {
    final movementRepository = _FakeMovementRepository();
    final pendingOperationRepository = _FakePendingOperationRepository();

    final movement = Movement(
      id: 1,
      operationId: 'OP-001',
      type: MovementType.inbound,
      boxNo: 'BOX-001',
      partNo: 'PART-001',
      quantity: 10,
      createdAt: DateTime(2026, 1, 1),
    );

    final useCase = SaveMovement(
      movementRepository: movementRepository,
      pendingOperationRepository: pendingOperationRepository,
    );

    await useCase(movement);

    expect(movementRepository.savedMovement, same(movement));

    final operation = pendingOperationRepository.savedOperation;

    expect(operation, isNotNull);
    expect(operation!.operationId, 'OP-001');
    expect(operation.type, 'INBOUND');
    expect(operation.entityType, 'MOVEMENT');
    expect(operation.entityId, 'OP-001');
    expect(operation.status, PendingOperationStatus.pending);
    expect(operation.retryCount, 0);
    expect(operation.createdAt, movement.createdAt);

    final payload = jsonDecode(operation.payload) as Map<String, dynamic>;

    expect(payload['operationId'], 'OP-001');
    expect(payload['type'], 'INBOUND');
    expect(payload['boxNo'], 'BOX-001');
    expect(payload['partNo'], 'PART-001');
    expect(payload['quantity'], 10);
  });
}
