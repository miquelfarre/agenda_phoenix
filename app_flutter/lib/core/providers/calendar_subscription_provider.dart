import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar.dart';
import '../../repositories/calendar_repository.dart';
import '../state/app_state.dart';
import '../../services/config_service.dart';

final publicCalendarsProvider = FutureProvider.family<List<Calendar>, String?>((ref, search) async {
  final calendars = await ref.read(calendarRepositoryProvider).fetchPublicCalendars(search: search);
  return calendars;
});

final calendarSubscriptionNotifierProvider = NotifierProvider<CalendarSubscriptionNotifier, AsyncValue<Set<int>>>(CalendarSubscriptionNotifier.new);

class CalendarSubscriptionNotifier extends Notifier<AsyncValue<Set<int>>> {
  late final CalendarRepository _repo;

  @override
  AsyncValue<Set<int>> build() {
    _repo = ref.watch(calendarRepositoryProvider);
    _loadSubscribedCalendarIds();
    return const AsyncValue.data({});
  }

  Future<void> _loadSubscribedCalendarIds() async {
    state = const AsyncValue.loading();
    try {
      final calendars = await _repo.calendarsStream.first;
      final ownCalendars = calendars.where((c) => c.isOwnedBy(ConfigService.instance.currentUserId)).toList();
      final ownIds = ownCalendars.map((c) => c.id).toSet();
      final subscribedIds = calendars.map((c) => c.id).where((id) => !ownIds.contains(id)).toSet();

      state = AsyncValue.data(subscribedIds);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> subscribe(int calendarId) async {
    try {
      await _repo.subscribeToCalendar(calendarId);
      state.whenData((subscribedIds) {
        state = AsyncValue.data({...subscribedIds, calendarId});
      });
    } catch (error) {
      await refresh();
      rethrow;
    }
  }

  Future<void> unsubscribe(int calendarId) async {
    try {
      await _repo.unsubscribeFromCalendar(calendarId);
      state.whenData((subscribedIds) {
        final newSet = Set<int>.from(subscribedIds);
        newSet.remove(calendarId);
        state = AsyncValue.data(newSet);
      });
    } catch (error) {
      await refresh();
      rethrow;
    }
  }

  bool isSubscribed(int calendarId) {
    return state.maybeWhen(data: (subscribedIds) => subscribedIds.contains(calendarId), orElse: () => false);
  }

  Future<void> refresh() => _loadSubscribedCalendarIds();
}
