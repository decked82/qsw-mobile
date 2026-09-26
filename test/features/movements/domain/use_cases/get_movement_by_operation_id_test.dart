import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/movements/domain/use_cases/get_movement_by_operation_id.dart';

class _FakeMovementRepository implements MovementRepository {
  Movement? movement;

  @override
  Future<Movement?> getById(int id) async {
    return null;
  }

  @override
  Future<Movement?> getByOperationId(String operationId) async {
    return movement;
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
  Future<void> save(Movement movement) async {}
}

void main() {
  test('returns movement from repository by operation id', () async {
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

    repository.movement = movement;

    final useCase = GetMovementByOperationId(repository);

    final result = await useCase('OP-001');

    expect(result, same(movement));
  });
}
