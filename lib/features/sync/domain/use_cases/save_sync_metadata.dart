import '../entities/sync_metadata.dart';
import '../repositories/sync_metadata_repository.dart';

class SaveSyncMetadata {
  const SaveSyncMetadata(this.repository);

  final SyncMetadataRepository repository;

  Future<void> call(SyncMetadata metadata) {
    return repository.save(metadata);
  }
}
