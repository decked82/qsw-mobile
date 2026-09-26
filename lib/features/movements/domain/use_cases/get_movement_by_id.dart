import '../entities/movement.dart';
import '../repositories/movement_repository.dart';

class GetMovementById {
  const GetMovementById(this.repository);

  final MovementRepository repository;

  Future<Movement?> call(int id) {
    return repository.getById(id);
  }
}
