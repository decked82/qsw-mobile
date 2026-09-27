import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/movements/data/repositories/sqlite_movement_repository.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';

void main() {
  late Database database;
  late SqliteMovementRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    await database.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        box_no TEXT NOT NULL,
        part_no TEXT NOT NULL,
        from_location TEXT,
        to_location TEXT,
        quantity INTEGER NOT NULL,
        user_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE INDEX idx_movements_box_no
      ON movements(box_no)
    ''');

    await database.execute('''
      CREATE INDEX idx_movements_part_no
      ON movements(part_no)
    ''');

    await database.execute('''
      CREATE INDEX idx_movements_created_at
      ON movements(created_at)
    ''');

    repository = SqliteMovementRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SqliteMovementRepository', () {
    test('saves and retrieves movement by id', () async {
      final movement = Movement(
        id: 1,
        operationId: 'operation-001',
        type: MovementType.inbound,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        toLocation: 'A-01-03',
        quantity: 400,
        userId: 'user-001',
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(movement);

      final result = await repository.getById(1);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.operationId, 'operation-001');
      expect(result.type, MovementType.inbound);
      expect(result.boxNo, 'HSF2609110012');
      expect(result.partNo, 'T46053-0290');
      expect(result.fromLocation, isNull);
      expect(result.toLocation, 'A-01-03');
      expect(result.quantity, 400);
      expect(result.userId, 'user-001');
      expect(result.createdAt, DateTime(2026, 9, 21, 10, 30));
    });

    test('save with id 0 lets SQLite generate the primary key', () async {
      final movement = Movement(
        id: 0,
        operationId: 'operation-000',
        type: MovementType.inbound,
        boxNo: 'TEST-BOX',
        partNo: 'TEST-PART',
        toLocation: 'TEST-LOCATION',
        quantity: 1,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(movement);

      final result = await repository.getByOperationId('operation-000');

      expect(result, isNotNull);
      expect(result!.id, isNot(0));
      expect(result.operationId, 'operation-000');
    });

    test('returns null when movement does not exist', () async {
      final result = await repository.getById(999);

      expect(result, isNull);
    });

    test('retrieves movement by operation id', () async {
      final movement = Movement(
        id: 1,
        operationId: 'operation-001',
        type: MovementType.inbound,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        toLocation: 'A-01-03',
        quantity: 400,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      await repository.save(movement);

      final result = await repository.getByOperationId('operation-001');

      expect(result, isNotNull);
      expect(result!.operationId, 'operation-001');
    });

    test('retrieves movements by box number in creation order', () async {
      final first = Movement(
        id: 1,
        operationId: 'operation-001',
        type: MovementType.inbound,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        toLocation: 'A-01-03',
        quantity: 400,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      final second = Movement(
        id: 2,
        operationId: 'operation-002',
        type: MovementType.move,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        fromLocation: 'A-01-03',
        toLocation: 'B-02-01',
        quantity: 400,
        createdAt: DateTime(2026, 9, 21, 11, 0),
      );

      await repository.save(first);
      await repository.save(second);

      final result = await repository.getByBoxNo('HSF2609110012');

      expect(result, hasLength(2));
      expect(result[0].operationId, 'operation-001');
      expect(result[1].operationId, 'operation-002');
    });

    test('retrieves movements by part number', () async {
      final first = Movement(
        id: 1,
        operationId: 'operation-001',
        type: MovementType.inbound,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        toLocation: 'A-01-03',
        quantity: 400,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      final second = Movement(
        id: 2,
        operationId: 'operation-002',
        type: MovementType.inbound,
        boxNo: 'HSF2609110013',
        partNo: 'T46053-0290',
        toLocation: 'A-01-04',
        quantity: 250,
        createdAt: DateTime(2026, 9, 21, 11, 0),
      );

      await repository.save(first);
      await repository.save(second);

      final result = await repository.getByPartNo('T46053-0290');

      expect(result, hasLength(2));
      expect(result[0].boxNo, 'HSF2609110012');
      expect(result[1].boxNo, 'HSF2609110013');
    });

    test('does not allow duplicate operation id', () async {
      final first = Movement(
        id: 1,
        operationId: 'operation-001',
        type: MovementType.inbound,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        toLocation: 'A-01-03',
        quantity: 400,
        createdAt: DateTime(2026, 9, 21, 10, 30),
      );

      final duplicate = Movement(
        id: 2,
        operationId: 'operation-001',
        type: MovementType.move,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        fromLocation: 'A-01-03',
        toLocation: 'B-02-01',
        quantity: 400,
        createdAt: DateTime(2026, 9, 21, 11, 0),
      );

      await repository.save(first);

      expect(
        () => repository.save(duplicate),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
