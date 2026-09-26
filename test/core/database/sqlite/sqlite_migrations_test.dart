import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/core/database/sqlite/sqlite_migrations.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('creates locations table in version 2', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final tables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'locations'],
    );

    expect(tables, hasLength(1));
    expect(tables.first['name'], equals('locations'));

    await database.close();
  });

  test('version 2 preserves parts table from version 1', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    await database.close();

    final upgradedDatabase = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final partsTables = await upgradedDatabase.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'parts'],
    );

    final locationsTables = await upgradedDatabase.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'locations'],
    );

    expect(partsTables, hasLength(1));
    expect(locationsTables, hasLength(1));

    await upgradedDatabase.close();
  });

  test('creates boxes table in version 3', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final tables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'boxes'],
    );

    expect(tables, hasLength(1));
    expect(tables.first['name'], equals('boxes'));

    await database.close();
  });

  test('version 3 preserves parts and locations tables', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final partsTables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'parts'],
    );

    final locationsTables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'locations'],
    );

    final boxesTables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'boxes'],
    );

    expect(partsTables, hasLength(1));
    expect(locationsTables, hasLength(1));
    expect(boxesTables, hasLength(1));

    await database.close();
  });

  test('version 3 creates boxes table with expected columns', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final columns = await database.rawQuery('PRAGMA table_info(boxes)');

    final columnNames = columns
        .map((column) => column['name'] as String)
        .toList();

    expect(
      columnNames,
      equals(['box_no', 'part_no', 'quantity', 'location', 'status']),
    );

    await database.close();
  });

  test('creates all V4 tables in a new version 4 database', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final tables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );

    final tableNames = tables.map((table) => table['name'] as String).toSet();

    expect(
      tableNames,
      containsAll([
        'parts',
        'locations',
        'boxes',
        'movements',
        'pending_operations',
        'sync_metadata',
      ]),
    );

    await database.close();
  });

  test('version 4 preserves existing V3 data', () async {
    final directory = await Directory.systemTemp.createTemp('qsw_migration_');
    final databasePath = '${directory.path}/qsw_test.db';

    try {
      final database = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: SqliteMigrations.onCreate,
          onUpgrade: SqliteMigrations.onUpgrade,
        ),
      );

      await database.insert('parts', {
        'part_code': 'T46053-0290',
        'name': 'Test Part',
        'specification': 'Test Specification',
        'barcode': '123456789',
        'unit': 'EA',
        'created_at': '2026-09-22T10:00:00.000Z',
        'updated_at': '2026-09-22T10:00:00.000Z',
      });

      await database.insert('locations', {
        'code': 'A-01-03',
        'name': 'Rack A-01-03',
        'description': 'Test Location',
        'is_active': 1,
        'created_at': '2026-09-22T10:00:00.000Z',
        'updated_at': '2026-09-22T10:00:00.000Z',
      });

      await database.insert('boxes', {
        'box_no': 'HSF2609110012',
        'part_no': 'T46053-0290',
        'quantity': 400,
        'location': 'A-01-03',
        'status': 'IN_STOCK',
      });

      await database.close();

      final upgradedDatabase = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: SqliteMigrations.onCreate,
          onUpgrade: SqliteMigrations.onUpgrade,
        ),
      );

      final parts = await upgradedDatabase.query('parts');
      final locations = await upgradedDatabase.query('locations');
      final boxes = await upgradedDatabase.query('boxes');

      expect(parts, hasLength(1));
      expect(parts.first['part_code'], equals('T46053-0290'));

      expect(locations, hasLength(1));
      expect(locations.first['code'], equals('A-01-03'));

      expect(boxes, hasLength(1));
      expect(boxes.first['box_no'], equals('HSF2609110012'));
      expect(boxes.first['quantity'], equals(400));

      final movementsTables = await upgradedDatabase.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'movements'],
      );

      final pendingOperationsTables = await upgradedDatabase.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'pending_operations'],
      );

      final syncMetadataTables = await upgradedDatabase.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'sync_metadata'],
      );

      expect(movementsTables, hasLength(1));
      expect(pendingOperationsTables, hasLength(1));
      expect(syncMetadataTables, hasLength(1));

      await upgradedDatabase.close();
    } finally {
      await Directory(directory.path).delete(recursive: true);
    }
  });

  test('version 4 creates required indexes', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final indexes = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['index'],
    );

    final indexNames = indexes.map((index) => index['name'] as String).toSet();

    expect(
      indexNames,
      containsAll([
        'idx_movements_box_no',
        'idx_movements_part_no',
        'idx_movements_created_at',
        'idx_pending_operations_status',
        'idx_pending_operations_created_at',
      ]),
    );

    await database.close();
  });

  test('version 4 creates required columns', () async {
    final database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    final movementColumns = await database.rawQuery(
      'PRAGMA table_info(movements)',
    );

    final movementColumnNames = movementColumns
        .map((column) => column['name'] as String)
        .toList();

    expect(
      movementColumnNames,
      equals([
        'id',
        'operation_id',
        'type',
        'box_no',
        'part_no',
        'from_location',
        'to_location',
        'quantity',
        'user_id',
        'created_at',
      ]),
    );

    final pendingOperationColumns = await database.rawQuery(
      'PRAGMA table_info(pending_operations)',
    );

    final pendingOperationColumnNames = pendingOperationColumns
        .map((column) => column['name'] as String)
        .toList();

    expect(
      pendingOperationColumnNames,
      equals([
        'id',
        'operation_id',
        'type',
        'entity_type',
        'entity_id',
        'payload',
        'status',
        'retry_count',
        'created_at',
        'last_attempt_at',
        'last_error',
      ]),
    );

    final syncMetadataColumns = await database.rawQuery(
      'PRAGMA table_info(sync_metadata)',
    );

    final syncMetadataColumnNames = syncMetadataColumns
        .map((column) => column['name'] as String)
        .toList();

    expect(
      syncMetadataColumnNames,
      equals(['entity_type', 'last_sync_at', 'status', 'cursor']),
    );

    await database.close();
  });
}
