import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/movements/domain/use_cases/save_movement.dart';

class _FakeMovementRepository implements MovementRepository {
  Movement? savedMovement;

  @override
  Future<Movement?> getById(int id) async {
    return null;
  }

  @override
  Future<Movement?> getByOperationId(String operationId) async {
    return null;
  }

  @override
  Future<List<Movement>> getByBoxNo(String boxNo) async {
    return [];
  }

  @override
  Future<List<Movement>> getByPartNo(String partNo) async {
    return [];
  }

  @override
  Future<void> save(Movement movement) async {
    savedMovement = movement;
  }
}

void main() {
  test('saves movement through repository', () async {
    final repository = _FakeMovementRepository();
    final movement = Movement(
      id: 1,
      operationId: 'OP-001',
      type: MovementType.inbound,
      boxNo: 'BOX-001',
      partNo: 'PART-001',
      quantity: 10,
      createdAt: DateTime(2026, 1, 1),
    );

    final useCase = SaveMovement(repository);

    await useCase(movement);

    expect(repository.savedMovement, same(movement));
  });
}
