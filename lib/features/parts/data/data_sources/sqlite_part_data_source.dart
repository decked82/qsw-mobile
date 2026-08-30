import '../../../../core/database/sqlite/sqlite_database_provider.dart';
import '../models/part_model.dart';

class SqlitePartDataSource {
  SqlitePartDataSource(this._databaseProvider);

  final SqliteDatabaseProvider _databaseProvider;

  Future<PartModel> addPart(PartModel part) async {
    final db = await _databaseProvider.database;

    final id = await db.insert('parts', part.toMap()..remove('id'));

    return PartModel(
      id: id,
      partCode: part.partCode,
      name: part.name,
      specification: part.specification,
      barcode: part.barcode,
      unit: part.unit,
      createdAt: part.createdAt,
      updatedAt: part.updatedAt,
    );
  }

  Future<List<PartModel>> getParts() async {
    final db = await _databaseProvider.database;

    final maps = await db.query('parts', orderBy: 'id DESC');

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
        part_code LIKE ? OR
        name LIKE ? OR
        specification LIKE ? OR
        barcode LIKE ?
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

    await db.delete('parts', where: 'id = ?', whereArgs: [id]);
  }
}
