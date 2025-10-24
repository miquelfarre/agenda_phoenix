import '../models/user.dart';
import 'api_client.dart';
import '../core/services/base_service.dart';
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

  Future<User?> loadCurrentUser({bool forceRefresh = false}) async {
    return await UnifiedUserService().loadCurrentUser(
      forceRefresh: forceRefresh,
    );
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
