import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../boxes/data/repositories/sqlite_box_number_range_repository.dart';
import '../../../boxes/domain/services/box_number_generator.dart';
import '../../../sync/data/repositories/sqlite_pending_operation_repository.dart';
import '../../data/repositories/sqlite_inbound_transaction_repository.dart';
import '../entities/inbound_transaction.dart';
import '../../../sync/domain/entities/pending_operation.dart';

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

    await boxNumberGenerator.getOrReserveRangeForDate(dateKey);

    late InboundTransaction savedTransaction;

    await database.transaction((transaction) async {
      final rangeRepository = SqliteBoxNumberRangeRepository(transaction);
      final inboundRepository = SqliteInboundTransactionRepository(transaction);
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

      await rangeRepository.updateNextNumber(
        dateKey: dateKey,
        nextNumber: sequence + 1,
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

      await inboundRepository.save(inboundTransaction);

      final pendingOperation = PendingOperationPayload(
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
        createdAt: inboundTransaction.createdAt,
      );

      await pendingOperationRepository.save(
        pendingOperation.toPendingOperation(),
      );

      savedTransaction = inboundTransaction;
    });

    return savedTransaction;
  }
}

class PendingOperationPayload {
  const PendingOperationPayload({
    required this.operationId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
  });

  final String operationId;
  final String type;
  final String entityType;
  final String entityId;
  final String payload;
  final DateTime createdAt;

  PendingOperation toPendingOperation() {
    return PendingOperation(
      id: 0,
      operationId: operationId,
      type: type,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      status: PendingOperationStatus.pending,
      retryCount: 0,
      createdAt: createdAt,
    );
  }
}
