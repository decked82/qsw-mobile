import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

void main() {
  group('PendingOperation', () {
    test('creates a pending operation', () {
      final createdAt = DateTime(2026, 9, 21, 10, 30);

      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{"boxNo":"HSF2609110012","quantity":400}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: createdAt,
      );

      expect(operation.id, 1);
      expect(operation.operationId, 'operation-001');
      expect(operation.type, 'INBOUND');
      expect(operation.entityType, 'MOVEMENT');
      expect(operation.entityId, '1');
      expect(operation.payload, '{"boxNo":"HSF2609110012","quantity":400}');
      expect(operation.status, PendingOperationStatus.pending);
      expect(operation.retryCount, 0);
      expect(operation.createdAt, createdAt);
      expect(operation.lastAttemptAt, isNull);
      expect(operation.lastError, isNull);
    });

    test('creates a failed operation with retry information', () {
      final createdAt = DateTime(2026, 9, 21, 10, 30);
      final lastAttemptAt = DateTime(2026, 9, 21, 10, 35);

      final operation = PendingOperation(
        id: 2,
        operationId: 'operation-002',
        type: 'MOVE',
        entityType: 'MOVEMENT',
        entityId: '2',
        payload: '{}',
        status: PendingOperationStatus.failed,
        retryCount: 3,
        createdAt: createdAt,
        lastAttemptAt: lastAttemptAt,
        lastError: 'Network unavailable',
      );

      expect(operation.status, PendingOperationStatus.failed);
      expect(operation.retryCount, 3);
      expect(operation.lastAttemptAt, lastAttemptAt);
      expect(operation.lastError, 'Network unavailable');
    });
  });
}
