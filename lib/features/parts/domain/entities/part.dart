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
    this.syncId,
    this.isDeleted = false,
    this.deletedAt,
  });

  final int? id;
  final String partCode;
  final String name;
  final String? specification;
  final String? barcode;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Стабильный идентификатор детали для синхронизации устройств.
  ///
  /// У существующих записей может быть null до этапа миграции
  /// и согласования каталога.
  final String? syncId;

  /// Логическое удаление. Удалённые записи нужны для передачи
  /// удаления на другие устройства.
  final bool isDeleted;

  /// Время логического удаления.
  final DateTime? deletedAt;
}
