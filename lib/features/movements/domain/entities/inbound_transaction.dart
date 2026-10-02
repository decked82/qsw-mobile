class InboundTransaction {
  const InboundTransaction({
    required this.id,
    required this.operationId,
    required this.boxNo,
    required this.partNo,
    required this.quantity,
    required this.location,
    this.userId,
    required this.createdAt,
  });

  final int id;
  final String operationId;
  final String boxNo;
  final String partNo;
  final int quantity;
  final String location;
  final String? userId;
  final DateTime createdAt;
}
