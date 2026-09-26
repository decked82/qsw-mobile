import '../entities/sync_metadata.dart';
import '../repositories/sync_metadata_repository.dart';

class UpdateSyncMetadataStatus {
  const UpdateSyncMetadataStatus(this.repository);

  final SyncMetadataRepository repository;

  Future<void> call({
    required String entityType,
    required SyncMetadataStatus status,
    DateTime? lastSyncAt,
    String? cursor,
  }) {
    return repository.updateStatus(
      entityType: entityType,
      status: status,
      lastSyncAt: lastSyncAt,
      cursor: cursor,
    );
  }
}
