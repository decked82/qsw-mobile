abstract interface class BoxNumberRangeRepository {
  Future<BoxNumberRangeState?> getByDateKey(String dateKey);

  Future<void> save(BoxNumberRangeState range);

  Future<void> updateNextNumber({
    required String dateKey,
    required int nextNumber,
  });
}

class BoxNumberRangeState {
  const BoxNumberRangeState({
    required this.dateKey,
    required this.rangeStart,
    required this.rangeEnd,
    required this.nextNumber,
  });

  final String dateKey;
  final int rangeStart;
  final int rangeEnd;
  final int nextNumber;
}
