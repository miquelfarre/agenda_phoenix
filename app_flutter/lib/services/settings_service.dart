import '../models/ui/app_settings.dart';
import 'api_client.dart';
import '../core/mixins/error_handling_mixin.dart';
import '../core/mixins/singleton_mixin.dart';
import '../core/utils/validation_utils.dart';

class SettingsService with SingletonMixin, ErrorHandlingMixin {
  SettingsService._internal();

  factory SettingsService() =>
      SingletonMixin.getInstance(() => SettingsService._internal());

  @override
  String get serviceName => 'SettingsService';

  static dynamic testApiService;

  Future<void> saveTimezoneToBackend(AppSettings settings) async {
    await withErrorHandling(
      'saveTimezoneToBackend',
      () async {
        final userId = ValidationUtils.requireCurrentUser();

        final api = testApiService ?? ApiClientFactory.instance;
        await api.put(
          '/api/v1/users/$userId',
          body: {
            'default_country_code': settings.defaultCountryCode,
            'default_timezone': settings.defaultTimezone,
            'default_city': settings.defaultCity,
          },
        );
      },
      shouldRethrow: false,
      customMessage: 'SettingsService.saveTimezoneToBackend failed',
    );
  }

  Future<AppSettings?> fetchRemoteSettings() async {
    return await withErrorHandling(
      'fetchRemoteSettings',
      () async {
        final userId = ValidationUtils.requireCurrentUser();

        final api = testApiService ?? ApiClientFactory.instance;
        final userData = await api.get('/api/v1/users/$userId');

        return AppSettings(
          defaultCountryCode: userData['default_country_code'] ?? 'ES',
          defaultTimezone: userData['default_timezone'] ?? 'Europe/Madrid',
          defaultCity: userData['default_city'] ?? 'Madrid',
        );
      },
      shouldRethrow: false,
      defaultValue: null,
      customMessage: 'SettingsService.fetchRemoteSettings failed',
    );
  }
}
