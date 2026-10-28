import 'package:uuid/uuid.dart';

import '../../../../core/database/sqlite/sqlite_database_provider.dart';
import '../models/part_model.dart';

class SqlitePartDataSource {
  SqlitePartDataSource(
    this._databaseProvider, {
    Uuid? uuid,
    DateTime Function()? clock,
  }) : _uuid = uuid ?? const Uuid(),
       _clock = clock ?? DateTime.now;

  final SqliteDatabaseProvider _databaseProvider;
  final Uuid _uuid;
  final DateTime Function() _clock;

  Future<PartModel> addPart(PartModel part) async {
    final db = await _databaseProvider.database;
    final now = _clock();
    final preparedPart = PartModel(
      partCode: part.partCode,
      name: part.name,
      specification: part.specification,
      barcode: part.barcode,
      unit: part.unit,
      createdAt: part.createdAt ?? now,
      updatedAt: part.updatedAt ?? now,
      syncId: part.syncId ?? _uuid.v4(),
      isDeleted: part.isDeleted,
      deletedAt: part.deletedAt,
    );

    final id = await db.insert('parts', preparedPart.toMap()..remove('id'));

    return PartModel.fromMap({...preparedPart.toMap(), 'id': id});
  }

  Future<List<PartModel>> getParts() async {
    final db = await _databaseProvider.database;

    final maps = await db.query(
      'parts',
      where: 'is_deleted = 0',
      orderBy: 'id DESC',
    );

    return maps.map(PartModel.fromMap).toList();
  }

  Future<List<PartModel>> searchParts(String query) async {
    final db = await _databaseProvider.database;

    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return getParts();
    }

    final maps = await db.query(
      'parts',
      where: '''
        is_deleted = 0 AND (
          part_code LIKE ? OR
          name LIKE ? OR
          specification LIKE ? OR
          barcode LIKE ?
        )
      ''',
      whereArgs: [
        '%$normalizedQuery%',
        '%$normalizedQuery%',
        '%$normalizedQuery%',
        '%$normalizedQuery%',
      ],
      orderBy: 'id DESC',
    );

    return maps.map(PartModel.fromMap).toList();
  }

  Future<void> deletePart(int id) async {
    final db = await _databaseProvider.database;
    final now = _clock().toIso8601String();

    await db.update(
      'parts',
      {'is_deleted': 1, 'deleted_at': now, 'updated_at': now},
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
  }
}
