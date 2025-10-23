import 'dart:async';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  const CacheEntry({
    required this.data,
    required this.timestamp,
    this.expiresAt,
    this.metadata = const {},
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get age => DateTime.now().difference(timestamp);

  CacheEntry<T> copyWith({
    T? data,
    DateTime? timestamp,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return CacheEntry<T>(
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int hitCount;
  final int missCount;
  final double hitRate;
  final int totalSize;
  final DateTime lastAccess;

  const CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
    required this.totalSize,
    required this.lastAccess,
  });

  factory CacheStats.empty() {
    return CacheStats(
      totalEntries: 0,
      expiredEntries: 0,
      hitCount: 0,
      missCount: 0,
      hitRate: 0.0,
      totalSize: 0,
      lastAccess: DateTime.now(),
    );
  }
}

enum CacheEvictionPolicy { lru, lfu, fifo, ttl, size }

abstract class ICacheManager<K, V> {
  String get cacheName;

  int get maxEntries;

  Duration get defaultTtl;

  CacheEvictionPolicy get evictionPolicy;

  Future<void> initialize();

  Future<void> dispose();

  Future<void> put(K key, V value, {Duration? ttl});

  Future<V?> get(K key);

  Future<bool> containsKey(K key);

  Future<bool> remove(K key);

  Future<void> clear();

  Future<CacheStats> getStats();

  Future<List<K>> getKeys();

  Future<int> size();

  Future<bool> isEmpty();

  Future<int> evictExpired();

  Future<int> evictByPolicy(int count);

  Stream<CacheEvent<K, V>> get eventStream;
}

enum CacheEventType { hit, miss, put, remove, evict, clear }

class CacheEvent<K, V> {
  final CacheEventType type;
  final K? key;
  final V? value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const CacheEvent({
    required this.type,
    this.key,
    this.value,
    required this.timestamp,
    this.metadata = const {},
  });
}

abstract class IMemoryAwareCache<K, V> extends ICacheManager<K, V> {
  Future<int> getMemoryUsage();

  int get maxMemorySize;

  Future<bool> isMemoryLimitExceeded();

  Future<int> trimToMemoryLimit();

  int estimateSize(V value);
}

abstract class IPersistentCache<K, V> extends ICacheManager<K, V> {
  Future<void> persist();

  Future<void> load();

  String get storagePath;

  Future<bool> isPersisted();

  Future<Map<String, dynamic>> getPersistenceStats();
}

abstract class IDistributedCache<K, V> extends ICacheManager<K, V> {
  Future<void> invalidateGlobal(K key);

  Future<void> broadcast(CacheEvent<K, V> event);

  Future<void> sync();

  String get nodeId;

  Future<bool> isConnectedToCluster();
}

class CacheConfig {
  final int maxEntries;
  final Duration defaultTtl;
  final CacheEvictionPolicy evictionPolicy;
  final int? maxMemorySize;
  final bool persistent;
  final String? storagePath;
  final bool distributed;
  final Duration cleanupInterval;

  const CacheConfig({
    this.maxEntries = 1000,
    this.defaultTtl = const Duration(hours: 1),
    this.evictionPolicy = CacheEvictionPolicy.lru,
    this.maxMemorySize,
    this.persistent = false,
    this.storagePath,
    this.distributed = false,
    this.cleanupInterval = const Duration(minutes: 5),
  });

  factory CacheConfig.memory() {
    return const CacheConfig(
      maxEntries: 500,
      defaultTtl: Duration(minutes: 30),
      evictionPolicy: CacheEvictionPolicy.lru,
      persistent: false,
    );
  }

  factory CacheConfig.persistent() {
    return const CacheConfig(
      maxEntries: 2000,
      defaultTtl: Duration(hours: 24),
      evictionPolicy: CacheEvictionPolicy.lru,
      persistent: true,
    );
  }

  factory CacheConfig.distributed() {
    return const CacheConfig(
      maxEntries: 5000,
      defaultTtl: Duration(hours: 2),
      evictionPolicy: CacheEvictionPolicy.lru,
      distributed: true,
    );
  }
}
