import 'package:uuid/uuid.dart';

import '../../data/dto/ownership_transfer_dto.dart';
import '../../data/hive_boxes.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../../models/dog_membership.dart';
import '../../models/ownership_transfer.dart';
import '../../models/sync_task.dart';
import 'local_sync_queue_repository.dart';

class LocalOwnershipTransferRepository implements OwnershipTransferRepository {
  LocalOwnershipTransferRepository({SyncQueueRepository? syncQueueRepository})
      : _syncQueueRepository =
            syncQueueRepository ?? LocalSyncQueueRepository();

  final SyncQueueRepository _syncQueueRepository;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<OwnershipTransfer>> getPendingForUser(String userId) async {
    return ownershipTransfersBox()
        .values
        .where((t) => t.toUserId == userId && t.status == Status.pending)
        .toList();
  }

  @override
  Future<OwnershipTransfer?> getById(String transferId) async {
    return ownershipTransfersBox().get(transferId);
  }

  @override
  Future<void> upsertTransfer(OwnershipTransfer transfer) async {
    await ownershipTransfersBox().put(transfer.transferId, transfer);
    await _enqueueSyncTask(transfer);
  }

  Future<void> _enqueueSyncTask(OwnershipTransfer transfer) async {
    final task = SyncTask(
      taskId: _uuid.v4(),
      entityType: 'ownership_transfer',
      entityId: transfer.transferId,
      payload: ownershipTransferToJson(transfer),
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );
    await _syncQueueRepository.addTask(task);
  }
}
