import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../boxes/data/repositories/sqlite_box_number_range_repository.dart';
import '../../../boxes/domain/services/box_number_generator.dart';
import '../../../sync/data/repositories/sqlite_pending_operation_repository.dart';
import '../../data/repositories/sqlite_movement_repository.dart';
import '../entities/movement.dart';
import 'save_movement.dart';

class SaveInboundMovement {
  SaveInboundMovement({
    required this._database,
    required this._boxNumberGenerator,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  final Database _database;
  final BoxNumberGenerator _boxNumberGenerator;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<Movement> call({
    required String partNo,
    required int quantity,
    required String location,
    String? userId,
  }) async {
    final normalizedPartNo = partNo.trim();
    final normalizedLocation = location.trim();

    if (normalizedPartNo.isEmpty) {
      throw ArgumentError.value(
        partNo,
        'partNo',
        'Part number must not be empty.',
      );
    }

    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Quantity must be greater than zero.',
      );
    }

    if (normalizedLocation.isEmpty) {
      throw ArgumentError.value(
        location,
        'location',
        'Location must not be empty.',
      );
    }

    final createdAt = _now();
    final dateKey = _boxNumberGenerator.dateKeyFor(createdAt);

    await _boxNumberGenerator.getOrReserveRangeForDate(dateKey);

    late Movement savedMovement;

    await _database.transaction((transaction) async {
      final rangeRepository = SqliteBoxNumberRangeRepository(transaction);
      final movementRepository = SqliteMovementRepository(transaction);
      final pendingOperationRepository = SqlitePendingOperationRepository(
        transaction,
      );

      final range = await rangeRepository.getByDateKey(dateKey);

      if (range == null) {
        throw StateError('Box number range not found for date key: $dateKey');
      }

      if (range.nextNumber < range.rangeStart ||
          range.nextNumber > range.rangeEnd) {
        throw StateError(
          'Box number range is exhausted for date key: $dateKey',
        );
      }

      final sequence = range.nextNumber;

      final boxNo = _boxNumberGenerator.formatBoxNumber(
        dateKey: dateKey,
        sequence: sequence,
      );

      await rangeRepository.updateNextNumber(
        dateKey: dateKey,
        nextNumber: sequence + 1,
      );

      final movement = Movement(
        id: 0,
        operationId: _uuid.v4(),
        type: MovementType.inbound,
        boxNo: boxNo,
        partNo: normalizedPartNo,
        fromLocation: null,
        toLocation: normalizedLocation,
        quantity: quantity,
        userId: userId,
        createdAt: createdAt,
      );

      final saveMovement = SaveMovement(
        movementRepository: movementRepository,
        pendingOperationRepository: pendingOperationRepository,
      );

      await saveMovement(movement);

      savedMovement = movement;
    });

    return savedMovement;
  }
}
