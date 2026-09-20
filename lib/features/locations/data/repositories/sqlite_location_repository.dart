import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../data_sources/location_data_source.dart';

class SqliteLocationRepository implements LocationRepository {
  SqliteLocationRepository(this._dataSource);

  final LocationDataSource _dataSource;

  @override
  Future<Location> addLocation(Location location) {
    return _dataSource.addLocation(location);
  }

  @override
  Future<List<Location>> getLocations() {
    return _dataSource.getLocations();
  }

  @override
  Future<Location?> getLocationByCode(String code) {
    return _dataSource.getLocationByCode(code);
  }

  @override
  Future<List<Location>> searchLocations(String query) {
    return _dataSource.searchLocations(query);
  }

  @override
  Future<void> deleteLocation(int id) {
    return _dataSource.deleteLocation(id);
  }
}
