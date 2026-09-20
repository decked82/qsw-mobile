import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../database_provider.dart';
import 'sqlite_migrations.dart';

class SqliteDatabaseProvider implements DatabaseProvider {
  SqliteDatabaseProvider({this.databaseName = 'qsw.db'});

  final String databaseName;

  Database? _database;

  @override
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);

    _database = await openDatabase(
      path,
      version: 3,
      onCreate: SqliteMigrations.onCreate,
      onUpgrade: SqliteMigrations.onUpgrade,
    );

    return _database!;
  }

  @override
  Future<void> close() async {
    final database = _database;

    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }
}
