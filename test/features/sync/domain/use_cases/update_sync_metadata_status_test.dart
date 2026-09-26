import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/sync_metadata.dart';
import 'package:qsw_mobile/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:qsw_mobile/features/sync/domain/use_cases/update_sync_metadata_status.dart';

class _FakeSyncMetadataRepository implements SyncMetadataRepository {
  String? updatedEntityType;
  SyncMetadataStatus? updatedStatus;
  DateTime? updatedLastSyncAt;
  String? updatedCursor;

  @override
  Future<SyncMetadata?> getByEntityType(String entityType) async {
    return null;
  }

  @override
  Future<void> save(SyncMetadata metadata) async {}

  @override
  Future<void> updateStatus({
    required String entityType,
    required SyncMetadataStatus status,
    DateTime? lastSyncAt,
    String? cursor,
  }) async {
    updatedEntityType = entityType;
    updatedStatus = status;
    updatedLastSyncAt = lastSyncAt;
    updatedCursor = cursor;
  }
}

void main() {
  test('updates sync metadata status through repository', () async {
    final repository = _FakeSyncMetadataRepository();
    final lastSyncAt = DateTime(2026, 1, 2);

    final useCase = UpdateSyncMetadataStatus(repository);

    await useCase(
      entityType: 'BOX',
      status: SyncMetadataStatus.success,
      lastSyncAt: lastSyncAt,
      cursor: 'cursor-002',
    );

    expect(repository.updatedEntityType, 'BOX');
    expect(repository.updatedStatus, SyncMetadataStatus.success);
    expect(repository.updatedLastSyncAt, lastSyncAt);
    expect(repository.updatedCursor, 'cursor-002');
  });
}
