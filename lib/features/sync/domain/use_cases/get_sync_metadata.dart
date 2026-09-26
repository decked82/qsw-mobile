import '../entities/sync_metadata.dart';
import '../repositories/sync_metadata_repository.dart';

class GetSyncMetadata {
  const GetSyncMetadata(this.repository);

  final SyncMetadataRepository repository;

  Future<SyncMetadata?> call(String entityType) {
    return repository.getByEntityType(entityType);
  }
}
