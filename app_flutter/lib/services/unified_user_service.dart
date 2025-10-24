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

class UnifiedUserService {
  static final UnifiedUserService _instance = UnifiedUserService._internal();
  factory UnifiedUserService() => _instance;
  UnifiedUserService._internal();

  String get serviceName => 'UnifiedUserService';

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

  Future<User> createOrUpdateUser({
    required String firebaseUid,
    required String phoneNumber,
    String? email,
    String? fullName,
    String? instagramName,
    String? profilePicture,
    String? defaultTimezone,
    String? defaultCountryCode,
    String? defaultCity,
  }) async {
    try {
      final idToken = await SupabaseAuthService.getCurrentUserToken();
      if (idToken == null) {
        throw AppException(
          message: 'No authentication token available',
          code: 1001,
          tag: 'AUTH',
        );
      }

      final response = await ApiClientFactory.instance.post(
        '/api/v1/firebase-auth/verify-token',
        body: {'id_token': idToken},
      );

      final user = User.fromJson(response);

      await SyncService.syncUserProfile(user.id);

      return user;
    } on ApiException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

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

        final response = await ApiClientFactory.instance.get(
          '/api/v1/users/me?enriched=true',
        );
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
        throw AppException(
          message: 'No authentication token available',
          code: 1001,
          tag: 'AUTH',
        );
      }

      // Get user data with enriched contact information
      final response = await ApiClientFactory.instance.get(
        '/api/v1/users/me?enriched=true',
      );

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
    final instance = UnifiedUserService();
    return await instance.loadCurrentUser();
  }

  static Future<bool> isCurrentUserPublic() async {
    final instance = UnifiedUserService();
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
      final configService = ConfigService.instance;
      if (configService.isTestMode) {
        final response = await ApiClientFactory.instance.get(
          '/api/v1/users/contacts/registered',
        );

        final List<dynamic> usersJson = response is List ? response : [];
        final users = usersJson.map((json) => User.fromJson(json)).toList();

        return users;
      }

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

      final response = await ApiClientFactory.instance.post(
        '/api/v1/users/find-by-phones',
        body: {'phone_numbers': phoneNumbers},
      );

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
      final response = await ApiClientFactory.instance.get(
        '/api/v1/users/public/search',
        queryParams: {'q': query},
      );

      final List<dynamic> usersJson = response['users'] ?? [];
      final users = usersJson.map((json) => User.fromJson(json)).toList();

      return users;
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    try {
      final response = await ApiClientFactory.instance.get(
        '/api/v1/users/search',
        queryParams: {'q': query, 'limit': limit},
      );

      final List<dynamic> usersJson = response['users'] ?? [];
      final users = usersJson.map((json) => User.fromJson(json)).toList();

      return users;
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearCache() async {
    await Hive.box<UserHive>('users').clear();
  }

  static Map<String, dynamic> getCacheStats() {
    final hiveBox = Hive.box<UserHive>('users');
    return {
      'hive_users_count': hiveBox.length,
      'hive_box_open': hiveBox.isOpen,
    };
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

class UserService {
  static Future<User?> getCurrentUser() => UnifiedUserService.getCurrentUser();
  static Future<bool> isCurrentUserPublic() =>
      UnifiedUserService.isCurrentUserPublic();
  static Future<List<Contact>> getContacts() =>
      UnifiedUserService.getContacts();
  static void clearCache() => UnifiedUserService.clearCache();
}

class UserManagementService {
  static final UnifiedUserService _unified = UnifiedUserService();

  User? get currentUser => _unified.currentUser;
  bool get isLoggedIn => _unified.isLoggedIn;

  Future<User> createOrUpdateUser({
    required String firebaseUid,
    required String phoneNumber,
    String? email,
    String? fullName,
    String? instagramName,
    String? profilePicture,
    String? defaultTimezone,
    String? defaultCountryCode,
    String? defaultCity,
  }) => _unified.createOrUpdateUser(
    firebaseUid: firebaseUid,
    phoneNumber: phoneNumber,
    email: email,
    fullName: fullName,
    instagramName: instagramName,
    profilePicture: profilePicture,
    defaultTimezone: defaultTimezone,
    defaultCountryCode: defaultCountryCode,
    defaultCity: defaultCity,
  );

  Future<User?> loadCurrentUser({bool forceRefresh = false}) =>
      _unified.loadCurrentUser(forceRefresh: forceRefresh);
}
