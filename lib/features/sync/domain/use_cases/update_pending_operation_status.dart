import '../entities/pending_operation.dart';
import '../repositories/pending_operation_repository.dart';

class UpdatePendingOperationStatus {
  const UpdatePendingOperationStatus(this.repository);

  final PendingOperationRepository repository;

  Future<void> call({
    required int id,
    required PendingOperationStatus status,
    DateTime? lastAttemptAt,
    String? lastError,
  }) {
    return repository.updateStatus(
      id: id,
      status: status,
      lastAttemptAt: lastAttemptAt,
      lastError: lastError,
    );
  }
}
