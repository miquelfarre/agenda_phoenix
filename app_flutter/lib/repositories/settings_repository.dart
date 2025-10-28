import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../services/city_service.dart';
import '../services/settings_service.dart';
import '../utils/error_handler.dart';
import '../core/mixins/singleton_mixin.dart';
import '../core/mixins/error_handling_mixin.dart';

class SettingsRepository with SingletonMixin, ErrorHandlingMixin {
  SettingsRepository._internal();

  factory SettingsRepository() => SingletonMixin.getInstance(() => SettingsRepository._internal());

  @override
  String get serviceName => 'SettingsRepository';

  Future<void> initialize() async {}

  static const String _defaultCountryCodeKey = 'default_country_code';
  static const String _defaultTimezoneKey = 'default_timezone';
  static const String _defaultCityKey = 'default_city';

  Future<AppSettings> loadSettings() async {
    return await withErrorHandling('loadSettings', () async {
      final localSettings = await _loadLocalSettings();

      _syncWithBackgroundInBackground(localSettings);

      return localSettings;
    });
  }

  Future<void> saveSettings(AppSettings settings) async {
    await withErrorHandling('saveSettings', () async {
      await _saveLocalSettings(settings);

      await _saveToBackend(settings);
    });
  }

  Future<AppSettings> createSettingsFromCity(String cityName) async {
    try {
      final cityInfo = await CityService.getCityInfo(cityName);

      if (cityInfo != null) {
        final settings = AppSettings(defaultCountryCode: cityInfo.countryCode, defaultTimezone: cityInfo.timezone ?? AppSettings.kDefaultTimezone, defaultCity: cityInfo.name);

        return settings;
      }
    } catch (e) {
      // Ignore errors
    }

    return AppSettings.withDefaults();
  }

  Future<AppSettings> validateAndFixSettings(AppSettings settings) async {
    try {
      if (settings.defaultCity.isEmpty || settings.defaultCity == AppSettings.kDefaultCity) {
        return settings;
      }

      final cityInfo = await CityService.getCityInfo(settings.defaultCity);

      if (cityInfo != null && (cityInfo.timezone != settings.defaultTimezone || cityInfo.countryCode != settings.defaultCountryCode)) {
        final correctedSettings = settings.copyWith(defaultCountryCode: cityInfo.countryCode, defaultTimezone: cityInfo.timezone ?? settings.defaultTimezone);

        await _saveLocalSettings(correctedSettings);

        return correctedSettings;
      }

      return settings;
    } catch (e) {
      return settings;
    }
  }

  Future<AppSettings> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final defaultCountryCode = prefs.getString(_defaultCountryCodeKey) ?? AppSettings.kDefaultCountryCode;
    final defaultTimezone = prefs.getString(_defaultTimezoneKey) ?? AppSettings.kDefaultTimezone;
    final defaultCity = prefs.getString(_defaultCityKey) ?? AppSettings.kDefaultCity;

    return AppSettings(defaultCountryCode: defaultCountryCode, defaultTimezone: defaultTimezone, defaultCity: defaultCity);
  }

  Future<void> _saveLocalSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([prefs.setString(_defaultCountryCodeKey, settings.defaultCountryCode), prefs.setString(_defaultTimezoneKey, settings.defaultTimezone), prefs.setString(_defaultCityKey, settings.defaultCity)]);
  }

  Future<void> _saveToBackend(AppSettings settings) async {
    try {
      final settingsService = SettingsService();
      await settingsService.saveTimezoneToBackend(settings);
    } catch (e) {
      // Ignore errors
    }
  }

  void _syncWithBackgroundInBackground(AppSettings localSettings) {
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();

        if (!prefs.containsKey(_defaultCountryCodeKey)) {
          final settingsService = SettingsService();
          final remoteSettings = await settingsService.fetchRemoteSettings();

          if (remoteSettings != null) {
            await _saveLocalSettings(remoteSettings);
          }
        }
      } catch (e) {
        // Ignore errors
      }
    }();
  }

  Future<void> saveTimezoneToBackend({required String countryCode, required String timezone, required String city}) async {
    try {
      final settings = AppSettings(defaultCountryCode: countryCode, defaultTimezone: timezone, defaultCity: city);
      await _saveToBackend(settings);
    } catch (e) {
      throw ErrorHandler.handleServiceError(e, operation: 'Save timezone to backend', tag: 'SettingsRepository');
    }
  }

  Future<void> clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([prefs.remove(_defaultCountryCodeKey), prefs.remove(_defaultTimezoneKey), prefs.remove(_defaultCityKey)]);
    } catch (e) {
      throw ErrorHandler.handleServiceError(e, operation: 'Clear local settings data', tag: 'SettingsRepository');
    }
  }
}
