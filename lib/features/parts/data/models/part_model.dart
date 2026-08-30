import '../../domain/entities/part.dart';

class PartModel extends Part {
  const PartModel({
    super.id,
    required super.partCode,
    required super.name,
    super.specification,
    super.barcode,
    super.unit,
    super.createdAt,
    super.updatedAt,
  });

  factory PartModel.fromMap(Map<String, dynamic> map) {
    return PartModel(
      id: map['id'] as int?,
      partCode: map['part_code'] as String,
      name: map['name'] as String,
      specification: map['specification'] as String?,
      barcode: map['barcode'] as String?,
      unit: map['unit'] as String? ?? 'EA',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'part_code': partCode,
      'name': name,
      'specification': specification,
      'barcode': barcode,
      'unit': unit,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PartModel.fromEntity(Part part) {
    return PartModel(
      id: part.id,
      partCode: part.partCode,
      name: part.name,
      specification: part.specification,
      barcode: part.barcode,
      unit: part.unit,
      createdAt: part.createdAt,
      updatedAt: part.updatedAt,
    );
  }
}
