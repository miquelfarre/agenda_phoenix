import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../models/event_hive.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../services/api_client.dart';

class EventRepository {
  static const String _boxName = 'events';
  final SupabaseService _supabaseService = SupabaseService.instance;

  Box<EventHive>? _box;
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _interactionsChannel;
  final StreamController<List<Event>> _eventsStreamController =
      StreamController<List<Event>>.broadcast();

  List<Event> _cachedEvents = [];

  Stream<List<Event>> get eventsStream => _eventsStreamController.stream;

  Future<void> initialize() async {
    _box = await Hive.openBox<EventHive>(_boxName);

    await _startRealtimeSubscription();
    await _startInteractionsSubscription();

    _emitCurrentEvents();
  }

  List<Event> getLocalEvents() {
    return List<Event>.from(_cachedEvents)
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
  }

  Future<List<Event>> fetchAndSyncEvents() async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final apiData = await ApiClient().fetchUserEvents(userId);

      _cachedEvents =
          apiData.map((json) => Event.fromJson(json)).toList();

      await _updateLocalCache(_cachedEvents);

      _emitCurrentEvents();

      print('✅ Synced ${_cachedEvents.length} events from API');

      return _cachedEvents;
    } catch (e) {
      print('Error fetching events: $e');

      return getLocalEvents();
    }
  }

  Event? getEventById(int id) {
    if (_box == null) return null;
    final eventHive = _box!.get(id);
    return eventHive?.toEvent();
  }

  Future<void> _startRealtimeSubscription() async {
    _realtimeChannel = _supabaseService.realtimeChannel('events_channel');

    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: _handleRealtimeEvent,
        )
        .subscribe();

    print('✅ Realtime subscription started for events table');
  }

  Future<void> _startInteractionsSubscription() async {
    _interactionsChannel =
        _supabaseService.realtimeChannel('interactions_channel');

    _interactionsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_interactions',
          callback: _handleInteractionChange,
        )
        .subscribe();

    print('✅ Realtime subscription started for event_interactions table');
  }

  void _handleInteractionChange(PostgresChangePayload payload) {
    print(
      '📡 Interaction change received: ${payload.eventType}',
    );

    try {
      final eventId = payload.newRecord['event_id'] as int? ??
          payload.oldRecord['event_id'] as int?;
      final userId = ConfigService.instance.currentUserId;

      if (eventId != null) {
        final index = _cachedEvents.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          final currentEvent = _cachedEvents[index];

          if (payload.newRecord['user_id'] == userId) {
            final updatedInteractionData = Map<String, dynamic>.from(
              currentEvent.interactionData ?? {},
            );

            updatedInteractionData['status'] = payload.newRecord['status'];
            updatedInteractionData['interaction_type'] =
                payload.newRecord['interaction_type'];
            updatedInteractionData['note'] = payload.newRecord['note'];
            updatedInteractionData['updated_at'] = payload.newRecord['updated_at'];

            final updatedEvent = Event(
              id: currentEvent.id,
              name: currentEvent.name,
              description: currentEvent.description,
              startDate: currentEvent.startDate,
              eventType: currentEvent.eventType,
              ownerId: currentEvent.ownerId,
              calendarId: currentEvent.calendarId,
              parentRecurringEventId: currentEvent.parentRecurringEventId,
              createdAt: currentEvent.createdAt,
              updatedAt: currentEvent.updatedAt,
              ownerName: currentEvent.ownerName,
              ownerProfilePicture: currentEvent.ownerProfilePicture,
              isOwnerPublic: currentEvent.isOwnerPublic,
              calendarName: currentEvent.calendarName,
              calendarColor: currentEvent.calendarColor,
              isBirthdayEvent: currentEvent.isBirthdayEvent,
              attendeesList: currentEvent.attendeesList,
              personalNote: currentEvent.personalNote,
              clientTempId: currentEvent.clientTempId,
              interactionData: updatedInteractionData,
            );

            _cachedEvents[index] = updatedEvent;
            _emitCurrentEvents();

            print('✅ Event interaction updated locally: ${currentEvent.name}');
          }
        } else {
          _refreshEventFull(eventId);
        }
      }
    } catch (e) {
      print('Error handling interaction change: $e');
    }
  }

  Future<void> _refreshEventFull(int eventId) async {
    try {
      final eventData = await ApiClient().fetchEvent(eventId);
      final event = Event.fromJson(eventData);

      final index = _cachedEvents.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _cachedEvents[index] = event;
      } else {
        _cachedEvents.add(event);
      }

      final eventHive = EventHive.fromEvent(event);
      _box?.put(event.id, eventHive);
      _emitCurrentEvents();

      print('✅ Event refreshed (full fetch): ${event.name}');
    } catch (e) {
      print('Error refreshing event $eventId: $e');
    }
  }

  void _handleRealtimeEvent(PostgresChangePayload payload) {
    print('📡 Realtime event received: ${payload.eventType}');

    try {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          _handleInsert(payload.newRecord);
          break;
        case PostgresChangeEvent.update:
          _handleUpdate(payload.newRecord);
          break;
        case PostgresChangeEvent.delete:
          _handleDelete(payload.oldRecord);
          break;
        default:
          break;
      }
    } catch (e) {
      print('Error handling realtime event: $e');
    }
  }

  void _handleInsert(Map<String, dynamic> record) {
    final event = Event.fromJson(record);
    _cachedEvents.add(event);
    final eventHive = EventHive.fromEvent(event);
    _box?.put(event.id, eventHive);
    _emitCurrentEvents();
    print('✅ Event inserted: ${event.name}');
  }

  void _handleUpdate(Map<String, dynamic> record) {
    final event = Event.fromJson(record);
    final index = _cachedEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _cachedEvents[index] = event;
    } else {
      _cachedEvents.add(event);
    }
    final eventHive = EventHive.fromEvent(event);
    _box?.put(event.id, eventHive);
    _emitCurrentEvents();
    print('✅ Event updated: ${event.name}');
  }

  void _handleDelete(Map<String, dynamic> record) {
    final id = record['id'] as int;
    _cachedEvents.removeWhere((e) => e.id == id);
    _box?.delete(id);
    _emitCurrentEvents();
    print('✅ Event deleted: ID $id');
  }

  Future<void> _updateLocalCache(List<Event> events) async {
    if (_box == null) return;

    await _box!.clear();

    for (final event in events) {
      if (event.id != null) {
        final eventHive = EventHive.fromEvent(event);
        await _box!.put(event.id, eventHive);
      }
    }

    print('✅ Local cache updated with ${events.length} events');
  }

  void _emitCurrentEvents() {
    final events = getLocalEvents();
    _eventsStreamController.add(events);
  }

  Future<void> dispose() async {
    await _realtimeChannel?.unsubscribe();
    await _interactionsChannel?.unsubscribe();
    await _eventsStreamController.close();
    await _box?.close();
  }
}
