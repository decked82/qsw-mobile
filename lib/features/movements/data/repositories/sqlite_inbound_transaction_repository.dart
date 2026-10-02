import 'package:sqflite/sqflite.dart';

import '../../domain/entities/inbound_transaction.dart';
import '../../domain/repositories/inbound_transaction_repository.dart';

class SqliteInboundTransactionRepository
    implements InboundTransactionRepository {
  const SqliteInboundTransactionRepository(this.database);

  final DatabaseExecutor database;

  @override
  Future<InboundTransaction?> getById(int id) async {
    final maps = await database.query(
      'inbound_transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  @override
  Future<InboundTransaction?> getByOperationId(String operationId) async {
    final maps = await database.query(
      'inbound_transactions',
      where: 'operation_id = ?',
      whereArgs: [operationId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _fromMap(maps.first);
  }

  @override
  Future<List<InboundTransaction>> getByBoxNo(String boxNo) async {
    final maps = await database.query(
      'inbound_transactions',
      where: 'box_no = ?',
      whereArgs: [boxNo],
      orderBy: 'created_at ASC',
    );

    return maps.map(_fromMap).toList();
  }

  @override
  Future<List<InboundTransaction>> getByPartNo(String partNo) async {
    final maps = await database.query(
      'inbound_transactions',
      where: 'part_no = ?',
      whereArgs: [partNo],
      orderBy: 'created_at ASC',
    );

    return maps.map(_fromMap).toList();
  }

  @override
  Future<void> save(InboundTransaction transaction) async {
    final values = _toMap(transaction);

    if (transaction.id == 0) {
      values.remove('id');
    }

    await database.insert(
      'inbound_transactions',
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  InboundTransaction _fromMap(Map<String, Object?> map) {
    return InboundTransaction(
      id: map['id']! as int,
      operationId: map['operation_id']! as String,
      boxNo: map['box_no']! as String,
      partNo: map['part_no']! as String,
      quantity: map['quantity']! as int,
      location: map['location']! as String,
      userId: map['user_id'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> _toMap(InboundTransaction transaction) {
    return {
      'id': transaction.id,
      'operation_id': transaction.operationId,
      'box_no': transaction.boxNo,
      'part_no': transaction.partNo,
      'quantity': transaction.quantity,
      'location': transaction.location,
      'user_id': transaction.userId,
      'created_at': transaction.createdAt.toIso8601String(),
    };
  }
}
