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

  late final AddPart addPart;
  late final GetParts getParts;
  late final DeletePart deletePart;
  late final SearchParts searchParts;

  Future<void> initialize() async {
    databaseProvider = SqliteDatabaseProvider();

    partDataSource = SqlitePartDataSource(databaseProvider);

    partRepository = SqlitePartRepository(partDataSource);

    addPart = AddPart(partRepository);
    getParts = GetParts(partRepository);
    searchParts = SearchParts(partRepository);
    deletePart = DeletePart(partRepository);
  }
}
