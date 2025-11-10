import '../../models/domain/user.dart' as models;
import 'realtime_repository_contract.dart';

abstract class IUserRepository implements IRealtimeRepository<models.User?> {
  @override
  Stream<models.User?> get dataStream => currentUserStream;
  Stream<models.User?> get currentUserStream;

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
  Future<models.User?> getCurrentUser({bool forceRefresh = false});
  Future<models.User?> getUserById(int userId);
  Future<List<models.User>> getUsersByIds(List<int> userIds);
  Future<List<models.User>> searchPublicUsers(String query);
  Future<List<models.User>> searchUsers(String query, {int limit = 20});
  Future<List<models.User>> fetchAvailableInvitees(int eventId);
  Future<void> updateOnlineStatus({
    required int userId,
    required bool isOnline,
    required DateTime lastSeen,
  });
  Future<void> logout();
}
