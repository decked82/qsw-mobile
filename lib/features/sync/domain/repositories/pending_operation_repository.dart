import '../entities/pending_operation.dart';

abstract interface class PendingOperationRepository {
  Future<PendingOperation?> getById(int id);

  Future<PendingOperation?> getByOperationId(String operationId);

  Future<List<PendingOperation>> getPending({int limit = 50});

  Future<void> save(PendingOperation operation);

  Future<void> updateStatus({
    required int id,
    required PendingOperationStatus status,
    DateTime? lastAttemptAt,
    String? lastError,
    int? retryCount,
  });
}
