import '../../models/domain/calendar.dart';
import 'realtime_repository_contract.dart';

abstract class ICalendarRepository
    implements
        IRealtimeRepository<List<Calendar>>,
        ILocalRepository<List<Calendar>> {
  @override
  Stream<List<Calendar>> get dataStream => calendarsStream;
  Stream<List<Calendar>> get calendarsStream;

  // Realtime methods inherited from IRealtimeRepository:
  // - Future<void> get initialized
  // - Future<void> initialize()
  // - Future<void> startRealtimeSubscription()
  // - Future<void> stopRealtimeSubscription()
  // - bool get isRealtimeConnected
  // - Future<void> loadFromCache()
  // - Future<void> saveToCache()
  // - Future<void> clearCache()
  // - void dispose()
  // - Calendar? getLocalData() (from ILocalRepository)
  Future<Calendar> createCalendar({
    required String name,
    String? description,
    bool isPublic = false,
  });
  Future<Calendar> updateCalendar(int calendarId, Map<String, dynamic> data);
  Future<void> deleteCalendar(
    int calendarId, {
    bool deleteAssociatedEvents = false,
  });
  Future<void> subscribeToCalendar(int calendarId);
  Future<void> unsubscribeFromCalendar(int calendarId);
  Future<List<Calendar>> fetchPublicCalendars({String? search});
  Future<Calendar?> searchByShareHash(String shareHash);
  Future<void> subscribeByShareHash(String shareHash);
  Future<void> unsubscribeByShareHash(String shareHash);
  Future<List<Map<String, dynamic>>> fetchCalendarMemberships(int calendarId);
  Calendar? getCalendarById(int calendarId);
}
