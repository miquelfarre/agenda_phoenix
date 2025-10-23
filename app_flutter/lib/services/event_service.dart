import 'dart:async';
import 'dart:io';
import 'package:hive_ce/hive.dart';
import '../models/event.dart';
import '../models/event_hive.dart';
import '../core/monitoring/performance_monitor.dart';
import 'contracts/api_client_contract.dart';
import 'api_client.dart';
import '../utils/app_exceptions.dart' as app_exceptions;
import 'config_service.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  IApiClient get _client => ApiClient();

  String get serviceName => 'EventService';
  String get hiveBoxName => 'events';

  int get currentUserId => ConfigService.instance.currentUserId;

  Future<List<Event>> fetchEvents({int? ownerId, int? calendarId}) async {
    try {
      final apiData = await _client.fetchEvents(
        ownerId: ownerId,
        calendarId: calendarId,
        currentUserId: currentUserId,
      );

      final events = apiData.map((data) => Event.fromJson(data)).toList();

      return events;
    } catch (e) {
      rethrow;
    }
  }

  List<Event> getEventsByOwner(int ownerId) {
    try {
      final eventsBox = Hive.box<EventHive>('events');
      final events = <Event>[];

      for (final eventHive in eventsBox.values) {
        if (eventHive.ownerId == ownerId) {
          events.add(_eventHiveToEvent(eventHive));
        }
      }

      return events;
    } catch (e) {
      return [];
    }
  }

  Future<Event> createEvent({
    required String name,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    String eventType = 'regular',
    int? calendarId,
  }) async {
    try {
      final response = await _client.createEvent({
        'name': name,
        if (description != null) 'description': description,
        'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        'event_type': eventType,
        'owner_id': currentUserId,
        if (calendarId != null) 'calendar_id': calendarId,
      });

      final createdEvent = Event.fromJson(response);

      return createdEvent;
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } on app_exceptions.ValidationException {
      rethrow;
    } catch (e) {
      throw app_exceptions.ApiException('Failed to create event: $e');
    }
  }

  Future<Event> updateEvent({
    required int eventId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    int? calendarId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
      }
      if (description != null) {
        updateData['description'] = description;
      }
      if (startDate != null) {
        updateData['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        updateData['end_date'] = endDate.toIso8601String();
      }
      if (eventType != null) {
        updateData['event_type'] = eventType;
      }
      if (calendarId != null) {
        updateData['calendar_id'] = calendarId;
      }

      final response = await _client.updateEvent(eventId, updateData);

      final updatedEvent = Event.fromJson(response);

      return updatedEvent;
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } on app_exceptions.NotFoundException {
      rethrow;
    } on app_exceptions.PermissionDeniedException {
      rethrow;
    } catch (e) {
      throw app_exceptions.ApiException('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(int eventId) async {
    try {
      await _client.deleteEvent(eventId);
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } on app_exceptions.NotFoundException {
      // Event already deleted - ignore
    } catch (e) {
      throw app_exceptions.ApiException('Failed to delete event: $e');
    }
  }

  Future<List<Event>> refreshEvents() async {
    try {
      return await fetchEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Event>> getUserEvents(int userId) async {
    try {
      final apiData = await _client.fetchUserEvents(
        userId,
        currentUserId: currentUserId,
      );
      final events = apiData.map((data) => Event.fromJson(data)).toList();
      return events;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCache() async {
    return PerformanceMonitor.instance.trackPerformance(
      'EventService.clearCache',
      () async {
        try {
          final eventsBox = Hive.box<EventHive>('events');
          await eventsBox.clear();
        } catch (e) {
          rethrow;
        }
      },
    );
  }

  Future<void> clearCacheForUser(int userId) async {
    return PerformanceMonitor.instance.trackPerformance(
      'EventService.clearCacheForUser',
      () async {
        try {
          final eventsBox = Hive.box<EventHive>('events');

          final keysToDelete = <dynamic>[];
          for (final key in eventsBox.keys) {
            final eventHive = eventsBox.get(key);
            if (eventHive?.ownerId == userId) {
              keysToDelete.add(key);
            }
          }

          for (final key in keysToDelete) {
            await eventsBox.delete(key);
          }
        } catch (e) {
          rethrow;
        }
      },
      metadata: {'userId': userId},
    );
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return PerformanceMonitor.instance.trackPerformance(
      'EventService.getCacheStats',
      () async {
        try {
          final eventsBox = Hive.box<EventHive>('events');
          final totalEntries = eventsBox.length;
          final cacheSize = await getCacheSize();

          final userCounts = <int, int>{};
          for (final value in eventsBox.values) {
            userCounts[value.ownerId] = (userCounts[value.ownerId] ?? 0) + 1;
          }

          return {
            'total_entries': totalEntries,
            'cache_size_bytes': cacheSize,
            'users_with_data': userCounts.length,
            'user_counts': userCounts,
            'service_name': serviceName,
            'box_name': hiveBoxName,
          };
        } catch (e) {
          rethrow;
        }
      },
    );
  }

  Future<void> optimizeCache() async {
    return PerformanceMonitor.instance.trackPerformance(
      'EventService.optimizeCache',
      () async {
        try {
          final eventsBox = Hive.box<EventHive>('events');

          final cutoffDate = DateTime.now().subtract(Duration(days: 30));
          final keysToDelete = <dynamic>[];

          for (final key in eventsBox.keys) {
            final eventHive = eventsBox.get(key);
            if (eventHive != null && eventHive.startDate.isBefore(cutoffDate)) {
              keysToDelete.add(key);
            }
          }

          for (final key in keysToDelete) {
            await eventsBox.delete(key);
          }
        } catch (e) {
          rethrow;
        }
      },
    );
  }

  Future<bool> validateCache() async {
    return PerformanceMonitor.instance.trackPerformance(
      'EventService.validateCache',
      () async {
        try {
          final eventsBox = Hive.box<EventHive>('events');

          int invalidEntries = 0;

          for (final value in eventsBox.values) {
            try {
              if (value.id > 0 && value.name.isNotEmpty && value.ownerId > 0) {
              } else {
                invalidEntries++;
              }
            } catch (_) {
              invalidEntries++;
            }
          }

          return invalidEntries == 0;
        } catch (e) {
          return false;
        }
      },
    );
  }

  Future<int> getCacheSize() async {
    try {
      final eventsBox = Hive.box<EventHive>('events');

      final entryCount = eventsBox.length;
      const averageEntrySize = 1024;
      return entryCount * averageEntrySize;
    } catch (e) {
      return 0;
    }
  }

  Event _eventHiveToEvent(EventHive eventHive) {
    return eventHive.toEvent();
  }
}
