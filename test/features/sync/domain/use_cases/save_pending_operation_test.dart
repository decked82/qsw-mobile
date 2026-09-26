import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/use_cases/save_pending_operation.dart';

class _FakePendingOperationRepository implements PendingOperationRepository {
  PendingOperation? savedOperation;

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
    return [];
  }

  @override
  Future<void> save(PendingOperation operation) async {
    savedOperation = operation;
  }

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
  test('saves pending operation through repository', () async {
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

    final useCase = SavePendingOperation(repository);

    await useCase(operation);

    expect(repository.savedOperation, same(operation));
  });
}
