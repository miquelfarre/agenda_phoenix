import '../models/user.dart';
import 'api_client.dart';
import 'firebase_auth_service.dart';
import '../core/services/base_service.dart';
import '../utils/app_exceptions.dart';
import 'unified_user_service.dart';

class UserManagementService extends BaseService {
  static final UserManagementService _instance =
      UserManagementService._internal();
  factory UserManagementService() => _instance;
  UserManagementService._internal();

  @override
  String get serviceName => 'UserManagementService';

  @override
  Future<void> onInitialize() async {}

  @override
  dynamic getDefaultApiService() => ApiClientFactory.instance;

  User? get currentUser => UnifiedUserService().currentUser;

  bool get isLoggedIn => UnifiedUserService().isLoggedIn;

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
      final idToken = await FirebaseAuthService.getCurrentUserToken();
      if (idToken == null) {
        throw AppException(
          message: 'No Firebase token available',
          code: 1001,
          tag: 'AUTH',
        );
      }

      final response = await ApiClientFactory.instance.post(
        '/api/v1/firebase-auth/verify-token',
        body: {'id_token': idToken},
      );

      final user = User.fromJson(response);

      return user;
    } on ApiException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<User?> loadCurrentUser({bool forceRefresh = false}) async {
    return await UnifiedUserService().loadCurrentUser(
      forceRefresh: forceRefresh,
    );
  }

  Future<User> updateProfile({
    String? fullName,
    String? instagramName,
    String? email,
    String? profilePicture,
    String? defaultTimezone,
    String? defaultCountryCode,
    String? defaultCity,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AppException(
        message: 'No current user to update',
        code: 1002,
        tag: 'AUTH',
      );
    }

    try {
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['full_name'] = fullName;
      if (instagramName != null) updateData['instagram_name'] = instagramName;
      if (email != null) updateData['email'] = email;
      if (profilePicture != null) {
        updateData['profile_picture'] = profilePicture;
      }
      if (defaultTimezone != null) {
        updateData['default_timezone'] = defaultTimezone;
      }
      if (defaultCountryCode != null) {
        updateData['default_country_code'] = defaultCountryCode;
      }
      if (defaultCity != null) updateData['default_city'] = defaultCity;

      final timezoneUpdate = <String, dynamic>{};
      if (defaultTimezone != null) {
        timezoneUpdate['default_timezone'] = defaultTimezone;
      }
      if (defaultCountryCode != null) {
        timezoneUpdate['default_country_code'] = defaultCountryCode;
      }
      if (defaultCity != null) timezoneUpdate['default_city'] = defaultCity;

      User? updatedUser;
      if (timezoneUpdate.isNotEmpty) {
        final tzResp = await ApiClientFactory.instance.put(
          '/api/v1/users/${user.id}/timezone',
          body: timezoneUpdate,
        );
        updatedUser = User.fromJson(tzResp);
      }

      if (updateData.keys.any(
        (k) => [
          'full_name',
          'instagram_name',
          'email',
          'profile_picture',
        ].contains(k),
      )) {}

      if (updatedUser != null) {
        return updatedUser;
      }
      return user;
    } on ApiException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> isCurrentUserPublic() async {
    final user = await loadCurrentUser();
    return user?.isPublic ?? false;
  }

  Future<void> signOut() async {
    try {
      await UnifiedUserService().logout();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFcmToken(String token) async {}
}
