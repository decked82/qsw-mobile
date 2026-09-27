import 'package:sqflite/sqflite.dart';

import '../../domain/entities/box.dart';
import '../../domain/repositories/box_repository.dart';

class SqliteBoxRepository implements BoxRepository {
  final Database database;

  SqliteBoxRepository(this.database);

  @override
  Future<Box?> getByBoxNo(String boxNo) async {
    final maps = await database.query(
      'boxes',
      where: 'box_no = ?',
      whereArgs: [boxNo],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  @override
  Future<List<Box>> getAll() async {
    final maps = await database.query('boxes');

    return maps.map(_fromMap).toList();
  }

  @override
  Future<void> save(Box box) async {
    await database.insert(
      'boxes',
      _toMap(box),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveAll(List<Box> boxes) async {
    final batch = database.batch();

    for (final box in boxes) {
      batch.insert(
        'boxes',
        _toMap(box),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> delete(String boxNo) async {
    await database.delete('boxes', where: 'box_no = ?', whereArgs: [boxNo]);
  }

  Box _fromMap(Map<String, Object?> map) {
    return Box(
      boxNo: map['box_no'] as String,
      partNo: map['part_no'] as String,
      quantity: map['quantity'] as int,
      location: map['location'] as String?,
      status: map['status'] as String?,
    );
  }

  Map<String, Object?> _toMap(Box box) {
    return {
      'box_no': box.boxNo,
      'part_no': box.partNo,
      'quantity': box.quantity,
      'location': box.location,
      'status': box.status,
    };
  }
}
