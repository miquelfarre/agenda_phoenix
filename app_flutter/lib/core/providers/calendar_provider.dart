import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar.dart';
import '../../services/calendar_service.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

final calendarsProvider = FutureProvider<List<Calendar>>((ref) async {
  final service = ref.watch(calendarServiceProvider);
  return await service.fetchCalendars();
});

final availableCalendarsProvider = FutureProvider<List<Calendar>>((ref) async {
  final service = ref.watch(calendarServiceProvider);
  return await service.fetchAvailableCalendars();
});

final calendarsNotifierProvider =
    NotifierProvider<CalendarsNotifier, AsyncValue<List<Calendar>>>(
      CalendarsNotifier.new,
    );

class CalendarsNotifier extends Notifier<AsyncValue<List<Calendar>>> {
  late final CalendarService _service;

  @override
  AsyncValue<List<Calendar>> build() {
    _service = ref.watch(calendarServiceProvider);
    _loadCalendars();
    return const AsyncValue.loading();
  }

  Future<void> _loadCalendars() async {
    try {
      state = const AsyncValue.loading();
      final calendars = await _service.fetchCalendars();
      state = AsyncValue.data(calendars);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<Calendar> createCalendar({
    required String name,
    String? description,
    String color = '#2196F3',
    bool isPublic = false,
    bool deleteAssociatedEvents = false,
  }) async {
    try {
      final calendar = await _service.createCalendar(
        name: name,
        description: description,
        color: color,
      );

      state.whenData((calendars) {
        state = AsyncValue.data([...calendars, calendar]);
      });

      return calendar;
    } catch (error) {
      await refresh();
      rethrow;
    }
  }

  Future<Calendar> updateCalendar(
    String id, {
    String? name,
    String? description,
    String? color,
  }) async {
    try {
      final updated = await _service.updateCalendar(
        id,
        name: name,
        description: description,
        color: color,
      );

      state.whenData((calendars) {
        final index = calendars.indexWhere((c) => c.id == id);
        if (index != -1) {
          final newList = [...calendars];
          newList[index] = updated;
          state = AsyncValue.data(newList);
        }
      });

      return updated;
    } catch (error) {
      await refresh();
      rethrow;
    }
  }

  Future<void> deleteCalendar(String id) async {
    try {
      await _service.deleteCalendar(id);

      state.whenData((calendars) {
        state = AsyncValue.data(calendars.where((c) => c.id != id).toList());
      });
    } catch (error) {
      await refresh();
      rethrow;
    }
  }

  Future<void> refresh() => _loadCalendars();

  List<Calendar> getLocalCalendars() {
    return _service.getLocalCalendars();
  }

  Calendar? getDefaultCalendar() {
    return _service.getDefaultCalendar();
  }
}
