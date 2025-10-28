import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';

class CalendarRepository {
  final _supabaseService = SupabaseService.instance;
  final RealtimeSync _rt = RealtimeSync();

  final StreamController<List<Calendar>> _calendarsController = StreamController<List<Calendar>>.broadcast();
  List<Calendar> _cachedCalendars = [];
  RealtimeChannel? _realtimeChannel;

  Stream<List<Calendar>> get calendarsStream => _calendarsController.stream;

  Future<void> initialize() async {
    await _fetchAndSync();
    await _startRealtimeSubscription();
    _emitCurrentCalendars();
  }

  Future<void> _fetchAndSync() async {
    try {
      final userId = ConfigService.instance.currentUserId;

      final response = await _supabaseService.client.from('calendars').select('*').eq('owner_id', userId);

      final list = (response as List);
      _cachedCalendars = list.map((json) => Calendar.fromJson(json)).toList();

      // Set server sync time from rows (serverTime not available here)
      _rt.setServerSyncTsFromResponse(rows: list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
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
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'owner_id', value: userId.toString()),
          callback: _handleCalendarChange,
        )
        .subscribe();
  }

  void _handleCalendarChange(PostgresChangePayload payload) {
    final ct = DateTime.tryParse(payload.commitTimestamp?.toString() ?? '');

    if (payload.eventType == PostgresChangeEvent.insert) {
      if (!_rt.shouldProcessInsertOrUpdate(ct)) return;
      final calendar = Calendar.fromJson(payload.newRecord);
      _cachedCalendars.add(calendar);
      _emitCurrentCalendars();
    } else if (payload.eventType == PostgresChangeEvent.update) {
      if (!_rt.shouldProcessInsertOrUpdate(ct)) return;
      final updatedCalendar = Calendar.fromJson(payload.newRecord);
      final index = _cachedCalendars.indexWhere((c) => c.id == updatedCalendar.id);
      if (index != -1) {
        _cachedCalendars[index] = updatedCalendar;
        _emitCurrentCalendars();
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      if (!_rt.shouldProcessDelete()) return;
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
