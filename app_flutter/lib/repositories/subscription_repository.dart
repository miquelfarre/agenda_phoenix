import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../models/user_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';

class SubscriptionRepository {
  static const String _boxName = 'subscriptions';
  final _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<UserHive>? _box;
  final StreamController<List<models.User>> _subscriptionsController =
      StreamController<List<models.User>>.broadcast();
  List<models.User> _cachedUsers = [];
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _statsChannel;

  Stream<List<models.User>> get subscriptionsStream async* {
    if (_cachedUsers.isNotEmpty) {
      yield List.from(_cachedUsers);
    }
    yield* _subscriptionsController.stream;
  }

  Future<void> initialize() async {
    print('🚀 [SubscriptionRepository] Initializing...');
    _box = await Hive.openBox<UserHive>(_boxName);

    // Load subscriptions from Hive cache first (if any)
    _loadSubscriptionsFromHive();

    // Fetch and sync subscriptions from API BEFORE subscribing to Realtime
    await _fetchAndSync();

    // Now subscribe to Realtime for future updates
    await _startRealtimeSubscription();

    _emitCurrentSubscriptions();
    print('✅ [SubscriptionRepository] Initialization complete');
  }

  void _loadSubscriptionsFromHive() {
    if (_box == null) return;

    try {
      _cachedUsers = _box!.values
          .map((userHive) => userHive.toUser())
          .toList();

      print('✅ [SubscriptionRepository] Loaded ${_cachedUsers.length} subscriptions from Hive cache');
    } catch (e) {
      print('❌ [SubscriptionRepository] Error loading from Hive: $e');
      _cachedUsers = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      print('📡 [SubscriptionRepository] Fetching subscriptions from API...');
      final userId = ConfigService.instance.currentUserId;
      final response = await _apiClient.fetchUserSubscriptions(userId);
      _cachedUsers = response.map((data) => models.User.fromJson(data)).toList();

      await _updateLocalCache(_cachedUsers);

      _rt.setServerSyncTsFromResponse(
        rows: _cachedUsers.map((u) => u.toJson()),
      );
      _emitCurrentSubscriptions();
      print('✅ [SubscriptionRepository] Fetched ${_cachedUsers.length} subscriptions');
    } catch (e) {
      print('❌ [SubscriptionRepository] Error fetching subscriptions: $e');
    }
  }

  Future<void> _updateLocalCache(List<models.User> users) async {
    if (_box == null) return;

    print('💾 [SubscriptionRepository] Updating Hive cache with ${users.length} users...');
    await _box!.clear();

    for (final user in users) {
      final userHive = UserHive.fromUser(user);
      await _box!.put(user.id, userHive);
    }
    print('✅ [SubscriptionRepository] Hive cache updated');
  }

  Future<void> refresh() async {
    print('🔄 [SubscriptionRepository] Manual refresh requested');
    await _fetchAndSync();
  }

  Future<void> createSubscription({required int targetUserId}) async {
    print('➕ [SubscriptionRepository] Creating subscription to user $targetUserId');
    await _apiClient.subscribeToUser(ConfigService.instance.currentUserId, targetUserId);
    await _fetchAndSync();
    print('✅ [SubscriptionRepository] Subscription created');
  }

  Future<void> deleteSubscription({required int targetUserId}) async {
    print('🗑️ [SubscriptionRepository] deleteSubscription START - userId: $targetUserId');

    final userBefore = _cachedUsers.where((u) => u.id == targetUserId).firstOrNull;
    print('🗑️ [SubscriptionRepository] User in cache: ${userBefore != null ? '"${userBefore.fullName ?? userBefore.instagramName}"' : 'NOT FOUND'}');
    print('🗑️ [SubscriptionRepository] Cache size before: ${_cachedUsers.length}');

    final currentUserId = ConfigService.instance.currentUserId;
    final interactions = await _apiClient.fetchInteractions(
      userId: currentUserId,
      interactionType: 'subscribed',
    );

    final targetInteraction = interactions.firstWhere(
      (interaction) => interaction['target_user_id'] == targetUserId,
      orElse: () => throw Exception('Subscription not found'),
    );

    await _apiClient.deleteInteraction(targetInteraction['id']);
    removeSubscriptionFromCache(targetUserId);

    print('✅ [SubscriptionRepository] Subscription deleted - User ID $targetUserId');
  }

  Future<List<models.User>> searchPublicUsers({required String query}) async {
    print('🔍 [SubscriptionRepository] Searching public users: "$query"');
    final usersData = await _apiClient.fetchUsers(isPublic: true);
    final results = usersData
        .map((data) => models.User.fromJson(data))
        .where((user) =>
            (user.fullName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
    print('✅ [SubscriptionRepository] Found ${results.length} users matching "$query"');
    return results;
  }

  void removeSubscriptionFromCache(int userId) {
    print('🗑️ [SubscriptionRepository] removeSubscriptionFromCache START - userId: $userId');

    final userBefore = _cachedUsers.where((u) => u.id == userId).firstOrNull;
    print('🗑️ [SubscriptionRepository] User in cache: ${userBefore != null ? '"${userBefore.fullName ?? userBefore.instagramName}"' : 'NOT FOUND'}');

    final initialCount = _cachedUsers.length;
    print('🗑️ [SubscriptionRepository] Cache size before: $initialCount');

    _cachedUsers.removeWhere((user) => user.id == userId);
    print('🗑️ [SubscriptionRepository] Cache size after: ${_cachedUsers.length}');

    _box?.delete(userId);
    print('🗑️ [SubscriptionRepository] Deleted from Hive box');

    if (_cachedUsers.length < initialCount) {
      print('🗑️ [SubscriptionRepository] Emitting updated subscriptions to stream...');
      _emitCurrentSubscriptions();
      print('✅ [SubscriptionRepository] User manually removed and stream emitted - ID $userId');
    }
  }

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _realtimeChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'event_interactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId.toString(),
      ),
      onChange: _handleSubscriptionChange,
    );

    print('✅ [SubscriptionRepository] Realtime subscription started for event_interactions table');

    _statsChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'user_subscription_stats',
      onChange: _handleStatsChange,
    );

    print('✅ [SubscriptionRepository] Realtime subscription started for user_subscription_stats table');
  }

  void _handleSubscriptionChange(PostgresChangePayload payload) {
    final userId = ConfigService.instance.currentUserId;
    bool isSubscribedInteraction(Map<String, dynamic> rec) {
      return rec['user_id'] == userId && rec['interaction_type'] == 'subscribed';
    }

    final ct = payload.commitTimestamp.toUtc();

    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldRec = Map<String, dynamic>.from(payload.oldRecord);
      if (isSubscribedInteraction(oldRec) && _rt.shouldProcessDelete()) {
        print('🔄 [SubscriptionRepository] DELETE detected, refreshing subscriptions');
        _fetchAndSync();
      }
      return;
    }

    final newRec = Map<String, dynamic>.from(payload.newRecord);
    if (isSubscribedInteraction(newRec)) {
      if (_rt.shouldProcessInsertOrUpdate(ct)) {
        print('🔄 [SubscriptionRepository] INSERT/UPDATE detected, refreshing subscriptions');
        _fetchAndSync();
      } else {
        print('⏸️ [SubscriptionRepository] Event skipped by time gate');
      }
    }
  }

  void _handleStatsChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) return;

    final statsRecord = Map<String, dynamic>.from(payload.newRecord);
    final affectedUserId = statsRecord['user_id'] as int?;
    if (affectedUserId == null) return;

    final userIndex = _cachedUsers.indexWhere((u) => u.id == affectedUserId);
    if (userIndex == -1) return;

    print('📊 [SubscriptionRepository] Stats updated for user $affectedUserId');
    final user = _cachedUsers[userIndex];
    _cachedUsers[userIndex] = user.copyWith(
      newEventsCount: statsRecord['new_events_count'] as int? ?? user.newEventsCount,
      totalEventsCount: statsRecord['total_events_count'] as int? ?? user.totalEventsCount,
      subscribersCount: statsRecord['subscribers_count'] as int? ?? user.subscribersCount,
    );

    // Update Hive cache
    final updatedUserHive = UserHive.fromUser(_cachedUsers[userIndex]);
    _box?.put(affectedUserId, updatedUserHive);

    _emitCurrentSubscriptions();
    print('✅ [SubscriptionRepository] Stats update applied to user $affectedUserId');
  }

  void _emitCurrentSubscriptions() {
    if (!_subscriptionsController.isClosed) {
      _subscriptionsController.add(List.from(_cachedUsers));
    }
  }

  void dispose() {
    print('👋 [SubscriptionRepository] Disposing...');
    _realtimeChannel?.unsubscribe();
    _statsChannel?.unsubscribe();
    _subscriptionsController.close();
  }
}
