import 'dart:async';
import 'package:contacts_service/contacts_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user.dart';
import '../models/user_hive.dart';
import '../utils/app_exceptions.dart';
import '../services/config_service.dart';
import 'api_client.dart';
import 'interfaces/isyncable.dart';
import 'sync_service.dart';

class UserService implements ISyncable, ICacheManager {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String get serviceName => 'UserService';

  String get hiveBoxName => 'users';

  SyncStatus _syncStatus = SyncStatus.idle;
  DateTime? _lastSyncTimestamp;
  final StreamController<SyncEvent> _syncEventController =
      StreamController<SyncEvent>.broadcast();

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

  late final hiveBox = Hive.box<UserHive>(hiveBoxName);

  int get currentUserId => ConfigService.instance.currentUserId;

  Future<void> updateLocalCache(int userId, UserHive userHive) async {
    await SyncService.syncUserProfile(userId);
  }

  static Future<User?> getCurrentUser() async {
    final userId = ConfigService.instance.currentUserId;
    if (userId == 0) return null;

    final userHive = Hive.box<UserHive>('users').get(userId);
    return userHive?.toUser();
  }

  static Future<bool> isCurrentUserPublic() async {
    final user = await getCurrentUser();
    return user?.isPublic ?? false;
  }

  static Future<User?> getUserById(int userId) async {
    final userHive = Hive.box<UserHive>('users').get(userId);
    return userHive?.toUser();
  }

  static Future<List<User>> searchPublicUsers(String query) async {
    try {
      final response = await ApiClientFactory.instance.get(
        '/api/v1/users/public/search',
        queryParams: {'q': query},
      );

      if (response is List) {
        final users = response
            .map((data) => User.fromJson(data as Map<String, dynamic>))
            .toList();
        return users;
      }
      return [];
    } on ApiException {
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<User> updateUser(
    int userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await ApiClientFactory.instance.put(
        '/api/v1/users/$userId',
        body: userData,
      );
      final updatedUser = User.fromJson(response);

      try {
        await SyncService.syncUserProfile(updatedUser.id);
      } catch (e) {
        // Ignore sync errors
      }

      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> blockUser(int targetUserId) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      await ApiClientFactory.instance.createUserBlock({
        'blocker_user_id': currentUserId,
        'blocked_user_id': targetUserId,
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> unblockUser(int targetUserId) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;

      final blocks = await ApiClientFactory.instance.fetchUserBlocks(
        blockerUserId: currentUserId,
        blockedUserId: targetUserId,
      );

      if (blocks.isEmpty) {
        throw ApiException('No block found for user $targetUserId');
      }

      final blockId = blocks.first['id'] as int;
      await ApiClientFactory.instance.deleteUserBlock(
        blockId,
        currentUserId: currentUserId,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<User>> getBlockedUsers(int userId) async {
    try {
      final blocks = await ApiClientFactory.instance.fetchUserBlocks(
        blockerUserId: userId,
      );

      final List<User> users = [];
      for (final block in blocks) {
        final blockedUserId = block['blocked_user_id'] as int;
        final userHive = Hive.box<UserHive>('users').get(blockedUserId);
        if (userHive != null) {
          users.add(userHive.toUser());
        }
      }

      return users;
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<User>> getContactUsers() async {
    try {
      final phoneNumbers = await _getDevicePhoneNumbers();
      if (phoneNumbers.isEmpty) {
        return [];
      }

      final response = await ApiClientFactory.instance.post(
        '/api/v1/users/find-by-phones',
        body: {'phone_numbers': phoneNumbers},
      );

      if (response is List) {
        final users = response
            .map((userData) => User.fromJson(userData))
            .toList();
        return users;
      }
      return [];
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

  static Future<void> syncDeviceUsers() async {
    return syncContactUsers();
  }

  static Future<List<String>> _getDevicePhoneNumbers() async {
    try {
      if (!(await Permission.contacts.status.isGranted)) {
        return [];
      }

      final contacts = await ContactsService.getContacts();
      final phoneNumbers = <String>{};

      for (final contact in contacts) {
        contact.phones?.forEach((phone) {
          final normalizedPhone = _normalizePhoneNumber(phone.value);
          if (normalizedPhone.isNotEmpty) {
            phoneNumbers.add(normalizedPhone);
          }
        });
      }

      return phoneNumbers.toList();
    } catch (e) {
      return [];
    }
  }

  static String _normalizePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return '';
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) return '';
    return digitsOnly;
  }

  @override
  SyncStatus get syncStatus => _syncStatus;

  @override
  DateTime? get lastSyncTimestamp => _lastSyncTimestamp;

  @override
  Stream<SyncEvent> get syncEventStream => _syncEventController.stream;

  @override
  Future<void> performFullSync() async {
    _emitSyncEvent(
      SyncEventType.started,
      message: 'Starting full user sync',
    );
    _syncStatus = SyncStatus.syncing;

    try {
      await SyncService.clearAllUsersCache();

      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw ApiException('No current user found for sync');
      }

      _emitSyncEvent(
        SyncEventType.progress,
        progress: 0.2,
        message: 'Fetching user contacts',
      );

      await _syncContactsInternal();

      _emitSyncEvent(
        SyncEventType.progress,
        progress: 0.6,
        message: 'Syncing user profile',
      );

      await _syncUserProfileInternal(currentUser.id);

      _lastSyncTimestamp = DateTime.now();
      _syncStatus = SyncStatus.completed;

      _emitSyncEvent(
        SyncEventType.completed,
        progress: 1.0,
        message: 'Full user sync completed successfully',
      );
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      _emitSyncEvent(
        SyncEventType.failed,
        error: e,
        message: 'Full user sync failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  @override
  Future<void> performIncrementalSync(DateTime lastSync) async {
    _emitSyncEvent(
      SyncEventType.started,
      message: 'Starting incremental user sync',
    );
    _syncStatus = SyncStatus.syncing;

    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw ApiException('No current user found for incremental sync');
      }

      _emitSyncEvent(
        SyncEventType.progress,
        progress: 0.3,
        message: 'Checking for profile updates',
      );

      await _syncUserProfileInternal(currentUser.id);

      _emitSyncEvent(
        SyncEventType.progress,
        progress: 0.7,
        message: 'Checking for contact updates',
      );

      await _syncContactsInternal();

      _lastSyncTimestamp = DateTime.now();
      _syncStatus = SyncStatus.completed;

      _emitSyncEvent(
        SyncEventType.completed,
        progress: 1.0,
        message: 'Incremental user sync completed',
      );
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      _emitSyncEvent(
        SyncEventType.failed,
        error: e,
        message: 'Incremental user sync failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  @override
  Future<void> performHashBasedSync(String currentHash) async {
    _emitSyncEvent(
      SyncEventType.started,
      message: 'Starting hash-based user sync',
    );
    _syncStatus = SyncStatus.syncing;

    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw ApiException('No current user found for hash-based sync');
      }

      _emitSyncEvent(
        SyncEventType.progress,
        progress: 0.2,
        message: 'Comparing user data hashes',
      );

      final localHash = await _getLocalUsersHash();

      if (currentHash == localHash) {
        _syncStatus = SyncStatus.completed;
        _emitSyncEvent(
          SyncEventType.completed,
          progress: 1.0,
          message: 'No user changes detected',
        );
        return;
      }

      _emitSyncEvent(
        SyncEventType.progress,
        progress: 0.4,
        message: 'Changes detected, performing incremental sync',
      );

      if (_lastSyncTimestamp != null) {
        await performIncrementalSync(_lastSyncTimestamp!);
      } else {
        await performFullSync();
      }
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      _emitSyncEvent(
        SyncEventType.failed,
        error: e,
        message: 'Hash-based user sync failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  @override
  Future<void> resolveConflict(dynamic local, dynamic remote) async {
    _emitSyncEvent(
      SyncEventType.started,
      message: 'Resolving user conflict',
    );
    _syncStatus = SyncStatus.conflict;

    try {
      final localUser = local is User ? local : User.fromJson(local);
      final remoteUser = remote is User ? remote : User.fromJson(remote);

      User resolvedUser;

      resolvedUser = User(
        id: remoteUser.id,
        fullName: remoteUser.fullName,
        instagramName: remoteUser.instagramName,
        email: remoteUser.email,
        phoneNumber: remoteUser.phoneNumber,
        profilePicture: remoteUser.profilePicture,
        isPublic: localUser.isPublic,
      );

      final userHive = _userToUserHive(resolvedUser);
      await updateLocalCache(resolvedUser.id, userHive);

      _syncStatus = SyncStatus.completed;
      _emitSyncEvent(
        SyncEventType.completed,
        message: 'User conflict resolved successfully',
      );
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      _emitSyncEvent(
        SyncEventType.failed,
        error: e,
        message: 'User conflict resolution failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  @override
  Future<List<T>> batchUploadEntities<T>(List<T> entities) async {
    _emitSyncEvent(
      SyncEventType.started,
      message: 'Starting batch upload of ${entities.length} user entities',
    );

    try {
      final users = entities.cast<User>();
      final uploadData = users
          .map(
            (user) => {
              'full_name': user.fullName,
              'instagram_name': user.instagramName,
              'email': user.email,
              'phone_number': user.phoneNumber,
              'is_public': user.isPublic,
            },
          )
          .toList();

      final response = await ApiClientFactory.instance.post(
        '/api/v1/users/batch',
        body: {'users': uploadData},
      );

      final uploadedUsers = (response['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();

      _emitSyncEvent(
        SyncEventType.completed,
        message: 'Batch user upload completed',
      );

      return uploadedUsers.cast<T>();
    } catch (e) {
      _emitSyncEvent(
        SyncEventType.failed,
        error: e,
        message: 'Batch user upload failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  @override
  Future<List<T>> batchDownloadEntities<T>(List<int> entityIds) async {
    _emitSyncEvent(
      SyncEventType.started,
      message:
          'Starting batch download of ${entityIds.length} user entities',
    );

    try {
      final response = await ApiClientFactory.instance.post(
        '/api/v1/users/batch-fetch',
        body: {'user_ids': entityIds},
      );

      final users = (response['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();

      for (final user in users) {
        final userHive = _userToUserHive(user);
        await updateLocalCache(user.id, userHive);
      }

      _emitSyncEvent(
        SyncEventType.completed,
        message: 'Batch user download completed',
      );

      return users.cast<T>();
    } catch (e) {
      _emitSyncEvent(
        SyncEventType.failed,
        error: e,
        message: 'Batch user download failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await hiveBox.clear();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearCacheForUser(int userId) async {
    try {
      await hiveBox.delete(userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final totalEntries = hiveBox.length;
      final cacheSize = await getCacheSize();

      return {
        'total_entries': totalEntries,
        'cache_size_bytes': cacheSize,
        'service_name': serviceName,
        'box_name': hiveBoxName,
      };
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> optimizeCache() async {
    try {
      final keysToDelete = <dynamic>[];

      for (final key in hiveBox.keys) {
        try {
          final userHive = hiveBox.get(key);
          if (userHive == null || userHive.id <= 0) {
            keysToDelete.add(key);
          }
        } catch (e) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await hiveBox.delete(key);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> validateCache() async {
    try {
      int invalidEntries = 0;

      for (final value in hiveBox.values) {
        try {
          if (value.id > 0 && value.fullName?.isNotEmpty == true) {
          } else {
            invalidEntries++;
          }
        } catch (_) {
          invalidEntries++;
        }
      }

      final isValid = invalidEntries == 0;

      return isValid;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      final hiveEntryCount = hiveBox.length;
      const averageUserEntrySize = 512;
      return hiveEntryCount * averageUserEntrySize;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _syncContactsInternal() async {
    try {
      final phoneNumbers = await _getDevicePhoneNumbers();
      if (phoneNumbers.isEmpty) {
        return;
      }

      const batchSize = 100;
      for (int i = 0; i < phoneNumbers.length; i += batchSize) {
        final batch = phoneNumbers.skip(i).take(batchSize).toList();

        try {
          final response = await ApiClientFactory.instance.post(
            '/api/v1/users/find-by-phones',
            body: {'phone_numbers': batch},
          );

          final foundUsers = (response['users'] as List)
              .map((json) => User.fromJson(json))
              .toList();

          for (final user in foundUsers) {
            await SyncService.syncUserProfile(user.id);
          }
        } catch (e) {
          // Ignore sync errors
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncUserProfileInternal(int userId) async {
    try {
      final response = await ApiClientFactory.instance.get(
        '/api/v1/users/$userId',
      );
      final user = User.fromJson(response);

      final userHive = _userToUserHive(user);
      await updateLocalCache(user.id, userHive);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _getLocalUsersHash() async {
    final users = hiveBox.values.toList();
    if (users.isEmpty) {
      return _computeHash([]);
    }

    final userData = users.map((hive) => _userHiveToJson(hive)).toList();
    return _computeHash(userData);
  }

  String _computeHash(List<Map<String, dynamic>> data) {
    final combined = data.map((e) => e.toString()).join('|');
    return combined.hashCode.toString();
  }

  Map<String, dynamic> _userHiveToJson(UserHive userHive) {
    return {
      'id': userHive.id,
      'full_name': userHive.fullName,
      'instagram_name': userHive.instagramName,

      'phone_number': userHive.phoneNumber,
      'is_public': userHive.isPublic,
    };
  }

  UserHive _userToUserHive(User user) {
    return UserHive(
      id: user.id,
      fullName: user.fullName,
      instagramName: user.instagramName,
      phoneNumber: user.phoneNumber,
      profilePicture: user.profilePicture,
      isPublic: user.isPublic,
    );
  }

  void _emitSyncEvent(
    SyncEventType type, {
    String? message,
    double? progress,
    dynamic error,
  }) {
    final event = SyncEvent(
      type: type,
      serviceName: serviceName,
      timestamp: DateTime.now(),
      message: message,
      progress: progress,
      error: error,
    );

    _syncEventController.add(event);
  }

  void dispose() {
    _syncEventController.close();
  }

  static Future<void> initializeService() async {}
}
