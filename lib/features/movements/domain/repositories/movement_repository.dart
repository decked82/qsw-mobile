import '../entities/movement.dart';

abstract interface class MovementRepository {
  Future<Movement?> getById(int id);

  Future<Movement?> getByOperationId(String operationId);

  Future<List<Movement>> getByBoxNo(String boxNo);

  Future<List<Movement>> getByPartNo(String partNo);

  Future<void> save(Movement movement);
}
