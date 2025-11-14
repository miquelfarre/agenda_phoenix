import 'package:flutter/foundation.dart';
import '../../config/app_defaults.dart';

@immutable
class AppSettings {
  static const String kDefaultCountryCode = AppDefaults.defaultCountryCode;
  static const String kDefaultTimezone = AppDefaults.defaultTimezone;
  static const String kDefaultCity = AppDefaults.defaultCity;

  final String defaultCountryCode;
  final String defaultTimezone;
  final String defaultCity;

  const AppSettings({
    required this.defaultCountryCode,
    required this.defaultTimezone,
    required this.defaultCity,
  });

  const AppSettings.withDefaults()
    : defaultCountryCode = AppSettings.kDefaultCountryCode,
      defaultTimezone = AppSettings.kDefaultTimezone,
      defaultCity = AppSettings.kDefaultCity;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultCountryCode:
          json['default_country_code'] ?? AppSettings.kDefaultCountryCode,
      defaultTimezone: json['default_timezone'] ?? AppSettings.kDefaultTimezone,
      defaultCity: json['default_city'] ?? AppSettings.kDefaultCity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_country_code': defaultCountryCode,
      'default_timezone': defaultTimezone,
      'default_city': defaultCity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.defaultCountryCode == defaultCountryCode &&
        other.defaultTimezone == defaultTimezone &&
        other.defaultCity == defaultCity;
  }

  @override
  int get hashCode {
    return Object.hash(defaultCountryCode, defaultTimezone, defaultCity);
  }

  @override
  String toString() {
    return 'AppSettings(defaultCountryCode: $defaultCountryCode, defaultTimezone: $defaultTimezone, defaultCity: $defaultCity)';
  }
}
