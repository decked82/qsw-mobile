import 'package:sqflite/sqflite.dart';

import '../../domain/entities/pending_operation.dart';
import '../../domain/repositories/pending_operation_repository.dart';

class SqlitePendingOperationRepository implements PendingOperationRepository {
  const SqlitePendingOperationRepository(this.database);

  final Database database;

  @override
  Future<PendingOperation?> getById(int id) async {
    final rows = await database.query(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  @override
  Future<PendingOperation?> getByOperationId(String operationId) async {
    final rows = await database.query(
      'pending_operations',
      where: 'operation_id = ?',
      whereArgs: [operationId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  @override
  Future<List<PendingOperation>> getPending({int limit = 50}) async {
    final rows = await database.query(
      'pending_operations',
      where: 'status IN (?, ?)',
      whereArgs: ['PENDING', 'FAILED'],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(_fromMap).toList();
  }

  @override
  Future<void> save(PendingOperation operation) async {
    final values = _toMap(operation);

    if (operation.id == 0) {
      values.remove('id');
    }

    await database.insert(
      'pending_operations',
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateStatus({
    required int id,
    required PendingOperationStatus status,
    DateTime? lastAttemptAt,
    String? lastError,
    int? retryCount,
  }) async {
    final values = <String, Object?>{
      'status': _statusToString(status),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'last_error': lastError,
    };

    if (retryCount != null) {
      values['retry_count'] = retryCount;
    }

    await database.update(
      'pending_operations',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  PendingOperation _fromMap(Map<String, Object?> map) {
    return PendingOperation(
      id: map['id']! as int,
      operationId: map['operation_id']! as String,
      type: map['type']! as String,
      entityType: map['entity_type']! as String,
      entityId: map['entity_id']! as String,
      payload: map['payload']! as String,
      status: _statusFromString(map['status']! as String),
      retryCount: map['retry_count']! as int,
      createdAt: DateTime.parse(map['created_at']! as String),
      lastAttemptAt: map['last_attempt_at'] == null
          ? null
          : DateTime.parse(map['last_attempt_at']! as String),
      lastError: map['last_error'] as String?,
    );
  }

  Map<String, Object?> _toMap(PendingOperation operation) {
    return {
      'id': operation.id,
      'operation_id': operation.operationId,
      'type': operation.type,
      'entity_type': operation.entityType,
      'entity_id': operation.entityId,
      'payload': operation.payload,
      'status': _statusToString(operation.status),
      'retry_count': operation.retryCount,
      'created_at': operation.createdAt.toIso8601String(),
      'last_attempt_at': operation.lastAttemptAt?.toIso8601String(),
      'last_error': operation.lastError,
    };
  }

  String _statusToString(PendingOperationStatus status) {
    switch (status) {
      case PendingOperationStatus.pending:
        return 'PENDING';
      case PendingOperationStatus.processing:
        return 'PROCESSING';
      case PendingOperationStatus.synced:
        return 'SYNCED';
      case PendingOperationStatus.failed:
        return 'FAILED';
    }
  }

  PendingOperationStatus _statusFromString(String value) {
    switch (value) {
      case 'PENDING':
        return PendingOperationStatus.pending;
      case 'PROCESSING':
        return PendingOperationStatus.processing;
      case 'SYNCED':
        return PendingOperationStatus.synced;
      case 'FAILED':
        return PendingOperationStatus.failed;
      default:
        throw StateError('Unknown pending operation status: $value');
    }
  }
}
