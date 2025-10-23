import '../models/city.dart';
import 'api_client.dart';

class CityService {
  static const String _baseUrl = '/api/v1/cities';

  static dynamic testApiService;

  static Future<City?> getCityInfo(String cityName) async {
    if (cityName.isEmpty) return null;

    try {
      final response = testApiService != null
          ? await testApiService.get('$_baseUrl/info/$cityName')
          : await ApiClientFactory.instance.get('$_baseUrl/info/$cityName');

      if (response != null && response['found'] == true) {
        return City(
          name: response['city'],
          countryCode: response['country_code'] ?? '',
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<City>> searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = testApiService != null
          ? await testApiService.get('$_baseUrl/search/$query')
          : await ApiClientFactory.instance.get('$_baseUrl/search/$query');

      if (response != null &&
          response['found'] == true &&
          response['matches'] != null) {
        return (response['matches'] as List)
            .map(
              (cityData) => City(
                name: cityData['city'] ?? cityData['name'] ?? '',
                countryCode: cityData['country_code'] ?? '',
              ),
            )
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
