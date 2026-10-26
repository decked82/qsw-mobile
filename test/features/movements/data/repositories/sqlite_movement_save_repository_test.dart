import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/movements/data/repositories/sqlite_movement_save_repository.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

void main() {
  late Database database;
  late SqliteMovementSaveRepository repository;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(
      'CREATE TABLE movements (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT NOT NULL UNIQUE, type TEXT NOT NULL, box_no TEXT NOT NULL, part_no TEXT NOT NULL, from_location TEXT, to_location TEXT, quantity INTEGER NOT NULL, user_id TEXT, created_at TEXT NOT NULL)',
    );
    await database.execute(
      'CREATE INDEX idx_movements_box_no ON movements(box_no)',
    );
    await database.execute(
      'CREATE INDEX idx_movements_part_no ON movements(part_no)',
    );
    await database.execute(
      'CREATE INDEX idx_movements_created_at ON movements(created_at)',
    );
    await database.execute(
      'CREATE TABLE pending_operations (id INTEGER PRIMARY KEY AUTOINCREMENT, operation_id TEXT NOT NULL UNIQUE, type TEXT NOT NULL, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, payload TEXT NOT NULL, status TEXT NOT NULL, retry_count INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, last_attempt_at TEXT, last_error TEXT)',
    );
    repository = SqliteMovementSaveRepository(database);
  });

  tearDown(() async => database.close());

  Movement makeMovement(String operationId) => Movement(
    id: 0,
    operationId: operationId,
    type: MovementType.inbound,
    boxNo: 'BOX-001',
    partNo: 'PART-001',
    quantity: 5,
    createdAt: DateTime(2026, 1, 1),
  );

  PendingOperation makeOperation(String operationId) => PendingOperation(
    id: 0,
    operationId: operationId,
    type: 'INBOUND',
    entityType: 'MOVEMENT',
    entityId: operationId,
    payload: '{"operationId":"$operationId"}',
    status: PendingOperationStatus.pending,
    retryCount: 0,
    createdAt: DateTime(2026, 1, 1),
  );

  test('persists movement and pending operation together', () async {
    await repository.saveAtomically(
      movement: makeMovement('OP-ATOMIC-001'),
      pendingOperation: makeOperation('OP-ATOMIC-001'),
    );
    expect(
      await database.query(
        'movements',
        where: 'operation_id = ?',
        whereArgs: ['OP-ATOMIC-001'],
      ),
      hasLength(1),
    );
    expect(
      await database.query(
        'pending_operations',
        where: 'operation_id = ?',
        whereArgs: ['OP-ATOMIC-001'],
      ),
      hasLength(1),
    );
  });

  test('rolls back movement if pending operation insert fails', () async {
    await database.insert('pending_operations', {
      'operation_id': 'OP-ATOMIC-002',
      'type': 'INBOUND',
      'entity_type': 'MOVEMENT',
      'entity_id': 'OP-ATOMIC-002',
      'payload': '{}',
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': DateTime(2026, 1, 1).toIso8601String(),
    });

    await expectLater(
      () => repository.saveAtomically(
        movement: makeMovement('OP-ATOMIC-002'),
        pendingOperation: makeOperation('OP-ATOMIC-002'),
      ),
      throwsA(isA<DatabaseException>()),
    );
    expect(
      await database.query(
        'movements',
        where: 'operation_id = ?',
        whereArgs: ['OP-ATOMIC-002'],
      ),
      isEmpty,
    );
    expect(
      await database.query(
        'pending_operations',
        where: 'operation_id = ?',
        whereArgs: ['OP-ATOMIC-002'],
      ),
      hasLength(1),
    );
  });
}
