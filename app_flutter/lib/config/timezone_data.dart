class TimezoneData {
  static const List<Map<String, String>> commonTimezones = [
    {'timezone': 'Europe/Madrid', 'city': 'Madrid'},
    {'timezone': 'Europe/Madrid', 'city': 'Barcelona'},
    {'timezone': 'Europe/London', 'city': 'London'},
    {'timezone': 'Europe/Paris', 'city': 'Paris'},
    {'timezone': 'Europe/Berlin', 'city': 'Berlin'},
    {'timezone': 'Europe/Rome', 'city': 'Rome'},
    {'timezone': 'Europe/Lisbon', 'city': 'Lisbon'},
    {'timezone': 'America/New_York', 'city': 'New York'},
    {'timezone': 'America/Los_Angeles', 'city': 'Los Angeles'},
    {'timezone': 'America/Chicago', 'city': 'Chicago'},
    {'timezone': 'America/Mexico_City', 'city': 'Mexico City'},
    {'timezone': 'America/Sao_Paulo', 'city': 'São Paulo'},
    {'timezone': 'America/Buenos_Aires', 'city': 'Buenos Aires'},
    {'timezone': 'Asia/Tokyo', 'city': 'Tokyo'},
    {'timezone': 'Asia/Shanghai', 'city': 'Shanghai'},
    {'timezone': 'Asia/Hong_Kong', 'city': 'Hong Kong'},
    {'timezone': 'Asia/Singapore', 'city': 'Singapore'},
    {'timezone': 'Asia/Dubai', 'city': 'Dubai'},
    {'timezone': 'Australia/Sydney', 'city': 'Sydney'},
    {'timezone': 'Australia/Melbourne', 'city': 'Melbourne'},
    {'timezone': 'Pacific/Auckland', 'city': 'Auckland'},
    {'timezone': 'UTC', 'city': 'UTC'},
  ];

  static List<Map<String, String>> getTimezoneList() => commonTimezones;

  static String? getCityFromTimezone(String timezone) {
    final entry = commonTimezones.firstWhere(
      (tz) => tz['timezone'] == timezone,
      orElse: () => {},
    );
    return entry['city'];
  }

  static String? getTimezoneFromCity(String city) {
    final entry = commonTimezones.firstWhere(
      (tz) => tz['city'] == city,
      orElse: () => {},
    );
    return entry['timezone'];
  }
}
