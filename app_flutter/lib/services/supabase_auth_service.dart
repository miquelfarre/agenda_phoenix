import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:gotrue/gotrue.dart' as gotrue;
import 'config_service.dart';

class SupabaseAuthService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static bool get isLoggedIn {
    final configService = ConfigService.instance;
    if (configService.isTestMode) {
      return true;
    }
    try {
      return _supabase.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }

  static gotrue.User? get currentUser {
    final configService = ConfigService.instance;
    if (configService.isTestMode) {
      final testUserInfo = configService.testUserInfo;
      if (testUserInfo != null) {
        return _MockSupabaseUser(testUserInfo);
      }
    }
    try {
      return _supabase.auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getCurrentUserToken() async {
    final configService = ConfigService.instance;
    if (configService.isTestMode) {
      final testToken = configService.testToken;
      if (testToken != null) {
        return testToken;
      }
    }

    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        return session.accessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await ConfigService.instance.clearCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signInWithPhone({required String phoneNumber, required Function() onCodeSent, required Function(String error) onError}) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
      onCodeSent();
    } catch (e) {
      onError(e.toString());
    }
  }

  static Future<AuthResponse> verifyOTP({required String phoneNumber, required String token}) async {
    try {
      final response = await _supabase.auth.verifyOTP(type: OtpType.sms, phone: phoneNumber, token: token);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

class _MockSupabaseUser implements gotrue.User {
  final Map<String, dynamic> _userInfo;

  _MockSupabaseUser(this._userInfo);

  @override
  String get id => _userInfo['uid'] as String;

  @override
  String? get email => _userInfo['email'] as String?;

  @override
  String? get phone => _userInfo['phoneNumber'] as String?;

  @override
  String get createdAt => DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

  @override
  String get aud => 'authenticated';

  @override
  Map<String, dynamic> get appMetadata => {};

  @override
  String? get confirmedAt => DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

  @override
  String? get emailConfirmedAt => null;

  @override
  List<Factor>? get factors => null;

  @override
  List<UserIdentity>? get identities => null;

  @override
  String? get lastSignInAt => DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();

  @override
  String? get phoneConfirmedAt => DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

  @override
  String? get role => 'authenticated';

  @override
  String? get updatedAt => DateTime.now().toIso8601String();

  @override
  Map<String, dynamic>? get userMetadata => _userInfo;

  @override
  bool get isAnonymous => false;

  @override
  Map<String, dynamic> toJson() => _userInfo;

  @override
  String? get actionLink => null;

  @override
  String? get confirmationSentAt => null;

  @override
  String? get emailChangeSentAt => null;

  @override
  String? get invitedAt => null;

  @override
  String? get newEmail => null;

  String? get newPhone => null;

  String? get phoneSentAt => null;

  @override
  String? get recoverySentAt => null;
}
