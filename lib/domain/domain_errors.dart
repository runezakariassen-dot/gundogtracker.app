enum ShareError {
  notOwner,
  inviteNotFound,
  inviteExpired,
  inviteRevoked,
  inviteInactive,
  alreadyHasAccess,
  invalidRole,
  invalidEmail,
}

enum TransferError {
  notOwner,
  notRecipient,
  transferNotFound,
  transferExpired,
  transferNotPending,
  cannotTransferToSelf,
  cancelled,
}

class ShareException implements Exception {
  ShareException(this.code, {this.message});

  final ShareError code;
  final String? message;

  @override
  String toString() =>
      'ShareException($code${message == null ? '' : ': $message'})';
}

class TransferException implements Exception {
  TransferException(this.code, {this.message});

  final TransferError code;
  final String? message;

  @override
  String toString() =>
      'TransferException($code${message == null ? '' : ': $message'})';
}
