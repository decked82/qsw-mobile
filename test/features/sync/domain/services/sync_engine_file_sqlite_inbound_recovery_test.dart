import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/movements/data/repositories/sqlite_inbound_transaction_repository.dart';
import 'package:qsw_mobile/features/movements/domain/entities/inbound_transaction.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_inbound_transaction_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/services/sync_engine.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;
  late FakeFirebaseFirestore firestore;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'qsw_inbound_recovery_',
    );
    databasePath = '${temporaryDirectory.path}/qsw_test.db';
    firestore = FakeFirebaseFirestore();
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  Future<Database> openTestDatabase() {
    return databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE inbound_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              operation_id TEXT NOT NULL UNIQUE,
              box_no TEXT NOT NULL,
              part_no TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              location TEXT NOT NULL,
              user_id TEXT,
              created_at TEXT NOT NULL
            )
          ''');

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
        },
      ),
    );
  }

  test(
    'recovers inbound transaction from file SQLite after simulated process restart',
    () async {
      const operationId = 'inbound-file-recovery-001';

      final transaction = InboundTransaction(
        id: 0,
        operationId: operationId,
        boxNo: 'BOX-RECOVERY-001',
        partNo: 'PART-RECOVERY-001',
        quantity: 25,
        location: 'A-01-03',
        userId: 'worker-01',
        createdAt: DateTime(2026, 11, 16, 10, 30),
      );

      final operation = PendingOperation(
        id: 0,
        operationId: operationId,
        type: 'INBOUND',
        entityType: 'INBOUND_TRANSACTION',
        entityId: operationId,
        payload: '{"operationId":"$operationId"}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: transaction.createdAt,
      );

      // First application process: persist the inbound transaction and outbox.
      final firstDatabase = await openTestDatabase();

      final firstInboundRepository = SqliteInboundTransactionRepository(
        firstDatabase,
      );
      final firstPendingRepository = SqlitePendingOperationRepository(
        firstDatabase,
      );

      await firstInboundRepository.save(transaction);
      await firstPendingRepository.save(operation);

      final savedOperation = await firstPendingRepository.getByOperationId(
        operationId,
      );

      expect(savedOperation, isNotNull);

      await firstPendingRepository.updateStatus(
        id: savedOperation!.id,
        status: PendingOperationStatus.processing,
        lastAttemptAt: DateTime.now(),
      );

      // Confirm PROCESSING was persisted before termination.
      final processingOperation = await firstPendingRepository.getByOperationId(
        operationId,
      );

      expect(processingOperation, isNotNull);
      expect(processingOperation!.status, PendingOperationStatus.processing);

      // Simulate termination of the application process.
      await firstDatabase.close();

      // Second application process: reopen the same SQLite file.
      final restartedDatabase = await openTestDatabase();

      final restartedInboundRepository = SqliteInboundTransactionRepository(
        restartedDatabase,
      );
      final restartedPendingRepository = SqlitePendingOperationRepository(
        restartedDatabase,
      );

      final remote = FirestoreInboundTransactionSyncDataSource(
        inboundTransactionRepository: restartedInboundRepository,
        firestore: firestore,
      );

      final engine = SyncEngine(
        pendingOperationRepository: restartedPendingRepository,
        remoteSyncDataSource: remote,
      );

      try {
        // Verify that the actual inbound transaction survived the restart.
        final persistedTransaction = await restartedInboundRepository
            .getByOperationId(operationId);

        expect(persistedTransaction, isNotNull);
        expect(persistedTransaction!.operationId, operationId);
        expect(persistedTransaction.boxNo, transaction.boxNo);
        expect(persistedTransaction.partNo, transaction.partNo);
        expect(persistedTransaction.quantity, transaction.quantity);
        expect(persistedTransaction.location, transaction.location);
        expect(persistedTransaction.userId, transaction.userId);

        // Verify that the outbox operation also survived the restart.
        final persistedOperation = await restartedPendingRepository
            .getByOperationId(operationId);

        expect(persistedOperation, isNotNull);
        expect(persistedOperation!.status, PendingOperationStatus.processing);

        // New SyncEngine must recover PROCESSING and synchronize the operation.
        await engine.syncPendingOperations();

        final recoveredOperation = await restartedPendingRepository
            .getByOperationId(operationId);

        expect(recoveredOperation, isNotNull);
        expect(recoveredOperation!.status, PendingOperationStatus.synced);

        // Verify that Firestore received the data read from reopened SQLite.
        final document = await firestore
            .collection('inbound_transactions')
            .doc(operationId)
            .get();

        expect(document.exists, isTrue);

        final data = document.data()!;

        expect(data['operationId'], operationId);
        expect(data['boxNo'], transaction.boxNo);
        expect(data['partNo'], transaction.partNo);
        expect(data['quantity'], transaction.quantity);
        expect(data['location'], transaction.location);
        expect(data['userId'], transaction.userId);

        expect((data['createdAt'] as dynamic).toDate(), transaction.createdAt);

        // Verify that the stable operationId prevents duplicate documents.
        final documents = await firestore
            .collection('inbound_transactions')
            .get();

        expect(documents.docs, hasLength(1));
        expect(documents.docs.single.id, operationId);
      } finally {
        engine.dispose();
        await restartedDatabase.close();
      }
    },
  );
}
