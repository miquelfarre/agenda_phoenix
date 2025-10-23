import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'config_service.dart';
import 'package:eventypop/l10n/app_localizations_en.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool get isLoggedIn {
    final configService = ConfigService.instance;
    if (configService.isTestMode) {
      return true;
    }
    try {
      return _auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  static User? get currentUser {
    final configService = ConfigService.instance;
    if (configService.isTestMode) {
      final testUserInfo = configService.testUserInfo;
      if (testUserInfo != null) {
        return _MockUser(testUserInfo);
      }
    }
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  static bool get _isIOSSimulator {
    if (!Platform.isIOS) {
      return false;
    }

    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
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
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdToken();
          return token;
        } catch (e) {
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signOut() async {
    try {
      await _auth.signOut();

      await ConfigService.instance.clearCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    if (_isIOSSimulator) {
      final l10n = AppLocalizationsEn();
      final simulatorError = FirebaseAuthException(
        code: 'simulator-not-supported',
        message: l10n.firebasePhoneAuthSimulatorError,
      );

      Future.microtask(() {
        verificationFailed(simulatorError);
      });
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          verificationCompleted(credential);
        },
        verificationFailed: (error) {
          verificationFailed(error);
        },
        codeSent: (verificationId, resendToken) {
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          codeAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        verificationFailed(e);
      } else {
        final l10n = AppLocalizationsEn();
        verificationFailed(
          FirebaseAuthException(
            code: 'unknown-error',
            message: '${l10n.unexpectedError} $e',
          ),
        );
      }
    }
  }

  static Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }
}

class _MockUser implements User {
  final Map<String, dynamic> _userInfo;

  _MockUser(this._userInfo);

  @override
  String get uid => _userInfo['uid'] as String;

  @override
  String? get email => _userInfo['email'] as String?;

  @override
  String? get displayName => _userInfo['displayName'] as String?;

  @override
  bool get emailVerified => _userInfo['emailVerified'] as bool? ?? false;

  @override
  bool get isAnonymous => _userInfo['isAnonymous'] as bool? ?? false;

  @override
  String? get photoURL => _userInfo['photoURL'] as String?;

  @override
  String? get phoneNumber => _userInfo['phoneNumber'] as String?;

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  UserMetadata get metadata => _MockUserMetadata();

  @override
  MultiFactor get multiFactor =>
      throw UnimplementedError('MultiFactor not implemented in test mode');

  @override
  Future<void> delete() =>
      throw UnimplementedError('delete not supported in test mode');

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    final configService = ConfigService.instance;
    return configService.testToken ?? 'mock-token';
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) =>
      throw UnimplementedError('getIdTokenResult not supported in test mode');

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) =>
      throw UnimplementedError('linkWithCredential not supported in test mode');

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) =>
      throw UnimplementedError('linkWithProvider not supported in test mode');

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
  ]) => throw UnimplementedError(
    'linkWithPhoneNumber not supported in test mode',
  );

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) =>
      throw UnimplementedError('linkWithPopup not supported in test mode');

  @override
  Future<void> linkWithRedirect(AuthProvider provider) =>
      throw UnimplementedError('linkWithRedirect not supported in test mode');

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) => throw UnimplementedError(
    'reauthenticateWithCredential not supported in test mode',
  );

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) =>
      throw UnimplementedError(
        'reauthenticateWithProvider not supported in test mode',
      );

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) =>
      throw UnimplementedError(
        'reauthenticateWithPopup not supported in test mode',
      );

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) =>
      throw UnimplementedError(
        'reauthenticateWithRedirect not supported in test mode',
      );

  @override
  Future<void> reload() async {}

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) => throw UnimplementedError(
    'sendEmailVerification not supported in test mode',
  );

  @override
  Future<User> unlink(String providerId) =>
      throw UnimplementedError('unlink not supported in test mode');

  @override
  Future<void> updateDisplayName(String? displayName) =>
      throw UnimplementedError('updateDisplayName not supported in test mode');

  Future<void> updateEmail(String newEmail) =>
      throw UnimplementedError('updateEmail not supported in test mode');

  @override
  Future<void> updatePassword(String newPassword) =>
      throw UnimplementedError('updatePassword not supported in test mode');

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) =>
      throw UnimplementedError('updatePhoneNumber not supported in test mode');

  @override
  Future<void> updatePhotoURL(String? photoURL) =>
      throw UnimplementedError('updatePhotoURL not supported in test mode');

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) =>
      throw UnimplementedError('updateProfile not supported in test mode');

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) => throw UnimplementedError(
    'verifyBeforeUpdateEmail not supported in test mode',
  );
}

class _MockUserMetadata implements UserMetadata {
  @override
  DateTime? get creationTime =>
      DateTime.now().subtract(const Duration(days: 30));

  @override
  DateTime? get lastSignInTime =>
      DateTime.now().subtract(const Duration(hours: 1));
}
