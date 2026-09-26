import '../entities/pending_operation.dart';
import '../repositories/pending_operation_repository.dart';

class SavePendingOperation {
  const SavePendingOperation(this.repository);

  final PendingOperationRepository repository;

  Future<void> call(PendingOperation operation) {
    return repository.save(operation);
  }
}
