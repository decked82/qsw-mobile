import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/use_cases/get_pending_operation_by_operation_id.dart';

class _FakePendingOperationRepository implements PendingOperationRepository {
  PendingOperation? operation;

  @override
  Future<PendingOperation?> getById(int id) async {
    return null;
  }

  @override
  Future<PendingOperation?> getByOperationId(String operationId) async {
    return operation;
  }

  @override
  Future<List<PendingOperation>> getPending({int limit = 50}) async {
    return [];
  }

  @override
  Future<void> save(PendingOperation operation) async {}

  @override
  Future<void> updateStatus({
    required int id,
    required PendingOperationStatus status,
    DateTime? lastAttemptAt,
    String? lastError,
    int? retryCount,
  }) async {}
}

void main() {
  test('returns pending operation by operation id', () async {
    final repository = _FakePendingOperationRepository();
    final operation = PendingOperation(
      id: 1,
      operationId: 'OP-001',
      type: 'CREATE',
      entityType: 'MOVEMENT',
      entityId: '1',
      payload: '{}',
      status: PendingOperationStatus.pending,
      retryCount: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    repository.operation = operation;

    final useCase = GetPendingOperationByOperationId(repository);

    final result = await useCase('OP-001');

    expect(result, same(operation));
  });
}
