import '../../features/boxes/data/repositories/sqlite_box_repository.dart';
import '../../features/boxes/domain/use_cases/get_box_by_box_no.dart';
import '../../features/locations/data/data_sources/sqlite_location_data_source.dart';
import '../../features/locations/data/repositories/sqlite_location_repository.dart';
import '../../features/locations/domain/repositories/location_repository.dart';
import '../../features/movements/data/repositories/sqlite_movement_repository.dart';
import '../../features/movements/domain/repositories/movement_repository.dart';
import '../../features/movements/domain/use_cases/get_movement_by_id.dart';
import '../../features/movements/domain/use_cases/get_movement_by_operation_id.dart';
import '../../features/movements/domain/use_cases/get_movements_by_box_no.dart';
import '../../features/movements/domain/use_cases/get_movements_by_part_no.dart';
import '../../features/movements/domain/use_cases/save_movement.dart';
import '../../features/parts/data/data_sources/sqlite_part_data_source.dart';
import '../../features/parts/data/repositories/sqlite_part_repository.dart';
import '../../features/parts/domain/repositories/part_repository.dart';
import '../../features/parts/domain/use_cases/add_part.dart';
import '../../features/parts/domain/use_cases/delete_part.dart';
import '../../features/parts/domain/use_cases/get_parts.dart';
import '../../features/parts/domain/use_cases/search_parts.dart';
import '../../features/sync/data/data_sources/not_configured_remote_sync_data_source.dart';
import '../../features/sync/data/data_sources/remote_sync_data_source.dart';
import '../../features/sync/data/repositories/sqlite_pending_operation_repository.dart';
import '../../features/sync/data/repositories/sqlite_sync_metadata_repository.dart';
import '../../features/sync/domain/repositories/pending_operation_repository.dart';
import '../../features/sync/domain/repositories/sync_metadata_repository.dart';
import '../../features/sync/domain/services/sync_engine.dart';
import '../../features/sync/domain/use_cases/get_pending_operation_by_operation_id.dart';
import '../../features/sync/domain/use_cases/get_pending_operations.dart';
import '../../features/sync/domain/use_cases/get_sync_metadata.dart';
import '../../features/sync/domain/use_cases/save_pending_operation.dart';
import '../../features/sync/domain/use_cases/save_sync_metadata.dart';
import '../../features/sync/domain/use_cases/update_pending_operation_status.dart';
import '../../features/sync/domain/use_cases/update_sync_metadata_status.dart';
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

  late final MovementRepository movementRepository;

  late final GetMovementById getMovementById;
  late final GetMovementByOperationId getMovementByOperationId;
  late final GetMovementsByBoxNo getMovementsByBoxNo;
  late final GetMovementsByPartNo getMovementsByPartNo;
  late final SaveMovement saveMovement;

  late final PendingOperationRepository pendingOperationRepository;

  late final RemoteSyncDataSource remoteSyncDataSource;
  late final SyncEngine syncEngine;

  late final GetPendingOperations getPendingOperations;
  late final GetPendingOperationByOperationId getPendingOperationByOperationId;
  late final SavePendingOperation savePendingOperation;
  late final UpdatePendingOperationStatus updatePendingOperationStatus;

  late final SyncMetadataRepository syncMetadataRepository;

  late final GetSyncMetadata getSyncMetadata;
  late final SaveSyncMetadata saveSyncMetadata;
  late final UpdateSyncMetadataStatus updateSyncMetadataStatus;

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

    movementRepository = SqliteMovementRepository(
      await databaseProvider.database,
    );

    getMovementById = GetMovementById(movementRepository);
    getMovementByOperationId = GetMovementByOperationId(movementRepository);
    getMovementsByBoxNo = GetMovementsByBoxNo(movementRepository);
    getMovementsByPartNo = GetMovementsByPartNo(movementRepository);
    saveMovement = SaveMovement(movementRepository);

    pendingOperationRepository = SqlitePendingOperationRepository(
      await databaseProvider.database,
    );

    remoteSyncDataSource = const NotConfiguredRemoteSyncDataSource();

    getPendingOperations = GetPendingOperations(pendingOperationRepository);
    getPendingOperationByOperationId = GetPendingOperationByOperationId(
      pendingOperationRepository,
    );
    savePendingOperation = SavePendingOperation(pendingOperationRepository);
    updatePendingOperationStatus = UpdatePendingOperationStatus(
      pendingOperationRepository,
    );

    syncEngine = SyncEngine(
      pendingOperationRepository: pendingOperationRepository,
      remoteSyncDataSource: remoteSyncDataSource,
    );

    syncMetadataRepository = SqliteSyncMetadataRepository(
      await databaseProvider.database,
    );

    getSyncMetadata = GetSyncMetadata(syncMetadataRepository);
    saveSyncMetadata = SaveSyncMetadata(syncMetadataRepository);
    updateSyncMetadataStatus = UpdateSyncMetadataStatus(syncMetadataRepository);

    addPart = AddPart(partRepository);
    getParts = GetParts(partRepository);
    searchParts = SearchParts(partRepository);
    deletePart = DeletePart(partRepository);

    getBoxByBoxNo = GetBoxByBoxNo(boxRepository);
  }
}
