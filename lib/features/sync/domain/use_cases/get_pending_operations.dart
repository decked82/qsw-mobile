import '../entities/pending_operation.dart';
import '../repositories/pending_operation_repository.dart';

class GetPendingOperations {
  const GetPendingOperations(this.repository);

  final PendingOperationRepository repository;

  Future<List<PendingOperation>> call({int limit = 50}) {
    return repository.getPending(limit: limit);
  }
}
