import 'api_client.dart';
import '../models/user.dart' as app_user;
import '../core/mixins/singleton_mixin.dart';
import '../core/mixins/error_handling_mixin.dart';

class AuthService with SingletonMixin, ErrorHandlingMixin {
  AuthService._internal();

  factory AuthService() =>
      SingletonMixin.getInstance(() => AuthService._internal());

  @override
  String get serviceName => 'AuthService';

  Future<app_user.User> verifyTokenAndFetchUser(String idToken) async {
    return await withErrorHandling('verifyTokenAndFetchUser', () async {
      final response = await ApiClientFactory.instance.post(
        '/api/v1/firebase-auth/verify-token',
        body: {'id_token': idToken},
      );
      return app_user.User.fromJson(response);
    });
  }

  Future<String> sendSmsVerification(String phoneNumber) async {
    return await withErrorHandling('sendSmsVerification', () async {
      final response = await ApiClientFactory.instance.post(
        '/api/v1/phone-auth/send-sms',
        body: {'phone_number': phoneNumber},
      );
      return response['session_info'];
    });
  }

  Future<Map<String, dynamic>> verifySmsCode(
    String phoneNumber,
    String verificationCode,
    String sessionInfo,
  ) async {
    return await withErrorHandling('verifySmsCode', () async {
      final response = await ApiClientFactory.instance.post(
        '/api/v1/phone-auth/verify-sms',
        body: {
          'phone_number': phoneNumber,
          'verification_code': verificationCode,
          'session_info': sessionInfo,
        },
      );
      return response;
    });
  }

  Future<Map<String, dynamic>> refreshAccessToken() async {
    return await withErrorHandling('refreshAccessToken', () async {
      final response = await ApiClientFactory.instance.post(
        '/api/v1/phone-auth/refresh-token',
      );
      return response;
    });
  }

  Future<void> updateUserOnlineStatus(int userId, bool isOnline) async {
    await withErrorHandling('updateUserOnlineStatus', () async {
      await ApiClientFactory.instance.put(
        '/api/v1/users/$userId',
        body: {
          'is_online': isOnline,
          'last_seen': DateTime.now().toIso8601String(),
        },
      );
    }, shouldRethrow: false);
  }
}
