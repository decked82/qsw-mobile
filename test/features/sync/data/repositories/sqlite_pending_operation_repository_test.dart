import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

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

    await database.execute('''
      CREATE INDEX idx_pending_operations_status
      ON pending_operations(status)
    ''');

    await database.execute('''
      CREATE INDEX idx_pending_operations_created_at
      ON pending_operations(created_at)
    ''');

    repository = SqlitePendingOperationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SqlitePendingOperationRepository', () {
    test('saves and retrieves operation by id', () async {
      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{"boxNo":"HSF2609110012","quantity":400}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(operation);

      final result = await repository.getById(1);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.operationId, 'operation-001');
      expect(result.type, 'INBOUND');
      expect(result.entityType, 'MOVEMENT');
      expect(result.entityId, '1');
      expect(result.payload, '{"boxNo":"HSF2609110012","quantity":400}');
      expect(result.status, PendingOperationStatus.pending);
      expect(result.retryCount, 0);
      expect(result.createdAt, DateTime(2026, 9, 21, 10, 30));
      expect(result.lastAttemptAt, isNull);
      expect(result.lastError, isNull);
    });

    test('save with id 0 lets SQLite generate the primary key', () async {
      final operation = PendingOperation(
        id: 0,
        operationId: 'operation-000',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: 'operation-000',
        payload: '{}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(operation);

      final result = await repository.getByOperationId('operation-000');

      expect(result, isNotNull);
      expect(result!.id, isNot(0));
      expect(result.operationId, 'operation-000');
    });

    test('returns null when operation does not exist', () async {
      final result = await repository.getById(999);

      expect(result, isNull);
    });

    test('retrieves operation by operation id', () async {
      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(operation);

      final result = await repository.getByOperationId('operation-001');

      expect(result, isNotNull);
      expect(result!.operationId, 'operation-001');
    });

    test('retrieves pending and failed operations in creation order', () async {
      final pending = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      final processing = PendingOperation(
        id: 2,
        operationId: 'operation-002',
        type: 'MOVE',
        entityType: 'MOVEMENT',
        entityId: '2',
        payload: '{}',
        status: PendingOperationStatus.processing,
        retryCount: 1,
        createdAt: DateTime(2026, 9, 21, 10, 31),
      );

      final failed = PendingOperation(
        id: 3,
        operationId: 'operation-003',
        type: 'OUTBOUND',
        entityType: 'MOVEMENT',
        entityId: '3',
        payload: '{}',
        status: PendingOperationStatus.failed,
        retryCount: 2,
        createdAt: DateTime(2026, 9, 21, 10, 32),
      );

      final synced = PendingOperation(
        id: 4,
        operationId: 'operation-004',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '4',
        payload: '{}',
        status: PendingOperationStatus.synced,
        retryCount: 1,
        createdAt: DateTime(2026, 9, 21, 10, 33),
      );

      await repository.save(pending);
      await repository.save(processing);
      await repository.save(failed);
      await repository.save(synced);

      final result = await repository.getPending();

      expect(result, hasLength(2));
      expect(result[0].operationId, 'operation-001');
      expect(result[1].operationId, 'operation-003');
    });

    test('respects pending operation limit', () async {
      for (var i = 1; i <= 3; i++) {
        await repository.save(
          PendingOperation(
            id: i,
            operationId: 'operation-00$i',
            type: 'INBOUND',
            entityType: 'MOVEMENT',
            entityId: '$i',
            payload: '{}',
            status: PendingOperationStatus.pending,
            retryCount: 0,
            createdAt: DateTime(2026, 9, 21, 10, i),
          ),
        );
      }

      final result = await repository.getPending(limit: 2);

      expect(result, hasLength(2));
      expect(result[0].operationId, 'operation-001');
      expect(result[1].operationId, 'operation-002');
    });

    test('updates operation status to processing', () async {
      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(operation);

      final attemptAt = DateTime(2026, 9, 21, 10, 35);

      await repository.updateStatus(
        id: 1,
        status: PendingOperationStatus.processing,
        lastAttemptAt: attemptAt,
      );

      final result = await repository.getById(1);

      expect(result, isNotNull);
      expect(result!.status, PendingOperationStatus.processing);
      expect(result.lastAttemptAt, attemptAt);
      expect(result.lastError, isNull);
      expect(result.retryCount, 0);
    });

    test('updates operation status to failed with error', () async {
      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{}',
        status: PendingOperationStatus.processing,
        retryCount: 1,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(operation);

      final attemptAt = DateTime(2026, 9, 21, 10, 36);

      await repository.updateStatus(
        id: 1,
        status: PendingOperationStatus.failed,
        lastAttemptAt: attemptAt,
        lastError: 'Network unavailable',
      );

      final result = await repository.getById(1);

      expect(result, isNotNull);
      expect(result!.status, PendingOperationStatus.failed);
      expect(result.lastAttemptAt, attemptAt);
      expect(result.lastError, 'Network unavailable');
      expect(result.retryCount, 1);
    });

    test('updates retry count', () async {
      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{}',
        status: PendingOperationStatus.failed,
        retryCount: 1,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(operation);

      final attemptAt = DateTime(2026, 9, 21, 10, 40);

      await repository.updateStatus(
        id: 1,
        status: PendingOperationStatus.failed,
        lastAttemptAt: attemptAt,
        lastError: 'Network unavailable',
        retryCount: 2,
      );

      final result = await repository.getById(1);

      expect(result, isNotNull);
      expect(result!.status, PendingOperationStatus.failed);
      expect(result.retryCount, 2);
      expect(result.lastAttemptAt, attemptAt);
      expect(result.lastError, 'Network unavailable');
    });

    test('updates operation status to synced', () async {
      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{}',
        status: PendingOperationStatus.processing,
        retryCount: 1,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(operation);

      await repository.updateStatus(
        id: 1,
        status: PendingOperationStatus.synced,
      );

      final result = await repository.getById(1);

      expect(result, isNotNull);
      expect(result!.status, PendingOperationStatus.synced);
      expect(result.retryCount, 1);
    });

    test('does not allow duplicate operation id', () async {
      final first = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      final duplicate = PendingOperation(
        id: 2,
        operationId: 'operation-001',
        type: 'MOVE',
        entityType: 'MOVEMENT',
        entityId: '2',
        payload: '{}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 21, 10, 31),
      );

      await repository.save(first);

      expect(
        () => repository.save(duplicate),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
