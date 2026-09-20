import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/locations/domain/entities/location.dart';

import 'fake_location_repository.dart';

void main() {
  late FakeLocationRepository repository;

  setUp(() {
    repository = FakeLocationRepository();
  });

  group('FakeLocationRepository', () {
    test('adds and returns a location', () async {
      const location = Location(
        code: 'A-01-01',
        name: 'Rack A / Level 1 / Position 1',
      );

      final addedLocation = await repository.addLocation(location);
      final locations = await repository.getLocations();

      expect(addedLocation.id, 1);
      expect(addedLocation.code, 'A-01-01');
      expect(locations, hasLength(1));
      expect(locations.first.code, 'A-01-01');
    });

    test('finds a location by code', () async {
      const location = Location(
        code: 'B-02-03',
        name: 'Rack B / Level 2 / Position 3',
      );

      await repository.addLocation(location);

      final result = await repository.getLocationByCode('B-02-03');

      expect(result, isNotNull);
      expect(result!.code, 'B-02-03');
      expect(result.name, 'Rack B / Level 2 / Position 3');
    });

    test('returns null when location code is not found', () async {
      final result = await repository.getLocationByCode('C-99-99');

      expect(result, isNull);
    });

    test('searches locations by code or name', () async {
      await repository.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      await repository.addLocation(
        const Location(code: 'B-02-03', name: 'Rack B / Level 2 / Position 3'),
      );

      final byCode = await repository.searchLocations('B-02');
      final byName = await repository.searchLocations('Rack A');

      expect(byCode, hasLength(1));
      expect(byCode.first.code, 'B-02-03');

      expect(byName, hasLength(1));
      expect(byName.first.code, 'A-01-01');
    });

    test('search is case insensitive', () async {
      await repository.addLocation(
        const Location(code: 'A-01-01', name: 'Rack A / Level 1 / Position 1'),
      );

      final result = await repository.searchLocations('rack a');

      expect(result, hasLength(1));
      expect(result.first.code, 'A-01-01');
    });

    test('deletes a location by id', () async {
      const location = Location(
        code: 'A-01-01',
        name: 'Rack A / Level 1 / Position 1',
      );

      final addedLocation = await repository.addLocation(location);

      await repository.deleteLocation(addedLocation.id!);

      final locations = await repository.getLocations();

      expect(locations, isEmpty);
    });
  });
}
