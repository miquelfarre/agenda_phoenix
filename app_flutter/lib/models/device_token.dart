import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

@immutable
class DeviceToken {
  final String id;
  final String userId;
  final String token;
  final String platform;
  final String? appVersion;
  final String? deviceModel;
  final String? osVersion;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsed;

  const DeviceToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    this.appVersion,
    this.deviceModel,
    this.osVersion,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsed,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      token: json['token'] ?? '',
      platform: json['platform'] ?? 'unknown',
      appVersion: json['app_version'],
      deviceModel: json['device_model'],
      osVersion: json['os_version'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
      updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
      lastUsed: json['last_used'] != null
          ? DateTimeUtils.parseAndNormalize(json['last_used'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'platform': platform,
      'app_version': appVersion,
      'device_model': deviceModel,
      'os_version': osVersion,
      'is_active': isActive,
      'created_at': DateTimeUtils.toNormalizedIso8601String(createdAt),
      'updated_at': DateTimeUtils.toNormalizedIso8601String(updatedAt),
      'last_used': lastUsed != null
          ? DateTimeUtils.toNormalizedIso8601String(lastUsed!)
          : null,
    };
  }

  DeviceToken copyWith({
    String? id,
    String? userId,
    String? token,
    String? platform,
    String? appVersion,
    String? deviceModel,
    String? osVersion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsed,
  }) {
    return DeviceToken(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceToken && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeviceToken(id: $id, platform: $platform, isActive: $isActive)';
  }

  bool get isValidToken => token.trim().isNotEmpty;
  bool get isValidPlatform =>
      ['ios', 'android', 'web'].contains(platform.toLowerCase());
  bool get isValid => isValidToken && isValidPlatform;

  bool belongsToUser(String userId) => this.userId == userId;
  bool get isIOS => platform.toLowerCase() == 'ios';
  bool get isAndroid => platform.toLowerCase() == 'android';
  bool get isWeb => platform.toLowerCase() == 'web';

  DeviceToken markAsUsed() {
    return copyWith(lastUsed: DateTime.now(), updatedAt: DateTime.now());
  }

  DeviceToken deactivate() {
    return copyWith(isActive: false, updatedAt: DateTime.now());
  }

  DeviceToken activate() {
    return copyWith(isActive: true, updatedAt: DateTime.now());
  }

  bool get isRecent {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return createdAt.isAfter(thirtyDaysAgo);
  }

  bool get isRecentlyUsed {
    if (lastUsed == null) return false;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return lastUsed!.isAfter(sevenDaysAgo);
  }

  int? get daysSinceLastUse {
    if (lastUsed == null) return null;
    return DateTime.now().difference(lastUsed!).inDays;
  }

  String get displayPlatform {
    switch (platform.toLowerCase()) {
      case 'ios':
        return 'iOS';
      case 'android':
        return 'Android';
      case 'web':
        return 'Web';
      default:
        return platform;
    }
  }

  String get displayInfo {
    final parts = <String>[displayPlatform];
    if (deviceModel != null) parts.add(deviceModel!);
    if (appVersion != null) parts.add('v$appVersion');
    return parts.join(' • ');
  }
}
