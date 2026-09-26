import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/core/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'initializes part, location, box, movement, and sync dependencies',
    () async {
      final serviceLocator = ServiceLocator.instance;

      await serviceLocator.initialize();

      expect(serviceLocator.databaseProvider, isNotNull);

      expect(serviceLocator.partDataSource, isNotNull);
      expect(serviceLocator.partRepository, isNotNull);

      expect(serviceLocator.locationDataSource, isNotNull);
      expect(serviceLocator.locationRepository, isNotNull);

      expect(serviceLocator.boxRepository, isNotNull);

      expect(serviceLocator.movementRepository, isNotNull);

      expect(serviceLocator.pendingOperationRepository, isNotNull);
      expect(serviceLocator.syncMetadataRepository, isNotNull);

      expect(serviceLocator.addPart, isNotNull);
      expect(serviceLocator.getParts, isNotNull);
      expect(serviceLocator.searchParts, isNotNull);
      expect(serviceLocator.deletePart, isNotNull);

      expect(serviceLocator.getBoxByBoxNo, isNotNull);

      expect(serviceLocator.getMovementById, isNotNull);
      expect(serviceLocator.getMovementByOperationId, isNotNull);
      expect(serviceLocator.getMovementsByBoxNo, isNotNull);
      expect(serviceLocator.getMovementsByPartNo, isNotNull);
      expect(serviceLocator.saveMovement, isNotNull);

      expect(serviceLocator.getPendingOperations, isNotNull);
      expect(serviceLocator.getPendingOperationByOperationId, isNotNull);
      expect(serviceLocator.savePendingOperation, isNotNull);
      expect(serviceLocator.updatePendingOperationStatus, isNotNull);

      expect(serviceLocator.getSyncMetadata, isNotNull);
      expect(serviceLocator.saveSyncMetadata, isNotNull);
      expect(serviceLocator.updateSyncMetadataStatus, isNotNull);

      await serviceLocator.databaseProvider.close();

      final databasePath = await getDatabasesPath();
      final path = '$databasePath/qsw.db';

      await deleteDatabase(path);
    },
  );
}
