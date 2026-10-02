import '../entities/inbound_transaction.dart';

abstract interface class InboundTransactionRepository {
  Future<InboundTransaction?> getById(int id);

  Future<InboundTransaction?> getByOperationId(String operationId);

  Future<List<InboundTransaction>> getByBoxNo(String boxNo);

  Future<List<InboundTransaction>> getByPartNo(String partNo);

  Future<void> save(InboundTransaction transaction);
}
