import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_movement_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

class _FakeMovementRepository implements MovementRepository {
  _FakeMovementRepository(this.movement);

  final Movement? movement;

  @override
  Future<Movement?> getByOperationId(String operationId) async =>
      movement?.operationId == operationId ? movement : null;

  @override
  Future<Movement?> getById(int id) async =>
      movement?.id == id ? movement : null;

  @override
  Future<List<Movement>> getByBoxNo(String boxNo) async => [];

  @override
  Future<List<Movement>> getByPartNo(String partNo) async => [];

  @override
  Future<void> save(Movement value) async {}
}

PendingOperation _operation({
  String operationId = 'movement-op-001',
  String entityType = 'MOVEMENT',
}) {
  return PendingOperation(
    id: 1,
    operationId: operationId,
    type: 'MOVE',
    entityType: entityType,
    entityId: operationId,
    payload: '{}',
    status: PendingOperationStatus.pending,
    retryCount: 0,
    createdAt: DateTime(2026, 10, 1, 9),
  );
}

Movement _movement({String operationId = 'movement-op-001'}) {
  return Movement(
    id: 11,
    operationId: operationId,
    type: MovementType.move,
    boxNo: 'BOX-001',
    partNo: 'PART-001',
    fromLocation: 'A-01',
    toLocation: 'B-02',
    quantity: 7,
    userId: 'worker-01',
    createdAt: DateTime(2026, 10, 1, 8, 30),
  );
}

void main() {
  group('FirestoreMovementSyncDataSource', () {
    test('writes the movement to a document keyed by operationId', () async {
      final firestore = FakeFirebaseFirestore();
      final movement = _movement();
      final source = FirestoreMovementSyncDataSource(
        movementRepository: _FakeMovementRepository(movement),
        firestore: firestore,
      );

      await source.sync(_operation());

      final snapshot = await firestore
          .collection('movements')
          .doc(movement.operationId)
          .get();
      expect(snapshot.exists, isTrue);
      final data = snapshot.data()!;
      expect(data['movementId'], movement.operationId);
      expect(data['operationId'], movement.operationId);
      expect(data['type'], 'MOVE');
      expect(data['boxNo'], 'BOX-001');
      expect(data['partNo'], 'PART-001');
      expect(data['fromLocation'], 'A-01');
      expect(data['toLocation'], 'B-02');
      expect(data['quantity'], 7);
      expect(data['userId'], 'worker-01');
      expect((data['createdAt'] as dynamic).toDate(), movement.createdAt);
    });

    test('repeated sync uses one stable document', () async {
      final firestore = FakeFirebaseFirestore();
      final movement = _movement();
      final source = FirestoreMovementSyncDataSource(
        movementRepository: _FakeMovementRepository(movement),
        firestore: firestore,
      );

      await source.sync(_operation());
      await source.sync(_operation());

      final snapshot = await firestore.collection('movements').get();
      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.single.id, movement.operationId);
    });

    test('rejects unsupported entity type', () async {
      final source = FirestoreMovementSyncDataSource(
        movementRepository: _FakeMovementRepository(_movement()),
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        source.sync(_operation(entityType: 'BOX')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when local movement is missing', () async {
      final source = FirestoreMovementSyncDataSource(
        movementRepository: _FakeMovementRepository(null),
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(source.sync(_operation()), throwsA(isA<StateError>()));
    });
  });
}
