import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';

class SubscriptionRepository {
  final _supabaseService = SupabaseService.instance;

  final StreamController<List<Subscription>> _subscriptionsController =
      StreamController<List<Subscription>>.broadcast();
  List<Subscription> _cachedSubscriptions = [];
  DateTime? _initialSyncTime;
  RealtimeChannel? _realtimeChannel;

  Stream<List<Subscription>> get subscriptionsStream =>
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

      final response = await _supabaseService.client
          .from('user_subscriptions')
          .select('''
            *,
            followed:users!user_subscriptions_subscribed_to_id_fkey(*)
          ''')
          .eq('user_id', userId);

      _cachedSubscriptions = (response as List)
          .map((json) => Subscription.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching subscriptions: $e');
    }
  }

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _realtimeChannel = _supabaseService.client
        .channel('subscriptions_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_subscriptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId.toString(),
          ),
          callback: _handleSubscriptionChange,
        )
        .subscribe();
  }

  void _handleSubscriptionChange(PostgresChangePayload payload) {
    final eventTime = DateTime.tryParse(payload.commitTimestamp.toString());
    if (eventTime != null &&
        _initialSyncTime != null &&
        eventTime.isBefore(_initialSyncTime!)) {
      return;
    }

    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      // For INSERT and UPDATE, re-fetch with user data included
      final subId = payload.newRecord['id'];
      if (subId != null) {
        _refetchSubscription(subId);
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final subId = payload.oldRecord['id'];
      if (subId != null) {
        _cachedSubscriptions.removeWhere((s) => s.id == subId);
        _emitCurrentSubscriptions();
      }
    }
  }

  Future<void> _refetchSubscription(int subId) async {
    try {
      final response = await _supabaseService.client
          .from('user_subscriptions')
          .select('''
            *,
            followed:users!user_subscriptions_subscribed_to_id_fkey(*)
          ''')
          .eq('id', subId)
          .single();

      final subscription = Subscription.fromJson(response);
      final index = _cachedSubscriptions.indexWhere((s) => s.id == subId);
      if (index != -1) {
        _cachedSubscriptions[index] = subscription;
      } else {
        _cachedSubscriptions.add(subscription);
      }
      _emitCurrentSubscriptions();
    } catch (e) {
      print('Error refetching subscription: $e');
    }
  }

  void _emitCurrentSubscriptions() {
    if (!_subscriptionsController.isClosed) {
      _subscriptionsController.add(List.from(_cachedSubscriptions));
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _subscriptionsController.close();
  }
}
