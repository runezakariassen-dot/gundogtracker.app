import '../../models/ownership_transfer.dart';

abstract class OwnershipTransferRepository {
  Future<List<OwnershipTransfer>> getPendingForUser(String userId);
  Future<OwnershipTransfer?> getById(String transferId);
  Future<void> upsertTransfer(OwnershipTransfer transfer);
}
