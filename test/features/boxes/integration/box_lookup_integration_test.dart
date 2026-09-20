import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/core/di/service_locator.dart';
import 'package:qsw_mobile/features/boxes/domain/entities/box.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('looks up boxes by BOX NO through ServiceLocator', () async {
    final serviceLocator = ServiceLocator.instance;

    await serviceLocator.initialize();

    try {
      const box = Box(
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        quantity: 400,
        location: 'A-01-03',
        status: 'IN_STOCK',
      );

      await serviceLocator.boxRepository.save(box);

      final existingBox = await serviceLocator.getBoxByBoxNo('HSF2609110012');

      expect(existingBox, isNotNull);
      expect(existingBox!.boxNo, equals('HSF2609110012'));
      expect(existingBox.partNo, equals('T46053-0290'));
      expect(existingBox.quantity, equals(400));
      expect(existingBox.location, equals('A-01-03'));
      expect(existingBox.status, equals('IN_STOCK'));

      final missingBox = await serviceLocator.getBoxByBoxNo('UNKNOWN_BOX');

      expect(missingBox, isNull);
    } finally {
      await serviceLocator.databaseProvider.close();

      final databasePath = await getDatabasesPath();
      final path = '$databasePath/qsw.db';

      await deleteDatabase(path);
    }
  });
}
