import 'package:sqflite/sqflite.dart';

import '../../domain/entities/movement.dart';
import '../../domain/repositories/movement_save_repository.dart';
import '../../../sync/data/repositories/sqlite_pending_operation_repository.dart';
import '../../../sync/domain/entities/pending_operation.dart';
import 'sqlite_movement_repository.dart';

class SqliteMovementSaveRepository implements MovementSaveRepository {
  const SqliteMovementSaveRepository(this.database);

  final Database database;

  @override
  Future<void> saveAtomically({
    required Movement movement,
    required PendingOperation pendingOperation,
  }) async {
    await database.transaction((transaction) async {
      final movementRepository = SqliteMovementRepository(transaction);
      final pendingOperationRepository = SqlitePendingOperationRepository(
        transaction,
      );
      await movementRepository.save(movement);
      await pendingOperationRepository.save(pendingOperation);
    });
  }
}
