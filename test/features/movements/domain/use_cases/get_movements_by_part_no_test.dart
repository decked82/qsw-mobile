import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/movements/domain/entities/movement.dart';
import 'package:qsw_mobile/features/movements/domain/repositories/movement_repository.dart';
import 'package:qsw_mobile/features/movements/domain/use_cases/get_movements_by_part_no.dart';

class _FakeMovementRepository implements MovementRepository {
  final List<Movement> movements = [];

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
    return movements;
  }

  @override
  Future<void> save(Movement movement) async {}
}

void main() {
  test('returns movements from repository by part number', () async {
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

    repository.movements.add(movement);

    final useCase = GetMovementsByPartNo(repository);

    final result = await useCase('PART-001');

    expect(result, hasLength(1));
    expect(result.first, same(movement));
  });
}
