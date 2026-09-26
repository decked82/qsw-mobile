import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:qsw_mobile/features/sync/data/repositories/sqlite_sync_metadata_repository.dart';
import 'package:qsw_mobile/features/sync/domain/entities/sync_metadata.dart';

void main() {
  late Database database;
  late SqliteSyncMetadataRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    await database.execute('''
      CREATE TABLE sync_metadata (
        entity_type TEXT PRIMARY KEY,
        last_sync_at TEXT,
        status TEXT NOT NULL,
        cursor TEXT
      )
    ''');

    repository = SqliteSyncMetadataRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SqliteSyncMetadataRepository', () {
    test('saves and retrieves metadata by entity type', () async {
      final lastSyncAt = DateTime(2026, 9, 22, 22, 30);

      final metadata = SyncMetadata(
        entityType: 'MOVEMENTS',
        lastSyncAt: lastSyncAt,
        status: SyncMetadataStatus.success,
        cursor: 'cursor-001',
      );

      await repository.save(metadata);

      final result = await repository.getByEntityType('MOVEMENTS');

      expect(result, isNotNull);
      expect(result!.entityType, 'MOVEMENTS');
      expect(result.lastSyncAt, lastSyncAt);
      expect(result.status, SyncMetadataStatus.success);
      expect(result.cursor, 'cursor-001');
    });

    test('returns null when metadata does not exist', () async {
      final result = await repository.getByEntityType('MOVEMENTS');

      expect(result, isNull);
    });

    test('saves metadata without last sync time and cursor', () async {
      final metadata = SyncMetadata(
        entityType: 'BOXES',
        status: SyncMetadataStatus.neverSynced,
        cursor: null,
      );

      await repository.save(metadata);

      final result = await repository.getByEntityType('BOXES');

      expect(result, isNotNull);
      expect(result!.entityType, 'BOXES');
      expect(result.lastSyncAt, isNull);
      expect(result.status, SyncMetadataStatus.neverSynced);
      expect(result.cursor, isNull);
    });

    test('updates metadata to syncing', () async {
      final metadata = SyncMetadata(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.neverSynced,
        cursor: null,
      );

      await repository.save(metadata);

      await repository.updateStatus(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.syncing,
      );

      final result = await repository.getByEntityType('MOVEMENTS');

      expect(result, isNotNull);
      expect(result!.status, SyncMetadataStatus.syncing);
      expect(result.lastSyncAt, isNull);
      expect(result.cursor, isNull);
    });

    test('updates metadata to success', () async {
      final metadata = SyncMetadata(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.syncing,
        cursor: null,
      );

      await repository.save(metadata);

      final lastSyncAt = DateTime(2026, 9, 22, 22, 40);

      await repository.updateStatus(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.success,
        lastSyncAt: lastSyncAt,
        cursor: 'cursor-002',
      );

      final result = await repository.getByEntityType('MOVEMENTS');

      expect(result, isNotNull);
      expect(result!.status, SyncMetadataStatus.success);
      expect(result.lastSyncAt, lastSyncAt);
      expect(result.cursor, 'cursor-002');
    });

    test('updates metadata to failed', () async {
      final metadata = SyncMetadata(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.syncing,
        cursor: 'cursor-001',
      );

      await repository.save(metadata);

      await repository.updateStatus(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.failed,
        cursor: 'cursor-001',
      );

      final result = await repository.getByEntityType('MOVEMENTS');

      expect(result, isNotNull);
      expect(result!.status, SyncMetadataStatus.failed);
      expect(result.cursor, 'cursor-001');
    });

    test('does not allow duplicate entity type', () async {
      final first = SyncMetadata(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.neverSynced,
        cursor: null,
      );

      final duplicate = SyncMetadata(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.success,
        cursor: 'cursor-001',
      );

      await repository.save(first);

      expect(
        () => repository.save(duplicate),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
