class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.operationId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.lastError,
  });

  final int id;

  /// Globally unique identifier of the business operation.
  final String operationId;

  /// Operation type, for example INBOUND, OUTBOUND or MOVE.
  final String type;

  /// Entity affected by the operation, for example MOVEMENT or BOX.
  final String entityType;

  /// Identifier of the affected entity.
  final String entityId;

  /// Serialized operation data, normally JSON.
  final String payload;

  final PendingOperationStatus status;

  final int retryCount;

  final DateTime createdAt;

  final DateTime? lastAttemptAt;

  final String? lastError;
}

enum PendingOperationStatus { pending, processing, synced, failed }
