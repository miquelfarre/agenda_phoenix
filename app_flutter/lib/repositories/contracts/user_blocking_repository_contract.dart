import '../../models/domain/user.dart';
import 'realtime_repository_contract.dart';

abstract class IUserBlockingRepository
    implements IRealtimeRepository<List<User>> {
  @override
  Stream<List<User>> get dataStream => blockedUsersStream;
  Stream<List<User>> get blockedUsersStream;

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
  Future<void> blockUser(int userId);
  Future<void> unblockUser(int userId);
}
