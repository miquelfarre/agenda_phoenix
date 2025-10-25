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
  DateTime? _initialSyncCompletedAt;

  Stream<List<Event>> get eventsStream => _eventsStreamController.stream;

  Future<void> initialize() async {
    _box = await Hive.openBox<EventHive>(_boxName);

    // Load events from Hive cache first (if any)
    _loadEventsFromHive();

    // Fetch and sync events from API BEFORE subscribing to Realtime
    // fetchAndSyncEvents() will set _initialSyncCompletedAt using server timestamps
    await fetchAndSyncEvents();

    // Now subscribe to Realtime for future updates
    // Historical events will be filtered using timestamp comparison
    await _startRealtimeSubscription();
    await _startInteractionsSubscription();

    _emitCurrentEvents();
  }

  void _loadEventsFromHive() {
    if (_box == null) return;

    try {
      _cachedEvents = _box!.values
          .map((eventHive) => eventHive.toEvent())
          .toList();

      print('✅ Loaded ${_cachedEvents.length} events from Hive cache');
    } catch (e) {
      print('❌ Error loading events from Hive: $e');
      _cachedEvents = [];
    }
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

      // Extract the most recent updated_at timestamp from server data
      // This ensures we use server time, not client time
      if (_cachedEvents.isNotEmpty) {
        final updatedAtTimestamps = _cachedEvents
            .map((e) => e.updatedAt)
            .whereType<DateTime>()
            .toList();

        if (updatedAtTimestamps.isNotEmpty) {
          // Find the most recent timestamp
          final latestUpdate = updatedAtTimestamps.reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
          _initialSyncCompletedAt = latestUpdate.toUtc();
          print('✅ Sync timestamp set to: ${_initialSyncCompletedAt!.toIso8601String()} (server time)');
        } else {
          // Fallback to client time if no timestamps available
          _initialSyncCompletedAt = DateTime.now().toUtc();
          print('⚠️ No event timestamps found, using client time');
        }
      } else {
        _initialSyncCompletedAt = DateTime.now().toUtc();
        print('ℹ️ No events cached, using client time');
      }

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

  /// Manually remove an event from cache
  /// Used when realtime DELETE events don't work properly
  void removeEventFromCache(int eventId) {
    print('🗑️ [EventRepository] removeEventFromCache START - eventId: $eventId');

    final eventBefore = _cachedEvents.where((e) => e.id == eventId).firstOrNull;
    print('🗑️ [EventRepository] Event in cache: ${eventBefore != null ? '"${eventBefore.name}"' : 'NOT FOUND'}');
    print('🗑️ [EventRepository] Cache size before: ${_cachedEvents.length}');

    _cachedEvents.removeWhere((e) => e.id == eventId);
    print('🗑️ [EventRepository] Cache size after: ${_cachedEvents.length}');

    _box?.delete(eventId);
    print('🗑️ [EventRepository] Deleted from Hive box');

    print('🗑️ [EventRepository] Emitting updated events to stream...');
    _emitCurrentEvents();
    print('✅ [EventRepository] Event manually removed and stream emitted - ID $eventId');
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

  /// Check if a Realtime event should be processed or ignored
  /// Returns true if the event is NEW (after sync), false if HISTORICAL (before sync)
  bool _shouldProcessEvent(PostgresChangePayload payload, String eventType) {
    print('🔍 [FILTER] Checking $eventType event (type=${payload.eventType})');

    // DELETE events should ALWAYS be processed, regardless of timestamp
    // because they are current actions, not historical data
    if (payload.eventType == PostgresChangeEvent.delete) {
      print('✅ [FILTER] DELETE event - processing immediately (skip timestamp check)');
      return true;
    }

    // Try to extract updated_at from newRecord or oldRecord
    final updatedAtStr = payload.newRecord['updated_at'] as String? ??
                         payload.oldRecord['updated_at'] as String?;

    print('🔍 [FILTER] updated_at from payload: $updatedAtStr');

    if (updatedAtStr == null) {
      print('⚠️ [FILTER] $eventType has no updated_at - processing by default');
      return true; // Better to process than to ignore if we can't determine
    }

    try {
      final eventUpdatedAt = DateTime.parse(updatedAtStr).toUtc();
      print('🔍 [FILTER] Parsed updated_at: ${eventUpdatedAt.toIso8601String()}');

      if (_initialSyncCompletedAt == null) {
        print('⚠️ [FILTER] No sync timestamp set - processing $eventType by default');
        return true; // No reference point, process everything
      }

      print('🔍 [FILTER] Sync timestamp: ${_initialSyncCompletedAt!.toIso8601String()}');

      // Add 1 second margin to avoid race conditions
      // (events updated exactly at sync time should be processed)
      final syncWithMargin = _initialSyncCompletedAt!.subtract(
        const Duration(seconds: 1),
      );

      print('🔍 [FILTER] Sync with margin: ${syncWithMargin.toIso8601String()}');
      print('🔍 [FILTER] Is before margin? ${eventUpdatedAt.isBefore(syncWithMargin)}');

      if (eventUpdatedAt.isBefore(syncWithMargin)) {
        print(
          '🚫 [FILTER] Ignoring historical $eventType: '
          'event=${eventUpdatedAt.toIso8601String()}, '
          'sync=${syncWithMargin.toIso8601String()}',
        );
        return false; // Historical event, ignore
      }

      print(
        '✅ [FILTER] Processing new $eventType: '
        'event=${eventUpdatedAt.toIso8601String()}, '
        'sync=${syncWithMargin.toIso8601String()}',
      );
      return true; // New event, process

    } catch (e) {
      print('❌ [FILTER] Error parsing timestamp for $eventType: $e');
      return true; // In case of error, process by default
    }
  }

  void _handleInteractionChange(PostgresChangePayload payload) {
    print('📡 [INTERACTION] Realtime event received: ${payload.eventType}');
    print('📡 [INTERACTION] Event ID: ${payload.newRecord['event_id'] ?? payload.oldRecord['event_id']}');
    print('📡 [INTERACTION] User ID: ${payload.newRecord['user_id'] ?? payload.oldRecord['user_id']}');
    print('📡 [INTERACTION] Current user: ${ConfigService.instance.currentUserId}');

    // Filter historical events using timestamp comparison
    if (!_shouldProcessEvent(payload, 'interaction')) {
      print('🚫 [INTERACTION] Event filtered out as historical');
      return; // Ignore historical event
    }

    print('✅ [INTERACTION] Event passed filter, processing...');

    try {
      final eventId = payload.newRecord['event_id'] as int? ??
          payload.oldRecord['event_id'] as int?;
      final userId = ConfigService.instance.currentUserId;

      print('🔍 [INTERACTION] Processing event_id=$eventId for user=$userId');

      if (eventId != null) {
        final index = _cachedEvents.indexWhere((e) => e.id == eventId);
        print('🔍 [INTERACTION] Event in cache: ${index != -1} (index=$index)');

        // Handle DELETE events - when user leaves an event
        if (payload.eventType == PostgresChangeEvent.delete) {
          print('🗑️ [INTERACTION] Handling DELETE event');
          final deletedUserId = payload.oldRecord['user_id'] as int?;
          print('🗑️ [INTERACTION] Deleted user_id=$deletedUserId, current user=$userId, match=${deletedUserId == userId}');

          if (deletedUserId == userId && index != -1) {
            final event = _cachedEvents[index];
            print('🗑️ [INTERACTION] Event found: "${event.name}", owner=${event.ownerId}, is_owner=${event.ownerId == userId}');

            // Only remove event if user is NOT the owner
            if (event.ownerId != userId) {
              print('🗑️ [INTERACTION] Removing event from cache (not owner)');
              _cachedEvents.removeAt(index);
              _box?.delete(eventId);
              _emitCurrentEvents();
              print('✅ Event removed from list (interaction deleted): ${event.name}');
            } else {
              // User is owner, just clear interaction data
              print('🗑️ [INTERACTION] Clearing interaction data (is owner)');
              final updatedEvent = Event(
                id: event.id,
                name: event.name,
                description: event.description,
                startDate: event.startDate,
                eventType: event.eventType,
                ownerId: event.ownerId,
                calendarId: event.calendarId,
                parentRecurringEventId: event.parentRecurringEventId,
                createdAt: event.createdAt,
                updatedAt: event.updatedAt,
                ownerName: event.ownerName,
                ownerProfilePicture: event.ownerProfilePicture,
                isOwnerPublic: event.isOwnerPublic,
                calendarName: event.calendarName,
                calendarColor: event.calendarColor,
                isBirthdayEvent: event.isBirthdayEvent,
                attendeesList: event.attendeesList,
                personalNote: event.personalNote,
                clientTempId: event.clientTempId,
                interactionData: null,
              );
              _cachedEvents[index] = updatedEvent;
              _emitCurrentEvents();
              print('✅ Event interaction cleared (owner deleted interaction): ${event.name}');
            }
          } else {
            print('ℹ️ [INTERACTION] Ignoring DELETE - user_match=${deletedUserId == userId}, in_cache=${index != -1}');
          }
          return;
        }

        // Handle INSERT/UPDATE events
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
          // Event not in cache, fetch it
          print('⚠️ Event $eventId not in cache, will fetch details');
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

      // Uncomment for debugging:
      // print('✅ Event refreshed (full fetch): ${event.name}');
    } catch (e) {
      print('❌ Error refreshing event $eventId: $e');
    }
  }

  void _handleRealtimeEvent(PostgresChangePayload payload) {
    // Filter historical events using timestamp comparison
    if (!_shouldProcessEvent(payload, 'event')) {
      return; // Ignore historical event
    }

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
    print('🗑️ [EventRepository] _handleDelete START - eventId: $id');

    final eventBefore = _cachedEvents.where((e) => e.id == id).firstOrNull;
    print('🗑️ [EventRepository] Event in cache before delete: ${eventBefore != null ? '"${eventBefore.name}"' : 'NOT FOUND'}');
    print('🗑️ [EventRepository] Cache size before delete: ${_cachedEvents.length}');

    _cachedEvents.removeWhere((e) => e.id == id);
    print('🗑️ [EventRepository] Cache size after removeWhere: ${_cachedEvents.length}');

    _box?.delete(id);
    print('🗑️ [EventRepository] Deleted from Hive box');

    print('🗑️ [EventRepository] Emitting updated events to stream...');
    _emitCurrentEvents();
    print('✅ [EventRepository] Event deleted and stream emitted - ID $id');
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
    print('📤 [EventRepository] _emitCurrentEvents - Emitting ${events.length} events to stream');
    print('📤 [EventRepository] Event IDs: ${events.map((e) => e.id).take(10).toList()}${events.length > 10 ? '...' : ''}');
    _eventsStreamController.add(events);
  }

  Future<void> dispose() async {
    await _realtimeChannel?.unsubscribe();
    await _interactionsChannel?.unsubscribe();
    await _eventsStreamController.close();
    await _box?.close();
  }
}
