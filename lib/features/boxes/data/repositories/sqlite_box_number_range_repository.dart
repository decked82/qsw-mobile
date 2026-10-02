import 'package:sqflite/sqflite.dart';

import '../../domain/repositories/box_number_range_repository.dart';

class SqliteBoxNumberRangeRepository implements BoxNumberRangeRepository {
  const SqliteBoxNumberRangeRepository(this.database);

  final DatabaseExecutor database;

  @override
  Future<BoxNumberRangeState?> getByDateKey(String dateKey) async {
    final rows = await database.query(
      'box_number_ranges',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;

    return BoxNumberRangeState(
      dateKey: row['date_key']! as String,
      rangeStart: row['range_start']! as int,
      rangeEnd: row['range_end']! as int,
      nextNumber: row['next_number']! as int,
    );
  }

  @override
  Future<void> save(BoxNumberRangeState range) async {
    await database.insert('box_number_ranges', {
      'date_key': range.dateKey,
      'range_start': range.rangeStart,
      'range_end': range.rangeEnd,
      'next_number': range.nextNumber,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateNextNumber({
    required String dateKey,
    required int nextNumber,
  }) async {
    final updatedRows = await database.update(
      'box_number_ranges',
      {'next_number': nextNumber},
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );

    if (updatedRows == 0) {
      throw StateError('Box number range not found for date key: $dateKey');
    }
  }
}
