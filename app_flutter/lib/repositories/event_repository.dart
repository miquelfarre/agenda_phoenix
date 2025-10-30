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
      print('🚀 [EventRepository] Initializing...');
      _box = await Hive.openBox<EventHive>(_boxName);

      _loadEventsFromHive();

      await _fetchAndSync();

      await _startRealtimeSubscription();
      await _startInteractionsSubscription();

      _emitCurrentEvents();
      print('✅ [EventRepository] Initialization complete');

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
      print('📡 [EventRepository] Fetching events from API...');
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
      print('✅ [EventRepository] Fetched ${_cachedEvents.length} events');
    } catch (e) {
      print('❌ [EventRepository] Error fetching events: $e');
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
      print('👋 [EventRepository] Leaving event $eventId');
      await _apiClient.delete('/events/$eventId/interaction');
      await _fetchAndSync();
      print('✅ [EventRepository] Left event $eventId');
    } catch (e, stackTrace) {
      print('❌ [EventRepository] Error leaving event: $e');
      print('📍 [EventRepository] Stack trace: $stackTrace');
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
      print('🔄 [EventRepository] Updating participation status for event $eventId: $status');
      final currentUserId = ConfigService.instance.currentUserId;
      final interactions = _extractInteractionsFromEvents();

      print('🔍 [EventRepository] Looking for interaction - eventId: $eventId, userId: $currentUserId, total interactions: ${interactions.length}');

      final interaction = interactions.firstWhere(
        (i) => i.eventId == eventId && i.userId == currentUserId,
        orElse: () => throw exceptions.NotFoundException(message: 'Interaction not found'),
      );

      print('✅ [EventRepository] Found interaction ID: ${interaction.id}');

      final updateData = <String, dynamic>{'status': status};
      if (decisionMessage != null) updateData['rejection_message'] = decisionMessage;
      if (isAttending != null) updateData['is_attending'] = isAttending;

      print('📤 [EventRepository] Calling patchInteraction with data: $updateData');
      final updatedInteraction = await _apiClient.patchInteraction(interaction.id!, updateData);

      print('📥 [EventRepository] patchInteraction successful, syncing...');
      await _fetchAndSync();
      _emitInteractions();
      print('✅ [EventRepository] Participation status updated for event $eventId');
      return EventInteraction.fromJson(updatedInteraction);
    } catch (e, stackTrace) {
      print('❌ [EventRepository] Error updating participation status: $e');
      print('📍 [EventRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> markAsViewed(int eventId) async {
    try {
      print('👁️ [EventRepository] Marking event $eventId as viewed');
      final currentUserId = ConfigService.instance.currentUserId;
      final interactions = _extractInteractionsFromEvents();
      final interaction = interactions.firstWhere(
        (i) => i.eventId == eventId && i.userId == currentUserId,
        orElse: () => throw exceptions.NotFoundException(message: 'Interaction not found'),
      );
      await _apiClient.markInteractionRead(interaction.id!);
      await _fetchAndSync();
      _emitInteractions();
      print('✅ [EventRepository] Event $eventId marked as viewed');
    } catch (e, stackTrace) {
      print('❌ [EventRepository] Error marking event as viewed: $e');
      print('📍 [EventRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> setPersonalNote(int eventId, String note) async {
    try {
      print('📝 [EventRepository] Setting personal note for event $eventId');
      final currentUserId = ConfigService.instance.currentUserId;
      final interactions = _extractInteractionsFromEvents();
      final interaction = interactions.firstWhere(
        (i) => i.eventId == eventId && i.userId == currentUserId,
        orElse: () => throw exceptions.NotFoundException(message: 'Interaction not found'),
      );
      await _apiClient.patchInteraction(interaction.id!, {'personal_note': note});
      await _fetchAndSync();
      _emitInteractions();
      print('✅ [EventRepository] Personal note set for event $eventId');
    } catch (e, stackTrace) {
      print('❌ [EventRepository] Error setting personal note: $e');
      print('📍 [EventRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> sendInvitation(
    int eventId,
    int invitedUserId,
    String? invitationMessage,
  ) async {
    try {
      print('✉️ [EventRepository] Sending invitation to user $invitedUserId for event $eventId');
      await _apiClient.createInteraction({
        'event_id': eventId,
        'user_id': invitedUserId,
        'interaction_type': 'invited',
        'status': 'pending',
        if (invitationMessage != null) 'note': invitationMessage,
      });
      await _fetchAndSync();
      _emitInteractions();
      print('✅ [EventRepository] Invitation sent to user $invitedUserId');
    } catch (e, stackTrace) {
      print('❌ [EventRepository] Error sending invitation: $e');
      print('📍 [EventRepository] Stack trace: $stackTrace');
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
          final interactionJson = Map<String, dynamic>.from(event.interactionData!);
          interactionJson['event_id'] = event.id;
          interactionJson['user_id'] = currentUserId;

          final interaction = EventInteraction.fromJson(interactionJson);
          interactions.add(interaction);
        } catch (e) {
          print('⚠️ [EventRepository] Error parsing interaction for event ${event.id}: $e');
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
            _emitInteractions();
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
    _emitInteractions();
  }

  void dispose() {
    print('👋 [EventRepository] Disposing...');
    _realtimeChannel?.unsubscribe();
    _interactionsChannel?.unsubscribe();
    _eventsStreamController.close();
    _interactionsStreamController.close();
    _box?.close();
  }
}
