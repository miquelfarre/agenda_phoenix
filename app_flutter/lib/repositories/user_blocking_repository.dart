import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';


class UserBlockingRepository {
  final _apiClient = ApiClient();
  final _supabaseService = SupabaseService.instance;

  final StreamController<List<User>> _blockedUsersController =
      StreamController<List<User>>.broadcast();
  List<User> _cachedBlockedUsers = [];
  RealtimeChannel? _realtimeChannel;

  Stream<List<User>> get blockedUsersStream => _blockedUsersController.stream;

  Future<void> initialize() async {
    print('🚀 [UserBlockingRepository] Initializing...');
    await _fetchAndSync();
    await _startRealtimeSubscription();
    _emitBlockedUsers();
    print('✅ [UserBlockingRepository] Initialization complete');
  }

  Future<void> _fetchAndSync() async {
    try {
      print('📡 [UserBlockingRepository] Fetching blocked users from API...');
      final currentUserId = ConfigService.instance.currentUserId;
      final blocks = await _apiClient.fetchUserBlocks(
        blockerUserId: currentUserId,
      );

      _cachedBlockedUsers = blocks
          .map(
            (block) => User(
              id: block['blocked_user_id'] as int,
              isPublic: false,
              fullName: 'Blocked User ${block['blocked_user_id']}',
            ),
          )
          .toList();
      _emitBlockedUsers();
      print('✅ [UserBlockingRepository] Fetched ${_cachedBlockedUsers.length} blocked users');
    } catch (e) {
      print('❌ [UserBlockingRepository] Error fetching blocked users: $e');
    }
  }

  Future<void> blockUser(int userId) async {
    try {
      print('🚫 [UserBlockingRepository] Blocking user $userId');
      final currentUserId = ConfigService.instance.currentUserId;
      await _apiClient.createUserBlock({
        'blocker_user_id': currentUserId,
        'blocked_user_id': userId,
      });
      await _fetchAndSync();
      print('✅ [UserBlockingRepository] User $userId blocked');
    } catch (e, stackTrace) {
      print('❌ [UserBlockingRepository] Error blocking user: $e');
      print('📍 [UserBlockingRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
      print('✅ [UserBlockingRepository] Unblocking user $userId');
      final currentUserId = ConfigService.instance.currentUserId;
      final blocks = await _apiClient.fetchUserBlocks(
        blockerUserId: currentUserId,
        blockedUserId: userId,
      );

      if (blocks.isNotEmpty) {
        final blockId = blocks.first['id'] as int;
        await _apiClient.deleteUserBlock(blockId, currentUserId: currentUserId);
      }
      await _fetchAndSync();
      print('✅ [UserBlockingRepository] User $userId unblocked');
    } catch (e, stackTrace) {
      print('❌ [UserBlockingRepository] Error unblocking user: $e');
      print('📍 [UserBlockingRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  bool isUserBlocked(int userId) {
    return _cachedBlockedUsers.any((user) => user.id == userId);
  }

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _realtimeChannel = _supabaseService.client
        .channel('user_blocks_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_blocks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'blocker_user_id',
            value: userId.toString(),
          ),
          callback: (payload) {
            // A block changed, refetch all blocked users
            _fetchAndSync();
          },
        )
        .subscribe();
  }

  void _emitBlockedUsers() {
    if (!_blockedUsersController.isClosed) {
      _blockedUsersController.add(List.from(_cachedBlockedUsers));
    }
  }

  void dispose() {
    print('👋 [UserBlockingRepository] Disposing...');
    _realtimeChannel?.unsubscribe();
    _blockedUsersController.close();
  }
}
