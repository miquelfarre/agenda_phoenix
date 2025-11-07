import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import '../models/calendar.dart';
import '../models/calendar_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';
import '../utils/app_exceptions.dart' as exceptions;
import '../utils/realtime_filter.dart';

class CalendarRepository {
  static const String _boxName = 'calendars';
  final _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<CalendarHive>? _box;
  final StreamController<List<Calendar>> _calendarsController = StreamController<List<Calendar>>.broadcast();
  List<Calendar> _cachedCalendars = [];
  RealtimeChannel? _membershipChannel;
  RealtimeChannel? _calendarsChannel;

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  Stream<List<Calendar>> get calendarsStream async* {
    if (_cachedCalendars.isNotEmpty) {
      yield List.from(_cachedCalendars);
    }
    yield* _calendarsController.stream;
  }

  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      print('📦 CalendarRepository: Starting initialization...');

      try {
        _box = await Hive.openBox<CalendarHive>(_boxName);
        print('✅ CalendarRepository: Hive box opened');
      } catch (e) {
        // If there's a schema error, delete the corrupted box and try again
        if (e.toString().contains('is not a subtype of type')) {
          print('⚠️  CalendarRepository: Detected schema incompatibility, clearing Hive box...');

          // Try to close the box if it's open
          try {
            if (Hive.isBoxOpen(_boxName)) {
              await Hive.box(_boxName).close();
              print('📪 CalendarRepository: Closed existing box');
            }
          } catch (_) {
            // Ignore close errors
          }

          // Delete and recreate
          try {
            await Hive.deleteBoxFromDisk(_boxName);
            print('🗑️  CalendarRepository: Old box deleted');
          } catch (deleteError) {
            print('⚠️  CalendarRepository: Could not delete box: $deleteError');
            // Continue anyway, box might not exist
          }

          _box = await Hive.openBox<CalendarHive>(_boxName);
          print('✅ CalendarRepository: New Hive box opened');
        } else {
          rethrow;
        }
      }

      // Load calendars from Hive cache first (if any)
      _loadCalendarsFromHive();
      print('✅ CalendarRepository: Loaded ${_cachedCalendars.length} calendars from Hive');

      // Fetch and sync calendars from API BEFORE subscribing to Realtime
      print('🌐 CalendarRepository: Fetching from API...');
      await _fetchAndSync();
      print('✅ CalendarRepository: API fetch complete, ${_cachedCalendars.length} calendars');

      // Now subscribe to Realtime for future updates
      print('🔄 CalendarRepository: Starting realtime subscription...');
      await _startRealtimeSubscription();
      print('✅ CalendarRepository: Realtime subscription active');

      _emitCurrentCalendars();

      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      print('✅ CalendarRepository: Initialization complete');
    } catch (e, stackTrace) {
      print('❌ CalendarRepository: Error during initialization: $e');
      print('Stack trace: $stackTrace');
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    }
  }

  void _loadCalendarsFromHive() {
    if (_box == null) return;

    try {
      print('📂 CalendarRepository: Loading from Hive, found ${_box!.length} items');
      _cachedCalendars = _box!.values.map((calendarHive) => calendarHive.toCalendar()).toList();
      print('✅ CalendarRepository: Successfully converted ${_cachedCalendars.length} calendars from Hive');
    } catch (e, stackTrace) {
      print('❌ CalendarRepository: Error loading from Hive: $e');
      print('Stack trace: $stackTrace');
      _cachedCalendars = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      print('🌐 CalendarRepository: Calling API fetchCalendars()...');
      final response = await _apiClient.fetchCalendars();
      print('✅ CalendarRepository: API returned ${response.length} calendars');

      print('🔄 CalendarRepository: Converting from JSON...');
      _cachedCalendars = response.map((data) => Calendar.fromJson(data)).toList();
      print('✅ CalendarRepository: Converted ${_cachedCalendars.length} calendars');

      print('💾 CalendarRepository: Updating local cache...');
      await _updateLocalCache(_cachedCalendars);
      print('✅ CalendarRepository: Local cache updated');

      // Set sync timestamp from latest updated_at
      if (_cachedCalendars.isNotEmpty) {
        final updatedAtTimestamps = _cachedCalendars.map((c) => c.updatedAt).toList();
        if (updatedAtTimestamps.isNotEmpty) {
          final latestUpdate = updatedAtTimestamps.reduce((a, b) => a.isAfter(b) ? a : b);
          _rt.setServerSyncTs(latestUpdate.toUtc());
        }
      }

      _emitCurrentCalendars();
    } catch (e, stackTrace) {
      print('❌ CalendarRepository: Error in _fetchAndSync: $e');
      print('Stack trace: $stackTrace');
      // Intentionally ignore realtime errors but log them
    }
  }

  Future<void> _updateLocalCache(List<Calendar> calendars) async {
    if (_box == null) return;

    await _box!.clear();

    for (final calendar in calendars) {
      final calendarHive = CalendarHive.fromCalendar(calendar);
      await _box!.put(calendar.id, calendarHive);
    }
  }

  // --- Mutations ---

  Future<Calendar> createCalendar({required String name, String? description, bool isPublic = false}) async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final newCalendar = await _apiClient.createCalendar({'name': name, 'description': description, 'is_public': isPublic, 'owner_id': userId});
      await _fetchAndSync();
      return Calendar.fromJson(newCalendar);
    } catch (e, _) {
      rethrow;
    }
  }

  Future<Calendar> updateCalendar(int calendarId, Map<String, dynamic> data) async {
    try {
      final updatedCalendar = await _apiClient.updateCalendar(calendarId, data);
      await _fetchAndSync();
      return Calendar.fromJson(updatedCalendar);
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> deleteCalendar(int calendarId, {bool deleteAssociatedEvents = false}) async {
    try {
      _cachedCalendars.firstWhere((c) => c.id == calendarId, orElse: () => throw exceptions.NotFoundException(message: 'Calendar not found in cache'));


      await _apiClient.deleteCalendar(calendarId, deleteEvents: deleteAssociatedEvents);
      await _fetchAndSync();

    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> subscribeToCalendar(int calendarId) async {
    try {
      await _apiClient.addCalendarMembership(calendarId, {}); // Body might need user id, check API
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> unsubscribeFromCalendar(int calendarId) async {
    try {
      final memberships = await _apiClient.fetchCalendarMemberships(calendarId);
      if (memberships.isEmpty) {
        return;
      }
      final membershipId = memberships[0]['id'];
      await _apiClient.deleteCalendarMembership(membershipId);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<List<Calendar>> fetchPublicCalendars({String? search}) async {
    try {
      final queryParams = <String, String>{'is_public': 'true'};
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.get('/calendars', queryParams: queryParams);

      final calendars = <Calendar>[];
      for (final item in response as List) {
        calendars.add(Calendar.fromJson(item));
      }
      return calendars;
    } catch (e, _) {
      rethrow;
    }
  }

  Future<Calendar?> searchByShareHash(String shareHash) async {
    try {
      final result = await _apiClient.searchCalendarByHash(shareHash);

      if (result != null) {
        final calendar = Calendar.fromJson(result);
        return calendar;
      }

      return null;
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> subscribeByShareHash(String shareHash) async {
    try {
      await _apiClient.subscribeByShareHash(shareHash);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> unsubscribeByShareHash(String shareHash) async {
    try {
      await _apiClient.unsubscribeByShareHash(shareHash);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCalendarMemberships(int calendarId) async {
    try {
      final memberships = await _apiClient.fetchCalendarMemberships(calendarId);
      return memberships;
    } catch (e, _) {
      rethrow;
    }
  }

  // --- Realtime ---

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;

    // Listen to calendar_memberships changes (when user subscribes/unsubscribes)
    _membershipChannel = _supabaseService.client
        .channel('calendar_memberships_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calendar_memberships',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId.toString()),
          callback: (payload) {
            if (!RealtimeFilter.shouldProcessEvent(payload, 'calendar_membership', _rt)) return;
            _fetchAndSync();
          },
        )
        .subscribe();

    // Listen to calendars table changes (when calendar properties change)
    _calendarsChannel = _supabaseService.client
        .channel('calendars_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calendars',
          callback: (payload) {
            if (!RealtimeFilter.shouldProcessEvent(payload, 'calendar', _rt)) return;
            _fetchAndSync();
          },
        )
        .subscribe();

  }

  void _emitCurrentCalendars() {
    if (!_calendarsController.isClosed) {
      _calendarsController.add(List.from(_cachedCalendars));
    }
  }

  Calendar? getCalendarById(int calendarId) {
    return _cachedCalendars.firstWhereOrNull((c) => c.id == calendarId);
  }

  void dispose() {
    _membershipChannel?.unsubscribe();
    _calendarsChannel?.unsubscribe();
    _calendarsController.close();
    _box?.close();
  }
}
