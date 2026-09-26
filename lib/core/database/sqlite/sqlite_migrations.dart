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

    if (version >= 4) {
      await _migrateToV4(db);
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
      case 4:
        await _migrateToV4(db);
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

  static Future<void> _migrateToV4(Database db) async {
    await db.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        box_no TEXT NOT NULL,
        part_no TEXT NOT NULL,
        from_location TEXT,
        to_location TEXT,
        quantity INTEGER NOT NULL,
        user_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_movements_box_no
      ON movements(box_no)
    ''');

    await db.execute('''
      CREATE INDEX idx_movements_part_no
      ON movements(part_no)
    ''');

    await db.execute('''
      CREATE INDEX idx_movements_created_at
      ON movements(created_at)
    ''');

    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT,
        last_error TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_pending_operations_status
      ON pending_operations(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_pending_operations_created_at
      ON pending_operations(created_at)
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        entity_type TEXT PRIMARY KEY,
        last_sync_at TEXT,
        status TEXT NOT NULL,
        cursor TEXT
      )
    ''');
  }
}
