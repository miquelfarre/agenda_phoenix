import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import '../models/domain/calendar.dart';
import '../models/persistence/calendar_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';
import '../utils/app_exceptions.dart' as exceptions;
import '../utils/realtime_filter.dart';
import 'contracts/calendar_repository_contract.dart';

class CalendarRepository implements ICalendarRepository {
  static const String _boxName = 'calendars';
  final _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<CalendarHive>? _box;
  final StreamController<List<Calendar>> _calendarsController =
      StreamController<List<Calendar>>.broadcast();
  List<Calendar> _cachedCalendars = [];
  RealtimeChannel? _membershipChannel;
  RealtimeChannel? _calendarsChannel;

  final Completer<void> _initCompleter = Completer<void>();

  @override
  Future<void> get initialized => _initCompleter.future;

  @override
  Stream<List<Calendar>> get dataStream => calendarsStream;

  @override
  Stream<List<Calendar>> get calendarsStream async* {
    // Wait for initialization to complete
    try {
      await initialized;
    } catch (e) {
      // If initialization failed, still emit empty list to avoid infinite loading
    }

    // Emit cached calendars immediately
    if (_cachedCalendars.isNotEmpty) {
      yield List.from(_cachedCalendars);
    } else {
      // Emit empty list to avoid infinite loading state
      yield [];
    }

    // Then emit future updates
    yield* _calendarsController.stream;
  }

  @override
  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      try {
        _box = await Hive.openBox<CalendarHive>(_boxName);
      } catch (e) {
        // If there's a schema error, delete the corrupted box and try again
        if (e.toString().contains('is not a subtype of type')) {
          // Try to close the box if it's open
          try {
            if (Hive.isBoxOpen(_boxName)) {
              await Hive.box(_boxName).close();
            }
          } catch (_) {
            // Ignore close errors
          }

          // Delete and recreate
          try {
            await Hive.deleteBoxFromDisk(_boxName);
          } catch (deleteError) {
            // Continue anyway, box might not exist
          }

          _box = await Hive.openBox<CalendarHive>(_boxName);
        } else {
          rethrow;
        }
      }

      // Load calendars from Hive cache first (if any)
      _loadCalendarsFromHive();

      // Fetch and sync calendars from API BEFORE subscribing to Realtime
      await _fetchAndSync();

      // Now subscribe to Realtime for future updates
      await _startRealtimeSubscription();

      _emitCurrentCalendars();

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
      _cachedCalendars = _box!.values
          .map((calendarHive) => calendarHive.toCalendar())
          .toList();
    } catch (e) {
      _cachedCalendars = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      final response = await _apiClient.fetchCalendars();

      _cachedCalendars = response
          .map((data) => Calendar.fromJson(data))
          .toList();

      await _updateLocalCache(_cachedCalendars);

      // Set sync timestamp from latest updated_at
      if (_cachedCalendars.isNotEmpty) {
        final updatedAtTimestamps = _cachedCalendars
            .map((c) => c.updatedAt)
            .toList();
        if (updatedAtTimestamps.isNotEmpty) {
          final latestUpdate = updatedAtTimestamps.reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
          _rt.setServerSyncTs(latestUpdate.toUtc());
        }
      }

      _emitCurrentCalendars();
    } catch (e) {
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

  @override
  Future<Calendar> createCalendar({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final newCalendar = await _apiClient.createCalendar({
        'name': name,
        'description': description,
        'is_public': isPublic,
        'owner_id': userId,
      });
      await _fetchAndSync();
      return Calendar.fromJson(newCalendar);
    } catch (e, _) {
      rethrow;
    }
  }

  @override
  Future<Calendar> updateCalendar(
    int calendarId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updatedCalendar = await _apiClient.updateCalendar(calendarId, data);
      await _fetchAndSync();
      return Calendar.fromJson(updatedCalendar);
    } catch (e, _) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCalendar(
    int calendarId, {
    bool deleteAssociatedEvents = false,
  }) async {
    try {
      _cachedCalendars.firstWhere(
        (c) => c.id == calendarId,
        orElse: () => throw exceptions.NotFoundException(
          message: 'Calendar not found in cache',
        ),
      );

      await _apiClient.deleteCalendar(
        calendarId,
        deleteEvents: deleteAssociatedEvents,
      );
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  @override
  Future<void> subscribeToCalendar(int calendarId) async {
    try {
      await _apiClient.addCalendarMembership(
        calendarId,
        {},
      ); // Body might need user id, check API
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  @override
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

  @override
  Future<List<Calendar>> fetchPublicCalendars({String? search}) async {
    try {
      final queryParams = <String, String>{'is_public': 'true'};
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.get(
        '/calendars',
        queryParams: queryParams,
      );

      final calendars = <Calendar>[];
      for (final item in response as List) {
        calendars.add(Calendar.fromJson(item));
      }
      return calendars;
    } catch (e, _) {
      rethrow;
    }
  }

  @override
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

  @override
  Future<void> subscribeByShareHash(String shareHash) async {
    try {
      await _apiClient.subscribeByShareHash(shareHash);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  @override
  Future<void> unsubscribeByShareHash(String shareHash) async {
    try {
      await _apiClient.unsubscribeByShareHash(shareHash);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCalendarMemberships(
    int calendarId,
  ) async {
    try {
      final memberships = await _apiClient.fetchCalendarMemberships(calendarId);
      return memberships;
    } catch (e, _) {
      rethrow;
    }
  }

  // --- Local cache and realtime ---

  @override
  Future<void> startRealtimeSubscription() async {
    await _startRealtimeSubscription();
  }

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;

    // Listen to calendar_memberships changes (when user subscribes/unsubscribes)
    _membershipChannel = _supabaseService.client
        .channel('calendar_memberships_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calendar_memberships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId.toString(),
          ),
          callback: (payload) {
            if (!RealtimeFilter.shouldProcessEvent(
              payload,
              'calendar_membership',
              _rt,
            )) {
              return;
            }
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
            if (!RealtimeFilter.shouldProcessEvent(payload, 'calendar', _rt)) {
              return;
            }
            _fetchAndSync();
          },
        )
        .subscribe();
  }

  @override
  Future<void> stopRealtimeSubscription() async {
    await _membershipChannel?.unsubscribe();
    await _calendarsChannel?.unsubscribe();
    _membershipChannel = null;
    _calendarsChannel = null;
  }

  @override
  bool get isRealtimeConnected =>
      _membershipChannel != null || _calendarsChannel != null;

  @override
  Future<void> loadFromCache() async {
    _loadCalendarsFromHive();
  }

  @override
  Future<void> saveToCache() async {
    await _updateLocalCache(_cachedCalendars);
  }

  @override
  Future<void> clearCache() async {
    _cachedCalendars = [];
    await _box?.clear();
    _emitCurrentCalendars();
  }

  @override
  List<Calendar> getLocalData() {
    return _cachedCalendars;
  }

  void _emitCurrentCalendars() {
    if (!_calendarsController.isClosed) {
      _calendarsController.add(List.from(_cachedCalendars));
    }
  }

  @override
  Calendar? getCalendarById(int calendarId) {
    return _cachedCalendars.firstWhereOrNull((c) => c.id == calendarId);
  }

  @override
  void dispose() {
    _membershipChannel?.unsubscribe();
    _calendarsChannel?.unsubscribe();
    _calendarsController.close();
    _box?.close();
  }
}
