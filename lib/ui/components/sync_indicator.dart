import 'package:flutter/material.dart';

import '../../services/cloud/sync_status_service.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({
    super.key,
    required this.status,
    this.size = 18,
  });

  final SyncStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.synced:
        return Icon(
          Icons.cloud_done,
          size: size,
          color: Colors.green,
        );
      case SyncStatus.pending:
        return Icon(
          Icons.cloud_queue,
          size: size,
          color: Colors.grey,
        );
      case SyncStatus.inProgress:
        return SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.failed:
        return Icon(
          Icons.error,
          size: size,
          color: Colors.red,
        );
    }
  }
}
