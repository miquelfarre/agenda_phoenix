import 'package:hive_ce/hive.dart';

part 'user_timezone_config.g.dart';

@HiveType(typeId: 10)
class UserTimezoneConfig extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String defaultCity;

  @HiveField(2)
  final String defaultTimezone;

  @HiveField(3)
  final DateTime lastUpdated;

  UserTimezoneConfig({
    required this.userId,
    required this.defaultCity,
    required this.defaultTimezone,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'defaultCity': defaultCity,
    'defaultTimezone': defaultTimezone,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory UserTimezoneConfig.fromJson(Map<String, dynamic> json) {
    return UserTimezoneConfig(
      userId: json['userId'] as String,
      defaultCity: json['defaultCity'] as String,
      defaultTimezone: json['defaultTimezone'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  UserTimezoneConfig copyWith({
    String? userId,
    String? defaultCity,
    String? defaultTimezone,
    DateTime? lastUpdated,
  }) {
    return UserTimezoneConfig(
      userId: userId ?? this.userId,
      defaultCity: defaultCity ?? this.defaultCity,
      defaultTimezone: defaultTimezone ?? this.defaultTimezone,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() =>
      'UserTimezoneConfig($userId, $defaultCity, $defaultTimezone)';
}
