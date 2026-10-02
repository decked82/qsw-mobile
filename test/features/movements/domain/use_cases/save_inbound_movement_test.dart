import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:qsw_mobile/features/boxes/data/data_sources/box_number_data_source.dart';
import 'package:qsw_mobile/features/boxes/data/repositories/sqlite_box_number_range_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/repositories/box_number_range_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/services/box_number_generator.dart';
import 'package:qsw_mobile/features/movements/data/repositories/sqlite_movement_repository.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/use_cases/save_inbound_movement.dart';
import 'package:qsw_mobile/features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

void main() {
  late Database database;
  late BoxNumberRangeRepository rangeRepository;
  late FakeBoxNumberDataSource boxNumberDataSource;
  late BoxNumberGenerator boxNumberGenerator;
  late SaveInboundMovement saveInboundMovement;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    await database.execute('''
      CREATE TABLE box_number_ranges (
        date_key TEXT PRIMARY KEY,
        range_start INTEGER NOT NULL,
        range_end INTEGER NOT NULL,
        next_number INTEGER NOT NULL
      )
    ''');

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
      CREATE INDEX idx_movements_operation_id
      ON movements(operation_id)
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
      CREATE INDEX idx_pending_operations_operation_id
      ON pending_operations(operation_id)
    ''');

    rangeRepository = SqliteBoxNumberRangeRepository(database);

    boxNumberDataSource = FakeBoxNumberDataSource();

    boxNumberGenerator = BoxNumberGenerator(
      dataSource: boxNumberDataSource,
      rangeRepository: rangeRepository,
      rangeSize: 20,
      now: () => DateTime(2026, 9, 27, 10, 30),
    );

    saveInboundMovement = SaveInboundMovement(
      database: database,
      boxNumberGenerator: boxNumberGenerator,
      uuid: const Uuid(),
      now: () => DateTime(2026, 9, 27, 10, 30),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saves inbound movement with generated BOX NO', () async {
    final movement = await saveInboundMovement(
      partNo: 'T46053-0290',
      quantity: 400,
      location: 'A-01-03',
    );

    expect(movement.id, 0);
    expect(movement.operationId, isNotEmpty);
    expect(movement.type, MovementType.inbound);
    expect(movement.boxNo, 'HSF260927000001');
    expect(movement.partNo, 'T46053-0290');
    expect(movement.quantity, 400);
    expect(movement.fromLocation, isNull);
    expect(movement.toLocation, 'A-01-03');
  });

  test('increments BOX NO after successful save', () async {
    final first = await saveInboundMovement(
      partNo: 'PART-001',
      quantity: 10,
      location: 'A-01-01',
    );

    final second = await saveInboundMovement(
      partNo: 'PART-002',
      quantity: 20,
      location: 'A-01-02',
    );

    expect(first.boxNo, 'HSF260927000001');
    expect(second.boxNo, 'HSF260927000002');

    final range = await rangeRepository.getByDateKey('260927');

    expect(range, isNotNull);
    expect(range!.nextNumber, 3);
  });

  test('saves pending operation together with movement', () async {
    final movement = await saveInboundMovement(
      partNo: 'T46053-0290',
      quantity: 400,
      location: 'A-01-03',
    );

    final movementRepository = SqliteMovementRepository(database);
    final pendingOperationRepository = SqlitePendingOperationRepository(
      database,
    );

    final savedMovement = await movementRepository.getByOperationId(
      movement.operationId,
    );

    final pendingOperation = await pendingOperationRepository.getByOperationId(
      movement.operationId,
    );

    expect(savedMovement, isNotNull);
    expect(savedMovement!.boxNo, movement.boxNo);

    expect(pendingOperation, isNotNull);
    expect(pendingOperation!.operationId, movement.operationId);
    expect(pendingOperation.type, 'INBOUND');
    expect(pendingOperation.entityType, 'MOVEMENT');
    expect(pendingOperation.entityId, movement.operationId);
    expect(pendingOperation.status, PendingOperationStatus.pending);
  });

  test('uses the same date in generated BOX NO', () async {
    final movement = await saveInboundMovement(
      partNo: 'PART-001',
      quantity: 1,
      location: 'B-02-01',
    );

    expect(movement.boxNo, 'HSF260927000001');
  });

  test('validates part number', () async {
    expect(
      () =>
          saveInboundMovement(partNo: '   ', quantity: 10, location: 'A-01-01'),
      throwsArgumentError,
    );
  });

  test('validates quantity', () async {
    expect(
      () => saveInboundMovement(
        partNo: 'PART-001',
        quantity: 0,
        location: 'A-01-01',
      ),
      throwsArgumentError,
    );

    expect(
      () => saveInboundMovement(
        partNo: 'PART-001',
        quantity: -1,
        location: 'A-01-01',
      ),
      throwsArgumentError,
    );
  });

  test('validates location', () async {
    expect(
      () => saveInboundMovement(
        partNo: 'PART-001',
        quantity: 10,
        location: '   ',
      ),
      throwsArgumentError,
    );
  });
}

class FakeBoxNumberDataSource implements BoxNumberDataSource {
  @override
  Future<BoxNumberRange> reserveRange({
    required String dateKey,
    required int size,
  }) async {
    return BoxNumberRange(start: 1, end: size);
  }
}
