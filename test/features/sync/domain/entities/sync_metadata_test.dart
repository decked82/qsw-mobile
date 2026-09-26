import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/domain/entities/sync_metadata.dart';

void main() {
  group('SyncMetadata', () {
    test('creates metadata for an entity that has never been synced', () {
      final metadata = SyncMetadata(
        entityType: 'MOVEMENTS',
        status: SyncMetadataStatus.neverSynced,
        cursor: null,
      );

      expect(metadata.entityType, 'MOVEMENTS');
      expect(metadata.lastSyncAt, isNull);
      expect(metadata.status, SyncMetadataStatus.neverSynced);
      expect(metadata.cursor, isNull);
    });

    test('creates successfully synchronized metadata', () {
      final lastSyncAt = DateTime(2026, 9, 22, 22, 30);

      final metadata = SyncMetadata(
        entityType: 'MOVEMENTS',
        lastSyncAt: lastSyncAt,
        status: SyncMetadataStatus.success,
        cursor: 'cursor-001',
      );

      expect(metadata.entityType, 'MOVEMENTS');
      expect(metadata.lastSyncAt, lastSyncAt);
      expect(metadata.status, SyncMetadataStatus.success);
      expect(metadata.cursor, 'cursor-001');
    });

    test('creates failed synchronization metadata', () {
      final metadata = SyncMetadata(
        entityType: 'BOXES',
        status: SyncMetadataStatus.failed,
        cursor: 'cursor-123',
      );

      expect(metadata.entityType, 'BOXES');
      expect(metadata.status, SyncMetadataStatus.failed);
      expect(metadata.cursor, 'cursor-123');
    });
  });
}
