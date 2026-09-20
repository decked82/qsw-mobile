import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/boxes/data/repositories/sqlite_box_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/entities/box.dart';

void main() {
  late Database database;
  late SqliteBoxRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    await database.execute('''
      CREATE TABLE boxes (
        box_no TEXT PRIMARY KEY,
        part_no TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        location TEXT,
        status TEXT
      )
    ''');

    repository = SqliteBoxRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('getByBoxNo', () {
    test('returns box when BOX NO exists', () async {
      const box = Box(
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        quantity: 400,
        location: 'A-01-03',
        status: 'IN_STOCK',
      );

      await repository.save(box);

      final result = await repository.getByBoxNo('HSF2609110012');

      expect(result, isNotNull);
      expect(result!.boxNo, 'HSF2609110012');
      expect(result.partNo, 'T46053-0290');
      expect(result.quantity, 400);
      expect(result.location, 'A-01-03');
      expect(result.status, 'IN_STOCK');
    });

    test('returns null when BOX NO does not exist', () async {
      final result = await repository.getByBoxNo('UNKNOWN_BOX');

      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns all boxes', () async {
      const boxes = [
        Box(
          boxNo: 'HSF2609110012',
          partNo: 'T46053-0290',
          quantity: 400,
          location: 'A-01-03',
          status: 'IN_STOCK',
        ),
        Box(
          boxNo: 'HSF2609110013',
          partNo: 'T46053-0231',
          quantity: 240,
          location: 'B-02-01',
          status: 'IN_STOCK',
        ),
      ];

      await repository.saveAll(boxes);

      final result = await repository.getAll();

      expect(result, hasLength(2));
      expect(
        result.map((box) => box.boxNo),
        containsAll(['HSF2609110012', 'HSF2609110013']),
      );
    });

    test('returns empty list when database contains no boxes', () async {
      final result = await repository.getAll();

      expect(result, isEmpty);
    });
  });

  group('save', () {
    test('saves a new box', () async {
      const box = Box(
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        quantity: 400,
      );

      await repository.save(box);

      final result = await repository.getByBoxNo('HSF2609110012');

      expect(result, isNotNull);
      expect(result!.boxNo, 'HSF2609110012');
      expect(result.partNo, 'T46053-0290');
      expect(result.quantity, 400);
      expect(result.location, isNull);
      expect(result.status, isNull);
    });

    test('replaces existing box with the same BOX NO', () async {
      const original = Box(
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        quantity: 400,
      );

      const updated = Box(
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        quantity: 500,
        location: 'C-03-02',
        status: 'IN_STOCK',
      );

      await repository.save(original);
      await repository.save(updated);

      final result = await repository.getByBoxNo('HSF2609110012');

      expect(result, isNotNull);
      expect(result!.quantity, 500);
      expect(result.location, 'C-03-02');
      expect(result.status, 'IN_STOCK');
    });
  });

  group('saveAll', () {
    test('saves multiple boxes', () async {
      const boxes = [
        Box(boxNo: 'HSF2609110012', partNo: 'T46053-0290', quantity: 400),
        Box(boxNo: 'HSF2609110013', partNo: 'T46053-0231', quantity: 240),
        Box(boxNo: 'HSF2609110014', partNo: 'T46053-0290', quantity: 300),
      ];

      await repository.saveAll(boxes);

      final result = await repository.getAll();

      expect(result, hasLength(3));
    });
  });

  group('delete', () {
    test('deletes box by BOX NO', () async {
      const box = Box(
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        quantity: 400,
      );

      await repository.save(box);
      await repository.delete('HSF2609110012');

      final result = await repository.getByBoxNo('HSF2609110012');

      expect(result, isNull);
    });
  });
}
