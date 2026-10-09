import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/boxes/data/data_sources/box_number_data_source.dart';
import 'package:qsw_mobile/features/boxes/data/repositories/sqlite_box_number_range_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/repositories/box_number_range_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/services/box_number_generator.dart';
import 'package:qsw_mobile/features/movements/data/repositories/sqlite_inbound_transaction_repository.dart';
import 'package:qsw_mobile/features/movements/domain/use_cases/save_inbound_transaction.dart';
import 'package:qsw_mobile/features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

void main() {
  late Database database;
  late BoxNumberRangeRepository rangeRepository;
  late FakeBoxNumberDataSource boxNumberDataSource;
  late BoxNumberGenerator boxNumberGenerator;
  late SaveInboundTransaction saveInboundTransaction;

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
      CREATE INDEX idx_inbound_transactions_operation_id
      ON inbound_transactions(operation_id)
    ''');

    await database.execute('''
      CREATE INDEX idx_inbound_transactions_box_no
      ON inbound_transactions(box_no)
    ''');

    await database.execute('''
      CREATE INDEX idx_inbound_transactions_part_no
      ON inbound_transactions(part_no)
    ''');

    await database.execute('''
      CREATE TABLE boxes (
        box_no TEXT PRIMARY KEY,
        part_no TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        location TEXT,
        status TEXT
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

    saveInboundTransaction = SaveInboundTransaction(
      database: database,
      boxNumberGenerator: boxNumberGenerator,
      now: () => DateTime(2026, 9, 27, 10, 30),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saves inbound transaction and box with generated BOX NO', () async {
    final transaction = await saveInboundTransaction(
      partNo: 'T46053-0290',
      quantity: 400,
      location: 'A-01-03',
    );

    expect(transaction.id, 0);
    expect(transaction.operationId, isNotEmpty);
    expect(transaction.boxNo, 'HSF260927000001');
    expect(transaction.partNo, 'T46053-0290');
    expect(transaction.quantity, 400);
    expect(transaction.location, 'A-01-03');
    expect(transaction.userId, isNull);

    final boxes = await database.query(
      'boxes',
      where: 'box_no = ?',
      whereArgs: [transaction.boxNo],
    );

    expect(boxes, hasLength(1));
    expect(boxes.single['box_no'], transaction.boxNo);
    expect(boxes.single['part_no'], 'T46053-0290');
    expect(boxes.single['quantity'], 400);
    expect(boxes.single['location'], 'A-01-03');
    expect(boxes.single['status'], 'IN_STOCK');
  });

  test('increments BOX NO after successful save', () async {
    final first = await saveInboundTransaction(
      partNo: 'PART-001',
      quantity: 10,
      location: 'A-01-01',
    );

    final second = await saveInboundTransaction(
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

  test('saves pending operation together with inbound transaction', () async {
    final transaction = await saveInboundTransaction(
      partNo: 'T46053-0290',
      quantity: 400,
      location: 'A-01-03',
    );

    final transactionRepository = SqliteInboundTransactionRepository(database);
    final pendingOperationRepository = SqlitePendingOperationRepository(
      database,
    );

    final savedTransaction = await transactionRepository.getByOperationId(
      transaction.operationId,
    );

    final pendingOperation = await pendingOperationRepository.getByOperationId(
      transaction.operationId,
    );

    expect(savedTransaction, isNotNull);
    expect(savedTransaction!.boxNo, transaction.boxNo);
    expect(savedTransaction.partNo, transaction.partNo);
    expect(savedTransaction.quantity, transaction.quantity);
    expect(savedTransaction.location, transaction.location);

    expect(pendingOperation, isNotNull);
    expect(pendingOperation!.operationId, transaction.operationId);
    expect(pendingOperation.type, 'INBOUND');
    expect(pendingOperation.entityType, 'INBOUND_TRANSACTION');
    expect(pendingOperation.entityId, transaction.operationId);
    expect(pendingOperation.status, PendingOperationStatus.pending);
  });

  test('rolls back all changes when saving box fails', () async {
    await database.execute('''
      CREATE TRIGGER fail_box_insert
      BEFORE INSERT ON boxes
      BEGIN
        SELECT RAISE(ABORT, 'forced box insert failure');
      END
    ''');

    await expectLater(
      saveInboundTransaction(
        partNo: 'PART-FAIL',
        quantity: 10,
        location: 'A-01-01',
      ),
      throwsA(anything),
    );

    final transactions = await database.query('inbound_transactions');
    final boxes = await database.query('boxes');
    final pendingOperations = await database.query('pending_operations');
    final range = await rangeRepository.getByDateKey('260927');

    expect(transactions, isEmpty);
    expect(boxes, isEmpty);
    expect(pendingOperations, isEmpty);

    expect(range, isNotNull);
    expect(range!.nextNumber, 1);
  });

  test('uses the same date in generated BOX NO', () async {
    final transaction = await saveInboundTransaction(
      partNo: 'PART-001',
      quantity: 1,
      location: 'B-02-01',
    );

    expect(transaction.boxNo, 'HSF260927000001');
  });

  test('validates part number', () async {
    expect(
      () => saveInboundTransaction(
        partNo: '   ',
        quantity: 10,
        location: 'A-01-01',
      ),
      throwsArgumentError,
    );
  });

  test('validates quantity', () async {
    expect(
      () => saveInboundTransaction(
        partNo: 'PART-001',
        quantity: 0,
        location: 'A-01-01',
      ),
      throwsArgumentError,
    );

    expect(
      () => saveInboundTransaction(
        partNo: 'PART-001',
        quantity: -1,
        location: 'A-01-01',
      ),
      throwsArgumentError,
    );
  });

  test('validates location', () async {
    expect(
      () => saveInboundTransaction(
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
