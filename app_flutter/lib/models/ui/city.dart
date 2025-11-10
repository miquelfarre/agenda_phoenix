class City {
  final String name;
  final String countryCode;
  final String? timezone;
  final int? population;
  final double? latitude;
  final double? longitude;
  final bool found;
  final String? currentTime;

  const City({
    required this.name,
    required this.countryCode,
    this.timezone,
    this.population,
    this.latitude,
    this.longitude,
    this.found = true,
    this.currentTime,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City &&
        other.name == name &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode => name.hashCode ^ countryCode.hashCode;

  @override
  String toString() =>
      'City(name: $name, countryCode: $countryCode, timezone: $timezone)';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'countryCode': countryCode,
      'timezone': timezone,
      'population': population,
      'latitude': latitude,
      'longitude': longitude,
      'found': found,
      'currentTime': currentTime,
    };
  }

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      name: map['name'] ?? '',
      countryCode: map['countryCode'] ?? '',
      timezone: map['timezone'],
      population: map['population'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      found: map['found'] ?? true,
      currentTime: map['currentTime'],
    );
  }

  factory City.fromApiResponse(Map<String, dynamic> json) {
    return City(
      name: json['city'] ?? '',
      countryCode: json['country_code'] ?? '',
      timezone: json['timezone'],
      population: json['population'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      found: json['found'] ?? false,
      currentTime: json['current_time'],
    );
  }
}
