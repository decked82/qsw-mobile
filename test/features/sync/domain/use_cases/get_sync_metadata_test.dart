import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/sync_metadata.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:qsw_mobile/features/sync/domain/use_cases/get_sync_metadata.dart';

class _FakeSyncMetadataRepository implements SyncMetadataRepository {
  SyncMetadata? metadata;

  @override
  Future<SyncMetadata?> getByEntityType(String entityType) async {
    return metadata;
  }

  @override
  Future<void> save(SyncMetadata metadata) async {}

  @override
  Future<void> updateStatus({
    required String entityType,
    required SyncMetadataStatus status,
    DateTime? lastSyncAt,
    String? cursor,
  }) async {}
}

void main() {
  test('returns sync metadata from repository', () async {
    final repository = _FakeSyncMetadataRepository();
    final metadata = SyncMetadata(
      entityType: 'BOX',
      status: SyncMetadataStatus.success,
      lastSyncAt: DateTime(2026, 1, 1),
      cursor: 'cursor-001',
    );

    repository.metadata = metadata;

    final useCase = GetSyncMetadata(repository);

    final result = await useCase('BOX');

    expect(result, same(metadata));
  });
}
