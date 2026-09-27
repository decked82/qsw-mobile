import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../movements/domain/entities/movement.dart';
import '../../../movements/domain/repositories/movement_repository.dart';
import '../../domain/entities/pending_operation.dart';
import 'remote_sync_data_source.dart';

class FirestoreMovementSyncDataSource implements RemoteSyncDataSource {
  FirestoreMovementSyncDataSource({
    required this._movementRepository,
    required this._firestore,
  });

  final MovementRepository _movementRepository;
  final FirebaseFirestore _firestore;

  @override
  Future<void> sync(PendingOperation operation) async {
    if (operation.entityType != 'MOVEMENT') {
      throw ArgumentError('Unsupported entity type: ${operation.entityType}');
    }

    final movement = await _movementRepository.getByOperationId(
      operation.operationId,
    );

    if (movement == null) {
      throw StateError(
        'Movement not found for operationId: '
        '${operation.operationId}',
      );
    }

    await _syncMovement(movement);
  }

  Future<void> _syncMovement(Movement movement) async {
    final document = _firestore
        .collection('movements')
        .doc(movement.operationId);

    await document.set(_toFirestoreMap(movement));
  }

  Map<String, Object?> _toFirestoreMap(Movement movement) {
    return {
      'movementId': movement.operationId,
      'operationId': movement.operationId,
      'type': _movementTypeToString(movement.type),
      'boxNo': movement.boxNo,
      'partNo': movement.partNo,
      'fromLocation': movement.fromLocation,
      'toLocation': movement.toLocation,
      'quantity': movement.quantity,
      'userId': movement.userId,
      'createdAt': Timestamp.fromDate(movement.createdAt),
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }

  String _movementTypeToString(MovementType type) {
    return switch (type) {
      MovementType.inbound => 'INBOUND',
      MovementType.outbound => 'OUTBOUND',
      MovementType.move => 'MOVE',
      MovementType.adjustment => 'ADJUSTMENT',
    };
  }
}
