import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/realtime_sync.dart';
import '../models/event.dart';
import '../models/event_hive.dart';
import '../models/event_interaction.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../services/api_client.dart';
import '../utils/app_exceptions.dart' as exceptions;
import '../utils/realtime_filter.dart';

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
  final StreamController<List<EventInteraction>> _interactionsStreamController =
      StreamController<List<EventInteraction>>.broadcast();

  List<Event> _cachedEvents = [];
  DateTime? _initialSyncCompletedAt;

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  Stream<List<Event>> get eventsStream async* {
    // Emit cached events immediately for new subscribers
    if (_cachedEvents.isNotEmpty) {
      yield List.from(_cachedEvents);
    }
    // Then listen for future updates
    yield* _eventsStreamController.stream;
  }

  Stream<List<EventInteraction>> get interactionsStream async* {
    final interactions = _extractInteractionsFromEvents();
    if (interactions.isNotEmpty) {
      yield interactions;
    }
    yield* _interactionsStreamController.stream;
  }

  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      _box = await Hive.openBox<EventHive>(_boxName);

      _loadEventsFromHive();

      await _fetchAndSync();

      await _startRealtimeSubscription();
      await _startInteractionsSubscription();

      _emitCurrentEvents();

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
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore realtime errors
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
    await _fetchAndSync();
  }

  Future<void> leaveEvent(int eventId) async {
    try {
      await _apiClient.delete('/events/$eventId/interaction');
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  // --- Event Interaction Methods ---

  Future<EventInteraction> updateParticipationStatus(
    int eventId,
    String status, {
    String? decisionMessage,
    bool? isAttending,
  }) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      final interactions = _extractInteractionsFromEvents();

      final interaction = interactions.firstWhere(
        (i) => i.eventId == eventId && i.userId == currentUserId,
        orElse: () => throw exceptions.NotFoundException(
          message: 'Interaction not found',
        ),
      );

      final updateData = <String, dynamic>{'status': status};
      if (decisionMessage != null)
        updateData['cancellation_note'] = decisionMessage;
      if (isAttending != null) updateData['is_attending'] = isAttending;

      final updatedInteraction = await _apiClient.patchInteraction(
        interaction.id!,
        updateData,
      );

      await _fetchAndSync();
      _emitInteractions();
      return EventInteraction.fromJson(updatedInteraction);
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> markAsViewed(int eventId) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      final interactions = _extractInteractionsFromEvents();
      final interaction = interactions.firstWhere(
        (i) => i.eventId == eventId && i.userId == currentUserId,
        orElse: () => throw exceptions.NotFoundException(
          message: 'Interaction not found',
        ),
      );
      await _apiClient.markInteractionRead(interaction.id!);
      await _fetchAndSync();
      _emitInteractions();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> setPersonalNote(int eventId, String note) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      final interactions = _extractInteractionsFromEvents();
      final interaction = interactions.firstWhere(
        (i) => i.eventId == eventId && i.userId == currentUserId,
        orElse: () => throw exceptions.NotFoundException(
          message: 'Interaction not found',
        ),
      );
      await _apiClient.patchInteraction(interaction.id!, {
        'personal_note': note,
      });
      await _fetchAndSync();
      _emitInteractions();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> sendInvitation(int eventId, int invitedUserId) async {
    try {
      await _apiClient.createInteraction({
        'event_id': eventId,
        'user_id': invitedUserId,
        'interaction_type': 'invited',
        'status': 'pending',
      });
      await _fetchAndSync();
      _emitInteractions();
    } catch (e, _) {
      rethrow;
    }
  }

  // --- Helper Methods ---

  List<EventInteraction> _extractInteractionsFromEvents() {
    final interactions = <EventInteraction>[];
    final currentUserId = ConfigService.instance.currentUserId;

    for (final event in _cachedEvents) {
      if (event.id != null && event.interactionData != null) {
        try {
          final interactionJson = Map<String, dynamic>.from(
            event.interactionData!,
          );
          interactionJson['event_id'] = event.id;
          interactionJson['user_id'] = currentUserId;

          final interaction = EventInteraction.fromJson(interactionJson);
          interactions.add(interaction);
          // ignore: empty_catches
        } catch (e) {
          // Intentionally ignore malformed interaction data
        }
      }
    }

    return interactions;
  }

  void _emitInteractions() {
    if (!_interactionsStreamController.isClosed) {
      final interactions = _extractInteractionsFromEvents();
      _interactionsStreamController.add(interactions);
    }
  }

  void _loadEventsFromHive() {
    if (_box == null) return;

    try {
      _cachedEvents = _box!.values
          .map((eventHive) => eventHive.toEvent())
          .toList();
    } catch (e) {
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

  Future<void> _startRealtimeSubscription() async {
    _realtimeChannel = RealtimeUtils.subscribeTable(
      client: _supabaseService.client,
      schema: 'public',
      table: 'events',
      onChange: _handleRealtimeEvent,
    );
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
  }

  bool _shouldProcessEvent(PostgresChangePayload payload, String eventType) {
    return RealtimeFilter.shouldProcessEvent(payload, eventType, _rt);
  }

  void _handleInteractionChange(PostgresChangePayload payload) {
    if (!_shouldProcessEvent(payload, 'interaction')) {
      return; // Ignore historical event
    }

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
            updatedInteractionData['is_attending'] =
                payload.newRecord['is_attending'];
            updatedInteractionData['role'] = payload.newRecord['role'];
            updatedInteractionData['note'] = payload.newRecord['note'];
            updatedInteractionData['read_at'] = payload.newRecord['read_at'];

            _cachedEvents[index] = currentEvent.copyWith(
              interactionData: updatedInteractionData,
            );

            _emitCurrentEvents();
            _emitInteractions();
          }
        } else {
          _refreshEventFull(eventId);
        }
      }
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore realtime handler errors
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
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore cache update errors
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
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore realtime event handler errors
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
    _emitInteractions();
  }

  /// Fetch detailed event information by ID
  Future<Event> fetchEventDetails(int eventId) async {
    final data = await _apiClient.fetchEvent(eventId);
    return Event.fromJson(data);
  }

  /// Fetch events for a specific user (used for event series / user's events list)
  Future<List<Event>> fetchUserEvents(int userId) async {
    final response = await _apiClient.get('/users/$userId/events');
    final List<dynamic> eventsData = response['data'] ?? response;
    return eventsData.map((data) => Event.fromJson(data)).toList();
  }

  /// Update personal note for an event
  Future<void> updatePersonalNote(int eventId, String? note) async {
    await _apiClient.patch(
      '/api/v1/events/$eventId/interaction',
      body: {'note': note},
    );
    // After updating, refresh the local cache
    await _fetchAndSync();
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _interactionsChannel?.unsubscribe();
    _eventsStreamController.close();
    _interactionsStreamController.close();
    _box?.close();
  }
}
