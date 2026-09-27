import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/sync/data/data_sources/not_configured_remote_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

void main() {
  group('NotConfiguredRemoteSyncDataSource', () {
    test('throws StateError when sync is attempted', () async {
      const dataSource = NotConfiguredRemoteSyncDataSource();

      final operation = PendingOperation(
        id: 1,
        operationId: 'operation-001',
        type: 'INBOUND',
        entityType: 'MOVEMENT',
        entityId: '1',
        payload: '{"boxNo":"HSF2609110012","quantity":400}',
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: DateTime(2026, 9, 24, 10, 30),
      );

      expect(
        () => dataSource.sync(operation),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Remote sync data source is not configured.',
          ),
        ),
      );
    });
  });
}
