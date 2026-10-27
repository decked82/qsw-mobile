import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/movements/domain/entities/inbound_transaction.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/inbound_transaction_repository.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_inbound_transaction_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/services/sync_engine.dart';

class _FakeInboundTransactionRepository
    implements InboundTransactionRepository {
  _FakeInboundTransactionRepository(this.transaction);

  final InboundTransaction transaction;

  @override
  Future<InboundTransaction?> getByOperationId(String operationId) async {
    return transaction.operationId == operationId ? transaction : null;
  }

  @override
  Future<InboundTransaction?> getById(int id) async {
    return transaction.id == id ? transaction : null;
  }

  @override
  Future<List<InboundTransaction>> getByBoxNo(String boxNo) async => [];

  @override
  Future<List<InboundTransaction>> getByPartNo(String partNo) async => [];

  @override
  Future<void> save(InboundTransaction value) async {}
}

void main() {
  late Database database;
  late SqlitePendingOperationRepository pendingRepository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    await database.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT,
        last_error TEXT
      )
    ''');

    pendingRepository = SqlitePendingOperationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'recovers PROCESSING inbound transaction and writes it to Firestore',
    () async {
      const operationId = 'inbound-recovery-001';

      final transaction = InboundTransaction(
        id: 22,
        operationId: operationId,
        boxNo: 'BOX-002',
        partNo: 'PART-002',
        quantity: 12,
        location: 'C-03',
        userId: 'worker-02',
        createdAt: DateTime(2026, 10, 20, 8, 45),
      );

      final staleOperation = PendingOperation(
        id: 0,
        operationId: operationId,
        type: 'INBOUND',
        entityType: 'INBOUND_TRANSACTION',
        entityId: transaction.id.toString(),
        payload: '{"boxNo":"BOX-002","quantity":12}',
        status: PendingOperationStatus.processing,
        retryCount: 2,
        createdAt: DateTime(2026, 10, 20, 8),
        lastAttemptAt: DateTime(2026, 10, 20, 8, 5),
      );

      await pendingRepository.save(staleOperation);

      final beforeSync = await pendingRepository.getByOperationId(operationId);

      expect(beforeSync, isNotNull);
      expect(beforeSync!.status, PendingOperationStatus.processing);

      final firestore = FakeFirebaseFirestore();

      final remoteDataSource = FirestoreInboundTransactionSyncDataSource(
        inboundTransactionRepository: _FakeInboundTransactionRepository(
          transaction,
        ),
        firestore: firestore,
      );

      // A fresh engine models the next application instance.
      final engine = SyncEngine(
        pendingOperationRepository: pendingRepository,
        remoteSyncDataSource: remoteDataSource,
      );

      try {
        await engine.syncPendingOperations();

        final recovered = await pendingRepository.getByOperationId(operationId);

        expect(recovered, isNotNull);
        expect(recovered!.status, PendingOperationStatus.synced);
        expect(recovered.retryCount, staleOperation.retryCount);
        expect(recovered.lastAttemptAt, isNotNull);
        expect(recovered.lastError, isNull);

        final snapshot = await firestore
            .collection('inbound_transactions')
            .doc(operationId)
            .get();

        expect(snapshot.exists, isTrue);

        final data = snapshot.data()!;
        expect(data['operationId'], operationId);
        expect(data['boxNo'], transaction.boxNo);
        expect(data['partNo'], transaction.partNo);
        expect(data['quantity'], transaction.quantity);
        expect(data['location'], transaction.location);
        expect(data['userId'], transaction.userId);
        expect((data['createdAt'] as dynamic).toDate(), transaction.createdAt);

        final allDocuments = await firestore
            .collection('inbound_transactions')
            .get();

        expect(allDocuments.docs, hasLength(1));
      } finally {
        engine.dispose();
      }
    },
  );
}
