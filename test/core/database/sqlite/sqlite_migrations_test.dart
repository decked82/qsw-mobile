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
}
