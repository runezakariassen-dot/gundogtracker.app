import '../../domain/repositories/transfer_repository.dart';
import '../../models/ownership_transfer.dart';

class RemoteOwnershipTransferRepository implements OwnershipTransferRepository {
  @override
  Future<List<OwnershipTransfer>> getPendingForUser(String userId) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<OwnershipTransfer?> getById(String transferId) {
    throw UnimplementedError('Remote sync disabled');
  }

  @override
  Future<void> upsertTransfer(OwnershipTransfer transfer) {
    throw UnimplementedError('Remote sync disabled');
  }
}
