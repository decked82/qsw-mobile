import '../entities/movement.dart';
import '../../../sync/domain/entities/pending_operation.dart';

abstract interface class MovementSaveRepository {
  Future<void> saveAtomically({
    required Movement movement,
    required PendingOperation pendingOperation,
  });
}
