import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/realtime_sync.dart';
import '../models/event.dart';
import '../models/event_hive.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../services/api_client.dart';

class EventRepository {
  static const String _boxName = 'events';
  final SupabaseService _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

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
    await _fetchAndSync();

    // Now subscribe to Realtime for future updates
    await _startRealtimeSubscription();
    await _startInteractionsSubscription();

    _emitCurrentEvents();
  }

  Future<void> _fetchAndSync() async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final apiData = await _apiClient.fetchUserEvents(userId);

      _cachedEvents = apiData.map((json) => Event.fromJson(json)).toList();

      await _updateLocalCache(_cachedEvents);

      if (_cachedEvents.isNotEmpty) {
        final updatedAtTimestamps = _cachedEvents
            .map((e) => e.updatedAt)
            .whereType<DateTime>()
            .toList();

        if (updatedAtTimestamps.isNotEmpty) {
          final latestUpdate = updatedAtTimestamps.reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
          _initialSyncCompletedAt = latestUpdate.toUtc();
          _rt.setServerSyncTs(_initialSyncCompletedAt!);
        }
      }
      _emitCurrentEvents();
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  // --- Mutations ---

  Future<Event> createEvent(Map<String, dynamic> data) async {
    final newEvent = await _apiClient.createEvent(data);
    await _fetchAndSync();
    return Event.fromJson(newEvent);
  }

  Future<Event> updateEvent(int eventId, Map<String, dynamic> data) async {
    final updatedEvent = await _apiClient.updateEvent(eventId, data);
    await _fetchAndSync();
    return Event.fromJson(updatedEvent);
  }

  Future<void> deleteEvent(int eventId) async {
    await _apiClient.deleteEvent(eventId);
    // Local cache will be updated by the realtime event, or by manual removal for non-owners
    // For owners, the realtime event should be sufficient.
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
    return List<Event>.from(_cachedEvents)..sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  Event? getEventById(int id) {
    if (_box == null) return null;
    final eventHive = _box!.get(id);
    return eventHive?.toEvent();
  }

  void removeEventFromCache(int eventId) {
    print(
      '🗑️ [EventRepository] removeEventFromCache START - eventId: $eventId',
    );

    final eventBefore = _cachedEvents.where((e) => e.id == eventId).firstOrNull;
    print(
      '🗑️ [EventRepository] Event in cache: ${eventBefore != null ? '"${eventBefore.name}"' : 'NOT FOUND'}',
    );
    print('🗑️ [EventRepository] Cache size before: ${_cachedEvents.length}');

    _cachedEvents.removeWhere((e) => e.id == eventId);
    print('🗑️ [EventRepository] Cache size after: ${_cachedEvents.length}');

    _box?.delete(eventId);
    print('🗑️ [EventRepository] Deleted from Hive box');

    print('🗑️ [EventRepository] Emitting updated events to stream...');
    _emitCurrentEvents();
    print(
      '✅ [EventRepository] Event manually removed and stream emitted - ID $eventId',
    );
  }

  Future<void> _startRealtimeSubscription() async {
    _realtimeChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'events',
      onChange: _handleRealtimeEvent,
    );

    print('✅ Realtime subscription started for events table');
  }

  Future<void> _startInteractionsSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _interactionsChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'event_interactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId.toString(),
      ),
      onChange: _handleInteractionChange,
    );

    print('✅ Realtime subscription started for event_interactions table');
  }

  bool _shouldProcessEvent(PostgresChangePayload payload, String eventType) {
    print('🔍 [FILTER] Checking $eventType event (type=${payload.eventType})');

    if (payload.eventType == PostgresChangeEvent.delete) {
      print(
        '✅ [FILTER] DELETE event - processing immediately (skip timestamp check)',
      );
      return _rt.shouldProcessDelete();
    }

    final ct = DateTime.tryParse(payload.commitTimestamp.toString());
    final ok = _rt.shouldProcessInsertOrUpdate(ct);
    if (!ok) {
      print(
        '🚫 [FILTER] Ignoring historical $eventType by commit_timestamp gate',
      );
    }
    return ok;
  }

  void _handleInteractionChange(PostgresChangePayload payload) {
    print('📡 [INTERACTION] Realtime event received: ${payload.eventType}');

    if (!_shouldProcessEvent(payload, 'interaction')) {
      print('🚫 [INTERACTION] Event filtered out as historical');
      return; // Ignore historical event
    }

    print('✅ [INTERACTION] Event passed filter, processing...');

    try {
      final eventId =
          payload.newRecord['event_id'] as int? ??
          payload.oldRecord['event_id'] as int?;
      final userId = ConfigService.instance.currentUserId;

      if (eventId != null) {
        final index = _cachedEvents.indexWhere((e) => e.id == eventId);

        if (payload.eventType == PostgresChangeEvent.delete) {
          final deletedUserId = payload.oldRecord['user_id'] as int?;
          if (deletedUserId == userId && index != -1) {
            final event = _cachedEvents[index];
            if (event.ownerId != userId) {
              _cachedEvents.removeAt(index);
              _box?.delete(eventId);
              _emitCurrentEvents();
            }
          }
          return;
        }

        if (index != -1) {
          final currentEvent = _cachedEvents[index];
          if (payload.newRecord['user_id'] == userId) {
            final updatedInteractionData = Map<String, dynamic>.from(
              currentEvent.interactionData ?? {},
            );
            updatedInteractionData['status'] = payload.newRecord['status'];
            updatedInteractionData['interaction_type'] =
                payload.newRecord['interaction_type'];
            _cachedEvents[index] = currentEvent.copyWith(interactionData: updatedInteractionData);
            _emitCurrentEvents();
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
      final eventData = await _apiClient.fetchEvent(eventId);
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
    } catch (e) {
      print('❌ Error refreshing event $eventId: $e');
    }
  }

  void _handleRealtimeEvent(PostgresChangePayload payload) {
    if (!_shouldProcessEvent(payload, 'event')) {
      return; // Ignore historical event
    }

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
  }

  void _handleDelete(Map<String, dynamic> record) {
    final id = record['id'] as int;
    _cachedEvents.removeWhere((e) => e.id == id);
    _box?.delete(id);
    _emitCurrentEvents();
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
