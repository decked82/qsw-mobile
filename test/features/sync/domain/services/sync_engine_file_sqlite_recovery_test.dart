import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_movement_sync_data_source.dart';
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
      'qsw_sync_recovery_',
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

  Future<void> saveProcessingOperation(
    SqlitePendingOperationRepository repository,
    String operationId,
  ) async {
    await repository.save(_createOperation(operationId));

    final saved = await repository.getByOperationId(operationId);

    expect(saved, isNotNull);

    await repository.updateStatus(
      id: saved!.id,
      status: PendingOperationStatus.processing,
      lastAttemptAt: DateTime.now(),
    );

    final processing = await repository.getByOperationId(operationId);

    expect(processing, isNotNull);
    expect(processing!.status, PendingOperationStatus.processing);
  }

  test(
    'recovers PROCESSING from file SQLite after simulated process restart',
    () async {
      const operationId = 'file-recovery-before-remote-001';

      final movement = _createMovement(operationId);

      final firstDatabase = await openTestDatabase();
      final firstRepository = SqlitePendingOperationRepository(firstDatabase);

      await saveProcessingOperation(firstRepository, operationId);

      // Simulate termination of the first application process.
      await firstDatabase.close();

      // Reopen the same file-backed SQLite database.
      final restartedDatabase = await openTestDatabase();
      final restartedRepository = SqlitePendingOperationRepository(
        restartedDatabase,
      );

      final remote = FirestoreMovementSyncDataSource(
        movementRepository: _TestMovementRepository(movement),
        firestore: firestore,
      );

      final engine = SyncEngine(
        pendingOperationRepository: restartedRepository,
        remoteSyncDataSource: remote,
      );

      try {
        final persisted = await restartedRepository.getByOperationId(
          operationId,
        );

        expect(persisted, isNotNull);
        expect(persisted!.status, PendingOperationStatus.processing);

        await engine.syncPendingOperations();

        final recovered = await restartedRepository.getByOperationId(
          operationId,
        );

        expect(recovered, isNotNull);
        expect(recovered!.status, PendingOperationStatus.synced);

        final documents = await firestore.collection('movements').get();

        expect(documents.docs, hasLength(1));
        expect(documents.docs.single.id, operationId);
      } finally {
        engine.dispose();
        await restartedDatabase.close();
      }
    },
  );

  test(
    'retries Firestore write after restart without creating duplicate document',
    () async {
      const operationId = 'file-recovery-after-remote-001';

      final movement = _createMovement(operationId);

      final firstDatabase = await openTestDatabase();
      final firstRepository = SqlitePendingOperationRepository(firstDatabase);

      await saveProcessingOperation(firstRepository, operationId);

      final firstRemote = FirestoreMovementSyncDataSource(
        movementRepository: _TestMovementRepository(movement),
        firestore: firestore,
      );

      // Firestore accepts the write, but local status remains PROCESSING.
      await firstRemote.sync(_createOperation(operationId));

      final documentsAfterFirstWrite = await firestore
          .collection('movements')
          .get();

      expect(documentsAfterFirstWrite.docs, hasLength(1));
      expect(documentsAfterFirstWrite.docs.single.id, operationId);

      // Simulate termination before local SYNCED status is persisted.
      await firstDatabase.close();

      final recoveryDatabase = await openTestDatabase();
      final recoveryRepository = SqlitePendingOperationRepository(
        recoveryDatabase,
      );

      final persisted = await recoveryRepository.getByOperationId(operationId);

      expect(persisted, isNotNull);
      expect(persisted!.status, PendingOperationStatus.processing);

      final recoveryRemote = FirestoreMovementSyncDataSource(
        movementRepository: _TestMovementRepository(movement),
        firestore: firestore,
      );

      final recoveryEngine = SyncEngine(
        pendingOperationRepository: recoveryRepository,
        remoteSyncDataSource: recoveryRemote,
      );

      try {
        await recoveryEngine.syncPendingOperations();

        final recovered = await recoveryRepository.getByOperationId(
          operationId,
        );

        expect(recovered, isNotNull);
        expect(recovered!.status, PendingOperationStatus.synced);

        final documents = await firestore.collection('movements').get();

        expect(documents.docs, hasLength(1));
        expect(documents.docs.single.id, operationId);
        expect(documents.docs.single.data()['operationId'], operationId);
      } finally {
        recoveryEngine.dispose();
        await recoveryDatabase.close();
      }
    },
  );
}

PendingOperation _createOperation(String operationId) {
  return PendingOperation(
    id: 0,
    operationId: operationId,
    type: 'MOVE',
    entityType: 'MOVEMENT',
    entityId: '1',
    payload: '{"boxNo":"BOX-001","quantity":1}',
    status: PendingOperationStatus.pending,
    retryCount: 0,
    createdAt: DateTime(2026, 11, 1, 10),
  );
}

Movement _createMovement(String operationId) {
  return Movement(
    id: 1,
    operationId: operationId,
    type: MovementType.move,
    boxNo: 'BOX-001',
    partNo: 'PART-001',
    fromLocation: 'A-01',
    toLocation: 'B-02',
    quantity: 1,
    userId: 'worker-01',
    createdAt: DateTime(2026, 11, 1, 10),
  );
}

class _TestMovementRepository implements MovementRepository {
  _TestMovementRepository(this.movement);

  final Movement movement;

  @override
  Future<Movement?> getById(int id) async {
    return movement.id == id ? movement : null;
  }

  @override
  Future<Movement?> getByOperationId(String operationId) async {
    return movement.operationId == operationId ? movement : null;
  }

  @override
  Future<List<Movement>> getByBoxNo(String boxNo) async => [];

  @override
  Future<List<Movement>> getByPartNo(String partNo) async => [];

  @override
  Future<void> save(Movement value) async {}
}
