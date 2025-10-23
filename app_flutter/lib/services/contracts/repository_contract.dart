import 'dart:async';

abstract class IRepository<T, K> {
  String get serviceName;

  Future<void> initialize();

  Future<void> dispose();

  Future<T?> getById(K id);

  Future<List<T>> getByIds(List<K> ids);

  Future<List<T>> getAll();

  Future<T> create(T entity);

  Future<T> update(T entity);

  Future<bool> delete(K id);

  Future<int> deleteMany(List<K> ids);

  Future<bool> exists(K id);

  Future<int> count();

  Future<List<T>> search(String query, {int limit = 20});
}

abstract class ICacheableRepository<T, K> extends IRepository<T, K> {
  Duration get cacheTimeout;

  bool isCacheValid();

  Future<void> clearCache();

  Future<void> refreshCache();

  Map<String, dynamic> getCacheStats();
}

abstract class IOfflineRepository<T, K> extends ICacheableRepository<T, K> {
  bool get isOffline;

  Future<List<T>> getLocal();

  Future<void> sync();

  Future<int> getPendingOperationsCount();

  Future<void> forceSyncPending();
}
