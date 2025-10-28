import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';

class SubscriptionRepository {
  final _supabaseService = SupabaseService.instance;
  final RealtimeSync _rt = RealtimeSync();

  final StreamController<List<models.User>> _subscriptionsController =
      StreamController<List<models.User>>.broadcast();
  List<models.User> _cachedUsers = [];
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _statsChannel; // Canal para escuchar cambios en stats

  Stream<List<models.User>> get subscriptionsStream async* {
    // Emit cached data immediately
    if (_cachedUsers.isNotEmpty) {
      print(
        '📡 [SubscriptionRepository] Stream accessed - yielding ${_cachedUsers.length} cached subscriptions',
      );
      yield List.from(_cachedUsers);
    }

    // Then listen to updates
    yield* _subscriptionsController.stream;
  }

  Future<void> initialize() async {
    await _fetchAndSync();
    // Start Realtime immediately after initial fetch to avoid missing CDC that may
    // occur between fetch and subscription start.
    await _startRealtimeSubscription();
    _emitCurrentSubscriptions();
  }

  /// Start Realtime subscription - should be called after the app is fully initialized
  Future<void> startRealtime() async {
    if (_realtimeChannel != null) {
      print('⚠️ [SubscriptionRepository] Realtime already started, skipping');
      return;
    }
    await _startRealtimeSubscription();
  }

  Future<void> _fetchAndSync() async {
    try {
      final userId = ConfigService.instance.currentUserId;

      print(
        '🔵 [SubscriptionRepository] Fetching subscriptions for user $userId',
      );

      // Query user_subscriptions_with_stats view which includes:
      // - new_events_count: Events created in last 7 days
      // - total_events_count: Total events owned by user
      // - subscribers_count: Unique subscribers to user's events
      final response = await _supabaseService.client
          .from('user_subscriptions_with_stats')
          .select('*')
          .eq('subscriber_id', userId);

      final List dataList = (response as List);
      print(
        '🔵 [SubscriptionRepository] Received ${dataList.length} subscriptions from view',
      );

      // Standardize: set server sync ts from rows (serverTime not available from Supabase here)
      _rt.setServerSyncTsFromResponse(
        rows: dataList.whereType<Map>().map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );

      _cachedUsers = dataList
          .map(
            (json) => models.User.fromJson({
              'id': json['subscribed_to_id'],
              'contact_id': json['contact_id'],
              'instagram_name': json['instagram_name'],
              'auth_provider': json['auth_provider'],
              'auth_id': json['auth_id'],
              'is_public': json['is_public'],
              'is_admin': json['is_admin'] ?? false,
              'profile_picture': json['profile_picture'],
              'last_seen': json['last_seen'],
              'created_at': json['created_at'],
              'updated_at': json['updated_at'],
              'new_events_count': json['new_events_count'],
              'total_events_count': json['total_events_count'],
              'subscribers_count': json['subscribers_count'],
            }),
          )
          .toList();

      print('🔵 [SubscriptionRepository] Cached ${_cachedUsers.length} users');
    } catch (e) {
      print('❌ [SubscriptionRepository] Error fetching subscriptions: $e');
    }
  }

  /// Public refresh method so UI can force a refetch without rebuilding providers
  Future<void> refresh() async {
    print('🔄 [SubscriptionRepository] Manual refresh triggered');
    await _fetchAndSync();
    _emitCurrentSubscriptions();
  }

  void removeSubscriptionFromCache(int userId) {
    print(
      '🗑️ [SubscriptionRepository] Manually removing subscription for user ID: $userId',
    );
    final initialCount = _cachedUsers.length;
    _cachedUsers.removeWhere((user) => user.id == userId);
    if (_cachedUsers.length < initialCount) {
      print(
        '✅ [SubscriptionRepository] User $userId removed from cache. Emitting update.',
      );
      _emitCurrentSubscriptions();
    } else {
      print(
        '⚠️ [SubscriptionRepository] User $userId not found in cache. No update emitted.',
      );
    }
  }

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;

    print(
      '🔵 [SubscriptionRepository] Starting Realtime subscriptions for user_id=$userId',
    );

    // Ensure auth token is applied before subscribing
    await SupabaseService.instance.applyTestAuthIfNeeded();

    // Canal 1: Escuchar cambios en event_interactions (subscripciones)
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

    print('✅ Realtime subscription started for event_interactions');

    // Canal 2: Escuchar cambios en user_subscription_stats
    _statsChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'user_subscription_stats',
      onChange: _handleStatsChange,
    );

    print('✅ Realtime subscription started for user_subscription_stats');
  }

  void _handleSubscriptionChange(PostgresChangePayload payload) {
    final userId = ConfigService.instance.currentUserId;
    print(
      '📡 [SubscriptionRepository] CDC ${payload.eventType.name.toUpperCase()}: event_interactions',
    );

    // Validar que sea una interacción de tipo 'subscribed'
    bool isSubscribedInteraction(Map<String, dynamic> rec) {
      return rec['user_id'] == userId &&
          rec['interaction_type'] == 'subscribed';
    }

    final ct = payload.commitTimestamp.toUtc();

    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldRec = Map<String, dynamic>.from(payload.oldRecord);

      if (isSubscribedInteraction(oldRec) && _rt.shouldProcessDelete()) {
        final eventId = oldRec['event_id'];
        print(
          '🗑️ [SubscriptionRepository] User unsubscribed from event $eventId - removing from cache',
        );

        // Encontrar y eliminar el usuario de la lista
        // (El trigger de stats ya actualizó los contadores)
        _fetchAndSync().then((_) => _emitCurrentSubscriptions());
      }
      return;
    }

    final newRec = Map<String, dynamic>.from(payload.newRecord);

    if (isSubscribedInteraction(newRec)) {
      if (_rt.shouldProcessInsertOrUpdate(ct)) {
        final eventId = newRec['event_id'];
        print(
          '✅ [SubscriptionRepository] User subscribed to event $eventId - adding to cache',
        );

        // Nueva suscripción - refetch para obtener datos del usuario
        _fetchAndSync().then((_) => _emitCurrentSubscriptions());
      } else {
        print('⏸️ [SubscriptionRepository] Event skipped by time gate');
      }
    }
  }

  /// Handle changes in user_subscription_stats table (CDC)
  void _handleStatsChange(PostgresChangePayload payload) {
    print(
      '📊 [SubscriptionRepository] CDC ${payload.eventType.name.toUpperCase()}: user_subscription_stats',
    );

    if (payload.eventType == PostgresChangeEvent.delete) {
      // Stats deleted (usuario eliminado) - ya manejado por CASCADE
      return;
    }

    final statsRecord = Map<String, dynamic>.from(payload.newRecord);
    final affectedUserId = statsRecord['user_id'] as int?;

    if (affectedUserId == null) {
      print('⚠️ [SubscriptionRepository] Stats change without user_id');
      return;
    }

    // Buscar el usuario en cache
    final userIndex = _cachedUsers.indexWhere((u) => u.id == affectedUserId);

    if (userIndex == -1) {
      // Usuario no está en nuestra lista de suscripciones - ignorar
      return;
    }

    // Actualizar solo las estadísticas del usuario (CDC granular!)
    final user = _cachedUsers[userIndex];
    _cachedUsers[userIndex] = models.User(
      id: user.id,
      firebaseUid: user.firebaseUid,
      phoneNumber: user.phoneNumber,
      instagramName: user.instagramName,
      email: user.email,
      fullName: user.fullName,
      isPublic: user.isPublic,
      isActive: user.isActive,
      profilePicture: user.profilePicture,
      isBanned: user.isBanned,
      lastSeen: user.lastSeen,
      isOnline: user.isOnline,
      defaultTimezone: user.defaultTimezone,
      defaultCountryCode: user.defaultCountryCode,
      defaultCity: user.defaultCity,
      createdAt: user.createdAt,
      // Actualizar stats desde CDC
      newEventsCount:
          statsRecord['new_events_count'] as int? ?? user.newEventsCount,
      totalEventsCount:
          statsRecord['total_events_count'] as int? ?? user.totalEventsCount,
      subscribersCount:
          statsRecord['subscribers_count'] as int? ?? user.subscribersCount,
    );

    print(
      '📊 [SubscriptionRepository] Stats updated for user $affectedUserId: '
      'events=${statsRecord['total_events_count']}, '
      'new=${statsRecord['new_events_count']}, '
      'subscribers=${statsRecord['subscribers_count']}',
    );

    _emitCurrentSubscriptions();
  }

  void _emitCurrentSubscriptions() {
    if (!_subscriptionsController.isClosed) {
      print(
        '📤 [SubscriptionRepository] Emitting ${_cachedUsers.length} subscriptions to stream',
      );
      _subscriptionsController.add(List.from(_cachedUsers));
    } else {
      print('⚠️ [SubscriptionRepository] Cannot emit - controller is closed');
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _statsChannel?.unsubscribe();
    _subscriptionsController.close();
  }
}
