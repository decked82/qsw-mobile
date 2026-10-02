import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../movements/domain/entities/inbound_transaction.dart';
import '../../../movements/domain/repositories/inbound_transaction_repository.dart';
import '../../domain/entities/pending_operation.dart';
import 'remote_sync_data_source.dart';

class FirestoreInboundTransactionSyncDataSource
    implements RemoteSyncDataSource {
  const FirestoreInboundTransactionSyncDataSource({
    required this._inboundTransactionRepository,
    required this._firestore,
  });

  final InboundTransactionRepository _inboundTransactionRepository;
  final FirebaseFirestore _firestore;

  @override
  Future<void> sync(PendingOperation operation) async {
    if (operation.entityType != 'INBOUND_TRANSACTION') {
      throw ArgumentError('Unsupported entity type: ${operation.entityType}');
    }

    final transaction = await _inboundTransactionRepository.getByOperationId(
      operation.operationId,
    );

    if (transaction == null) {
      throw StateError(
        'Inbound transaction not found for operationId: '
        '${operation.operationId}',
      );
    }

    await _syncTransaction(transaction);
  }

  Future<void> _syncTransaction(InboundTransaction transaction) async {
    final document = _firestore
        .collection('inbound_transactions')
        .doc(transaction.operationId);

    await document.set({
      'operationId': transaction.operationId,
      'boxNo': transaction.boxNo,
      'partNo': transaction.partNo,
      'quantity': transaction.quantity,
      'location': transaction.location,
      'userId': transaction.userId,
      'createdAt': Timestamp.fromDate(transaction.createdAt),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }
}
