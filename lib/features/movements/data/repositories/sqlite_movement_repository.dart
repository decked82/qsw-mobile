import 'package:sqflite/sqflite.dart';

import '../../domain/entities/movement.dart';
import '../../domain/repositories/movement_repository.dart';

class SqliteMovementRepository implements MovementRepository {
  final Database database;

  SqliteMovementRepository(this.database);

  @override
  Future<Movement?> getById(int id) async {
    final maps = await database.query(
      'movements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  @override
  Future<Movement?> getByOperationId(String operationId) async {
    final maps = await database.query(
      'movements',
      where: 'operation_id = ?',
      whereArgs: [operationId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  @override
  Future<List<Movement>> getByBoxNo(String boxNo) async {
    final maps = await database.query(
      'movements',
      where: 'box_no = ?',
      whereArgs: [boxNo],
      orderBy: 'created_at ASC',
    );

    return maps.map(_fromMap).toList();
  }

  @override
  Future<List<Movement>> getByPartNo(String partNo) async {
    final maps = await database.query(
      'movements',
      where: 'part_no = ?',
      whereArgs: [partNo],
      orderBy: 'created_at ASC',
    );

    return maps.map(_fromMap).toList();
  }

  @override
  Future<void> save(Movement movement) async {
    final values = _toMap(movement);

    if (movement.id == 0) {
      values.remove('id');
    }

    await database.insert(
      'movements',
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Movement _fromMap(Map<String, Object?> map) {
    return Movement(
      id: map['id'] as int,
      operationId: map['operation_id'] as String,
      type: _movementTypeFromString(map['type'] as String),
      boxNo: map['box_no'] as String,
      partNo: map['part_no'] as String,
      fromLocation: map['from_location'] as String?,
      toLocation: map['to_location'] as String?,
      quantity: map['quantity'] as int,
      userId: map['user_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> _toMap(Movement movement) {
    return {
      'id': movement.id,
      'operation_id': movement.operationId,
      'type': _movementTypeToString(movement.type),
      'box_no': movement.boxNo,
      'part_no': movement.partNo,
      'from_location': movement.fromLocation,
      'to_location': movement.toLocation,
      'quantity': movement.quantity,
      'user_id': movement.userId,
      'created_at': movement.createdAt.toIso8601String(),
    };
  }

  MovementType _movementTypeFromString(String value) {
    return switch (value) {
      'INBOUND' => MovementType.inbound,
      'OUTBOUND' => MovementType.outbound,
      'MOVE' => MovementType.move,
      'ADJUSTMENT' => MovementType.adjustment,
      _ => throw ArgumentError('Unknown movement type: $value'),
    };
  }

  String _movementTypeToString(MovementType type) {
    return switch (type) {
      MovementType.inbound => 'INBOUND',
      MovementType.outbound => 'OUTBOUND',
      MovementType.move => 'MOVE',
      MovementType.adjustment => 'ADJUSTMENT',
    };
  }
}
