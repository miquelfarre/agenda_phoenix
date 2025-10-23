import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../models/event_hive.dart';
import '../services/supabase_service.dart';

class EventRepository {
  static const String _boxName = 'events';
  final SupabaseService _supabaseService = SupabaseService.instance;

  Box<EventHive>? _box;
  RealtimeChannel? _realtimeChannel;
  final StreamController<List<Event>> _eventsStreamController =
      StreamController<List<Event>>.broadcast();

  Stream<List<Event>> get eventsStream => _eventsStreamController.stream;

  Future<void> initialize() async {
    _box = await Hive.openBox<EventHive>(_boxName);

    await _startRealtimeSubscription();

    _emitCurrentEvents();
  }

  List<Event> getLocalEvents() {
    if (_box == null) {
      throw Exception('EventRepository not initialized');
    }
    return _box!.values.map((eventHive) => eventHive.toEvent()).toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
  }

  Future<List<Event>> fetchAndSyncEvents() async {
    try {
      final response = await _supabaseService.events.select().order(
        'created_at',
        ascending: false,
      );

      final events = (response as List)
          .map((json) => Event.fromJson(json))
          .toList();

      await _updateLocalCache(events);

      _emitCurrentEvents();

      return events;
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
    final eventHive = EventHive.fromEvent(event);
    _box?.put(event.id, eventHive);
    _emitCurrentEvents();
    print('✅ Event inserted: ${event.name}');
  }

  void _handleUpdate(Map<String, dynamic> record) {
    final event = Event.fromJson(record);
    final eventHive = EventHive.fromEvent(event);
    _box?.put(event.id, eventHive);
    _emitCurrentEvents();
    print('✅ Event updated: ${event.name}');
  }

  void _handleDelete(Map<String, dynamic> record) {
    final id = record['id'] as int;
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
    await _eventsStreamController.close();
    await _box?.close();
  }
}
