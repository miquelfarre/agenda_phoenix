import 'dart:async';

/// Base contract for all repositories that use Realtime synchronization
///
/// This contract ensures consistent behavior across all repositories:
/// - Initialization lifecycle
/// - Realtime subscription management
/// - Local cache (Hive) operations
/// - Cleanup and disposal
///
/// All repositories with realtime should implement this to guarantee:
/// - Compile-time safety
/// - Consistent patterns
/// - Easier testing and maintenance
abstract class IRealtimeRepository<T> {
  // ============================================================================
  // Initialization
  // ============================================================================

  /// Completes when the repository is fully initialized
  /// (Hive opened, cache loaded, API synced, realtime connected)
  Future<void> get initialized;

  /// Initialize the repository:
  /// 1. Open Hive box
  /// 2. Load cached data from Hive
  /// 3. Fetch fresh data from API
  /// 4. Start realtime subscription
  /// 5. Complete initialization
  Future<void> initialize();

  // ============================================================================
  // Data Stream
  // ============================================================================

  /// Stream of data changes
  /// - Emits cached data immediately to new subscribers
  /// - Then emits updates from API/Realtime
  Stream<T> get dataStream;

  // ============================================================================
  // Realtime Subscription
  // ============================================================================

  /// Start listening to realtime changes from Supabase
  Future<void> startRealtimeSubscription();

  /// Stop listening to realtime changes
  Future<void> stopRealtimeSubscription();

  /// Check if realtime is currently connected
  bool get isRealtimeConnected;

  // ============================================================================
  // Cache Management (Hive)
  // ============================================================================

  /// Load data from local Hive cache
  Future<void> loadFromCache();

  /// Save current data to local Hive cache
  Future<void> saveToCache();

  /// Clear local Hive cache
  Future<void> clearCache();

  // ============================================================================
  // Lifecycle
  // ============================================================================

  /// Cleanup resources:
  /// - Unsubscribe from realtime
  /// - Close stream controllers
  /// - Close Hive box
  void dispose();
}

/// Extension for repositories that support manual refresh
abstract class IRefreshableRepository<T> implements IRealtimeRepository<T> {
  /// Force refresh data from API
  Future<void> refresh();
}

/// Extension for repositories that have local-only data access
abstract class ILocalRepository<T> implements IRealtimeRepository<T> {
  /// Get current cached data without triggering fetch
  T getLocalData();
}
