import '../entities/movement.dart';
import '../repositories/movement_repository.dart';

class GetMovementsByBoxNo {
  const GetMovementsByBoxNo(this.repository);

  final MovementRepository repository;

  Future<List<Movement>> call(String boxNo) {
    return repository.getByBoxNo(boxNo);
  }
}
