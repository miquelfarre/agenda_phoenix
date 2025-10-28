import '../models/user.dart';
import '../core/mixins/singleton_mixin.dart';
import '../core/mixins/error_handling_mixin.dart';
import 'api_client.dart';

class UserBlockingService with SingletonMixin, ErrorHandlingMixin {
  UserBlockingService._internal();

  factory UserBlockingService() =>
      SingletonMixin.getInstance(() => UserBlockingService._internal());

  @override
  String get serviceName => 'UserBlockingService';

  Future<void> blockUser(int currentUserId, int userId) async {
    await withErrorHandling('blockUser', () async {
      await ApiClientFactory.instance.createUserBlock({
        'blocker_user_id': currentUserId,
        'blocked_user_id': userId,
      });
    });
  }

  Future<void> unblockUser(int currentUserId, int userId) async {
    await withErrorHandling('unblockUser', () async {
      final blocks = await ApiClientFactory.instance.fetchUserBlocks(
        blockerUserId: currentUserId,
        blockedUserId: userId,
      );

      if (blocks.isNotEmpty) {
        final blockId = blocks.first['id'] as int;
        await ApiClientFactory.instance.deleteUserBlock(
          blockId,
          currentUserId: currentUserId,
        );
      }
    });
  }

  Future<List<User>> getBlockedUsers(
    int currentUserId, {
    bool forceRefresh = false,
  }) async {
    try {
      final blocks = await ApiClientFactory.instance.fetchUserBlocks(
        blockerUserId: currentUserId,
      );

      return blocks
          .map(
            (block) => User(
              id: block['blocked_user_id'] as int,
              isPublic: false,
              fullName: 'Blocked User ${block['blocked_user_id']}',
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isUserBlocked(int currentUserId, int userId) async {
    final blockedUsers = await getBlockedUsers(currentUserId);
    return blockedUsers.any((user) => user.id == userId);
  }
}
