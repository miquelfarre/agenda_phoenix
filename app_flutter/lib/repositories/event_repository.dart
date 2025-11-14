import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/realtime_sync.dart';
import '../models/domain/event.dart';
import '../models/persistence/event_hive.dart';
import '../models/domain/event_interaction.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../services/api_client.dart';
import '../utils/app_exceptions.dart' as exceptions;
import '../utils/realtime_filter.dart';
import 'contracts/event_repository_contract.dart';

class EventRepository implements IEventRepository {
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

  @override
  Future<void> get initialized => _initCompleter.future;

  @override
  Stream<List<Event>> get dataStream => eventsStream;

  @override
  Stream<List<Event>> get eventsStream async* {
    // Emit cached events immediately for new subscribers
    if (_cachedEvents.isNotEmpty) {
      yield List.from(_cachedEvents);
    }
    // Then listen for future updates
    yield* _eventsStreamController.stream;
  }

  @override
  Stream<List<EventInteraction>> get interactionsStream async* {
    final interactions = _extractInteractionsFromEvents();
    if (interactions.isNotEmpty) {
      yield interactions;
    }
    yield* _interactionsStreamController.stream;
  }

  @override
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

  @override
  Future<Event> createEvent(Map<String, dynamic> data) async {
    final newEvent = await _apiClient.createEvent(data);
    await _fetchAndSync();
    return Event.fromJson(newEvent);
  }

  @override
  Future<Event> updateEvent(int eventId, Map<String, dynamic> data) async {
    final updatedEvent = await _apiClient.updateEvent(eventId, data);
    await _fetchAndSync();
    return Event.fromJson(updatedEvent);
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    await _apiClient.deleteEvent(eventId);
    await _fetchAndSync();
  }

  @override
  Future<void> leaveEvent(int eventId) async {
    try {
      await _apiClient.delete('/events/$eventId/interaction');
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  // --- Event Interaction Methods ---

  @override
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
      if (decisionMessage != null) {
        updateData['cancellation_note'] = decisionMessage;
      }
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

  @override
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
      await _apiClient.patchInteraction(interaction.id!, {
        'read_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _fetchAndSync();
      _emitInteractions();
    } catch (e, _) {
      rethrow;
    }
  }

  @override
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

  @override
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

  Future<List<Map<String, dynamic>>> fetchEventInteractions(int eventId) async {
    try {
      return await _apiClient.fetchInteractions(eventId: eventId, enriched: true);
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> updateParticipantRole(int interactionId, String role) async {
    try {
      await _apiClient.patchInteraction(interactionId, {'role': role});
      await _fetchAndSync();
      _emitInteractions();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> deleteInteraction(int interactionId) async {
    try {
      await _apiClient.deleteInteraction(interactionId);
      await _fetchAndSync();
      _emitInteractions();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addParticipantsBulk({
    required int eventId,
    List<int> userIds = const [],
    List<int> groupIds = const [],
    String role = 'attendee',
  }) async {
    try {
      final result = await _apiClient.addEventParticipantsBulk(
        eventId: eventId,
        userIds: userIds,
        groupIds: groupIds,
        role: role,
      );
      await _fetchAndSync();
      _emitInteractions();
      return result;
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

  @override
  List<Event> getLocalEvents() {
    return List<Event>.from(_cachedEvents)..sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  @override
  Event? getEventById(int id) {
    if (_box == null) return null;
    final eventHive = _box!.get(id);
    return eventHive?.toEvent();
  }

  // --- IRealtimeRepository Implementation ---

  @override
  Future<void> startRealtimeSubscription() async {
    await _startRealtimeSubscription();
  }

  @override
  Future<void> stopRealtimeSubscription() async {
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  @override
  bool get isRealtimeConnected => _realtimeChannel != null;

  @override
  Future<void> loadFromCache() async {
    _loadEventsFromHive();
  }

  @override
  Future<void> saveToCache() async {
    await _updateLocalCache(_cachedEvents);
  }

  @override
  Future<void> clearCache() async {
    _cachedEvents = [];
    await _box?.clear();
    _emitCurrentEvents();
  }

  @override
  Future<void> refresh() async {
    await _fetchAndSync();
  }

  @override
  List<Event> getLocalData() => getLocalEvents();

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
            // Update only interaction data without refetching everything
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

            _cachedEvents[index] = Event(
              id: currentEvent.id,
              name: currentEvent.name,
              description: currentEvent.description,
              startDate: currentEvent.startDate,
              timezone: currentEvent.timezone,
              eventType: currentEvent.eventType,
              ownerId: currentEvent.ownerId,
              owner: currentEvent.owner,
              members: currentEvent.members,
              admins: currentEvent.admins,
              calendarId: currentEvent.calendarId,
              parentRecurringEventId: currentEvent.parentRecurringEventId,
              recurrenceEndDate: currentEvent.recurrenceEndDate,
              createdAt: currentEvent.createdAt,
              updatedAt: currentEvent.updatedAt,
              calendarName: currentEvent.calendarName,
              calendarColor: currentEvent.calendarColor,
              isBirthdayEvent: currentEvent.isBirthdayEvent,
              attendeesList: currentEvent.attendeesList,
              interactionData: updatedInteractionData,
              personalNote: currentEvent.personalNote,
              clientTempId: currentEvent.clientTempId,
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
  @override
  Future<Event> fetchEventDetails(int eventId) async {
    final data = await _apiClient.fetchEvent(eventId);
    return Event.fromJson(data);
  }

  /// Fetch events for a specific user (used for event series / user's events list)
  @override
  Future<List<Event>> fetchUserEvents(int userId) async {
    final response = await _apiClient.get('/users/$userId/events');
    final List<dynamic> eventsData = response['data'] ?? response;
    return eventsData.map((data) => Event.fromJson(data)).toList();
  }

  /// Update personal note for an event
  @override
  Future<void> updatePersonalNote(int eventId, String? note) async {
    // Get the event to find the interaction ID
    final event = _cachedEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw exceptions.ApiException('Event not found in cache'),
    );

    // Get the current user's interaction ID from the event
    final interactionId = event.interactionData?['id'] as int?;
    if (interactionId == null) {
      throw exceptions.ApiException('No interaction found for this event');
    }

    // Update the interaction using the correct endpoint
    await _apiClient.patchInteraction(interactionId, {'personal_note': note});

    // After updating, refresh the local cache
    await _fetchAndSync();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _interactionsChannel?.unsubscribe();
    _eventsStreamController.close();
    _interactionsStreamController.close();
    _box?.close();
  }
}
