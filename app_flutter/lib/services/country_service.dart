import '../models/country.dart';

class CountryService {
  static final List<Country> _countries = _initializeCountries();
  static final Map<String, Country> _countryMap = {for (var country in _countries) country.code: country};

  static List<Country> _initializeCountries() {
    return [
      const Country(code: 'ES', name: 'España', nameEn: 'Spain', flag: '🇪🇸', dialCode: '+34', timezones: ['Europe/Madrid', 'Atlantic/Canary'], primaryTimezone: 'Europe/Madrid'),
      const Country(code: 'FR', name: 'Francia', nameEn: 'France', flag: '🇫🇷', dialCode: '+33', timezones: ['Europe/Paris'], primaryTimezone: 'Europe/Paris'),
      const Country(code: 'DE', name: 'Alemania', nameEn: 'Germany', flag: '🇩🇪', dialCode: '+49', timezones: ['Europe/Berlin'], primaryTimezone: 'Europe/Berlin'),
      const Country(code: 'IT', name: 'Italia', nameEn: 'Italy', flag: '🇮🇹', dialCode: '+39', timezones: ['Europe/Rome'], primaryTimezone: 'Europe/Rome'),
      const Country(code: 'GB', name: 'Reino Unido', nameEn: 'United Kingdom', flag: '🇬🇧', dialCode: '+44', timezones: ['Europe/London'], primaryTimezone: 'Europe/London'),
      const Country(code: 'PT', name: 'Portugal', nameEn: 'Portugal', flag: '🇵🇹', dialCode: '+351', timezones: ['Europe/Lisbon', 'Atlantic/Madeira', 'Atlantic/Azores'], primaryTimezone: 'Europe/Lisbon'),

      const Country(code: 'US', name: 'Estados Unidos', nameEn: 'United States', flag: '🇺🇸', dialCode: '+1', timezones: ['America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles', 'America/Anchorage', 'Pacific/Honolulu'], primaryTimezone: 'America/New_York'),
      const Country(code: 'CA', dialCode: '+1', name: 'Canadá', nameEn: 'Canada', flag: '🇨🇦', timezones: ['America/Toronto', 'America/Vancouver', 'America/Calgary', 'America/Winnipeg', 'America/Halifax'], primaryTimezone: 'America/Toronto'),
      const Country(code: 'MX', dialCode: '+52', name: 'México', nameEn: 'Mexico', flag: '🇲🇽', timezones: ['America/Mexico_City', 'America/Tijuana', 'America/Hermosillo'], primaryTimezone: 'America/Mexico_City'),

      const Country(code: 'BR', dialCode: '+55', name: 'Brasil', nameEn: 'Brazil', flag: '🇧🇷', timezones: ['America/Sao_Paulo', 'America/Manaus', 'America/Fortaleza', 'America/Noronha'], primaryTimezone: 'America/Sao_Paulo'),
      const Country(code: 'AR', dialCode: '+54', name: 'Argentina', nameEn: 'Argentina', flag: '🇦🇷', timezones: ['America/Argentina/Buenos_Aires'], primaryTimezone: 'America/Argentina/Buenos_Aires'),
      const Country(code: 'CO', dialCode: '+57', name: 'Colombia', nameEn: 'Colombia', flag: '🇨🇴', timezones: ['America/Bogota'], primaryTimezone: 'America/Bogota'),
      const Country(code: 'CL', dialCode: '+56', name: 'Chile', nameEn: 'Chile', flag: '🇨🇱', timezones: ['America/Santiago', 'Pacific/Easter'], primaryTimezone: 'America/Santiago'),

      const Country(code: 'JP', dialCode: '+81', name: 'Japón', nameEn: 'Japan', flag: '🇯🇵', timezones: ['Asia/Tokyo'], primaryTimezone: 'Asia/Tokyo'),
      const Country(code: 'CN', dialCode: '+86', name: 'China', nameEn: 'China', flag: '🇨🇳', timezones: ['Asia/Shanghai'], primaryTimezone: 'Asia/Shanghai'),
      const Country(code: 'IN', dialCode: '+91', name: 'India', nameEn: 'India', flag: '🇮🇳', timezones: ['Asia/Kolkata'], primaryTimezone: 'Asia/Kolkata'),
      const Country(code: 'KR', dialCode: '+82', name: 'Corea del Sur', nameEn: 'South Korea', flag: '🇰🇷', timezones: ['Asia/Seoul'], primaryTimezone: 'Asia/Seoul'),

      const Country(code: 'AU', dialCode: '+61', name: 'Australia', nameEn: 'Australia', flag: '🇦🇺', timezones: ['Australia/Sydney', 'Australia/Melbourne', 'Australia/Perth', 'Australia/Adelaide', 'Australia/Brisbane', 'Australia/Darwin'], primaryTimezone: 'Australia/Sydney'),
      const Country(code: 'NZ', dialCode: '+64', name: 'Nueva Zelanda', nameEn: 'New Zealand', flag: '🇳🇿', timezones: ['Pacific/Auckland', 'Pacific/Chatham'], primaryTimezone: 'Pacific/Auckland'),
    ];
  }

  static List<Country> getAllCountries() => List.unmodifiable(_countries);

  static Country? getCountryByCode(String code) {
    return _countryMap[code];
  }

  static List<Country> searchCountries(String query) {
    if (query.isEmpty) return getAllCountries();

    final lowerQuery = query.toLowerCase();
    return _countries.where((country) {
      return country.name.toLowerCase().contains(lowerQuery) || country.nameEn.toLowerCase().contains(lowerQuery) || country.code.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static List<Country> getCountriesByRegion(String region) {
    switch (region.toLowerCase()) {
      case 'europe':
      case 'europa':
        return _countries.where((c) => ['ES', 'FR', 'DE', 'IT', 'GB', 'PT'].contains(c.code)).toList();
      case 'america':
      case 'américa':
        return _countries.where((c) => ['US', 'CA', 'MX', 'BR', 'AR', 'CO', 'CL'].contains(c.code)).toList();
      case 'asia':
        return _countries.where((c) => ['JP', 'CN', 'IN', 'KR'].contains(c.code)).toList();
      case 'oceania':
        return _countries.where((c) => ['AU', 'NZ'].contains(c.code)).toList();
      default:
        return getAllCountries();
    }
  }

  static String? getPrimaryTimezone(String countryCode) {
    return getCountryByCode(countryCode)?.primaryTimezone;
  }
}
