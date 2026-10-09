import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../boxes/data/repositories/sqlite_box_number_range_repository.dart';
import '../../../boxes/data/repositories/sqlite_box_repository.dart';
import '../../../boxes/domain/entities/box.dart';
import '../../../boxes/domain/services/box_number_generator.dart';
import '../../../sync/data/repositories/sqlite_pending_operation_repository.dart';
import '../../../sync/domain/entities/pending_operation.dart';
import '../../data/repositories/sqlite_inbound_transaction_repository.dart';
import '../entities/inbound_transaction.dart';

class SaveInboundTransaction {
  SaveInboundTransaction({
    required this.database,
    required this.boxNumberGenerator,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  final Database database;
  final BoxNumberGenerator boxNumberGenerator;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<InboundTransaction> call({
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
    final dateKey = boxNumberGenerator.dateKeyFor(createdAt);

    // Reserve a range remotely if the local device has no available range.
    // Reserving a range does not consume an individual box number.
    await boxNumberGenerator.getOrReserveRangeForDate(dateKey);

    late InboundTransaction savedTransaction;

    await database.transaction((transaction) async {
      final rangeRepository = SqliteBoxNumberRangeRepository(transaction);
      final inboundRepository = SqliteInboundTransactionRepository(transaction);
      final boxRepository = SqliteBoxRepository(transaction);
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
      final boxNo = boxNumberGenerator.formatBoxNumber(
        dateKey: dateKey,
        sequence: sequence,
      );

      final inboundTransaction = InboundTransaction(
        id: 0,
        operationId: _uuid.v4(),
        boxNo: boxNo,
        partNo: normalizedPartNo,
        quantity: quantity,
        location: normalizedLocation,
        userId: userId,
        createdAt: createdAt,
      );

      final box = Box(
        boxNo: boxNo,
        partNo: normalizedPartNo,
        quantity: quantity,
        location: normalizedLocation,
        status: 'IN_STOCK',
      );

      final pendingOperation = PendingOperation(
        id: 0,
        operationId: inboundTransaction.operationId,
        type: 'INBOUND',
        entityType: 'INBOUND_TRANSACTION',
        entityId: inboundTransaction.operationId,
        payload: jsonEncode({
          'operationId': inboundTransaction.operationId,
          'boxNo': inboundTransaction.boxNo,
          'partNo': inboundTransaction.partNo,
          'quantity': inboundTransaction.quantity,
          'location': inboundTransaction.location,
          'userId': inboundTransaction.userId,
          'createdAt': inboundTransaction.createdAt.toIso8601String(),
        }),
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: inboundTransaction.createdAt,
      );

      // All local changes commit together or roll back together.
      await inboundRepository.save(inboundTransaction);
      await boxRepository.save(box);
      await pendingOperationRepository.save(pendingOperation);

      // Consume the sequence only after the records have been saved.
      await rangeRepository.updateNextNumber(
        dateKey: dateKey,
        nextNumber: sequence + 1,
      );

      savedTransaction = inboundTransaction;
    });

    return savedTransaction;
  }
}
