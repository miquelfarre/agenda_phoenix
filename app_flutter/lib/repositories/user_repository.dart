import 'dart:async';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/config_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/app_exceptions.dart' as exceptions;

class UserRepository {
  final _apiClient = ApiClient();

  final StreamController<User?> _currentUserController =
      StreamController<User?>.broadcast();
  User? _cachedCurrentUser;

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  Stream<User?> get currentUserStream async* {
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
      print('🚀 [UserRepository] Initializing...');
      await _loadCurrentUser();
      print('✅ [UserRepository] Initialization complete');

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

  Future<User?> _loadCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCurrentUser != null) {
      return _cachedCurrentUser;
    }

    try {
      final configService = ConfigService.instance;
      if (configService.isTestMode) {
        final response = await _apiClient.fetchUser(configService.currentUserId, enriched: true);
        _cachedCurrentUser = User.fromJson(response);
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
      _cachedCurrentUser = User.fromJson(response);
      _emitCurrentUser();
      return _cachedCurrentUser;
    } on exceptions.ApiException {
      // If API call fails, try to return cached user
      return _cachedCurrentUser;
    } catch (e) {
      print('Error loading current user: $e');
      _cachedCurrentUser = null;
      _emitCurrentUser();
      return null;
    }
  }

  Future<User?> getCurrentUser({bool forceRefresh = false}) => _loadCurrentUser(forceRefresh: forceRefresh);

  Future<User?> getUserById(int userId) async {
    try {
      final response = await _apiClient.fetchUser(userId);
      return User.fromJson(response);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  Future<List<User>> getUsersByIds(List<int> userIds) async {
    // This would ideally be an API call to fetch multiple users by ID
    // For now, fetching individually
    final users = <User>[];
    for (final id in userIds) {
      final user = await getUserById(id);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }

  Future<List<User>> searchPublicUsers(String query) async {
    final usersData = await _apiClient.fetchUsers(isPublic: true, search: query);
    return usersData.map((data) => User.fromJson(data)).toList();
  }

  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    final usersData = await _apiClient.fetchUsers(search: query, limit: limit);
    return usersData.map((data) => User.fromJson(data)).toList();
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
    print('👋 [UserRepository] Disposing...');
    _currentUserController.close();
  }
}
