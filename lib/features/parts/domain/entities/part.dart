class Part {
  const Part({
    this.id,
    required this.partCode,
    required this.name,
    this.specification,
    this.barcode,
    this.unit = 'EA',
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String partCode;
  final String name;
  final String? specification;
  final String? barcode;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
