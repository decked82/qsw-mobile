import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/inbound_transaction.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/inbound_transaction_repository.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_inbound_transaction_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

class _FakeInboundTransactionRepository
    implements InboundTransactionRepository {
  _FakeInboundTransactionRepository(this.transaction);

  final InboundTransaction? transaction;

  @override
  Future<InboundTransaction?> getByOperationId(String operationId) async =>
      transaction?.operationId == operationId ? transaction : null;

  @override
  Future<InboundTransaction?> getById(int id) async =>
      transaction?.id == id ? transaction : null;

  @override
  Future<List<InboundTransaction>> getByBoxNo(String boxNo) async => [];

  @override
  Future<List<InboundTransaction>> getByPartNo(String partNo) async => [];

  @override
  Future<void> save(InboundTransaction value) async {}
}

PendingOperation _operation({
  String operationId = 'inbound-op-001',
  String entityType = 'INBOUND_TRANSACTION',
}) {
  return PendingOperation(
    id: 1,
    operationId: operationId,
    type: 'INBOUND',
    entityType: entityType,
    entityId: operationId,
    payload: '{}',
    status: PendingOperationStatus.pending,
    retryCount: 0,
    createdAt: DateTime(2026, 10, 1, 9),
  );
}

InboundTransaction _transaction({String operationId = 'inbound-op-001'}) {
  return InboundTransaction(
    id: 22,
    operationId: operationId,
    boxNo: 'BOX-002',
    partNo: 'PART-002',
    quantity: 12,
    location: 'C-03',
    userId: 'worker-02',
    createdAt: DateTime(2026, 10, 1, 8, 45),
  );
}

void main() {
  group('FirestoreInboundTransactionSyncDataSource', () {
    test('writes the transaction to a document keyed by operationId', () async {
      final firestore = FakeFirebaseFirestore();
      final transaction = _transaction();
      final source = FirestoreInboundTransactionSyncDataSource(
        inboundTransactionRepository: _FakeInboundTransactionRepository(
          transaction,
        ),
        firestore: firestore,
      );

      await source.sync(_operation());

      final snapshot = await firestore
          .collection('inbound_transactions')
          .doc(transaction.operationId)
          .get();
      expect(snapshot.exists, isTrue);
      final data = snapshot.data()!;
      expect(data['operationId'], transaction.operationId);
      expect(data['boxNo'], 'BOX-002');
      expect(data['partNo'], 'PART-002');
      expect(data['quantity'], 12);
      expect(data['location'], 'C-03');
      expect(data['userId'], 'worker-02');
      expect((data['createdAt'] as dynamic).toDate(), transaction.createdAt);
    });

    test('repeated sync uses one stable document', () async {
      final firestore = FakeFirebaseFirestore();
      final transaction = _transaction();
      final source = FirestoreInboundTransactionSyncDataSource(
        inboundTransactionRepository: _FakeInboundTransactionRepository(
          transaction,
        ),
        firestore: firestore,
      );

      await source.sync(_operation());
      await source.sync(_operation());

      final snapshot = await firestore.collection('inbound_transactions').get();
      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.single.id, transaction.operationId);
    });

    test('rejects unsupported entity type', () async {
      final source = FirestoreInboundTransactionSyncDataSource(
        inboundTransactionRepository: _FakeInboundTransactionRepository(
          _transaction(),
        ),
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        source.sync(_operation(entityType: 'BOX')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when local transaction is missing', () async {
      final source = FirestoreInboundTransactionSyncDataSource(
        inboundTransactionRepository: _FakeInboundTransactionRepository(null),
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(source.sync(_operation()), throwsA(isA<StateError>()));
    });
  });
}
