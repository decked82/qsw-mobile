import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/use_cases/get_pending_operations.dart';

class _FakePendingOperationRepository implements PendingOperationRepository {
  final List<PendingOperation> operations = [];
  int? requestedLimit;

  @override
  Future<PendingOperation?> getById(int id) async {
    return null;
  }

  @override
  Future<PendingOperation?> getByOperationId(String operationId) async {
    return null;
  }

  @override
  Future<List<PendingOperation>> getPending({int limit = 50}) async {
    requestedLimit = limit;
    return operations;
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
  test('returns pending operations with requested limit', () async {
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

    repository.operations.add(operation);

    final useCase = GetPendingOperations(repository);

    final result = await useCase(limit: 10);

    expect(result, hasLength(1));
    expect(result.first, same(operation));
    expect(repository.requestedLimit, 10);
  });
}
