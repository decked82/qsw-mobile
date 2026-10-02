import 'package:flutter_test/flutter_test.dart';

import 'package:qsw_mobile/features/boxes/data/data_sources/box_number_data_source.dart';
import 'package:qsw_mobile/features/boxes/domain/repositories/box_number_range_repository.dart';
import 'package:qsw_mobile/features/boxes/domain/services/box_number_generator.dart';

void main() {
  group('BoxNumberGenerator', () {
    test('peek returns first number from a newly reserved range', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [const BoxNumberRange(start: 1, end: 20)],
      );
      final repository = FakeBoxNumberRangeRepository();

      final generator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => DateTime(2026, 9, 28),
      );

      final result = await generator.peek();

      expect(result, 'HSF260928000001');
      expect(dataSource.reserveCallCount, 1);

      final savedRange = await repository.getByDateKey('260928');

      expect(savedRange, isNotNull);
      expect(savedRange!.rangeStart, 1);
      expect(savedRange.rangeEnd, 20);
      expect(savedRange.nextNumber, 1);
    });

    test('peek does not consume the number', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [const BoxNumberRange(start: 1, end: 20)],
      );
      final repository = FakeBoxNumberRangeRepository();

      final generator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => DateTime(2026, 9, 28),
      );

      final first = await generator.peek();
      final second = await generator.peek();

      expect(first, 'HSF260928000001');
      expect(second, 'HSF260928000001');
      expect(dataSource.reserveCallCount, 1);
    });

    test('generate consumes the number', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [const BoxNumberRange(start: 1, end: 20)],
      );
      final repository = FakeBoxNumberRangeRepository();

      final generator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => DateTime(2026, 9, 28),
      );

      final result = await generator.generate();

      expect(result, 'HSF260928000001');

      final savedRange = await repository.getByDateKey('260928');

      expect(savedRange!.nextNumber, 2);
    });

    test('subsequent generations use the saved range', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [const BoxNumberRange(start: 1, end: 20)],
      );
      final repository = FakeBoxNumberRangeRepository();

      final generator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => DateTime(2026, 9, 28),
      );

      final first = await generator.generate();
      final second = await generator.generate();

      expect(first, 'HSF260928000001');
      expect(second, 'HSF260928000002');
      expect(dataSource.reserveCallCount, 1);
    });

    test('generator recreation continues the sequence', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [const BoxNumberRange(start: 1, end: 20)],
      );
      final repository = FakeBoxNumberRangeRepository();

      final firstGenerator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => DateTime(2026, 9, 28),
      );

      expect(await firstGenerator.generate(), 'HSF260928000001');

      final secondGenerator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => DateTime(2026, 9, 28),
      );

      expect(await secondGenerator.generate(), 'HSF260928000002');

      expect(dataSource.reserveCallCount, 1);
    });

    test('new range is reserved when saved range is exhausted', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [
          const BoxNumberRange(start: 1, end: 2),
          const BoxNumberRange(start: 3, end: 22),
        ],
      );
      final repository = FakeBoxNumberRangeRepository();

      final generator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        rangeSize: 2,
        now: () => DateTime(2026, 9, 28),
      );

      expect(await generator.generate(), 'HSF260928000001');
      expect(await generator.generate(), 'HSF260928000002');
      expect(await generator.generate(), 'HSF260928000003');

      expect(dataSource.reserveCallCount, 2);
    });

    test('new sequence is used for a new date', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [
          const BoxNumberRange(start: 1, end: 20),
          const BoxNumberRange(start: 1, end: 20),
        ],
      );
      final repository = FakeBoxNumberRangeRepository();

      var currentDate = DateTime(2026, 9, 28);

      final generator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => currentDate,
      );

      expect(await generator.generate(), 'HSF260928000001');

      currentDate = DateTime(2026, 9, 29);

      expect(await generator.peek(), 'HSF260929000001');

      expect(dataSource.reserveCallCount, 2);
    });

    test('invalid remote range throws', () async {
      final dataSource = FakeBoxNumberDataSource(
        ranges: [const BoxNumberRange(start: 0, end: 20)],
      );
      final repository = FakeBoxNumberRangeRepository();

      final generator = BoxNumberGenerator(
        dataSource: dataSource,
        rangeRepository: repository,
        now: () => DateTime(2026, 9, 28),
      );

      expect(() => generator.peek(), throwsA(isA<StateError>()));
    });
  });
}

class FakeBoxNumberDataSource implements BoxNumberDataSource {
  FakeBoxNumberDataSource({required this.ranges});

  final List<BoxNumberRange> ranges;
  int reserveCallCount = 0;

  @override
  Future<BoxNumberRange> reserveRange({
    required String dateKey,
    required int size,
  }) async {
    final index = reserveCallCount;
    reserveCallCount++;

    if (index >= ranges.length) {
      throw StateError('No fake range available.');
    }

    return ranges[index];
  }
}

class FakeBoxNumberRangeRepository implements BoxNumberRangeRepository {
  final Map<String, BoxNumberRangeState> _states = {};

  @override
  Future<BoxNumberRangeState?> getByDateKey(String dateKey) async {
    return _states[dateKey];
  }

  @override
  Future<void> save(BoxNumberRangeState range) async {
    _states[range.dateKey] = range;
  }

  @override
  Future<void> updateNextNumber({
    required String dateKey,
    required int nextNumber,
  }) async {
    final current = _states[dateKey];

    if (current == null) {
      throw StateError('Box number range not found for date key: $dateKey');
    }

    _states[dateKey] = BoxNumberRangeState(
      dateKey: current.dateKey,
      rangeStart: current.rangeStart,
      rangeEnd: current.rangeEnd,
      nextNumber: nextNumber,
    );
  }
}
