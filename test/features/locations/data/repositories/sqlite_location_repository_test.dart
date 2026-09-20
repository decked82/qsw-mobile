import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/locations/data/data_sources/location_data_source.dart';
import 'package:qsw_mobile/features/locations/data/repositories/sqlite_location_repository.dart';
import 'package:qsw_mobile/features/locations/domain/entities/location.dart';

class FakeLocationDataSource implements LocationDataSource {
  final List<Location> _locations = [];

  @override
  Future<Location> addLocation(Location location) async {
    final addedLocation = Location(
      id: location.id ?? _locations.length + 1,
      code: location.code,
      name: location.name,
      description: location.description,
      isActive: location.isActive,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt,
    );

    _locations.add(addedLocation);

    return addedLocation;
  }

  @override
  Future<List<Location>> getLocations() async {
    return List.unmodifiable(_locations);
  }

  @override
  Future<Location?> getLocationByCode(String code) async {
    for (final location in _locations) {
      if (location.code == code) {
        return location;
      }
    }

    return null;
  }

  @override
  Future<List<Location>> searchLocations(String query) async {
    final normalizedQuery = query.toLowerCase();

    return _locations.where((location) {
      return location.code.toLowerCase().contains(normalizedQuery) ||
          location.name.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<void> deleteLocation(int id) async {
    _locations.removeWhere((location) => location.id == id);
  }
}

void main() {
  late FakeLocationDataSource dataSource;
  late SqliteLocationRepository repository;

  setUp(() {
    dataSource = FakeLocationDataSource();
    repository = SqliteLocationRepository(dataSource);
  });

  group('SqliteLocationRepository', () {
    test('adds and returns a location', () async {
      const location = Location(
        code: 'A-01-01',
        name: 'Rack A / Level 1 / Position 1',
      );

      final addedLocation = await repository.addLocation(location);

      expect(addedLocation.id, 1);
      expect(addedLocation.code, 'A-01-01');
      expect(addedLocation.name, 'Rack A / Level 1 / Position 1');
    });

    test('gets all locations', () async {
      await repository.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      await repository.addLocation(
        const Location(code: 'B-02-03', name: 'Rack B / Level 2 / Position 3'),
      );

      final locations = await repository.getLocations();

      expect(locations, hasLength(2));
      expect(locations[0].code, 'A-01-01');
      expect(locations[1].code, 'B-02-03');
    });

    test('gets a location by code', () async {
      await repository.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      final location = await repository.getLocationByCode('A-01-01');

      expect(location, isNotNull);
      expect(location!.code, 'A-01-01');
    });

    test('returns null when location code does not exist', () async {
      final location = await repository.getLocationByCode('Z-99-99');

      expect(location, isNull);
    });

    test('searches locations', () async {
      await repository.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      await repository.addLocation(
        const Location(code: 'B-02-03', name: 'Rack B / Level 2 / Position 3'),
      );

      final results = await repository.searchLocations('Rack B');

      expect(results, hasLength(1));
      expect(results.first.code, 'B-02-03');
    });

    test('deletes a location', () async {
      final addedLocation = await repository.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      await repository.deleteLocation(addedLocation.id!);

      final locations = await repository.getLocations();

      expect(locations, isEmpty);
    });
  });
}
