import 'package:qsw_mobile/features/locations/domain/entities/location.dart';
import 'package:qsw_mobile/features/locations/domain/repositories/location_repository.dart';

class FakeLocationRepository implements LocationRepository {
  final List<Location> _locations = [];

  @override
  Future<Location> addLocation(Location location) async {
    final newLocation = Location(
      id: location.id ?? _locations.length + 1,
      code: location.code,
      name: location.name,
      description: location.description,
      isActive: location.isActive,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt,
    );

    _locations.add(newLocation);

    return newLocation;
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
