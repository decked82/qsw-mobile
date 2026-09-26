import '../entities/sync_metadata.dart';

abstract interface class SyncMetadataRepository {
  Future<SyncMetadata?> getByEntityType(String entityType);

  Future<void> save(SyncMetadata metadata);

  Future<void> updateStatus({
    required String entityType,
    required SyncMetadataStatus status,
    DateTime? lastSyncAt,
    String? cursor,
  });
}
