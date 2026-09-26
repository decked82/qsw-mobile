import '../entities/pending_operation.dart';
import '../repositories/pending_operation_repository.dart';

class GetPendingOperationByOperationId {
  const GetPendingOperationByOperationId(this.repository);

  final PendingOperationRepository repository;

  Future<PendingOperation?> call(String operationId) {
    return repository.getByOperationId(operationId);
  }
}
