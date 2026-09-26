class SyncMetadata {
  const SyncMetadata({
    required this.entityType,
    this.lastSyncAt,
    required this.status,
    this.cursor,
  });

  /// Type of entity being synchronized.
  /// Examples: PARTS, LOCATIONS, BOXES, MOVEMENTS.
  final String entityType;

  /// Time of the last successfully completed synchronization.
  final DateTime? lastSyncAt;

  final SyncMetadataStatus status;

  /// Cursor/token used for incremental synchronization.
  /// Null when no cursor has been established yet.
  final String? cursor;
}

enum SyncMetadataStatus { neverSynced, syncing, success, failed }
