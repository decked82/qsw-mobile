import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/core/database/sqlite/sqlite_database_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late SqliteDatabaseProvider databaseProvider;

  setUp(() {
    databaseProvider = SqliteDatabaseProvider(databaseName: 'qsw_test.db');
  });

  tearDown(() async {
    await databaseProvider.close();

    final databasePath = await getDatabasesPath();
    final path = '$databasePath/qsw_test.db';

    await deleteDatabase(path);
  });

  test('opens database with version 4 and creates required tables', () async {
    final database = await databaseProvider.database;

    final version = await database.getVersion();

    expect(version, equals(4));

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
    expect(partsTables.first['name'], equals('parts'));

    expect(locationsTables, hasLength(1));
    expect(locationsTables.first['name'], equals('locations'));

    expect(boxesTables, hasLength(1));
    expect(boxesTables.first['name'], equals('boxes'));
  });
}
