import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/inbound_transaction_repository.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_inbound_transaction_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_movement_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_part_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_remote_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

class _UnusedMovementRepository implements MovementRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedInboundTransactionRepository
    implements InboundTransactionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirestoreRemoteSyncDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreRemoteSyncDataSource dataSource;

    setUp(() {
      firestore = FakeFirebaseFirestore();

      dataSource = FirestoreRemoteSyncDataSource(
        movementSyncDataSource: FirestoreMovementSyncDataSource(
          movementRepository: _UnusedMovementRepository(),
          firestore: firestore,
        ),
        inboundTransactionSyncDataSource:
            FirestoreInboundTransactionSyncDataSource(
              inboundTransactionRepository:
                  _UnusedInboundTransactionRepository(),
              firestore: firestore,
            ),
        partSyncDataSource: FirestorePartSyncDataSource(firestore: firestore),
      );
    });

    test('routes PART operation to FirestorePartSyncDataSource', () async {
      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-part-001',
        type: 'CREATE',
        entityType: 'PART',
        entityId: 'part-sync-001',
        payload: '''
          {
            "sync_id": "part-sync-001",
            "part_no": "PART-001",
            "is_deleted": false,
            "updated_at": "2026-10-28T10:00:00.000Z"
          }
        ''',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime.utc(2026, 10, 28, 10),
      );

      await dataSource.sync(operation);

      final document = await firestore
          .collection('parts')
          .doc('part-sync-001')
          .get();

      expect(document.exists, isTrue);
      expect(document.data()?['sync_id'], 'part-sync-001');
      expect(document.data()?['part_no'], 'PART-001');
      expect(document.data()?['is_deleted'], isFalse);
    });

    test('rejects unsupported entity type', () async {
      final operation = PendingOperation(
        id: 2,
        operationId: 'operation-unsupported-001',
        type: 'CREATE',
        entityType: 'UNKNOWN',
        entityId: 'unknown-001',
        payload: '{}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime.utc(2026, 10, 28, 10),
      );

      expect(() => dataSource.sync(operation), throwsA(isA<ArgumentError>()));
    });
  });
}
