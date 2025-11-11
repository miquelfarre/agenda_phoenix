import 'package:shared_preferences/shared_preferences.dart';
import '../core/mixins/singleton_mixin.dart';
import '../core/mixins/error_handling_mixin.dart';
import '../utils/test_mode_validator.dart';

class ConfigService with SingletonMixin, ErrorHandlingMixin {
  ConfigService._internal();

  factory ConfigService() =>
      SingletonMixin.getInstance(() => ConfigService._internal());
  static ConfigService get instance => ConfigService();

  @override
  String get serviceName => 'ConfigService';

  int? _userId;
  bool enableContactEnrichment = true;
  bool _isTestMode = false;
  String? _testToken;
  Map<String, dynamic>? _testUserInfo;

  // Recurring instances always enabled (feature flag removed)
  final bool _useRecurringInstances = true;

  Future<void> initialize() async {
    await withErrorHandling('initialize', () async {
      final scriptUserId = _getUserIdFromEnvironment();

      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getInt('current_user_id');

      if (savedUserId != scriptUserId) {
        _userId = scriptUserId;
        await setCurrentUserId(_userId!);
      } else {
        _userId = savedUserId ?? scriptUserId;
      }
    });
  }

  Future<void> setCurrentUserId(int userId) async {
    await withErrorHandling('setCurrentUserId', () async {
      _userId = userId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', userId);

      if (_isTestMode) {
        _generateTestCredentials();
      }
    });
  }

  Future<void> clearCurrentUser() async {
    await withErrorHandling('clearCurrentUser', () async {
      _userId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
    });
  }

  int get currentUserId {
    if (_userId == null) {
      final userId = _getUserIdFromEnvironment();
      return userId;
    }
    return _userId!;
  }

  bool get isTestMode => _isTestMode;

  void enableTestMode() {
    final validationResult = TestModeValidator.validateTestModeActivation();

    if (!validationResult.isValid) {
      throw Exception(
        'Test mode not allowed: ${validationResult.violations.join(', ')}',
      );
    }

    _isTestMode = true;
    // Don't generate test credentials - let Supabase use anonymous auth
    // _generateTestCredentials();
    TestModeValidator.logTestModeStatus(isEnabled: true);
  }

  void disableTestMode() {
    _isTestMode = false;
    _testToken = null;
    _testUserInfo = null;
    TestModeValidator.logTestModeStatus(isEnabled: false);
  }

  void _generateTestCredentials() {
    final userId = currentUserId;
    _testToken = TestModeValidator.generateTestToken(userId);
    _testUserInfo = TestModeValidator.createTestUserInfo(userId);
  }

  String? get testToken {
    if (!_isTestMode) return null;

    if (_testToken == null) {
      _generateTestCredentials();
    }

    return _testToken;
  }

  Map<String, dynamic>? get testUserInfo {
    if (!_isTestMode) return null;

    if (_testUserInfo == null) {
      _generateTestCredentials();
    }

    return _testUserInfo;
  }

  bool get canEnableTestMode => TestModeValidator.canEnableTestMode();

  bool get useRecurringInstances => _useRecurringInstances;

  int _getUserIdFromEnvironment() {
    const String userIdString = String.fromEnvironment(
      'USER_ID',
      defaultValue: '8',
    );
    return int.tryParse(userIdString) ?? 8;
  }

  bool get hasUser => _userId != null;
}
