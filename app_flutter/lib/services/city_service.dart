import '../models/city.dart';
import '../config/timezone_data.dart';

class CityService {
  static dynamic testApiService;

  static Future<City?> getCityInfo(String cityName) async {
    if (cityName.isEmpty) return null;

    try {
      final timezone = TimezoneData.getTimezoneFromCity(cityName);
      if (timezone == null) return null;

      final countryCode = _extractCountryCode(timezone);

      return City(name: cityName, countryCode: countryCode, timezone: timezone);
    } catch (e) {
      return null;
    }
  }

  static Future<List<City>> searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final lowerQuery = query.toLowerCase();
      final allTimezones = TimezoneData.getTimezoneList();

      final matches = allTimezones
          .where((tz) {
            final cityName = tz['city']?.toLowerCase() ?? '';
            return cityName.contains(lowerQuery);
          })
          .map((tz) {
            final timezone = tz['timezone'] ?? '';
            final countryCode = _extractCountryCode(timezone);

            return City(
              name: tz['city'] ?? '',
              countryCode: countryCode,
              timezone: timezone,
            );
          })
          .toList();

      return matches;
    } catch (e) {
      return [];
    }
  }

  static String _extractCountryCode(String timezone) {
    // Extract country code from timezone (e.g., "Europe/Madrid" -> "ES")
    // This is a simple mapping for common timezones
    const timezoneToCountry = {
      'Europe/Madrid': 'ES',
      'Europe/Barcelona': 'ES',
      'Europe/London': 'GB',
      'Europe/Paris': 'FR',
      'Europe/Berlin': 'DE',
      'Europe/Rome': 'IT',
      'Europe/Lisbon': 'PT',
      'America/New_York': 'US',
      'America/Los_Angeles': 'US',
      'America/Chicago': 'US',
      'America/Mexico_City': 'MX',
      'America/Sao_Paulo': 'BR',
      'America/Buenos_Aires': 'AR',
      'Asia/Tokyo': 'JP',
      'Asia/Shanghai': 'CN',
      'Asia/Hong_Kong': 'HK',
      'Asia/Singapore': 'SG',
      'Asia/Dubai': 'AE',
      'Australia/Sydney': 'AU',
      'Australia/Melbourne': 'AU',
      'Pacific/Auckland': 'NZ',
      'UTC': 'UTC',
    };

    return timezoneToCountry[timezone] ??
        timezone.split('/').first.toUpperCase();
  }
}
