import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/core/database/sqlite/sqlite_migrations.dart';
import 'package:qsw_mobile/features/locations/data/data_sources/sqlite_location_data_source.dart';
import 'package:qsw_mobile/features/locations/domain/entities/location.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database database;
  late SqliteLocationDataSource dataSource;

  setUp(() async {
    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: SqliteMigrations.onCreate,
        onUpgrade: SqliteMigrations.onUpgrade,
      ),
    );

    dataSource = SqliteLocationDataSource(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SqliteLocationDataSource', () {
    test('adds and returns a location', () async {
      final createdAt = DateTime(2026, 9, 11, 8, 0);
      final updatedAt = DateTime(2026, 9, 11, 9, 0);

      final location = Location(
        code: 'A-01-01',
        name: 'Rack A / Level 1 / Position 1',
        description: 'Near receiving area',
        isActive: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final addedLocation = await dataSource.addLocation(location);

      expect(addedLocation.id, isNotNull);
      expect(addedLocation.code, 'A-01-01');
      expect(addedLocation.name, 'Rack A / Level 1 / Position 1');
      expect(addedLocation.description, 'Near receiving area');
      expect(addedLocation.isActive, isTrue);
      expect(addedLocation.createdAt, createdAt);
      expect(addedLocation.updatedAt, updatedAt);
    });

    test('gets locations ordered by code', () async {
      await dataSource.addLocation(
        const Location(code: 'B-02-03', name: 'Rack B / Level 2 / Position 3'),
      );

      await dataSource.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      await dataSource.addLocation(
        const Location(code: 'C-01-02', name: 'Rack C / Level 1 / Position 2'),
      );

      final locations = await dataSource.getLocations();

      expect(locations, hasLength(3));
      expect(locations[0].code, 'A-01-01');
      expect(locations[1].code, 'B-02-03');
      expect(locations[2].code, 'C-01-02');
    });

    test('gets a location by code', () async {
      await dataSource.addLocation(
        const Location(code: 'B-02-03', name: 'Rack B / Level 2 / Position 3'),
      );

      final location = await dataSource.getLocationByCode('B-02-03');

      expect(location, isNotNull);
      expect(location!.code, 'B-02-03');
      expect(location.name, 'Rack B / Level 2 / Position 3');
    });

    test('returns null when location code does not exist', () async {
      final location = await dataSource.getLocationByCode('C-99-99');

      expect(location, isNull);
    });

    test('searches locations by code', () async {
      await dataSource.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      await dataSource.addLocation(
        const Location(code: 'B-02-03', name: 'Rack B / Level 2 / Position 3'),
      );

      final locations = await dataSource.searchLocations('B-02');

      expect(locations, hasLength(1));
      expect(locations.first.code, 'B-02-03');
    });

    test('searches locations by name', () async {
      await dataSource.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      await dataSource.addLocation(
        const Location(code: 'B-02-03', name: 'Rack B / Level 2 / Position 3'),
      );

      final locations = await dataSource.searchLocations('Rack A');

      expect(locations, hasLength(1));
      expect(locations.first.code, 'A-01-01');
    });

    test('search is case insensitive', () async {
      await dataSource.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      final locations = await dataSource.searchLocations('rack a');

      expect(locations, hasLength(1));
      expect(locations.first.code, 'A-01-01');
    });

    test('preserves inactive status', () async {
      const location = Location(
        code: 'A-02-01',
        name: 'Rack A / Level 2 / Position 1',
        isActive: false,
      );

      final addedLocation = await dataSource.addLocation(location);
      final foundLocation = await dataSource.getLocationByCode('A-02-01');

      expect(addedLocation.isActive, isFalse);
      expect(foundLocation, isNotNull);
      expect(foundLocation!.isActive, isFalse);
    });

    test('preserves createdAt and updatedAt', () async {
      final createdAt = DateTime(2026, 9, 11, 8, 30);
      final updatedAt = DateTime(2026, 9, 11, 10, 45);

      final location = Location(
        code: 'A-03-01',
        name: 'Rack A / Level 3 / Position 1',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      await dataSource.addLocation(location);

      final foundLocation = await dataSource.getLocationByCode('A-03-01');

      expect(foundLocation, isNotNull);
      expect(foundLocation!.createdAt, createdAt);
      expect(foundLocation.updatedAt, updatedAt);
    });

    test('deletes a location by id', () async {
      const location = Location(
        code: 'A-01-01',
        name: 'Rack A / Level 1 / Position 1',
      );

      final addedLocation = await dataSource.addLocation(location);

      await dataSource.deleteLocation(addedLocation.id!);

      final foundLocation = await dataSource.getLocationByCode('A-01-01');

      expect(foundLocation, isNull);
    });

    test('does not allow duplicate location codes', () async {
      const location = Location(
        code: 'A-01-01',
        name: 'Rack A / Level 1 / Position 1',
      );

      await dataSource.addLocation(location);

      expect(
        () => dataSource.addLocation(
          const Location(code: 'A-01-01', name: 'Another location'),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
