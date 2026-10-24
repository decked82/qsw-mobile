import 'dart:async';
import '../../data/data_sources/remote_sync_data_source.dart';
import '../entities/pending_operation.dart';
import '../repositories/pending_operation_repository.dart';

class SyncEngine {
  SyncEngine({
    required this.pendingOperationRepository,
    required this.remoteSyncDataSource,
    this.automaticRetry = false,
    this.initialRetryDelay = const Duration(seconds: 30),
    this.maxRetryDelay = const Duration(minutes: 15),
  });

  final PendingOperationRepository pendingOperationRepository;
  final RemoteSyncDataSource remoteSyncDataSource;

  /// Enables background retries after a sync pass leaves operations retryable.
  /// Disabled by default so tests and explicitly managed engines stay deterministic.
  final bool automaticRetry;
  final Duration initialRetryDelay;
  final Duration maxRetryDelay;

  bool _processingRecoveryCompleted = false;
  Future<void>? _syncInProgress;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _scheduleRetry() {
    if (!automaticRetry || _retryTimer != null) {
      return;
    }

    final exponent = _retryAttempt.clamp(0, 30).toInt();
    final multiplier = 1 << exponent;
    final proposedMilliseconds = initialRetryDelay.inMilliseconds * multiplier;
    final delay = Duration(
      milliseconds: proposedMilliseconds > maxRetryDelay.inMilliseconds
          ? maxRetryDelay.inMilliseconds
          : proposedMilliseconds,
    );
    if (_retryAttempt < 30) {
      _retryAttempt++;
    }

    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(_runScheduledRetry());
    });
  }

  Future<void> _runScheduledRetry() async {
    try {
      await syncPendingOperations();
    } catch (_) {
      // A later scheduled retry or an explicit sync trigger can try again.
      _scheduleRetry();
    }
  }

  Future<void> syncPendingOperations({int? limit}) {
    // Do not run the same queue concurrently when startup sync and a
    // user-triggered sync happen at nearly the same time.
    final activeSync = _syncInProgress;
    if (activeSync != null) {
      return activeSync;
    }

    late final Future<void> sync;
    sync = _runSyncPendingOperations(limit: limit).whenComplete(() {
      if (identical(_syncInProgress, sync)) {
        _syncInProgress = null;
      }
    });

    _syncInProgress = sync;
    return sync;
  }

  Future<void> _runSyncPendingOperations({required int? limit}) async {
    // Recover stale PROCESSING records once per SyncEngine instance.
    // If recovery fails, the flag stays false so a later call can retry.
    if (!_processingRecoveryCompleted) {
      try {
        await pendingOperationRepository.recoverProcessingOperations();
        _processingRecoveryCompleted = true;
      } catch (_) {
        // Preserve the error for the caller, but schedule another attempt
        // when automatic retries are enabled.
        _scheduleRetry();
        rethrow;
      }
    }

    const batchSize = 50;
    var processedCount = 0;
    var retryNeeded = false;

    while (limit == null || processedCount < limit) {
      final remaining = limit == null ? batchSize : limit - processedCount;
      final fetchLimit = remaining < batchSize ? remaining : batchSize;
      if (fetchLimit <= 0) {
        break;
      }

      late final List<PendingOperation> operations;

      try {
        operations = await pendingOperationRepository.getPending(
          limit: fetchLimit,
        );
      } catch (_) {
        // Retry transient queue-read failures without hiding the error
        // from the caller of the current sync attempt.
        _scheduleRetry();
        rethrow;
      }

      if (operations.isEmpty) {
        break;
      }

      retryNeeded = false;

      for (final operation in operations) {
        final operationNeedsRetry = await _syncOperation(operation);
        processedCount++;
        retryNeeded = retryNeeded || operationNeedsRetry;
      }

      // Retryable operations remain in the queue. Stop this pass so the
      // retry timer can handle them without repeatedly selecting them.
      if (retryNeeded) {
        break;
      }

      // A short batch means the queue has been drained.
      if (operations.length < fetchLimit) {
        break;
      }
    }

    if (retryNeeded) {
      _scheduleRetry();
    } else {
      _retryTimer?.cancel();
      _retryTimer = null;
      _retryAttempt = 0;
    }
  }

  Future<bool> _syncOperation(PendingOperation operation) async {
    try {
      await pendingOperationRepository.updateStatus(
        id: operation.id,
        status: PendingOperationStatus.processing,
        lastAttemptAt: DateTime.now(),
        lastError: null,
      );
    } catch (_) {
      // The operation may have been persisted as PROCESSING even though
      // the status update reported an error. Recover it before the next
      // queue read so the same engine can retry it safely.
      _processingRecoveryCompleted = false;
      return true;
    }

    try {
      await remoteSyncDataSource.sync(operation);
    } catch (error) {
      try {
        await pendingOperationRepository.updateStatus(
          id: operation.id,
          status: PendingOperationStatus.failed,
          lastAttemptAt: DateTime.now(),
          lastError: error.toString(),
          retryCount: operation.retryCount + 1,
        );
      } catch (_) {
        // The operation may remain PROCESSING. Retry recovery before the next
        // queue read so this same engine can recover it without an app restart.
        _processingRecoveryCompleted =
            false; // QSW_RECOVER_PROCESSING_ON_STATUS_FAILURE
      }
      return true;
    }

    try {
      await pendingOperationRepository.updateStatus(
        id: operation.id,
        status: PendingOperationStatus.synced,
        lastAttemptAt: DateTime.now(),
        lastError: null,
      );
    } catch (error) {
      try {
        await pendingOperationRepository.updateStatus(
          id: operation.id,
          status: PendingOperationStatus.pending,
          lastAttemptAt: DateTime.now(),
          lastError: 'Failed to save SYNCED status: $error',
        );
      } catch (_) {
        // The operation may remain PROCESSING. Recover it before the next
        // queue read, even when this engine instance is reused.
        _processingRecoveryCompleted =
            false; // QSW_RECOVER_PROCESSING_ON_STATUS_FAILURE
      }
      return true;
    }

    return false;
  }
}
