import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';

void main() {
  group('Movement', () {
    test('creates an inbound movement', () {
      final createdAt = DateTime(2026, 9, 21, 10, 30);

      final movement = Movement(
        id: 1,
        operationId: 'operation-001',
        type: MovementType.inbound,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        toLocation: 'A-01-03',
        quantity: 400,
        userId: 'user-001',
        createdAt: createdAt,
      );

      expect(movement.id, 1);
      expect(movement.operationId, 'operation-001');
      expect(movement.type, MovementType.inbound);
      expect(movement.boxNo, 'HSF2609110012');
      expect(movement.partNo, 'T46053-0290');
      expect(movement.fromLocation, isNull);
      expect(movement.toLocation, 'A-01-03');
      expect(movement.quantity, 400);
      expect(movement.userId, 'user-001');
      expect(movement.createdAt, createdAt);
    });

    test('creates a move movement', () {
      final movement = Movement(
        id: 2,
        operationId: 'operation-002',
        type: MovementType.move,
        boxNo: 'HSF2609110012',
        partNo: 'T46053-0290',
        fromLocation: 'A-01-03',
        toLocation: 'B-02-01',
        quantity: 400,
        createdAt: DateTime(2026, 9, 21, 11, 0),
      );

      expect(movement.type, MovementType.move);
      expect(movement.fromLocation, 'A-01-03');
      expect(movement.toLocation, 'B-02-01');
    });
  });
}
