import 'dart:convert';

import '../entities/movement.dart';
import '../repositories/movement_repository.dart';
import '../../../sync/domain/entities/pending_operation.dart';
import '../../../sync/domain/repositories/pending_operation_repository.dart';

class SaveMovement {
  const SaveMovement({
    required this.movementRepository,
    required this.pendingOperationRepository,
  });

  final MovementRepository movementRepository;
  final PendingOperationRepository pendingOperationRepository;

  Future<void> call(Movement movement) async {
    await movementRepository.save(movement);

    final pendingOperation = PendingOperation(
      id: 0,
      operationId: movement.operationId,
      type: _movementTypeToOperationType(movement.type),
      entityType: 'MOVEMENT',
      entityId: movement.operationId,
      payload: jsonEncode(_movementToMap(movement)),
      status: PendingOperationStatus.pending,
      retryCount: 0,
      createdAt: movement.createdAt,
    );

    await pendingOperationRepository.save(pendingOperation);
  }

  String _movementTypeToOperationType(MovementType type) {
    return switch (type) {
      MovementType.inbound => 'INBOUND',
      MovementType.outbound => 'OUTBOUND',
      MovementType.move => 'MOVE',
      MovementType.adjustment => 'ADJUSTMENT',
    };
  }

  Map<String, Object?> _movementToMap(Movement movement) {
    return {
      'operationId': movement.operationId,
      'type': _movementTypeToOperationType(movement.type),
      'boxNo': movement.boxNo,
      'partNo': movement.partNo,
      'fromLocation': movement.fromLocation,
      'toLocation': movement.toLocation,
      'quantity': movement.quantity,
      'userId': movement.userId,
      'createdAt': movement.createdAt.toIso8601String(),
    };
  }
}
