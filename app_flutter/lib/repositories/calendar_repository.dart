import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';

class CalendarRepository {
  final _supabaseService = SupabaseService.instance;

  final StreamController<List<Calendar>> _calendarsController =
      StreamController<List<Calendar>>.broadcast();
  List<Calendar> _cachedCalendars = [];
  DateTime? _initialSyncTime;
  RealtimeChannel? _realtimeChannel;

  Stream<List<Calendar>> get calendarsStream => _calendarsController.stream;

  Future<void> initialize() async {
    await _fetchAndSync();
    await _startRealtimeSubscription();
    _emitCurrentCalendars();
  }

  Future<void> _fetchAndSync() async {
    try {
      _initialSyncTime = DateTime.now().toUtc();
      final userId = ConfigService.instance.currentUserId;

      final response = await _supabaseService.client
          .from('calendars')
          .select('*')
          .eq('owner_id', userId);

      _cachedCalendars = (response as List)
          .map((json) => Calendar.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching calendars: $e');
    }
  }

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _realtimeChannel = _supabaseService.client
        .channel('calendars_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calendars',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: userId.toString(),
          ),
          callback: _handleCalendarChange,
        )
        .subscribe();
  }

  void _handleCalendarChange(PostgresChangePayload payload) {
    final eventTime = DateTime.tryParse(payload.commitTimestamp.toString());
    if (eventTime != null &&
        _initialSyncTime != null &&
        eventTime.isBefore(_initialSyncTime!)) {
      return;
    }

    if (payload.eventType == PostgresChangeEvent.insert) {
      final calendar = Calendar.fromJson(payload.newRecord);
      _cachedCalendars.add(calendar);
      _emitCurrentCalendars();
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final updatedCalendar = Calendar.fromJson(payload.newRecord);
      final index = _cachedCalendars.indexWhere(
        (c) => c.id == updatedCalendar.id,
      );
      if (index != -1) {
        _cachedCalendars[index] = updatedCalendar;
        _emitCurrentCalendars();
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final calendarId = payload.oldRecord['id']?.toString() ?? '';
      _cachedCalendars.removeWhere((c) => c.id == calendarId);
      _emitCurrentCalendars();
    }
  }

  void _emitCurrentCalendars() {
    if (!_calendarsController.isClosed) {
      _calendarsController.add(List.from(_cachedCalendars));
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _calendarsController.close();
  }
}
