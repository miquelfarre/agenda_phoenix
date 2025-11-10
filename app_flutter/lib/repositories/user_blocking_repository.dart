import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../core/realtime_sync.dart';
import '../models/domain/user.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../utils/realtime_filter.dart';
import 'contracts/user_blocking_repository_contract.dart';

class UserBlockingRepository implements IUserBlockingRepository {
  static const String _boxName = 'blocked_users';
  final SupabaseService _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<List<int>>? _box;
  final StreamController<List<User>> _blockedUsersController =
      StreamController<List<User>>.broadcast();
  List<User> _cachedBlockedUsers = [];
  RealtimeChannel? _realtimeChannel;

  final Completer<void> _initCompleter = Completer<void>();

  @override
  Future<void> get initialized => _initCompleter.future;

  @override
  Stream<List<User>> get dataStream => blockedUsersStream;

  @override
  Stream<List<User>> get blockedUsersStream async* {
    if (_cachedBlockedUsers.isNotEmpty) {
      yield List.from(_cachedBlockedUsers);
    }
    yield* _blockedUsersController.stream;
  }

  @override
  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      _box = await Hive.openBox<List<int>>(_boxName);

      // Load blocked user IDs from Hive cache first
      _loadBlockedUsersFromHive();

      // Fetch and sync from API
      await _fetchAndSync();

      // Subscribe to Realtime updates
      await _startRealtimeSubscription();

      _emitBlockedUsers();

      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    }
  }

  void _loadBlockedUsersFromHive() {
    if (_box == null) return;

    try {
      final blockedUserIds =
          _box!.get('blocked_user_ids', defaultValue: <int>[]) ?? <int>[];
      _cachedBlockedUsers = blockedUserIds
          .map(
            (id) =>
                User(id: id, isPublic: false, contactName: 'Blocked User $id'),
          )
          .toList();
    } catch (e) {
      _cachedBlockedUsers = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      final blocks = await _apiClient.fetchUserBlocks(
        blockerUserId: currentUserId,
      );

      _cachedBlockedUsers = blocks
          .map(
            (block) => User(
              id: block['blocked_user_id'] as int,
              isPublic: false,
              contactName: 'Blocked User ${block['blocked_user_id']}',
            ),
          )
          .toList();

      // Update Hive cache with blocked user IDs
      await _updateLocalCache();

      // Set sync timestamp
      _rt.setServerSyncTs(DateTime.now().toUtc());

      _emitBlockedUsers();
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore fetch errors
    }
  }

  Future<void> _updateLocalCache() async {
    if (_box == null) return;

    try {
      final blockedUserIds = _cachedBlockedUsers
          .map((user) => user.id)
          .toList();
      await _box!.put('blocked_user_ids', blockedUserIds);
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore cache update errors
    }
  }

  Future<void> blockUser(int userId) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      await _apiClient.createUserBlock({
        'blocker_user_id': currentUserId,
        'blocked_user_id': userId,
      });
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
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
    } catch (e, _) {
      rethrow;
    }
  }

  bool isUserBlocked(int userId) {
    return _cachedBlockedUsers.any((user) => user.id == userId);
  }

  // --- Local cache and realtime ---

  @override
  Future<void> startRealtimeSubscription() async {
    await _startRealtimeSubscription();
  }

  @override
  Future<void> stopRealtimeSubscription() async {
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  @override
  bool get isRealtimeConnected => _realtimeChannel != null;

  @override
  Future<void> loadFromCache() async {
    _loadBlockedUsersFromHive();
  }

  @override
  Future<void> saveToCache() async {
    await _updateLocalCache();
  }

  @override
  Future<void> clearCache() async {
    _cachedBlockedUsers = [];
    await _box?.clear();
    _emitBlockedUsers();
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
          callback: _handleBlockChange,
        )
        .subscribe();
  }

  void _handleBlockChange(PostgresChangePayload payload) {
    if (!RealtimeFilter.shouldProcessEvent(payload, 'user_block', _rt)) {
      return;
    }

    // A block changed, refetch all blocked users
    _fetchAndSync();
  }

  void _emitBlockedUsers() {
    if (!_blockedUsersController.isClosed) {
      _blockedUsersController.add(List.from(_cachedBlockedUsers));
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _blockedUsersController.close();
    _box?.close();
  }
}
