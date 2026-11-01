import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/core/database/sqlite/sqlite_database_provider.dart';
import 'package:qsw_mobile/features/parts/data/data_sources/sqlite_part_data_source.dart';
import 'package:qsw_mobile/features/parts/data/repositories/sqlite_part_repository.dart';
import 'package:qsw_mobile/features/parts/data/repositories/sqlite_part_save_repository.dart';
import 'package:qsw_mobile/features/parts/domain/entities/part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/add_part.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_part_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/services/sync_engine.dart';

void main() {
  const databaseName = 'qsw_parts_firestore_integration_test.db';

  late SqliteDatabaseProvider databaseProvider;
  late Database database;
  late SqlitePartRepository partRepository;
  late SqlitePendingOperationRepository pendingRepository;
  late AddPart addPart;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final databasePath = await getDatabasesPath();

    await deleteDatabase('$databasePath/$databaseName');

    databaseProvider = SqliteDatabaseProvider(databaseName: databaseName);

    database = await databaseProvider.database;

    final partDataSource = SqlitePartDataSource(databaseProvider);

    final saveRepository = SqlitePartSaveRepository(database, partDataSource);

    partRepository = SqlitePartRepository(
      partDataSource,
      saveRepository: saveRepository,
    );

    pendingRepository = SqlitePendingOperationRepository(database);

    addPart = AddPart(partRepository);
  });

  tearDown(() async {
    await databaseProvider.close();

    final databasePath = await getDatabasesPath();
    await deleteDatabase('$databasePath/$databaseName');
  });

  test(
    'adds part to SQLite, synchronizes it to Firestore and marks operation SYNCED',
    () async {
      const part = Part(
        partCode: 'INTEGRATION-PART-001',
        name: 'Integration Test Part',
        specification: 'Integration specification',
        barcode: '4901234567890',
        unit: 'EA',
      );

      // 1. Add a part through the real domain use case.
      final addedPart = await addPart(part);

      expect(addedPart.id, isNotNull);
      expect(addedPart.syncId, isNotNull);
      expect(addedPart.syncId, isNotEmpty);
      expect(addedPart.partCode, part.partCode);
      expect(addedPart.name, part.name);

      final syncId = addedPart.syncId!;

      // 2. Verify that the part was persisted in SQLite.
      final storedParts = await partRepository.getParts();

      expect(storedParts, hasLength(1));
      expect(storedParts.single.id, addedPart.id);
      expect(storedParts.single.syncId, syncId);
      expect(storedParts.single.partCode, part.partCode);

      // 3. Verify that the transactional outbox contains CREATE/PENDING.
      final pendingRows = await database.query(
        'pending_operations',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['PART', syncId],
      );

      expect(pendingRows, hasLength(1));

      final pendingRow = pendingRows.single;

      expect(pendingRow['type'], 'CREATE');
      expect(pendingRow['entity_type'], 'PART');
      expect(pendingRow['entity_id'], syncId);
      expect(pendingRow['status'], 'PENDING');
      expect(pendingRow['retry_count'], 0);

      final operationId = pendingRow['operation_id']! as String;

      final payload =
          jsonDecode(pendingRow['payload']! as String) as Map<String, dynamic>;

      expect(payload['sync_id'], syncId);
      expect(payload['part_code'], part.partCode);
      expect(payload['name'], part.name);
      expect(payload['is_deleted'], isFalse);
      expect(payload.containsKey('id'), isFalse);

      // 4. Configure the real PART Firestore data source.
      final firestore = FakeFirebaseFirestore();

      final partSyncDataSource = FirestorePartSyncDataSource(
        firestore: firestore,
      );

      // 5. Run the real SyncEngine against the SQLite outbox.
      final engine = SyncEngine(
        pendingOperationRepository: pendingRepository,
        remoteSyncDataSource: partSyncDataSource,
      );

      try {
        await engine.syncPendingOperations();

        // 6. Verify that the operation reached SYNCED in SQLite.
        final syncedOperation = await pendingRepository.getByOperationId(
          operationId,
        );

        expect(syncedOperation, isNotNull);
        expect(syncedOperation!.status, PendingOperationStatus.synced);
        expect(syncedOperation.retryCount, 0);
        expect(syncedOperation.lastAttemptAt, isNotNull);
        expect(syncedOperation.lastError, isNull);

        // 7. Verify the Firestore document using the stable sync_id.
        final document = await firestore.collection('parts').doc(syncId).get();

        expect(document.exists, isTrue);

        final remoteData = document.data()!;

        expect(remoteData['sync_id'], syncId);
        expect(remoteData['part_code'], part.partCode);
        expect(remoteData['name'], part.name);
        expect(remoteData['specification'], part.specification);
        expect(remoteData['barcode'], part.barcode);
        expect(remoteData['unit'], part.unit);
        expect(remoteData['is_deleted'], isFalse);
        expect(remoteData['synced_at'], isNotNull);

        // 8. A subsequent sync must not create another document.
        await engine.syncPendingOperations();

        final allRemoteParts = await firestore.collection('parts').get();

        expect(allRemoteParts.docs, hasLength(1));
        expect(allRemoteParts.docs.single.id, syncId);

        final operationAfterSecondSync = await pendingRepository
            .getByOperationId(operationId);

        expect(operationAfterSecondSync!.status, PendingOperationStatus.synced);
      } finally {
        engine.dispose();
      }
    },
  );
}
