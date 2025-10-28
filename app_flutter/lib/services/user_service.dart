import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_ce/hive.dart';
import 'sync_service.dart';
import '../models/user.dart';
import '../models/user_hive.dart';
import '../utils/app_exceptions.dart';
import '../services/config_service.dart';
import 'api_client.dart';
import 'supabase_auth_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String get serviceName => 'UserService';

  String get hiveBoxName => 'users';

  dynamic toHiveModel(dynamic domainModel) {
    if (domainModel is User) {
      return domainModel.toUserHive();
    }
    throw ArgumentError('Expected User, got ${domainModel.runtimeType}');
  }

  dynamic toDomainModel(dynamic hiveModel) {
    if (hiveModel is UserHive) {
      return hiveModel.toUser();
    }
    throw ArgumentError('Expected UserHive, got ${hiveModel.runtimeType}');
  }

  User? get currentUser {
    final userId = ConfigService.instance.currentUserId;
    if (userId == 0) return null;
    return Hive.box<UserHive>('users').get(userId)?.toUser();
  }

  bool get isLoggedIn => currentUser != null && SupabaseAuthService.isLoggedIn;

  Future<User?> loadCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedUser = currentUser;
      if (cachedUser != null) {
        return cachedUser;
      }
    }

    try {
      final configService = ConfigService.instance;
      if (configService.isTestMode) {
        configService.currentUserId;

        final response = await ApiClientFactory.instance.get('/api/v1/users/me?enriched=true');
        final user = User.fromJson(response);

        await SyncService.syncUserProfile(user.id);

        return user;
      }

      final supabaseUser = SupabaseAuthService.currentUser;
      if (supabaseUser == null) {
        return null;
      }

      final idToken = await SupabaseAuthService.getCurrentUserToken();
      if (idToken == null) {
        throw AppException(message: 'No authentication token available', code: 1001, tag: 'AUTH');
      }

      // Get user data with enriched contact information
      final response = await ApiClientFactory.instance.get('/api/v1/users/me?enriched=true');

      final user = User.fromJson(response);

      await SyncService.syncUserProfile(user.id);

      return user;
    } on ApiException {
      return currentUser;
    } catch (_) {
      return currentUser;
    }
  }

  static Future<User?> getCurrentUser() async {
    final instance = UserService();
    return await instance.loadCurrentUser();
  }

  static Future<bool> isCurrentUserPublic() async {
    final instance = UserService();
    final user = await instance.loadCurrentUser();
    return user?.isPublic ?? false;
  }

  Future<User?> getUserById(int userId) async {
    final userHive = Hive.box<UserHive>('users').get(userId);
    return userHive?.toUser();
  }

  Future<List<User>> getUsersByIds(List<int> userIds) async {
    final users = <User>[];
    final hiveBox = Hive.box<UserHive>('users');

    for (final id in userIds) {
      final userHive = hiveBox.get(id);
      if (userHive != null) {
        users.add(userHive.toUser());
      }
    }

    return users;
  }

  static Future<List<Contact>> getContacts() async {
    try {
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        return [];
      }

      final contacts = await ContactsService.getContacts();
      return contacts;
    } catch (e) {
      return [];
    }
  }

  static Future<List<User>> getContactUsers() async {
    try {
      final contacts = await getContacts();
      if (contacts.isEmpty) {
        return [];
      }

      final phoneNumbers = <String>[];
      for (final contact in contacts) {
        for (final phone in contact.phones ?? []) {
          if (phone.value != null) {
            phoneNumbers.add(phone.value!);
          }
        }
      }

      if (phoneNumbers.isEmpty) {
        return [];
      }

      final response = await ApiClientFactory.instance.post('/api/v1/users/find-by-phones', body: {'phone_numbers': phoneNumbers});

      final List<dynamic> usersJson = response is List ? response : [];
      final users = usersJson.map((json) => User.fromJson(json)).toList();

      return users;
    } catch (e) {
      return [];
    }
  }

  static Future<void> syncContactUsers() async {
    try {
      await getContactUsers();
    } catch (e) {
      // Ignore sync errors
    }
  }

  static Future<List<User>> searchPublicUsers(String query) async {
    try {
      // Get all public users and filter client-side
      // TODO: Backend should implement search parameter in GET /users
      final response = await ApiClientFactory.instance.get('/api/v1/users', queryParams: {'public': 'true', 'limit': '100'});

      final List<dynamic> usersJson = response is List ? response : [];
      final allUsers = usersJson.map((json) => User.fromJson(json)).toList();

      // Filter by query (username or full name)
      if (query.isEmpty) return allUsers;

      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        final username = user.instagramName?.toLowerCase() ?? '';
        final fullName = user.fullName?.toLowerCase() ?? '';
        return username.contains(lowerQuery) || fullName.contains(lowerQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    try {
      // Get all users and filter client-side
      // TODO: Backend should implement search parameter in GET /users
      final response = await ApiClientFactory.instance.get('/api/v1/users', queryParams: {'limit': limit.toString()});

      final List<dynamic> usersJson = response is List ? response : [];
      final allUsers = usersJson.map((json) => User.fromJson(json)).toList();

      // Filter by query (username or full name)
      if (query.isEmpty) return allUsers;

      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        final username = user.instagramName?.toLowerCase() ?? '';
        final fullName = user.fullName?.toLowerCase() ?? '';
        return username.contains(lowerQuery) || fullName.contains(lowerQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearCache() async {
    await Hive.box<UserHive>('users').clear();
  }

  static Map<String, dynamic> getCacheStats() {
    final hiveBox = Hive.box<UserHive>('users');
    return {'hive_users_count': hiveBox.length, 'hive_box_open': hiveBox.isOpen};
  }

  Future<void> logout() async {
    try {
      await SupabaseAuthService.signOut();
      clearCache();
    } catch (e) {
      rethrow;
    }
  }
}
