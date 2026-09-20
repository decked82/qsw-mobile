import '../../features/boxes/data/repositories/sqlite_box_repository.dart';
import '../../features/boxes/domain/use_cases/get_box_by_box_no.dart';
import '../../features/locations/data/data_sources/sqlite_location_data_source.dart';
import '../../features/locations/data/repositories/sqlite_location_repository.dart';
import '../../features/locations/domain/repositories/location_repository.dart';
import '../../features/parts/data/data_sources/sqlite_part_data_source.dart';
import '../../features/parts/data/repositories/sqlite_part_repository.dart';
import '../../features/parts/domain/repositories/part_repository.dart';
import '../../features/parts/domain/use_cases/add_part.dart';
import '../../features/parts/domain/use_cases/delete_part.dart';
import '../../features/parts/domain/use_cases/get_parts.dart';
import '../../features/parts/domain/use_cases/search_parts.dart';
import '../database/sqlite/sqlite_database_provider.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final SqliteDatabaseProvider databaseProvider;

  late final SqlitePartDataSource partDataSource;
  late final PartRepository partRepository;

  late final SqliteLocationDataSource locationDataSource;
  late final LocationRepository locationRepository;

  late final SqliteBoxRepository boxRepository;
  late final GetBoxByBoxNo getBoxByBoxNo;

  late final AddPart addPart;
  late final GetParts getParts;
  late final DeletePart deletePart;
  late final SearchParts searchParts;

  Future<void> initialize() async {
    databaseProvider = SqliteDatabaseProvider();

    partDataSource = SqlitePartDataSource(databaseProvider);
    partRepository = SqlitePartRepository(partDataSource);

    locationDataSource = SqliteLocationDataSource(
      await databaseProvider.database,
    );
    locationRepository = SqliteLocationRepository(locationDataSource);

    boxRepository = SqliteBoxRepository(await databaseProvider.database);

    addPart = AddPart(partRepository);
    getParts = GetParts(partRepository);
    searchParts = SearchParts(partRepository);
    deletePart = DeletePart(partRepository);

    getBoxByBoxNo = GetBoxByBoxNo(boxRepository);
  }
}
