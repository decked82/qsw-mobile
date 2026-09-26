import '../entities/movement.dart';
import '../repositories/movement_repository.dart';

class SaveMovement {
  const SaveMovement(this.repository);

  final MovementRepository repository;

  Future<void> call(Movement movement) {
    return repository.save(movement);
  }
}
