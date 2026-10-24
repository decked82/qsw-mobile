import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/sync/data/data_sources/remote_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/services/sync_engine.dart';

void main() {
  late Database database;
  late SqlitePendingOperationRepository repository;

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

    repository = SqlitePendingOperationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'recovers PROCESSING operation left by a previous app instance',
    () async {
      final staleOperation = PendingOperation(
        id: 0,
        operationId: 'recovery-after-restart-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{"boxNo":"BOX-001","quantity":10}',
        status: PendingOperationStatus.processing,
        retryCount: 2,
        createdAt: DateTime(2026, 10, 20, 10),
        lastAttemptAt: DateTime(2026, 10, 20, 10, 5),
      );

      await repository.save(staleOperation);

      final beforeSync = await repository.getByOperationId(
        staleOperation.operationId,
      );

      expect(beforeSync, isNotNull);
      expect(beforeSync!.status, PendingOperationStatus.processing);

      final remote = _RecordingRemoteSyncDataSource();

      // A new engine instance simulates the app starting after a crash.
      final engine = SyncEngine(
        pendingOperationRepository: repository,
        remoteSyncDataSource: remote,
      );

      await engine.syncPendingOperations();

      final recovered = await repository.getByOperationId(
        staleOperation.operationId,
      );

      expect(remote.syncedOperations, hasLength(1));
      expect(
        remote.syncedOperations.single.operationId,
        staleOperation.operationId,
      );

      expect(recovered, isNotNull);
      expect(recovered!.status, PendingOperationStatus.synced);
      expect(recovered.retryCount, staleOperation.retryCount);
      expect(recovered.lastAttemptAt, isNotNull);
      expect(recovered.lastError, isNull);

      engine.dispose();
    },
  );
}

class _RecordingRemoteSyncDataSource implements RemoteSyncDataSource {
  final List<PendingOperation> syncedOperations = [];

  @override
  Future<void> sync(PendingOperation operation) async {
    syncedOperations.add(operation);
  }
}
