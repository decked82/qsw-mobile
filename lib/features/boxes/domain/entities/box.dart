class Box {
  final String boxNo;
  final String partNo;
  final int quantity;
  final String? location;
  final String? status;

  const Box({
    required this.boxNo,
    required this.partNo,
    required this.quantity,
    this.location,
    this.status,
  });
}
