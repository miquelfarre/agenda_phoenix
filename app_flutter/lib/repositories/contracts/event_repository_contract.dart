import '../../models/domain/event.dart';
import '../../models/domain/event_interaction.dart';
import 'realtime_repository_contract.dart';

abstract class IEventRepository
    implements
        IRealtimeRepository<List<Event>>,
        IRefreshableRepository<List<Event>>,
        ILocalRepository<List<Event>> {
  @override
  Stream<List<Event>> get dataStream => eventsStream;
  Stream<List<Event>> get eventsStream;
  Stream<List<EventInteraction>> get interactionsStream;

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
  // - Future<void> refresh() (from IRefreshableRepository)
  // - List<Event> getLocalData() (from ILocalRepository)
  Future<Event> createEvent(Map<String, dynamic> data);
  Future<Event> updateEvent(int eventId, Map<String, dynamic> data);
  Future<void> deleteEvent(int eventId);
  Future<void> leaveEvent(int eventId);
  Future<EventInteraction> updateParticipationStatus(
    int eventId,
    String status, {
    String? decisionMessage,
    bool? isAttending,
  });
  Future<void> markAsViewed(int eventId);
  Future<void> setPersonalNote(int eventId, String note);
  Future<void> sendInvitation(int eventId, int invitedUserId);
  @override
  List<Event> getLocalData() => getLocalEvents();
  List<Event> getLocalEvents();
  Event? getEventById(int id);
  Future<Event> fetchEventDetails(int eventId);
  Future<List<Event>> fetchUserEvents(int userId);
  Future<void> updatePersonalNote(int eventId, String? note);
}
