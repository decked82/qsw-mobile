import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/core/database/sqlite/sqlite_database_provider.dart';
import 'package:qsw_mobile/features/parts/data/data_sources/sqlite_part_data_source.dart';
import 'package:qsw_mobile/features/parts/data/repositories/sqlite_part_repository.dart';
import 'package:qsw_mobile/features/parts/domain/entities/part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/add_part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/delete_part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/get_parts.dart';

void main() {
  late SqliteDatabaseProvider databaseProvider;
  late AddPart addPart;
  late GetParts getParts;
  late DeletePart deletePart;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseProvider = SqliteDatabaseProvider();

    final db = await databaseProvider.database;
    await db.delete('parts');

    final dataSource = SqlitePartDataSource(databaseProvider);
    final repository = SqlitePartRepository(dataSource);

    addPart = AddPart(repository);
    getParts = GetParts(repository);
    deletePart = DeletePart(repository);
  });

  tearDown(() async {
    await databaseProvider.close();
  });

  test('adds part and retrieves it from SQLite', () async {
    const part = Part(
      partCode: 'TEST-001',
      name: 'Test Part',
      specification: 'Test specification',
      barcode: '123456789',
      unit: 'EA',
    );

    final addedPart = await addPart(part);

    expect(addedPart.id, isNotNull);
    expect(addedPart.partCode, 'TEST-001');
    expect(addedPart.name, 'Test Part');
    expect(addedPart.specification, 'Test specification');
    expect(addedPart.barcode, '123456789');
    expect(addedPart.unit, 'EA');

    final parts = await getParts();

    expect(parts, hasLength(1));
    expect(parts.first.id, addedPart.id);
    expect(parts.first.partCode, 'TEST-001');
    expect(parts.first.name, 'Test Part');
    expect(parts.first.specification, 'Test specification');
    expect(parts.first.barcode, '123456789');
    expect(parts.first.unit, 'EA');
  });

  test('deletes part from SQLite', () async {
    const part = Part(
      partCode: 'TEST-DELETE-001',
      name: 'Part to Delete',
      specification: 'Test specification',
      barcode: '987654321',
      unit: 'EA',
    );

    final addedPart = await addPart(part);

    expect(addedPart.id, isNotNull);

    var parts = await getParts();

    expect(parts, hasLength(1));
    expect(parts.first.id, addedPart.id);

    await deletePart(addedPart.id!);

    parts = await getParts();

    expect(parts, isEmpty);
  });
}
