import '../entities/movement.dart';
import '../repositories/movement_repository.dart';

class GetMovementByOperationId {
  const GetMovementByOperationId(this.repository);

  final MovementRepository repository;

  Future<Movement?> call(String operationId) {
    return repository.getByOperationId(operationId);
  }
}
