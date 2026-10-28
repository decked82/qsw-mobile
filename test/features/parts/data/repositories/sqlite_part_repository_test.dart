import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/core/database/sqlite/sqlite_database_provider.dart';
import 'package:qsw_mobile/features/parts/data/data_sources/sqlite_part_data_source.dart';
import 'package:qsw_mobile/features/parts/data/repositories/sqlite_part_repository.dart';
import 'package:qsw_mobile/features/parts/domain/entities/part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/add_part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/delete_part.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/get_parts.dart';
import 'package:qsw_mobile/features/parts/domain/use_cases/search_parts.dart';

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
    expect(addedPart.syncId, isNotNull);
    expect(addedPart.syncId, isNotEmpty);
    expect(addedPart.createdAt, isNotNull);
    expect(addedPart.updatedAt, isNotNull);
    expect(addedPart.isDeleted, isFalse);

    final parts = await getParts();

    expect(parts, hasLength(1));
    expect(parts.first.id, addedPart.id);
    expect(parts.first.partCode, 'TEST-001');
    expect(parts.first.name, 'Test Part');
    expect(parts.first.specification, 'Test specification');
    expect(parts.first.barcode, '123456789');
    expect(parts.first.unit, 'EA');
  });

  test('soft deletes part and preserves its sync metadata', () async {
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

    final db = await databaseProvider.database;
    await deletePart(addedPart.id!);

    parts = await getParts();
    expect(parts, isEmpty);

    final rows = await db.query(
      'parts',
      where: 'id = ?',
      whereArgs: [addedPart.id],
    );
    expect(rows, hasLength(1));
    expect(rows.single['is_deleted'], 1);
    expect(rows.single['sync_id'], addedPart.syncId);
    expect(rows.single['deleted_at'], isNotNull);
    expect(rows.single['updated_at'], isNotNull);
  });

  test('does not show soft-deleted parts in search', () async {
    final searchParts = SearchParts(
      SqlitePartRepository(SqlitePartDataSource(databaseProvider)),
    );

    const hiddenPart = Part(
      partCode: 'TEST-HIDDEN-001',
      name: 'Hidden Part',
      barcode: 'HIDDEN-BARCODE-001',
    );
    const activePart = Part(
      partCode: 'TEST-ACTIVE-001',
      name: 'Active Part',
      barcode: 'ACTIVE-BARCODE-001',
    );

    final addedHiddenPart = await addPart(hiddenPart);
    await addPart(activePart);
    await deletePart(addedHiddenPart.id!);

    expect(await getParts(), hasLength(1));

    expect(await searchParts('TEST-HIDDEN-001'), isEmpty);
    expect(await searchParts('Hidden Part'), isEmpty);
    expect(await searchParts('HIDDEN-BARCODE-001'), isEmpty);

    final activeResults = await searchParts('TEST-ACTIVE-001');
    expect(activeResults, hasLength(1));
    expect(activeResults.single.partCode, 'TEST-ACTIVE-001');

    final emptyQueryResults = await searchParts('   ');
    expect(emptyQueryResults, hasLength(1));
    expect(emptyQueryResults.single.partCode, 'TEST-ACTIVE-001');

    final db = await databaseProvider.database;
    final deletedRows = await db.query(
      'parts',
      where: 'id = ?',
      whereArgs: [addedHiddenPart.id],
    );

    expect(deletedRows, hasLength(1));
    expect(deletedRows.single['is_deleted'], 1);
    expect(deletedRows.single['sync_id'], addedHiddenPart.syncId);
  });

  test('preserves explicitly supplied synchronization metadata', () async {
    final createdAt = DateTime.utc(2025, 1, 2, 3, 4, 5);
    final updatedAt = DateTime.utc(2025, 2, 3, 4, 5, 6);

    const part = Part(
      partCode: 'TEST-METADATA-001',
      name: 'Metadata Part',
      syncId: 'qsw-test-sync-id-001',
    );

    final addedPart = await addPart(
      Part(
        partCode: part.partCode,
        name: part.name,
        syncId: part.syncId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );

    expect(addedPart.syncId, 'qsw-test-sync-id-001');
    expect(addedPart.createdAt, createdAt);
    expect(addedPart.updatedAt, updatedAt);
  });

  test('assigns different sync IDs to new parts', () async {
    final first = await addPart(
      const Part(partCode: 'TEST-UUID-001', name: 'First UUID Part'),
    );
    final second = await addPart(
      const Part(partCode: 'TEST-UUID-002', name: 'Second UUID Part'),
    );

    expect(first.syncId, isNotNull);
    expect(second.syncId, isNotNull);
    expect(first.syncId, isNot(second.syncId));
  });

  test(
    'repeated soft deletion preserves original deletion timestamps',
    () async {
      var clockValue = DateTime.utc(2025, 3, 1, 10);

      final dataSource = SqlitePartDataSource(
        databaseProvider,
        clock: () => clockValue,
      );
      final repository = SqlitePartRepository(dataSource);
      final controlledAddPart = AddPart(repository);
      final controlledDeletePart = DeletePart(repository);

      final addedPart = await controlledAddPart(
        const Part(partCode: 'TEST-REDELETE-001', name: 'Repeated Delete Part'),
      );

      final createdAt = addedPart.createdAt;
      final syncId = addedPart.syncId;

      clockValue = DateTime.utc(2025, 3, 2, 11);
      await controlledDeletePart(addedPart.id!);

      final db = await databaseProvider.database;
      final firstRows = await db.query(
        'parts',
        where: 'id = ?',
        whereArgs: [addedPart.id],
      );

      expect(firstRows, hasLength(1));
      final firstDeletedAt = firstRows.single['deleted_at'];
      final firstUpdatedAt = firstRows.single['updated_at'];

      expect(firstDeletedAt, clockValue.toIso8601String());
      expect(firstUpdatedAt, clockValue.toIso8601String());

      clockValue = DateTime.utc(2025, 3, 3, 12);
      await controlledDeletePart(addedPart.id!);

      final secondRows = await db.query(
        'parts',
        where: 'id = ?',
        whereArgs: [addedPart.id],
      );

      expect(secondRows, hasLength(1));
      expect(secondRows.single['deleted_at'], firstDeletedAt);
      expect(secondRows.single['updated_at'], firstUpdatedAt);
      expect(secondRows.single['created_at'], createdAt?.toIso8601String());
      expect(secondRows.single['sync_id'], syncId);
      expect(secondRows.single['is_deleted'], 1);
    },
  );
}
