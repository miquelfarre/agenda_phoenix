import '../../models/domain/user.dart' as models;
import '../../models/domain/event.dart';
import 'realtime_repository_contract.dart';

abstract class ISubscriptionRepository
    implements
        IRealtimeRepository<List<models.User>>,
        IRefreshableRepository<List<models.User>> {
  @override
  Stream<List<models.User>> get dataStream => subscriptionsStream;
  Stream<List<models.User>> get subscriptionsStream;

  // Realtime methods inherited from IRealtimeRepository:
  // - Future<void> get initialized
  // - Future<void> initialize()
  // - Future<void> refresh() (from IRefreshableRepository)
  // - Future<void> startRealtimeSubscription()
  // - Future<void> stopRealtimeSubscription()
  // - bool get isRealtimeConnected
  // - Future<void> loadFromCache()
  // - Future<void> saveToCache()
  // - Future<void> clearCache()
  // - void dispose()
  Future<void> createSubscription({required int targetUserId});
  Future<void> deleteSubscription({required int targetUserId});
  Future<List<models.User>> searchPublicUsers({required String query});
  Future<List<Event>> fetchUserEvents(int userId);
  Future<void> subscribeToUser(int userId);
  Future<void> unsubscribeFromUser(int userId);
}
