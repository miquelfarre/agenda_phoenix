import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../services/supabase_service.dart';
import '../services/config_service.dart';

class SubscriptionRepository {
  final _supabaseService = SupabaseService.instance;

  final StreamController<List<models.User>> _subscriptionsController =
      StreamController<List<models.User>>.broadcast();
  List<models.User> _cachedUsers = [];
  DateTime? _initialSyncTime;
  RealtimeChannel? _realtimeChannel;

  Stream<List<models.User>> get subscriptionsStream =>
      _subscriptionsController.stream;

  Future<void> initialize() async {
    await _fetchAndSync();
    await _startRealtimeSubscription();
    _emitCurrentSubscriptions();
  }

  Future<void> _fetchAndSync() async {
    try {
      _initialSyncTime = DateTime.now().toUtc();
      final userId = ConfigService.instance.currentUserId;

      print('🔵 [SubscriptionRepository] Fetching subscriptions for user $userId');

      // Query user_subscriptions_with_stats view which includes:
      // - new_events_count: Events created in last 7 days
      // - total_events_count: Total events owned by user
      // - subscribers_count: Unique subscribers to user's events
      final response = await _supabaseService.client
          .from('user_subscriptions_with_stats')
          .select('*')
          .eq('subscriber_id', userId);

      print('🔵 [SubscriptionRepository] Received ${(response as List).length} subscriptions from view');

      _cachedUsers = (response as List)
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

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;

    print('🔵 [SubscriptionRepository] Starting Realtime subscription for user_id=$userId');

    // Listen to event_interactions changes for this user
    // When the user subscribes/unsubscribes from events, refetch subscriptions
    _realtimeChannel = _supabaseService.client
        .channel('subscriptions_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId.toString(),
          ),
          callback: _handleSubscriptionChange,
        )
        .subscribe();

    print('🔵 [SubscriptionRepository] Realtime subscription started');
  }

  void _handleSubscriptionChange(PostgresChangePayload payload) {
    print('🟢 [SubscriptionRepository] Realtime event received!');
    print('🟢 [SubscriptionRepository] Event type: ${payload.eventType}');
    print('🟢 [SubscriptionRepository] Commit timestamp: ${payload.commitTimestamp}');

    final eventTime = DateTime.tryParse(payload.commitTimestamp.toString());
    print('🟢 [SubscriptionRepository] Event time: $eventTime');
    print('🟢 [SubscriptionRepository] Initial sync time: $_initialSyncTime');

    if (eventTime != null &&
        _initialSyncTime != null &&
        eventTime.isBefore(_initialSyncTime!)) {
      print('⚠️ [SubscriptionRepository] Event blocked: timestamp before initial sync');
      return;
    }

    // Only process subscription-related changes
    final interactionType = payload.eventType == PostgresChangeEvent.delete
        ? payload.oldRecord['interaction_type']
        : payload.newRecord['interaction_type'];

    print('🟢 [SubscriptionRepository] Interaction type: $interactionType');
    print('🟢 [SubscriptionRepository] Old record: ${payload.oldRecord}');
    print('🟢 [SubscriptionRepository] New record: ${payload.newRecord}');

    if (interactionType == 'subscribed') {
      print('✅ [SubscriptionRepository] Subscription change detected! Refetching...');
      // Refetch subscriptions from view with calculated fields
      _fetchAndSync().then((_) {
        _emitCurrentSubscriptions();
        print('✅ [SubscriptionRepository] Subscriptions refetched and emitted');
      });
    } else {
      print('⚠️ [SubscriptionRepository] Ignoring non-subscription interaction: $interactionType');
    }
  }

  void _emitCurrentSubscriptions() {
    if (!_subscriptionsController.isClosed) {
      _subscriptionsController.add(List.from(_cachedUsers));
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _subscriptionsController.close();
  }
}
