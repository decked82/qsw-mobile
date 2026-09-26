import '../../data/data_sources/remote_sync_data_source.dart';
import '../entities/pending_operation.dart';
import '../repositories/pending_operation_repository.dart';

class SyncEngine {
  const SyncEngine({
    required this.pendingOperationRepository,
    required this.remoteSyncDataSource,
  });

  final PendingOperationRepository pendingOperationRepository;
  final RemoteSyncDataSource remoteSyncDataSource;

  Future<void> syncPendingOperations({int limit = 50}) async {
    final operations = await pendingOperationRepository.getPending(
      limit: limit,
    );

    for (final operation in operations) {
      await _syncOperation(operation);
    }
  }

  Future<void> _syncOperation(PendingOperation operation) async {
    final now = DateTime.now();

    await pendingOperationRepository.updateStatus(
      id: operation.id,
      status: PendingOperationStatus.processing,
      lastAttemptAt: now,
      lastError: null,
    );

    try {
      await remoteSyncDataSource.sync(operation);

      await pendingOperationRepository.updateStatus(
        id: operation.id,
        status: PendingOperationStatus.synced,
        lastAttemptAt: DateTime.now(),
        lastError: null,
      );
    } catch (error) {
      await pendingOperationRepository.updateStatus(
        id: operation.id,
        status: PendingOperationStatus.failed,
        lastAttemptAt: DateTime.now(),
        lastError: error.toString(),
        retryCount: operation.retryCount + 1,
      );
    }
  }
}
