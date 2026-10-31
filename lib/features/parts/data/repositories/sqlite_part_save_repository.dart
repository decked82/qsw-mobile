import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../features/sync/data/repositories/'
    'sqlite_pending_operation_repository.dart';
import '../../../../features/sync/domain/entities/pending_operation.dart';
import '../data_sources/sqlite_part_data_source.dart';
import '../models/part_model.dart';

class SqlitePartSaveRepository {
  SqlitePartSaveRepository(
    this.database,
    this.dataSource, {
    Uuid? uuid,
    this._operationIdGenerator,
  }) : _uuid = uuid ?? const Uuid();

  final Database database;
  final SqlitePartDataSource dataSource;
  final Uuid _uuid;
  final String Function()? _operationIdGenerator;

  String _newOperationId() {
    return _operationIdGenerator?.call() ?? _uuid.v4();
  }

  Future<PartModel> addPart(PartModel part) async {
    return database.transaction((transaction) async {
      final storedPart = await dataSource.addPart(part, executor: transaction);

      final syncId = storedPart.syncId;
      if (syncId == null || syncId.trim().isEmpty) {
        throw StateError('New part has no sync_id.');
      }

      final operation = PendingOperation(
        id: 0,
        operationId: _newOperationId(),
        type: 'CREATE',
        entityType: 'PART',
        entityId: syncId,
        payload: jsonEncode(storedPart.toSyncMap()),
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt: storedPart.createdAt ?? DateTime.now(),
      );

      final pendingRepository = SqlitePendingOperationRepository(transaction);
      await pendingRepository.save(operation);

      return storedPart;
    });
  }

  Future<void> deletePart(int id) async {
    await database.transaction((transaction) async {
      final deletedPart = await dataSource.deletePart(
        id,
        executor: transaction,
      );

      // Missing or already deleted: do not enqueue another DELETE.
      if (deletedPart == null) {
        return;
      }

      final syncId = deletedPart.syncId;
      if (syncId == null || syncId.trim().isEmpty) {
        throw StateError('Deleted part has no sync_id.');
      }

      final operation = PendingOperation(
        id: 0,
        operationId: _newOperationId(),
        type: 'DELETE',
        entityType: 'PART',
        entityId: syncId,
        payload: jsonEncode(deletedPart.toSyncMap()),
        status: PendingOperationStatus.pending,
        retryCount: 0,
        createdAt:
            deletedPart.deletedAt ?? deletedPart.updatedAt ?? DateTime.now(),
      );

      final pendingRepository = SqlitePendingOperationRepository(transaction);
      await pendingRepository.save(operation);
    });
  }
}
