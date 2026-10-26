import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_save_repository.dart';
import 'package:qsw_mobile/features/movements/domain/use_cases/save_movement.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

class _FakeMovementSaveRepository implements MovementSaveRepository {
  Movement? savedMovement;
  PendingOperation? savedOperation;
  Object? error;

  @override
  Future<void> saveAtomically({
    required Movement movement,
    required PendingOperation pendingOperation,
  }) async {
    if (error != null) throw error!;
    savedMovement = movement;
    savedOperation = pendingOperation;
  }
}

void main() {
  test('saves movement and creates pending operation atomically', () async {
    final repository = _FakeMovementSaveRepository();
    final movement = Movement(
      id: 1,
      operationId: 'OP-001',
      type: MovementType.inbound,
      boxNo: 'BOX-001',
      partNo: 'PART-001',
      quantity: 10,
      createdAt: DateTime(2026, 1, 1),
    );
    final useCase = SaveMovement(movementSaveRepository: repository);
    await useCase(movement);

    expect(repository.savedMovement, same(movement));
    final operation = repository.savedOperation;
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

  test('propagates atomic persistence failure', () async {
    final repository = _FakeMovementSaveRepository()
      ..error = StateError('database write failed');
    final movement = Movement(
      id: 0,
      operationId: 'OP-002',
      type: MovementType.outbound,
      boxNo: 'BOX-002',
      partNo: 'PART-002',
      quantity: 2,
      createdAt: DateTime(2026, 1, 2),
    );
    final useCase = SaveMovement(movementSaveRepository: repository);

    await expectLater(() => useCase(movement), throwsA(isA<StateError>()));
    expect(repository.savedMovement, isNull);
    expect(repository.savedOperation, isNull);
  });
}
