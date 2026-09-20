import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/core/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('initializes part, location, and box dependencies', () async {
    final serviceLocator = ServiceLocator.instance;

    await serviceLocator.initialize();

    expect(serviceLocator.databaseProvider, isNotNull);

    expect(serviceLocator.partDataSource, isNotNull);
    expect(serviceLocator.partRepository, isNotNull);

    expect(serviceLocator.locationDataSource, isNotNull);
    expect(serviceLocator.locationRepository, isNotNull);

    expect(serviceLocator.boxRepository, isNotNull);

    expect(serviceLocator.addPart, isNotNull);
    expect(serviceLocator.getParts, isNotNull);
    expect(serviceLocator.searchParts, isNotNull);
    expect(serviceLocator.deletePart, isNotNull);

    expect(serviceLocator.getBoxByBoxNo, isNotNull);

    await serviceLocator.databaseProvider.close();

    final databasePath = await getDatabasesPath();
    final path = '$databasePath/qsw.db';

    await deleteDatabase(path);
  });
}
