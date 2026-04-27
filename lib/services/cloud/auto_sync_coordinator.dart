import 'package:flutter/foundation.dart';

import '../../data/local/sync_outbox_service.dart';
import 'network_awareness_service.dart';
import 'pull_sync_service.dart';
import 'sync_cleanup_service.dart';
import 'sync_outbox_processor.dart';

class AutoSyncCoordinator {
  AutoSyncCoordinator._internal({
    SyncOutboxService? outboxService,
    SyncOutboxProcessor? processor,
    NetworkAwarenessService? networkAwarenessService,
    PullSyncService? pullSyncService,
    SyncCleanupService? syncCleanupService,
    Future<int> Function()? resetFailedTasks,
    Future<void> Function()? processOutbox,
    Future<void> Function()? pullData,
    Future<void> Function()? cleanupData,
    DateTime Function()? now,
    Duration lifecycleCooldown = const Duration(seconds: 10),
  })  : _outboxService = outboxService,
        _processor = processor,
        _networkAwarenessService =
            networkAwarenessService ?? NetworkAwarenessServiceImpl(),
        _pullSyncService = pullSyncService,
        _syncCleanupService = syncCleanupService,
        _resetFailedTasksOverride = resetFailedTasks,
        _processOutboxOverride = processOutbox,
        _pullDataOverride = pullData,
        _cleanupDataOverride = cleanupData,
        _now = now ?? DateTime.now,
        _lifecycleCooldown = lifecycleCooldown;

  static final AutoSyncCoordinator instance = AutoSyncCoordinator._internal(
    outboxService: SyncOutboxService(enableAutoSync: false),
  );

  AutoSyncCoordinator({
    SyncOutboxService? outboxService,
    SyncOutboxProcessor? processor,
    NetworkAwarenessService? networkAwarenessService,
    PullSyncService? pullSyncService,
    SyncCleanupService? syncCleanupService,
    Future<int> Function()? resetFailedTasks,
    Future<void> Function()? processOutbox,
    Future<void> Function()? pullData,
    Future<void> Function()? cleanupData,
    DateTime Function()? now,
    Duration lifecycleCooldown = const Duration(seconds: 10),
  }) : this._internal(
          outboxService: outboxService,
          processor: processor,
          networkAwarenessService: networkAwarenessService,
          pullSyncService: pullSyncService,
          syncCleanupService: syncCleanupService,
          resetFailedTasks: resetFailedTasks,
          processOutbox: processOutbox,
          pullData: pullData,
          cleanupData: cleanupData,
          now: now,
          lifecycleCooldown: lifecycleCooldown,
        );

  final SyncOutboxService? _outboxService;
  final SyncOutboxProcessor? _processor;
  final NetworkAwarenessService _networkAwarenessService;
  final PullSyncService? _pullSyncService;
  final SyncCleanupService? _syncCleanupService;
  final Future<int> Function()? _resetFailedTasksOverride;
  final Future<void> Function()? _processOutboxOverride;
  final Future<void> Function()? _pullDataOverride;
  final Future<void> Function()? _cleanupDataOverride;
  final DateTime Function() _now;
  final Duration _lifecycleCooldown;

  bool _isRunning = false;
  bool _rerunRequested = false;
  bool _isLifecycleTriggerActive = false;
  DateTime? _lastLifecycleTriggerAt;

  Future<void> runAfterEnqueue() {
    return _run(
      source: 'enqueue',
      allowQueuedRerun: true,
      logPrefix: '[SYNC][AUTO]',
      logTriggerMessage: 'enqueue trigger',
    );
  }

  Future<void> runOnStartup() {
    return _run(
      source: 'startup',
      allowQueuedRerun: false,
      logPrefix: '[SYNC][AUTO]',
      logTriggerMessage: 'startup trigger',
    );
  }

  Future<void> runOnResumed() async {
    await _runForegroundTrigger(
      source: 'resumed',
      triggerMessage: 'resumed trigger',
    );
  }

  Future<void> runOnNetworkOnline() async {
    await _runForegroundTrigger(
      source: 'network',
      triggerMessage: 'network online trigger',
    );
  }

  Future<void> _runForegroundTrigger({
    required String source,
    required String triggerMessage,
  }) async {
    const logPrefix = '[SYNC][AUTO]';
    debugPrint('$logPrefix $triggerMessage');

    if (_isRunning) {
      debugPrint('$logPrefix skipped reason=already_running source=$source');
      return;
    }

    if (_isLifecycleTriggerActive) {
      debugPrint('$logPrefix skipped reason=trigger_active source=$source');
      return;
    }

    final now = _now();
    final lastLifecycleTriggerAt = _lastLifecycleTriggerAt;
    if (lastLifecycleTriggerAt != null &&
        now.difference(lastLifecycleTriggerAt) < _lifecycleCooldown) {
      debugPrint('$logPrefix skipped reason=cooldown source=$source');
      return;
    }

    _isLifecycleTriggerActive = true;
    _lastLifecycleTriggerAt = now;

    try {
      final allowed = await _networkAwarenessService.shouldProcessOutbox();
      if (!allowed) {
        debugPrint('$logPrefix skipped reason=offline source=$source');
        return;
      }

      if (_isRunning) {
        debugPrint('$logPrefix skipped reason=already_running source=$source');
        return;
      }

      await _run(
        source: source,
        allowQueuedRerun: false,
        logPrefix: logPrefix,
      );
    } finally {
      _isLifecycleTriggerActive = false;
    }
  }

  Future<void> _run({
    required String source,
    required bool allowQueuedRerun,
    required String logPrefix,
    String? logTriggerMessage,
  }) async {
    if (logTriggerMessage != null) {
      debugPrint('$logPrefix $logTriggerMessage');
    }

    if (_isRunning) {
      if (allowQueuedRerun) {
        _rerunRequested = true;
        debugPrint('$logPrefix overlap detected; queued rerun source=$source');
      } else {
        debugPrint('$logPrefix skipped reason=already_running source=$source');
      }
      return;
    }

    _isRunning = true;
    try {
      do {
        _rerunRequested = false;
        try {
          debugPrint('$logPrefix processing start source=$source');
          final resetCount = await _resetFailedTasks();
          debugPrint('$logPrefix retry reset count=$resetCount');
          await _pullData();
          await _processOutbox();
          if (source != 'enqueue') {
            await _cleanupData();
          }
          debugPrint('$logPrefix complete source=$source');
        } catch (error, stackTrace) {
          debugPrint('$logPrefix failed source=$source error=$error');
          debugPrint(stackTrace.toString());
        }
      } while (_rerunRequested);
    } finally {
      _isRunning = false;
    }
  }

  Future<int> _resetFailedTasks() {
    final override = _resetFailedTasksOverride;
    if (override != null) {
      return override();
    }
    return (_outboxService ?? SyncOutboxService(enableAutoSync: false))
        .resetFailedTasksForAutomaticRetry();
  }

  Future<void> _processOutbox() {
    final override = _processOutboxOverride;
    if (override != null) {
      return override();
    }
    final outboxService =
        _outboxService ?? SyncOutboxService(enableAutoSync: false);
    return (_processor ?? SyncOutboxProcessor(outboxService: outboxService))
        .runOnce();
  }

  Future<void> _pullData() {
    final override = _pullDataOverride;
    if (override != null) {
      return override();
    }
    return (_pullSyncService ?? PullSyncService()).pullAllVisibleData();
  }

  Future<void> _cleanupData() async {
    final override = _cleanupDataOverride;
    if (override != null) {
      await override();
      return;
    }
    await (_syncCleanupService ?? SyncCleanupService()).runCleanup();
  }
}
