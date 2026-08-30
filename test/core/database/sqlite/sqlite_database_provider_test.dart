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

  test('opens database with version 1 and creates parts table', () async {
    final database = await databaseProvider.database;

    expect(database.getVersion(), completion(equals(1)));

    final tables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'parts'],
    );

    expect(tables, hasLength(1));
    expect(tables.first['name'], equals('parts'));
  });
}
