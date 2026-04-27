import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class NetworkAwarenessService {
  /// Returns true when the outbox processor should run now.
  Future<bool> shouldProcessOutbox();

  Stream<bool> watchOnlineStatus({
    Duration pollInterval = const Duration(seconds: 20),
  });
}

class NetworkAwarenessServiceImpl implements NetworkAwarenessService {
  NetworkAwarenessServiceImpl({
    this.host = 'example.com',
    this.lookupTimeout = const Duration(seconds: 2),
    Future<List<InternetAddress>> Function(String host)? lookup,
  }) : _lookup = lookup ?? InternetAddress.lookup;

  final String host;
  final Duration lookupTimeout;
  final Future<List<InternetAddress>> Function(String host) _lookup;

  @override
  Future<bool> shouldProcessOutbox() async {
    return _checkConnectivity(logFailures: true);
  }

  @override
  Stream<bool> watchOnlineStatus({
    Duration pollInterval = const Duration(seconds: 20),
  }) async* {
    bool? lastStatus;

    while (true) {
      final status = await _checkConnectivity(logFailures: false);
      if (lastStatus == null || status != lastStatus) {
        yield status;
        lastStatus = status;
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<bool> _checkConnectivity({
    required bool logFailures,
  }) async {
    if (kIsWeb) {
      // On web, we rely on platform-level network posture.
      return true;
    }

    try {
      final result = await _lookup(host).timeout(lookupTimeout);
      final hasAddress = result.isNotEmpty;
      if (!hasAddress && logFailures) {
        debugPrint('[SYNC][NETWORK] offline, skipping processor run');
      }
      return hasAddress;
    } catch (error) {
      if (logFailures) {
        debugPrint(
          '[SYNC][NETWORK] offline, skipping processor run error=$error',
        );
      }
      return false;
    }
  }
}
