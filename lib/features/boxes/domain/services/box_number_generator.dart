import '../../data/data_sources/box_number_data_source.dart';
import '../repositories/box_number_range_repository.dart';

class BoxNumberGenerator {
  BoxNumberGenerator({
    required this.dataSource,
    required this.rangeRepository,
    this.rangeSize = 20,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BoxNumberDataSource dataSource;
  final BoxNumberRangeRepository rangeRepository;
  final int rangeSize;
  final DateTime Function() _now;

  Future<String> peek() async {
    final dateKey = _formatDateKey(_now());
    final range = await _getOrReserveRange(dateKey);

    return _formatBoxNumber(dateKey: dateKey, sequence: range.nextNumber);
  }

  Future<String> generate() async {
    final dateKey = _formatDateKey(_now());
    final range = await _getOrReserveRange(dateKey);

    final sequence = range.nextNumber;

    await rangeRepository.updateNextNumber(
      dateKey: dateKey,
      nextNumber: sequence + 1,
    );

    return _formatBoxNumber(dateKey: dateKey, sequence: sequence);
  }

  String formatBoxNumber({required String dateKey, required int sequence}) {
    return _formatBoxNumber(dateKey: dateKey, sequence: sequence);
  }

  String dateKeyFor(DateTime date) {
    return _formatDateKey(date);
  }

  Future<BoxNumberRangeState> getOrReserveRangeForDate(String dateKey) {
    return _getOrReserveRange(dateKey);
  }

  Future<BoxNumberRangeState> _getOrReserveRange(String dateKey) async {
    final savedRange = await rangeRepository.getByDateKey(dateKey);

    if (savedRange != null &&
        savedRange.nextNumber >= savedRange.rangeStart &&
        savedRange.nextNumber <= savedRange.rangeEnd) {
      return savedRange;
    }

    final range = await dataSource.reserveRange(
      dateKey: dateKey,
      size: rangeSize,
    );

    if (range.start <= 0 || range.end < range.start) {
      throw StateError('Invalid box number range: ${range.start}-${range.end}');
    }

    final state = BoxNumberRangeState(
      dateKey: dateKey,
      rangeStart: range.start,
      rangeEnd: range.end,
      nextNumber: range.start,
    );

    await rangeRepository.save(state);

    return state;
  }

  String _formatBoxNumber({required String dateKey, required int sequence}) {
    return 'HSF$dateKey${sequence.toString().padLeft(6, '0')}';
  }

  String _formatDateKey(DateTime date) {
    final year = (date.year % 100).toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }
}
