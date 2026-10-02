import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/boxes/data/repositories/'
    'sqlite_box_number_range_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/repositories/'
    'box_number_range_repository.dart';

void main() {
  late Database database;
  late SqliteBoxNumberRangeRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE box_number_ranges (
              date_key TEXT PRIMARY KEY,
              range_start INTEGER NOT NULL,
              range_end INTEGER NOT NULL,
              next_number INTEGER NOT NULL
            )
          ''');
        },
      ),
    );

    repository = SqliteBoxNumberRangeRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('returns null when range does not exist', () async {
    final result = await repository.getByDateKey('260927');

    expect(result, isNull);
  });

  test('saves and reads a range', () async {
    const range = BoxNumberRangeState(
      dateKey: '260927',
      rangeStart: 1,
      rangeEnd: 20,
      nextNumber: 1,
    );

    await repository.save(range);

    final result = await repository.getByDateKey('260927');

    expect(result, isNotNull);
    expect(result!.dateKey, equals('260927'));
    expect(result.rangeStart, equals(1));
    expect(result.rangeEnd, equals(20));
    expect(result.nextNumber, equals(1));
  });

  test('updates next number', () async {
    const range = BoxNumberRangeState(
      dateKey: '260927',
      rangeStart: 1,
      rangeEnd: 20,
      nextNumber: 1,
    );

    await repository.save(range);

    await repository.updateNextNumber(dateKey: '260927', nextNumber: 2);

    final result = await repository.getByDateKey('260927');

    expect(result, isNotNull);
    expect(result!.nextNumber, equals(2));
    expect(result.rangeStart, equals(1));
    expect(result.rangeEnd, equals(20));
  });

  test('replaces existing range for the same date', () async {
    const firstRange = BoxNumberRangeState(
      dateKey: '260927',
      rangeStart: 1,
      rangeEnd: 20,
      nextNumber: 5,
    );

    const secondRange = BoxNumberRangeState(
      dateKey: '260927',
      rangeStart: 21,
      rangeEnd: 40,
      nextNumber: 21,
    );

    await repository.save(firstRange);
    await repository.save(secondRange);

    final result = await repository.getByDateKey('260927');

    expect(result, isNotNull);
    expect(result!.rangeStart, equals(21));
    expect(result.rangeEnd, equals(40));
    expect(result.nextNumber, equals(21));
  });

  test('keeps ranges for different dates separately', () async {
    const firstRange = BoxNumberRangeState(
      dateKey: '260927',
      rangeStart: 1,
      rangeEnd: 20,
      nextNumber: 3,
    );

    const secondRange = BoxNumberRangeState(
      dateKey: '260928',
      rangeStart: 1,
      rangeEnd: 20,
      nextNumber: 1,
    );

    await repository.save(firstRange);
    await repository.save(secondRange);

    final firstResult = await repository.getByDateKey('260927');
    final secondResult = await repository.getByDateKey('260928');

    expect(firstResult!.nextNumber, equals(3));
    expect(secondResult!.nextNumber, equals(1));
  });

  test('throws when updating a missing date range', () async {
    expect(
      () => repository.updateNextNumber(dateKey: '260927', nextNumber: 2),
      throwsA(isA<StateError>()),
    );
  });
}
