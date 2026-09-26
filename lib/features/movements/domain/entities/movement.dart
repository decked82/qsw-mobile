class Movement {
  const Movement({
    required this.id,
    required this.operationId,
    required this.type,
    required this.boxNo,
    required this.partNo,
    this.fromLocation,
    this.toLocation,
    required this.quantity,
    this.userId,
    required this.createdAt,
  });

  final int id;
  final String operationId;
  final MovementType type;
  final String boxNo;
  final String partNo;
  final String? fromLocation;
  final String? toLocation;
  final int quantity;
  final String? userId;
  final DateTime createdAt;
}

enum MovementType { inbound, outbound, move, adjustment }
