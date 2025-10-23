abstract class ISyncable {
  Future<void> performFullSync();

  Future<void> performIncrementalSync(DateTime lastSync);

  Future<void> performHashBasedSync(String currentHash);

  SyncStatus get syncStatus;

  DateTime? get lastSyncTimestamp;

  Stream<SyncEvent> get syncEventStream;

  Future<void> resolveConflict(dynamic local, dynamic remote);

  Future<List<T>> batchUploadEntities<T>(List<T> entities);

  Future<List<T>> batchDownloadEntities<T>(List<int> entityIds);
}

enum SyncStatus { idle, syncing, completed, failed, conflict }

class SyncEvent {
  final SyncEventType type;
  final String serviceName;
  final DateTime timestamp;
  final double? progress;
  final String? message;
  final dynamic error;
  final Map<String, dynamic>? metadata;

  const SyncEvent({
    required this.type,
    required this.serviceName,
    required this.timestamp,
    this.progress,
    this.message,
    this.error,
    this.metadata,
  });

  @override
  String toString() {
    return 'SyncEvent(type: $type, service: $serviceName, message: $message, progress: $progress)';
  }
}

enum SyncEventType {
  started,
  progress,
  completed,
  failed,
  conflict,
  retrying,
  cancelled,
}

abstract class ICacheManager {
  Future<void> clearCache();

  Future<void> clearCacheForUser(int userId);

  Future<Map<String, dynamic>> getCacheStats();

  Future<void> optimizeCache();

  Future<bool> validateCache();

  Future<int> getCacheSize();
}
