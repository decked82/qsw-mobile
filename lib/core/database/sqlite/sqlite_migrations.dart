import 'package:sqflite/sqflite.dart';

class SqliteMigrations {
  static Future<void> onCreate(Database db, int version) async {
    await _migrateToV1(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateTo(db, version);
    }
  }

  static Future<void> _migrateTo(Database db, int version) async {
    switch (version) {
      case 1:
        await _migrateToV1(db);
        break;
    }
  }

  static Future<void> _migrateToV1(Database db) async {
    await db.execute('''
      CREATE TABLE parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_code TEXT NOT NULL,
        name TEXT NOT NULL,
        specification TEXT,
        barcode TEXT,
        unit TEXT NOT NULL DEFAULT 'EA',
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }
}
