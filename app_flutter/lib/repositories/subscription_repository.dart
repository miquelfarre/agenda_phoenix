import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';

class SubscriptionRepository {
  final _supabaseService = SupabaseService.instance;
  final RealtimeSync _rt = RealtimeSync();

  final StreamController<List<models.User>> _subscriptionsController = StreamController<List<models.User>>.broadcast();
  List<models.User> _cachedUsers = [];
  RealtimeChannel? _realtimeChannel;

  Stream<List<models.User>> get subscriptionsStream async* {
    // Emit cached data immediately
    if (_cachedUsers.isNotEmpty) {
      print('📡 [SubscriptionRepository] Stream accessed - yielding ${_cachedUsers.length} cached subscriptions');
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

      print('🔵 [SubscriptionRepository] Fetching subscriptions for user $userId');

      // Query user_subscriptions_with_stats view which includes:
      // - new_events_count: Events created in last 7 days
      // - total_events_count: Total events owned by user
      // - subscribers_count: Unique subscribers to user's events
      final response = await _supabaseService.client.from('user_subscriptions_with_stats').select('*').eq('subscriber_id', userId);

      final List dataList = (response as List);
      print('🔵 [SubscriptionRepository] Received ${dataList.length} subscriptions from view');

      // Standardize: set server sync ts from rows (serverTime not available from Supabase here)
      _rt.setServerSyncTsFromResponse(rows: dataList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));

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

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;

    print('🔵 [SubscriptionRepository] Starting Realtime subscription for user_id=$userId');

    // Ensure auth token is applied before subscribing
    await SupabaseService.instance.applyTestAuthIfNeeded();

    // Listen to event_interactions changes for this user
    // When the user subscribes/unsubscribes from events, refetch subscriptions
    _realtimeChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'event_interactions',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId.toString()),
      onChange: _handleSubscriptionChange,
    );

    print('✅ Realtime subscription started for subscriptions (event_interactions)');
  }

  void _handleSubscriptionChange(PostgresChangePayload payload) {
    final userId = ConfigService.instance.currentUserId;
    print('🟢 [SubscriptionRepository] Realtime event received! type=${payload.eventType} ct=${payload.commitTimestamp}');

    bool isSubscribed(Map<String, dynamic> rec) => rec['user_id'] == userId && rec['interaction_type'] == 'subscribed';

    // commitTimestamp can be String or DateTime depending on sdk; normalize to DateTime?
    DateTime? ct;
    final ctRaw = payload.commitTimestamp;
    if (ctRaw is DateTime) {
      ct = ctRaw.toUtc();
    } else if (ctRaw != null) {
      ct = DateTime.tryParse(ctRaw.toString())?.toUtc();
    }

    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldRec = Map<String, dynamic>.from(payload.oldRecord);
      print('🗑️ [SubscriptionRepository] DELETE oldRecord: ' + oldRec.toString());
      if (isSubscribed(oldRec) && _rt.shouldProcessDelete()) {
        print('🟢 [SubscriptionRepository] DELETE subscribed -> refetch');
        _fetchAndSync().then((_) => _emitCurrentSubscriptions());
      } else {
        print('ℹ️ [SubscriptionRepository] DELETE ignored (not subscribed/user mismatch)');
      }
      return;
    }

    final newRec = Map<String, dynamic>.from(payload.newRecord);
    print('📝 [SubscriptionRepository] UPSERT newRecord: ' + newRec.toString());
    if (isSubscribed(newRec)) {
      if (_rt.shouldProcessInsertOrUpdate(ct)) {
        print('🟢 [SubscriptionRepository] ${payload.eventType.name.toUpperCase()} subscribed (after gate) -> refetch');
        _fetchAndSync().then((_) => _emitCurrentSubscriptions());
      } else {
        print('⏸️ [SubscriptionRepository] Event skipped by time gate');
      }
    } else {
      print('ℹ️ [SubscriptionRepository] Ignoring non-subscribed interaction change');
    }
  }

  void _emitCurrentSubscriptions() {
    if (!_subscriptionsController.isClosed) {
      print('📤 [SubscriptionRepository] Emitting ${_cachedUsers.length} subscriptions to stream');
      _subscriptionsController.add(List.from(_cachedUsers));
    } else {
      print('⚠️ [SubscriptionRepository] Cannot emit - controller is closed');
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _subscriptionsController.close();
  }
}
