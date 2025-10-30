import 'dart:async';

class SyncResult {
  final bool success;
  final int itemsSynced;
  final int itemsAdded;
  final int itemsUpdated;
  final int itemsDeleted;
  final List<String> errors;
  final Duration syncDuration;
  final DateTime syncTimestamp;
  final String? lastSyncHash;
  final Map<String, dynamic> metadata;

  const SyncResult({required this.success, required this.itemsSynced, required this.itemsAdded, required this.itemsUpdated, required this.itemsDeleted, required this.errors, required this.syncDuration, required this.syncTimestamp, this.lastSyncHash, this.metadata = const {}});

  factory SyncResult.success({required int itemsSynced, int itemsAdded = 0, int itemsUpdated = 0, int itemsDeleted = 0, required Duration syncDuration, String? lastSyncHash, Map<String, dynamic> metadata = const {}}) {
    return SyncResult(success: true, itemsSynced: itemsSynced, itemsAdded: itemsAdded, itemsUpdated: itemsUpdated, itemsDeleted: itemsDeleted, errors: [], syncDuration: syncDuration, syncTimestamp: DateTime.now(), lastSyncHash: lastSyncHash, metadata: metadata);
  }

  factory SyncResult.failure({required List<String> errors, required Duration syncDuration, Map<String, dynamic> metadata = const {}}) {
    return SyncResult(success: false, itemsSynced: 0, itemsAdded: 0, itemsUpdated: 0, itemsDeleted: 0, errors: errors, syncDuration: syncDuration, syncTimestamp: DateTime.now(), metadata: metadata);
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get hasChanges => itemsAdded > 0 || itemsUpdated > 0 || itemsDeleted > 0;

  @override
  String toString() {
    return 'SyncResult(success: $success, synced: $itemsSynced, added: $itemsAdded, updated: $itemsUpdated, deleted: $itemsDeleted, errors: ${errors.length})';
  }
}

enum SyncStrategy { full, incremental, hashBased, timestampBased, manual }

enum SyncDirection { pull, push, bidirectional }

enum ConflictResolution { clientWins, serverWins, lastModified, manual, merge }

class SyncConfig {
  final SyncStrategy strategy;
  final SyncDirection direction;
  final ConflictResolution conflictResolution;
  final Duration syncInterval;
  final int retryAttempts;
  final Duration retryDelay;
  final bool autoSync;
  final List<String> includedFields;
  final List<String> excludedFields;

  const SyncConfig({
    this.strategy = SyncStrategy.incremental,
    this.direction = SyncDirection.bidirectional,
    this.conflictResolution = ConflictResolution.lastModified,
    this.syncInterval = const Duration(minutes: 5),
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.autoSync = true,
    this.includedFields = const [],
    this.excludedFields = const [],
  });

  factory SyncConfig.realtime() {
    return const SyncConfig(strategy: SyncStrategy.incremental, direction: SyncDirection.bidirectional, syncInterval: Duration(seconds: 30), autoSync: true);
  }

  factory SyncConfig.background() {
    return const SyncConfig(strategy: SyncStrategy.hashBased, direction: SyncDirection.bidirectional, syncInterval: Duration(minutes: 15), autoSync: true);
  }

  factory SyncConfig.manual() {
    return const SyncConfig(strategy: SyncStrategy.full, direction: SyncDirection.bidirectional, autoSync: false);
  }
}

abstract class ISyncable {
  String get serviceName;

  SyncConfig get syncConfig;

  SyncStatus get syncStatus;

  DateTime? get lastSyncTime;

  String? get lastSyncHash;

  Future<SyncResult> sync({bool force = false, SyncStrategy? strategy, SyncDirection? direction});

  void startAutoSync();

  void stopAutoSync();

  Future<bool> needsSync();

  Future<int> getPendingChangesCount();

  Future<SyncResult> pushChanges();

  Future<SyncResult> pullChanges();

  Future<void> resolveConflicts(List<SyncConflict> conflicts);

  Future<List<SyncConflict>> getSyncConflicts();

  Future<void> resetSyncState();

  Stream<SyncEvent> get syncEventStream;

  Stream<SyncStatus> get syncStatusStream;
}

enum SyncStatus { idle, syncing, pushing, pulling, conflicts, error, disabled }

enum SyncEventType { started, progress, completed, failed, conflict, cancelled }

class SyncEvent {
  final SyncEventType type;
  final String serviceName;
  final DateTime timestamp;
  final double? progress;
  final String? message;
  final SyncResult? result;
  final Map<String, dynamic> metadata;

  const SyncEvent({required this.type, required this.serviceName, required this.timestamp, this.progress, this.message, this.result, this.metadata = const {}});

  factory SyncEvent.started(String serviceName) {
    return SyncEvent(type: SyncEventType.started, serviceName: serviceName, timestamp: DateTime.now(), progress: 0.0);
  }

  factory SyncEvent.progress(String serviceName, double progress, String? message) {
    return SyncEvent(type: SyncEventType.progress, serviceName: serviceName, timestamp: DateTime.now(), progress: progress, message: message);
  }

  factory SyncEvent.completed(String serviceName, SyncResult result) {
    return SyncEvent(type: SyncEventType.completed, serviceName: serviceName, timestamp: DateTime.now(), progress: 1.0, result: result);
  }

  factory SyncEvent.failed(String serviceName, String message) {
    return SyncEvent(type: SyncEventType.failed, serviceName: serviceName, timestamp: DateTime.now(), message: message);
  }
}

class SyncConflict {
  final String id;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final ConflictResolution suggestedResolution;

  const SyncConflict({required this.id, required this.entityType, required this.entityId, required this.localData, required this.remoteData, required this.localTimestamp, required this.remoteTimestamp, required this.suggestedResolution});

  bool get isLocalNewer => localTimestamp.isAfter(remoteTimestamp);
  bool get isRemoteNewer => remoteTimestamp.isAfter(localTimestamp);
  bool get isSameTimestamp => localTimestamp == remoteTimestamp;
}

abstract class IBatchSyncable extends ISyncable {
  Future<Map<String, SyncResult>> batchSync({required List<String> serviceNames, bool force = false});

  List<String> get syncPriorityOrder;

  Map<String, List<String>> get syncDependencies;
}

abstract class IRealtimeSyncable extends ISyncable {
  Future<void> connectRealtime();

  Future<void> disconnectRealtime();

  bool get isRealtimeConnected;

  Stream<RealtimeChange> get realtimeChangeStream;
}

class RealtimeChange {
  final String entityType;
  final String entityId;
  final RealtimeChangeType changeType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? userId;

  const RealtimeChange({required this.entityType, required this.entityId, required this.changeType, required this.data, required this.timestamp, this.userId});
}

enum RealtimeChangeType { created, updated, deleted, moved }

class SyncException implements Exception {
  final String message;
  final String serviceName;
  final SyncEventType? eventType;
  final dynamic originalError;

  const SyncException({required this.message, required this.serviceName, this.eventType, this.originalError});

  @override
  String toString() => 'SyncException($serviceName): $message';
}
