import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/sqlite/sqlite_database_provider.dart';
import '../models/part_model.dart';

class PartSyncIdReconciliationResult {
  const PartSyncIdReconciliationResult({
    required this.assignedCount,
    required this.conflicts,
  });

  final int assignedCount;
  final List<String> conflicts;

  bool get succeeded => conflicts.isEmpty;
}

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

  Future<PartModel> addPart(
    PartModel part, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _databaseProvider.database;
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

  /// Assigns sync IDs to eligible legacy parts, including soft-deleted rows.
  ///
  /// This operation is explicit and is not run automatically at app startup.
  /// If an unassigned row has a blank part_code, or its code is shared with
  /// another row, no IDs are assigned and the conflicts are returned.
  Future<PartSyncIdReconciliationResult> reconcileLegacySyncIds() async {
    final db = await _databaseProvider.database;

    return db.transaction((txn) async {
      final rows = await txn.query(
        'parts',
        columns: ['id', 'part_code', 'sync_id'],
        orderBy: 'id ASC',
      );

      final rowsByCode = <String, List<Map<String, Object?>>>{};
      final conflicts = <String>[];

      for (final row in rows) {
        final id = row['id'] as int;
        final rawCode = row['part_code'] as String? ?? '';
        final code = rawCode.trim();
        final syncId = row['sync_id'] as String?;

        if (syncId == null && code.isEmpty) {
          conflicts.add('Part id=$id has no sync_id and an empty part_code.');
        }

        if (code.isNotEmpty) {
          rowsByCode.putIfAbsent(code, () => []).add(row);
        }
      }

      for (final entry in rowsByCode.entries) {
        final matchingRows = entry.value;
        final containsLegacyRow = matchingRows.any(
          (row) => row['sync_id'] == null,
        );

        if (matchingRows.length > 1 && containsLegacyRow) {
          final ids = matchingRows.map((row) => row['id']).join(', ');
          conflicts.add(
            'part_code="${entry.key}" is used by multiple rows '
            '(ids: $ids), including a row without sync_id.',
          );
        }
      }

      if (conflicts.isNotEmpty) {
        return PartSyncIdReconciliationResult(
          assignedCount: 0,
          conflicts: List.unmodifiable(conflicts),
        );
      }

      var assignedCount = 0;
      for (final row in rows) {
        if (row['sync_id'] != null) {
          continue;
        }

        final id = row['id'] as int;
        final changed = await txn.update(
          'parts',
          {'sync_id': _uuid.v4()},
          where: 'id = ? AND sync_id IS NULL',
          whereArgs: [id],
        );

        if (changed != 1) {
          throw StateError('Could not assign sync_id to legacy part id=$id.');
        }
        assignedCount++;
      }

      return PartSyncIdReconciliationResult(
        assignedCount: assignedCount,
        conflicts: const [],
      );
    });
  }

  Future<PartModel?> deletePart(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _databaseProvider.database;

    final rows = await db.query(
      'parts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final current = PartModel.fromMap(rows.single);

    if (current.isDeleted) {
      return null;
    }

    final syncId = current.syncId;
    if (syncId == null || syncId.trim().isEmpty) {
      throw StateError(
        'Cannot delete legacy part id=$id without sync_id. '
        'Run reconcileLegacySyncIds() first.',
      );
    }

    final now = _clock();
    final timestamp = now.toIso8601String();

    final changed = await db.update(
      'parts',
      {'is_deleted': 1, 'deleted_at': timestamp, 'updated_at': timestamp},
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (changed != 1) {
      throw StateError('Could not soft-delete part id=$id.');
    }

    return PartModel(
      id: current.id,
      partCode: current.partCode,
      name: current.name,
      specification: current.specification,
      barcode: current.barcode,
      unit: current.unit,
      createdAt: current.createdAt,
      updatedAt: now,
      syncId: syncId,
      isDeleted: true,
      deletedAt: now,
    );
  }
}
