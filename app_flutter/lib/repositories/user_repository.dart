import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/realtime_sync.dart';
import '../models/user.dart' as models;
import '../models/user_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/app_exceptions.dart' as exceptions;
import '../utils/realtime_filter.dart';

class UserRepository {
  static const String _boxName = 'current_user';
  final SupabaseService _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<UserHive>? _box;
  RealtimeChannel? _userChannel;
  final StreamController<models.User?> _currentUserController = StreamController<models.User?>.broadcast();
  models.User? _cachedCurrentUser;

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  Stream<models.User?> get currentUserStream async* {
    // Emit cached user immediately for new subscribers
    if (_cachedCurrentUser != null) {
      yield _cachedCurrentUser;
    }
    // Then listen for future updates
    yield* _currentUserController.stream;
  }

  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      _box = await Hive.openBox<UserHive>(_boxName);

      // Load current user from Hive cache first
      _loadCurrentUserFromHive();

      // Fetch and sync from API
      await _loadCurrentUser();

      // Subscribe to Realtime updates for current user
      await _startRealtimeSubscription();

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

  void _loadCurrentUserFromHive() {
    if (_box == null) return;

    try {
      final configService = ConfigService.instance;
      final userId = configService.currentUserId;
      final userHive = _box!.get(userId);
      if (userHive != null) {
        _cachedCurrentUser = userHive.toUser();
      }
    } catch (e) {
      _cachedCurrentUser = null;
    }
  }

  Future<void> _startRealtimeSubscription() async {
    final configService = ConfigService.instance;
    if (!configService.hasUser) return;

    final userId = configService.currentUserId;

    _userChannel = _supabaseService.client
        .channel('user_${userId}_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId.toString(),
          ),
          callback: _handleUserChange,
        )
        .subscribe();
  }

  void _handleUserChange(PostgresChangePayload payload) {
    if (!RealtimeFilter.shouldProcessEvent(payload, 'user', _rt)) {
      return;
    }

    try {
      final userData = payload.newRecord;
      final updatedUser = models.User.fromJson(userData);

      _cachedCurrentUser = updatedUser;

      // Update Hive cache
      final userHive = UserHive.fromUser(updatedUser);
      _box?.put(updatedUser.id, userHive);

      _emitCurrentUser();
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore realtime handler errors
    }
  }

  Future<models.User?> _loadCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCurrentUser != null) {
      return _cachedCurrentUser;
    }

    try {
      final configService = ConfigService.instance;
      if (configService.isTestMode) {
        final response = await _apiClient.fetchUser(configService.currentUserId, enriched: true);
        _cachedCurrentUser = models.User.fromJson(response);
        await _updateLocalCache(_cachedCurrentUser!);
        _rt.setServerSyncTs(DateTime.now().toUtc());
        _emitCurrentUser();
        return _cachedCurrentUser;
      }

      final supabaseUser = SupabaseAuthService.currentUser;
      if (supabaseUser == null) {
        _cachedCurrentUser = null;
        _emitCurrentUser();
        return null;
      }

      final response = await _apiClient.fetchUser(configService.currentUserId, enriched: true);
      _cachedCurrentUser = models.User.fromJson(response);
      await _updateLocalCache(_cachedCurrentUser!);
      _rt.setServerSyncTs(DateTime.now().toUtc());
      _emitCurrentUser();
      return _cachedCurrentUser;
    } on exceptions.ApiException {
      // If API call fails, try to return cached user
      return _cachedCurrentUser;
    } catch (e) {
      _cachedCurrentUser = null;
      _emitCurrentUser();
      return null;
    }
  }

  Future<void> _updateLocalCache(models.User user) async {
    if (_box == null) return;

    try {
      final userHive = UserHive.fromUser(user);
      await _box!.put(user.id, userHive);
      // ignore: empty_catches
    } catch (e) {
      // Intentionally ignore cache update errors
    }
  }

  Future<models.User?> getCurrentUser({bool forceRefresh = false}) => _loadCurrentUser(forceRefresh: forceRefresh);

  Future<models.User?> getUserById(int userId) async {
    try {
      final response = await _apiClient.fetchUser(userId);
      return models.User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<models.User>> getUsersByIds(List<int> userIds) async {
    // This would ideally be an API call to fetch multiple users by ID
    // For now, fetching individually
    final users = <models.User>[];
    for (final id in userIds) {
      final user = await getUserById(id);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }

  Future<List<models.User>> searchPublicUsers(String query) async {
    final usersData = await _apiClient.fetchUsers(isPublic: true, search: query);
    return usersData.map((data) => models.User.fromJson(data)).toList();
  }

  Future<List<models.User>> searchUsers(String query, {int limit = 20}) async {
    final usersData = await _apiClient.fetchUsers(search: query, limit: limit);
    return usersData.map((data) => models.User.fromJson(data)).toList();
  }

  /// Fetch contacts for a specific user
  Future<List<models.User>> fetchContacts(int userId) async {
    final contactsData = await _apiClient.fetchContacts(currentUserId: userId);
    return contactsData.map((data) => models.User.fromJson(data)).toList();
  }

  /// Fetch detailed information for a specific contact
  Future<models.User> fetchContact(int contactId, {required int currentUserId}) async {
    final contactData = await _apiClient.fetchContact(contactId, currentUserId: currentUserId);
    return models.User.fromJson(contactData);
  }

  /// Fetch available users that can be invited to an event
  Future<List<models.User>> fetchAvailableInvitees(int eventId) async {
    final usersData = await _apiClient.fetchAvailableInvitees(eventId);
    return usersData.map((data) => models.User.fromJson(data)).toList();
  }

  /// Update user online status and last seen timestamp
  Future<void> updateOnlineStatus({required int userId, required bool isOnline, required DateTime lastSeen}) async {
    try {
      await _apiClient.updateUser(
        userId,
        {
          'is_online': isOnline,
          'last_seen': lastSeen.toIso8601String(),
        },
        currentUserId: userId,
      );
      // The realtime subscription will handle updating the cached user
    } catch (e) {
      // Ignore errors - this is a best-effort update
    }
  }

  Future<void> logout() async {
    await SupabaseAuthService.signOut();
    _cachedCurrentUser = null;
    _emitCurrentUser();
    // Clear all app data related to the user
    // This might involve clearing Hive boxes for all repositories
  }

  void _emitCurrentUser() {
    if (!_currentUserController.isClosed) {
      _currentUserController.add(_cachedCurrentUser);
    }
  }

  void dispose() {
    _userChannel?.unsubscribe();
    _currentUserController.close();
    _box?.close();
  }
}
