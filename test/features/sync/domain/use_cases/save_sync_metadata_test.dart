import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/sync_metadata.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:qsw_mobile/features/sync/domain/use_cases/save_sync_metadata.dart';

class _FakeSyncMetadataRepository implements SyncMetadataRepository {
  SyncMetadata? savedMetadata;

  @override
  Future<SyncMetadata?> getByEntityType(String entityType) async {
    return null;
  }

  @override
  Future<void> save(SyncMetadata metadata) async {
    savedMetadata = metadata;
  }

  @override
  Future<void> updateStatus({
    required String entityType,
    required SyncMetadataStatus status,
    DateTime? lastSyncAt,
    String? cursor,
  }) async {}
}

void main() {
  test('saves sync metadata through repository', () async {
    final repository = _FakeSyncMetadataRepository();
    final metadata = SyncMetadata(
      entityType: 'BOX',
      status: SyncMetadataStatus.success,
      lastSyncAt: DateTime(2026, 1, 1),
      cursor: 'cursor-001',
    );

    final useCase = SaveSyncMetadata(repository);

    await useCase(metadata);

    expect(repository.savedMetadata, same(metadata));
  });
}
