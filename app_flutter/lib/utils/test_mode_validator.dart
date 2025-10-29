import 'package:flutter/foundation.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class TestModeValidator {
  TestModeValidator._();

  // JWT secret must match the one in .env and docker-compose.yml
  // MUST match the unified JWT secret used by backend/compose/Realtime
  static const String _jwtSecret =
      'super-secret-jwt-token-with-at-least-32-characters-long';

  static bool canEnableTestMode() {
    final violations = getSafetyViolations();
    return violations.isEmpty;
  }

  static List<String> getSafetyViolations() {
    final violations = <String>[];

    if (!kDebugMode) {
      violations.add('Not running in debug mode (kDebugMode = false)');
    }

    if (!isDebugEnvironment()) {
      violations.add('Production environment detected');
    }

    return violations;
  }

  static bool isDebugEnvironment() {
    return kDebugMode;
  }

  static bool isValidTestUserId(int userId) {
    return userId > 0 && userId < 1000000;
  }

  static String generateTestToken(int userId) {
    // Generate a valid JWT token for test mode
    // This matches the format expected by Supabase
    final jwt = JWT({
      'aud': 'authenticated',
      'role': 'authenticated',
      'sub': 'test-user-$userId',
      'user_id': userId,
      'email': 'test-user-$userId@eventypop.test',
      'iss': 'supabase',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          DateTime.now()
              .add(const Duration(hours: 24))
              .millisecondsSinceEpoch ~/
          1000,
    });

    final token = jwt.sign(SecretKey(_jwtSecret));
    if (kDebugMode) {
      print('🔐 [TestMode] Generated JWT token for user $userId');
      print(
        '🔐 [TestMode] Token (first 50 chars): ${token.substring(0, 50)}...',
      );
    }
    return token;
  }

  static Map<String, dynamic> createTestUserInfo(int userId) {
    return {
      'id': userId,
      'uid': 'test-user-$userId',
      'email': 'test-user-$userId@eventypop.test',
      'fullName': 'Test User $userId',
      'displayName': 'Test User $userId',
      'emailVerified': true,
      'isAnonymous': false,
      'photoURL': null,
      'phoneNumber':
          '+1555${userId.toString().padLeft(7, '0').substring(0, 7)}',
      'instagramName': 'testuser$userId',
      'isPublic': true,
      'isTestUser': true,
      'providerData': [],
      'bio': 'Test user for EventyPop development',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static void logTestModeStatus({required bool isEnabled, String? reason}) {}

  static TestModeValidationResult validateTestModeActivation({int? userId}) {
    final violations = getSafetyViolations();

    if (violations.isNotEmpty) {
      return TestModeValidationResult.failure(
        'Test mode not allowed',
        violations,
      );
    }

    if (userId != null && !isValidTestUserId(userId)) {
      return TestModeValidationResult.failure('Invalid test user ID', [
        'User ID must be between 1 and 999999, got $userId',
      ]);
    }

    return TestModeValidationResult.success();
  }
}

class TestModeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> violations;

  TestModeValidationResult._(this.isValid, this.errorMessage, this.violations);

  factory TestModeValidationResult.success() {
    return TestModeValidationResult._(true, null, []);
  }

  factory TestModeValidationResult.failure(
    String message,
    List<String> violations,
  ) {
    return TestModeValidationResult._(false, message, violations);
  }

  @override
  String toString() {
    if (isValid) return 'Valid';
    return 'Invalid: $errorMessage (${violations.join(', ')})';
  }
}
