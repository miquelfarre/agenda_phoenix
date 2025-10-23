import 'package:flutter/foundation.dart';

class TestModeValidator {
  TestModeValidator._();

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
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test-token-$userId-$timestamp';
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
