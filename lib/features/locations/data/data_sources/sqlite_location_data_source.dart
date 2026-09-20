import 'package:sqflite/sqflite.dart';

import '../../domain/entities/location.dart';
import 'location_data_source.dart';

class SqliteLocationDataSource implements LocationDataSource {
  SqliteLocationDataSource(this._database);

  final Database _database;

  @override
  Future<Location> addLocation(Location location) async {
    final id = await _database.insert(
      'locations',
      _toMap(location),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return Location(
      id: id,
      code: location.code,
      name: location.name,
      description: location.description,
      isActive: location.isActive,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt,
    );
  }

  @override
  Future<List<Location>> getLocations() async {
    final rows = await _database.query('locations', orderBy: 'code ASC');

    return rows.map(_fromMap).toList();
  }

  @override
  Future<Location?> getLocationByCode(String code) async {
    final rows = await _database.query(
      'locations',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  @override
  Future<List<Location>> searchLocations(String query) async {
    final searchQuery = '%$query%';

    final rows = await _database.query(
      'locations',
      where: 'LOWER(code) LIKE LOWER(?) OR LOWER(name) LIKE LOWER(?)',
      whereArgs: [searchQuery, searchQuery],
      orderBy: 'code ASC',
    );

    return rows.map(_fromMap).toList();
  }

  @override
  Future<void> deleteLocation(int id) async {
    await _database.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toMap(Location location) {
    return {
      'code': location.code,
      'name': location.name,
      'description': location.description,
      'is_active': location.isActive ? 1 : 0,
      'created_at': location.createdAt?.toIso8601String(),
      'updated_at': location.updatedAt?.toIso8601String(),
    };
  }

  Location _fromMap(Map<String, Object?> map) {
    return Location(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value as String);
  }
}
