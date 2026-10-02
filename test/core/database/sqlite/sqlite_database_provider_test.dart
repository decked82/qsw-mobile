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

  test('opens database with version 6 and creates required tables', () async {
    final database = await databaseProvider.database;

    final version = await database.getVersion();

    expect(version, equals(6));

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

    final boxNumberRangesTables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'box_number_ranges'],
    );

    final inboundTransactionsTables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'inbound_transactions'],
    );

    expect(partsTables, hasLength(1));
    expect(partsTables.first['name'], equals('parts'));

    expect(locationsTables, hasLength(1));
    expect(locationsTables.first['name'], equals('locations'));

    expect(boxesTables, hasLength(1));
    expect(boxesTables.first['name'], equals('boxes'));

    expect(boxNumberRangesTables, hasLength(1));
    expect(boxNumberRangesTables.first['name'], equals('box_number_ranges'));

    expect(inboundTransactionsTables, hasLength(1));
    expect(
      inboundTransactionsTables.first['name'],
      equals('inbound_transactions'),
    );
  });
}
