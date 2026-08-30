import 'package:qsw_mobile/features/parts/domain/entities/part.dart';
import 'package:qsw_mobile/features/parts/domain/repositories/part_repository.dart';

class FakePartRepository implements PartRepository {
  final List<Part> _parts = [];
  int _nextId = 1;

  @override
  Future<Part> addPart(Part part) async {
    final savedPart = Part(
      id: _nextId++,
      partCode: part.partCode,
      name: part.name,
      specification: part.specification,
      barcode: part.barcode,
      unit: part.unit,
      createdAt: part.createdAt,
      updatedAt: part.updatedAt,
    );

    _parts.add(savedPart);

    return savedPart;
  }

  @override
  Future<List<Part>> getParts() async {
    return List.unmodifiable(_parts.reversed);
  }

  @override
  Future<List<Part>> searchParts(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(_parts.reversed);
    }

    return List.unmodifiable(
      _parts.reversed.where(
        (part) =>
            part.partCode.toLowerCase().contains(normalizedQuery) ||
            part.name.toLowerCase().contains(normalizedQuery) ||
            (part.barcode?.toLowerCase().contains(normalizedQuery) ?? false),
      ),
    );
  }

  @override
  Future<void> deletePart(int id) async {
    _parts.removeWhere((part) => part.id == id);
  }
}
