import 'package:sqflite/sqflite.dart';

class SqliteMigrations {
  static Future<void> onCreate(Database db, int version) async {
    await _migrateToV1(db);

    if (version >= 2) {
      await _migrateToV2(db);
    }

    if (version >= 3) {
      await _migrateToV3(db);
    }
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
      case 2:
        await _migrateToV2(db);
        break;
      case 3:
        await _migrateToV3(db);
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

  static Future<void> _migrateToV2(Database db) async {
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  static Future<void> _migrateToV3(Database db) async {
    await db.execute('''
      CREATE TABLE boxes (
        box_no TEXT PRIMARY KEY,
        part_no TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        location TEXT,
        status TEXT
      )
    ''');
  }
}
