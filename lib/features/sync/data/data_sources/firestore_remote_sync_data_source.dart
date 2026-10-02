import '../../domain/entities/pending_operation.dart';
import 'firestore_inbound_transaction_sync_data_source.dart';
import 'firestore_movement_sync_data_source.dart';
import 'remote_sync_data_source.dart';

class FirestoreRemoteSyncDataSource implements RemoteSyncDataSource {
  const FirestoreRemoteSyncDataSource({
    required this.movementSyncDataSource,
    required this.inboundTransactionSyncDataSource,
  });

  final FirestoreMovementSyncDataSource movementSyncDataSource;
  final FirestoreInboundTransactionSyncDataSource
  inboundTransactionSyncDataSource;

  @override
  Future<void> sync(PendingOperation operation) {
    return switch (operation.entityType) {
      'MOVEMENT' => movementSyncDataSource.sync(operation),
      'INBOUND_TRANSACTION' => inboundTransactionSyncDataSource.sync(operation),
      _ => throw ArgumentError(
        'Unsupported entity type: ${operation.entityType}',
      ),
    };
  }
}
