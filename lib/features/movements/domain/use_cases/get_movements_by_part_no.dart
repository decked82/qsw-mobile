import '../entities/movement.dart';
import '../repositories/movement_repository.dart';

class GetMovementsByPartNo {
  const GetMovementsByPartNo(this.repository);

  final MovementRepository repository;

  Future<List<Movement>> call(String partNo) {
    return repository.getByPartNo(partNo);
  }
}
