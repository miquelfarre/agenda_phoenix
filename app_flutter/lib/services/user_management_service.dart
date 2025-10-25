import '../models/user.dart';
import 'api_client.dart';
import '../core/services/base_service.dart';
import 'user_service.dart';

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

  User? get currentUser => UserService().currentUser;

  bool get isLoggedIn => UserService().isLoggedIn;

  Future<User?> loadCurrentUser({bool forceRefresh = false}) async {
    return await UserService().loadCurrentUser(
      forceRefresh: forceRefresh,
    );
  }

  Future<bool> isCurrentUserPublic() async {
    final user = await loadCurrentUser();
    return user?.isPublic ?? false;
  }

  Future<void> signOut() async {
    try {
      await UserService().logout();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFcmToken(String token) async {}
}
