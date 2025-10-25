import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_interaction.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';

class EventInteractionRepository {
  final _supabaseService = SupabaseService.instance;

  final StreamController<List<EventInteraction>> _interactionsController =
      StreamController<List<EventInteraction>>.broadcast();
  List<EventInteraction> _cachedInteractions = [];
  DateTime? _initialSyncTime;
  RealtimeChannel? _realtimeChannel;

  Stream<List<EventInteraction>> get interactionsStream =>
      _interactionsController.stream;

  Future<void> initialize() async {
    await _fetchAndSync();
    await _startRealtimeSubscription();
    _emitCurrentInteractions();
  }

  Future<void> _fetchAndSync() async {
    try {
      _initialSyncTime = DateTime.now().toUtc();
      final userId = ConfigService.instance.currentUserId;

      final response = await _supabaseService.client
          .from('event_interactions')
          .select('*')
          .eq('user_id', userId);

      _cachedInteractions = (response as List)
          .map((json) => EventInteraction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching interactions: $e');
    }
  }

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _realtimeChannel = _supabaseService.client
        .channel('interactions_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId.toString(),
          ),
          callback: _handleInteractionChange,
        )
        .subscribe();
  }

  void _handleInteractionChange(PostgresChangePayload payload) {
    final eventTime = DateTime.tryParse(payload.commitTimestamp.toString());
    if (eventTime != null &&
        _initialSyncTime != null &&
        eventTime.isBefore(_initialSyncTime!)) {
      return;
    }

    if (payload.eventType == PostgresChangeEvent.insert) {
      final interaction = EventInteraction.fromJson(payload.newRecord);
      _cachedInteractions.add(interaction);
      _emitCurrentInteractions();
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final updatedInteraction = EventInteraction.fromJson(payload.newRecord);
      final index = _cachedInteractions.indexWhere(
        (i) =>
            i.userId == updatedInteraction.userId &&
            i.eventId == updatedInteraction.eventId,
      );
      if (index != -1) {
        _cachedInteractions[index] = updatedInteraction;
        _emitCurrentInteractions();
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final userId = payload.oldRecord['user_id'];
      final eventId = payload.oldRecord['event_id'];
      if (userId != null && eventId != null) {
        _cachedInteractions.removeWhere(
          (i) => i.userId == userId && i.eventId == eventId,
        );
        _emitCurrentInteractions();
      }
    }
  }

  void _emitCurrentInteractions() {
    if (!_interactionsController.isClosed) {
      _interactionsController.add(List.from(_cachedInteractions));
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _interactionsController.close();
  }
}
