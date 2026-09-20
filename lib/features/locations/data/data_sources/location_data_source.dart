import '../../domain/entities/location.dart';

abstract interface class LocationDataSource {
  Future<Location> addLocation(Location location);

  Future<List<Location>> getLocations();

  Future<Location?> getLocationByCode(String code);

  Future<List<Location>> searchLocations(String query);

  Future<void> deleteLocation(int id);
}
