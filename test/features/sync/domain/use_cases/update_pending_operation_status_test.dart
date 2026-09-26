import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/pending_operation_repository.dart';
import 'package:qsw_mobile/features/sync/domain/use_cases/update_pending_operation_status.dart';

class _FakePendingOperationRepository implements PendingOperationRepository {
  int? updatedId;
  PendingOperationStatus? updatedStatus;
  DateTime? updatedLastAttemptAt;
  String? updatedLastError;

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
  Future<void> save(PendingOperation operation) async {}

  @override
  Future<void> updateStatus({
    required int id,
    required PendingOperationStatus status,
    DateTime? lastAttemptAt,
    String? lastError,
    int? retryCount,
  }) async {
    updatedId = id;
    updatedStatus = status;
    updatedLastAttemptAt = lastAttemptAt;
    updatedLastError = lastError;
  }
}

void main() {
  test('updates pending operation status through repository', () async {
    final repository = _FakePendingOperationRepository();
    final lastAttemptAt = DateTime(2026, 1, 2);

    final useCase = UpdatePendingOperationStatus(repository);

    await useCase(
      id: 1,
      status: PendingOperationStatus.failed,
      lastAttemptAt: lastAttemptAt,
      lastError: 'Network error',
    );

    expect(repository.updatedId, 1);
    expect(repository.updatedStatus, PendingOperationStatus.failed);
    expect(repository.updatedLastAttemptAt, lastAttemptAt);
    expect(repository.updatedLastError, 'Network error');
  });
}
