import '../../models/domain/group.dart';
import 'realtime_repository_contract.dart';

abstract class IGroupRepository implements IRealtimeRepository<List<Group>> {
  @override
  Stream<List<Group>> get dataStream => groupsStream;
  Stream<List<Group>> get groupsStream;

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
  Future<Group> createGroup({required String name, String? description});
  Future<Group> updateGroup({
    required int groupId,
    String? name,
    String? description,
  });
  Future<void> deleteGroup({required int groupId});
  Future<void> addMemberToGroup({
    required int groupId,
    required int memberUserId,
  });
  Future<void> removeMemberFromGroup({
    required int groupId,
    required int memberUserId,
  });
  Future<void> leaveGroup(int groupId);
  Future<void> grantAdminPermission({
    required int groupId,
    required int userId,
  });
  Future<void> removeAdminPermission({
    required int groupId,
    required int userId,
  });
}
