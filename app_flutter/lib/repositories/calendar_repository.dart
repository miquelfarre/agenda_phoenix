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

class CalendarRepository {
  static const String _boxName = 'calendars';
  final _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<CalendarHive>? _box;
  final StreamController<List<Calendar>> _calendarsController = StreamController<List<Calendar>>.broadcast();
  List<Calendar> _cachedCalendars = [];
  RealtimeChannel? _realtimeChannel;

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
      print('🚀 [CalendarRepository] Initializing...');
      _box = await Hive.openBox<CalendarHive>(_boxName);

      // Load calendars from Hive cache first (if any)
      _loadCalendarsFromHive();

      // Fetch and sync calendars from API BEFORE subscribing to Realtime
      await _fetchAndSync();

      // Now subscribe to Realtime for future updates
      await _startRealtimeSubscription();

      _emitCurrentCalendars();
      print('✅ [CalendarRepository] Initialization complete');

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

  void _loadCalendarsFromHive() {
    if (_box == null) return;

    try {
      _cachedCalendars = _box!.values.map((calendarHive) => calendarHive.toCalendar()).toList();

      print('✅ [CalendarRepository] Loaded ${_cachedCalendars.length} calendars from Hive cache');
    } catch (e) {
      print('❌ [CalendarRepository] Error loading from Hive: $e');
      _cachedCalendars = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      print('📡 [CalendarRepository] Fetching calendars from API...');
      final response = await _apiClient.fetchCalendars();
      _cachedCalendars = response.map((data) => Calendar.fromJson(data)).toList();

      await _updateLocalCache(_cachedCalendars);

      _rt.setServerSyncTsFromResponse(rows: _cachedCalendars.map((c) => c.toJson()));
      _emitCurrentCalendars();
      print('✅ [CalendarRepository] Fetched ${_cachedCalendars.length} calendars');
    } catch (e) {
      print('❌ [CalendarRepository] Error fetching calendars: $e');
    }
  }

  Future<void> _updateLocalCache(List<Calendar> calendars) async {
    if (_box == null) return;

    print('💾 [CalendarRepository] Updating Hive cache with ${calendars.length} calendars...');
    await _box!.clear();

    for (final calendar in calendars) {
      final calendarHive = CalendarHive.fromCalendar(calendar);
      await _box!.put(calendar.id, calendarHive);
    }
    print('✅ [CalendarRepository] Hive cache updated');
  }

  // --- Mutations ---

  Future<Calendar> createCalendar({required String name, String? description, String color = '#2196F3', bool isPublic = false}) async {
    try {
      print('➕ [CalendarRepository] Creating calendar: "$name"');
      final userId = ConfigService.instance.currentUserId;
      final newCalendar = await _apiClient.createCalendar({'name': name, 'description': description, 'color': color, 'is_public': isPublic, 'owner_id': userId});
      await _fetchAndSync();
      print('✅ [CalendarRepository] Calendar created: "${newCalendar['name']}"');
      return Calendar.fromJson(newCalendar);
    } catch (e, stackTrace) {
      print('❌ [CalendarRepository] Error creating calendar: $e');
      print('📍 [CalendarRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Calendar> updateCalendar(int calendarId, Map<String, dynamic> data) async {
    try {
      print('🔄 [CalendarRepository] Updating calendar ID $calendarId');
      final updatedCalendar = await _apiClient.updateCalendar(calendarId, data);
      await _fetchAndSync();
      print('✅ [CalendarRepository] Calendar updated: ID $calendarId');
      return Calendar.fromJson(updatedCalendar);
    } catch (e, stackTrace) {
      print('❌ [CalendarRepository] Error updating calendar: $e');
      print('📍 [CalendarRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteCalendar(int calendarId) async {
    try {
      print('🗑️ [CalendarRepository] deleteCalendar START - calendarId: $calendarId');
      final calendar = _cachedCalendars.firstWhere((c) => c.id == calendarId.toString(), orElse: () => throw exceptions.NotFoundException(message: 'Calendar not found in cache'));

      if (calendar.isDefault) {
        print('❌ [CalendarRepository] Cannot delete default calendar');
        throw exceptions.ValidationException(message: 'Cannot delete default calendar');
      }

      print('🗑️ [CalendarRepository] Calendar in cache: "${calendar.name}"');
      print('🗑️ [CalendarRepository] Cache size before: ${_cachedCalendars.length}');

      await _apiClient.deleteCalendar(calendarId);
      await _fetchAndSync();

      print('🗑️ [CalendarRepository] Cache size after: ${_cachedCalendars.length}');
      print('✅ [CalendarRepository] Calendar deleted: ID $calendarId');
    } catch (e, stackTrace) {
      print('❌ [CalendarRepository] Error deleting calendar: $e');
      print('📍 [CalendarRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> subscribeToCalendar(int calendarId) async {
    try {
      print('➕ [CalendarRepository] Subscribing to calendar ID $calendarId');
      await _apiClient.addCalendarMembership(calendarId, {}); // Body might need user id, check API
      await _fetchAndSync();
      print('✅ [CalendarRepository] Subscribed to calendar ID $calendarId');
    } catch (e, stackTrace) {
      print('❌ [CalendarRepository] Error subscribing to calendar: $e');
      print('📍 [CalendarRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> unsubscribeFromCalendar(int calendarId) async {
    try {
      print('🗑️ [CalendarRepository] Unsubscribing from calendar ID $calendarId');
      final memberships = await _apiClient.fetchCalendarMemberships(calendarId);
      if (memberships.isEmpty) {
        print('⚠️ [CalendarRepository] No membership found, already unsubscribed');
        return;
      }
      final membershipId = memberships[0]['id'];
      await _apiClient.deleteCalendarMembership(membershipId);
      await _fetchAndSync();
      print('✅ [CalendarRepository] Unsubscribed from calendar ID $calendarId');
    } catch (e, stackTrace) {
      print('❌ [CalendarRepository] Error unsubscribing from calendar: $e');
      print('📍 [CalendarRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Calendar>> fetchPublicCalendars({String? search}) async {
    try {
      print('🔍 [CalendarRepository] Searching public calendars${search != null ? ': "$search"' : ''}');
      final queryParams = <String, String>{'is_public': 'true'};
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.get('/calendars', queryParams: queryParams);

      final calendars = <Calendar>[];
      for (final item in response as List) {
        calendars.add(Calendar.fromJson(item));
      }
      print('✅ [CalendarRepository] Found ${calendars.length} public calendars');
      return calendars;
    } catch (e, stackTrace) {
      print('❌ [CalendarRepository] Error fetching public calendars: $e');
      print('📍 [CalendarRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // --- Realtime ---

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _realtimeChannel = _supabaseService.client
        .channel('calendar_memberships_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calendar_memberships',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId.toString()),
          callback: (payload) {
            print('🔄 [CalendarRepository] Realtime change detected, refreshing calendars');
            _fetchAndSync();
          },
        )
        .subscribe();

    print('✅ [CalendarRepository] Realtime subscription started for calendar_memberships table');
  }

  void _emitCurrentCalendars() {
    if (!_calendarsController.isClosed) {
      _calendarsController.add(List.from(_cachedCalendars));
    }
  }

  Calendar? getCalendarById(int calendarId) {
    return _cachedCalendars.firstWhereOrNull((c) => c.id == calendarId.toString());
  }

  void dispose() {
    print('👋 [CalendarRepository] Disposing...');
    _realtimeChannel?.unsubscribe();
    _calendarsController.close();
    _box?.close();
  }
}
