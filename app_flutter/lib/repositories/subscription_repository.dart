import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../models/user_hive.dart';
import '../models/event.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';
import '../utils/realtime_filter.dart';

class SubscriptionRepository {
  static const String _boxName = 'subscriptions';
  final _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<UserHive>? _box;
  final StreamController<List<models.User>> _subscriptionsController =
      StreamController<List<models.User>>.broadcast();
  List<models.User> _cachedUsers = [];
  RealtimeChannel? _statsChannel;

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  Stream<List<models.User>> get subscriptionsStream async* {
    if (_cachedUsers.isNotEmpty) {
      yield List.from(_cachedUsers);
    }
    yield* _subscriptionsController.stream;
  }

  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      _box = await Hive.openBox<UserHive>(_boxName);

      // Load subscriptions from Hive cache first (if any)
      _loadSubscriptionsFromHive();

      // Fetch and sync subscriptions from API BEFORE subscribing to Realtime
      await _fetchAndSync();

      // Now subscribe to Realtime for future updates
      await _startRealtimeSubscription();

      _emitCurrentSubscriptions();

      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    }
  }

  void _loadSubscriptionsFromHive() {
    if (_box == null) return;

    try {
      _cachedUsers = _box!.values.map((userHive) => userHive.toUser()).toList();
    } catch (e) {
      _cachedUsers = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final response = await _apiClient.fetchUserSubscriptions(userId);
      _cachedUsers = response
          .map((data) => models.User.fromJson(data))
          .toList();

      await _updateLocalCache(_cachedUsers);

      // Set sync timestamp to now (after successful fetch)
      // This ensures we only process realtime events that occur AFTER this fetch
      _rt.setServerSyncTs(DateTime.now().toUtc());

      _emitCurrentSubscriptions();
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore realtime errors
    }
  }

  Future<void> _updateLocalCache(List<models.User> users) async {
    if (_box == null) return;

    await _box!.clear();

    for (final user in users) {
      final userHive = UserHive.fromUser(user);
      await _box!.put(user.id, userHive);
    }
  }

  Future<void> refresh() async {
    try {
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> createSubscription({required int targetUserId}) async {
    try {
      await _apiClient.subscribeToUser(
        ConfigService.instance.currentUserId,
        targetUserId,
      );
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> deleteSubscription({required int targetUserId}) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;

      // Usar el endpoint correcto que borra TODAS las suscripciones a eventos del usuario
      await _apiClient.unsubscribeFromUser(currentUserId, targetUserId);

      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<List<models.User>> searchPublicUsers({required String query}) async {
    try {
      final usersData = await _apiClient.fetchUsers(isPublic: true);
      final results = usersData
          .map((data) => models.User.fromJson(data))
          .where(
            (user) =>
                (user.fullName?.toLowerCase().contains(query.toLowerCase()) ??
                    false) ||
                (user.instagramName?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false) ||
                (user.username?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
      return results;
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> _startRealtimeSubscription() async {
    // NOTE: We no longer subscribe to event_interactions here because EventRepository
    // now handles all interactions (including subscriptions). This avoids conflicts
    // with duplicate Realtime subscriptions to the same table.

    _statsChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'user_subscription_stats',
      onChange: _handleStatsChange,
    );
  }

  void _handleStatsChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) return;

    // Filter out historical events from initial payload
    if (!RealtimeFilter.shouldProcessEvent(
      payload,
      'subscription_stats',
      _rt,
    )) {
      return;
    }

    final statsRecord = Map<String, dynamic>.from(payload.newRecord);
    final affectedUserId = statsRecord['user_id'] as int?;
    if (affectedUserId == null) return;

    final userIndex = _cachedUsers.indexWhere((u) => u.id == affectedUserId);
    if (userIndex == -1) return;

    final user = _cachedUsers[userIndex];
    _cachedUsers[userIndex] = user.copyWith(
      newEventsCount:
          statsRecord['new_events_count'] as int? ?? user.newEventsCount,
      totalEventsCount:
          statsRecord['total_events_count'] as int? ?? user.totalEventsCount,
      subscribersCount:
          statsRecord['subscribers_count'] as int? ?? user.subscribersCount,
    );

    // Update Hive cache
    final updatedUserHive = UserHive.fromUser(_cachedUsers[userIndex]);
    _box?.put(affectedUserId, updatedUserHive);

    _emitCurrentSubscriptions();
  }

  void _emitCurrentSubscriptions() {
    if (!_subscriptionsController.isClosed) {
      _subscriptionsController.add(List.from(_cachedUsers));
    }
  }

  /// Fetch events from a specific user
  Future<List<Event>> fetchUserEvents(int userId) async {
    final eventsData = await _apiClient.fetchUserEvents(userId);
    return eventsData.map((data) => Event.fromJson(data)).toList();
  }

  /// Subscribe to a user
  Future<void> subscribeToUser(int userId) async {
    await _apiClient.post('/users/$userId/subscribe');
    // Refresh subscriptions after subscribing
    await _fetchAndSync();
  }

  /// Unsubscribe from a user
  Future<void> unsubscribeFromUser(int userId) async {
    await _apiClient.delete('/users/$userId/subscribe');
    // Refresh subscriptions after unsubscribing
    await _fetchAndSync();
  }

  void dispose() {
    _statsChannel?.unsubscribe();
    _subscriptionsController.close();
    _box?.close();
  }
}
