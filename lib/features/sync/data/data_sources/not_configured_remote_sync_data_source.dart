import '../../domain/entities/pending_operation.dart';
import 'remote_sync_data_source.dart';

class NotConfiguredRemoteSyncDataSource implements RemoteSyncDataSource {
  const NotConfiguredRemoteSyncDataSource();

  @override
  Future<void> sync(PendingOperation operation) async {
    throw StateError('Remote sync data source is not configured.');
  }
}
