import '../../domain/entities/pending_operation.dart';

abstract interface class RemoteSyncDataSource {
  Future<void> sync(PendingOperation operation);
}
