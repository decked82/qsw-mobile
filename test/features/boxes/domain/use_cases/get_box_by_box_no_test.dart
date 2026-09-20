import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/boxes/domain/entities/box.dart';
import 'package:qsw_mobile/features/boxes/domain/repositories/box_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/use_cases/get_box_by_box_no.dart';

class FakeBoxRepository implements BoxRepository {
  final Map<String, Box> boxes = {};

  @override
  Future<Box?> getByBoxNo(String boxNo) async {
    return boxes[boxNo];
  }

  @override
  Future<List<Box>> getAll() async {
    return boxes.values.toList();
  }

  @override
  Future<void> save(Box box) async {
    boxes[box.boxNo] = box;
  }

  @override
  Future<void> saveAll(List<Box> boxes) async {
    for (final box in boxes) {
      this.boxes[box.boxNo] = box;
    }
  }

  @override
  Future<void> delete(String boxNo) async {
    boxes.remove(boxNo);
  }
}

void main() {
  late FakeBoxRepository repository;
  late GetBoxByBoxNo useCase;

  setUp(() {
    repository = FakeBoxRepository();
    useCase = GetBoxByBoxNo(repository);
  });

  test('returns box when BOX NO exists', () async {
    const box = Box(
      boxNo: 'HSF2609110012',
      partNo: 'T46053-0290',
      quantity: 400,
      location: 'A-01-03',
      status: 'IN_STOCK',
    );

    await repository.save(box);

    final result = await useCase('HSF2609110012');

    expect(result, isNotNull);
    expect(result!.boxNo, 'HSF2609110012');
    expect(result.partNo, 'T46053-0290');
    expect(result.quantity, 400);
    expect(result.location, 'A-01-03');
    expect(result.status, 'IN_STOCK');
  });

  test('returns null when BOX NO does not exist', () async {
    final result = await useCase('UNKNOWN_BOX');

    expect(result, isNull);
  });
}
