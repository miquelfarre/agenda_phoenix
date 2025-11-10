import '../../models/ui/app_settings.dart';

abstract class ISettingsRepository {
  String get serviceName;

  Future<void> initialize();
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<AppSettings> createSettingsFromCity(String cityName);
  Future<AppSettings> validateAndFixSettings(AppSettings settings);
  Future<void> saveTimezoneToBackend({
    required String countryCode,
    required String timezone,
    required String city,
  });
  Future<void> clearLocalData();
  void dispose();
}
