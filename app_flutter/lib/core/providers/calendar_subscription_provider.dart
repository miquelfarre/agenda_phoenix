import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar.dart';
import '../../services/calendar_service.dart';
import '../state/app_state.dart';

final publicCalendarsProvider = FutureProvider.family<List<Calendar>, String?>((
  ref,
  search,
) async {
  final service = ref.watch(calendarServiceProvider);
  return await service.fetchPublicCalendars(search: search);
});

final calendarSubscriptionNotifierProvider =
    NotifierProvider<CalendarSubscriptionNotifier, AsyncValue<Set<int>>>(
      CalendarSubscriptionNotifier.new,
    );

class CalendarSubscriptionNotifier extends Notifier<AsyncValue<Set<int>>> {
  late final CalendarService _service;

  @override
  AsyncValue<Set<int>> build() {
    _service = ref.watch(calendarServiceProvider);
    _loadSubscribedCalendarIds();
    return const AsyncValue.data({});
  }

  Future<void> _loadSubscribedCalendarIds() async {
    try {
      state = const AsyncValue.loading();

      final availableCalendars = await _service.fetchAvailableCalendars();
      final ownCalendars = await _service.fetchCalendars();

      final ownIds = ownCalendars.map((c) => int.parse(c.id)).toSet();
      final subscribedIds = availableCalendars
          .map((c) => int.parse(c.id))
          .where((id) => !ownIds.contains(id))
          .toSet();

      state = AsyncValue.data(subscribedIds);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> subscribe(int calendarId) async {
    try {
      await _service.subscribeToCalendar(calendarId);

      state.whenData((subscribedIds) {
        state = AsyncValue.data({...subscribedIds, calendarId});
      });

      ref.invalidate(calendarsStreamProvider);
    } catch (error) {
      await refresh();
      rethrow;
    }
  }

  Future<void> unsubscribe(int calendarId) async {
    try {
      await _service.unsubscribeFromCalendar(calendarId);

      state.whenData((subscribedIds) {
        final newSet = Set<int>.from(subscribedIds);
        newSet.remove(calendarId);
        state = AsyncValue.data(newSet);
      });

      ref.invalidate(calendarsStreamProvider);
    } catch (error) {
      await refresh();
      rethrow;
    }
  }

  bool isSubscribed(int calendarId) {
    return state.maybeWhen(
      data: (subscribedIds) => subscribedIds.contains(calendarId),
      orElse: () => false,
    );
  }

  Future<void> refresh() => _loadSubscribedCalendarIds();
}
