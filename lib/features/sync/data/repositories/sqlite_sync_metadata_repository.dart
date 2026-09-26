import 'package:sqflite/sqflite.dart';

import '../../domain/entities/sync_metadata.dart';
import '../../domain/repositories/sync_metadata_repository.dart';

class SqliteSyncMetadataRepository implements SyncMetadataRepository {
  final Database database;

  SqliteSyncMetadataRepository(this.database);

  @override
  Future<SyncMetadata?> getByEntityType(String entityType) async {
    final maps = await database.query(
      'sync_metadata',
      where: 'entity_type = ?',
      whereArgs: [entityType],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  @override
  Future<void> save(SyncMetadata metadata) async {
    await database.insert(
      'sync_metadata',
      _toMap(metadata),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateStatus({
    required String entityType,
    required SyncMetadataStatus status,
    DateTime? lastSyncAt,
    String? cursor,
  }) async {
    await database.update(
      'sync_metadata',
      {
        'status': _statusToString(status),
        'last_sync_at': lastSyncAt?.toIso8601String(),
        'cursor': cursor,
      },
      where: 'entity_type = ?',
      whereArgs: [entityType],
    );
  }

  SyncMetadata _fromMap(Map<String, Object?> map) {
    return SyncMetadata(
      entityType: map['entity_type'] as String,
      lastSyncAt: map['last_sync_at'] == null
          ? null
          : DateTime.parse(map['last_sync_at'] as String),
      status: _statusFromString(map['status'] as String),
      cursor: map['cursor'] as String?,
    );
  }

  Map<String, Object?> _toMap(SyncMetadata metadata) {
    return {
      'entity_type': metadata.entityType,
      'last_sync_at': metadata.lastSyncAt?.toIso8601String(),
      'status': _statusToString(metadata.status),
      'cursor': metadata.cursor,
    };
  }

  SyncMetadataStatus _statusFromString(String value) {
    return switch (value) {
      'NEVER_SYNCED' => SyncMetadataStatus.neverSynced,
      'SYNCING' => SyncMetadataStatus.syncing,
      'SUCCESS' => SyncMetadataStatus.success,
      'FAILED' => SyncMetadataStatus.failed,
      _ => throw ArgumentError('Unknown sync metadata status: $value'),
    };
  }

  String _statusToString(SyncMetadataStatus status) {
    return switch (status) {
      SyncMetadataStatus.neverSynced => 'NEVER_SYNCED',
      SyncMetadataStatus.syncing => 'SYNCING',
      SyncMetadataStatus.success => 'SUCCESS',
      SyncMetadataStatus.failed => 'FAILED',
    };
  }
}
