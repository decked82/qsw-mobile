abstract interface class BoxNumberDataSource {
  Future<BoxNumberRange> reserveRange({
    required String dateKey,
    required int size,
  });
}

class BoxNumberRange {
  const BoxNumberRange({required this.start, required this.end});

  final int start;
  final int end;
}
