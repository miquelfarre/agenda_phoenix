import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';
import 'user_hive.dart';

@immutable
class User {
  final int id;
  final String? firebaseUid;
  final String? phoneNumber;
  final String? instagramName;
  final String? email;
  final String? fullName;
  final bool isPublic;
  final bool isActive;
  final String? profilePicture;
  final bool isBanned;
  final DateTime? lastSeen;
  final bool isOnline;
  final String defaultTimezone;
  final String defaultCountryCode;
  final String defaultCity;
  final DateTime? createdAt;
  // Subscription statistics (only present in /users/{id}/subscriptions endpoint)
  final int? newEventsCount;
  final int? totalEventsCount;
  final int? subscribersCount;

  const User({
    required this.id,
    this.firebaseUid,
    this.phoneNumber,
    this.instagramName,
    this.email,
    this.fullName,
    required this.isPublic,
    this.isActive = true,
    this.profilePicture,
    this.isBanned = false,
    this.lastSeen,
    this.isOnline = false,
    this.defaultTimezone = 'Europe/Madrid',
    this.defaultCountryCode = 'ES',
    this.defaultCity = 'Madrid',
    this.createdAt,
    this.newEventsCount,
    this.totalEventsCount,
    this.subscribersCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final instagramName =
        json['instagram_name'] as String? ?? json['username'] as String?;
    final fullName =
        json['full_name'] as String? ?? json['contact_name'] as String?;

    return User(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      phoneNumber: json['phone_number'] ?? json['contact_phone'],
      instagramName: instagramName,
      email: json['email'],
      fullName: fullName,
      isPublic: json['is_public'] ?? false,
      isActive: json['is_active'] ?? true,
      profilePicture: json['profile_picture'] ?? json['profile_picture_url'],
      isBanned: json['is_banned'] ?? false,
      lastSeen: json['last_seen'] != null
          ? (json['last_seen'] is String
                ? DateTimeUtils.parseAndNormalize(json['last_seen'])
                : json['last_seen'])
          : null,
      isOnline: json['is_online'] ?? false,
      defaultTimezone: json['default_timezone'] ?? 'Europe/Madrid',
      defaultCountryCode: json['default_country_code'] ?? 'ES',
      defaultCity: json['default_city'] ?? 'Madrid',
      createdAt: json['created_at'] != null
          ? (json['created_at'] is String
                ? DateTimeUtils.parseAndNormalize(json['created_at'])
                : json['created_at'])
          : null,
      newEventsCount: json['new_events_count'] as int?,
      totalEventsCount: json['total_events_count'] as int?,
      subscribersCount: json['subscribers_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'phone_number': phoneNumber,
      'instagram_name': instagramName,
      'email': email,
      'full_name': fullName,
      'is_public': isPublic,
      'is_active': isActive,
      'profile_picture': profilePicture,
      'is_banned': isBanned,
      'last_seen': lastSeen?.toIso8601String(),
      'is_online': isOnline,
      'default_timezone': defaultTimezone,
      'default_country_code': defaultCountryCode,
      'default_city': defaultCity,
      'created_at': createdAt?.toIso8601String(),
      if (newEventsCount != null) 'new_events_count': newEventsCount,
      if (totalEventsCount != null) 'total_events_count': totalEventsCount,
      if (subscribersCount != null) 'subscribers_count': subscribersCount,
    };
  }

  String get displayName {
    if (fullName?.isNotEmpty == true) return fullName!;
    if (instagramName?.isNotEmpty == true) return instagramName!;
    return '';
  }

  String? get displaySubtitle {
    if (instagramName?.isNotEmpty == true) return '@$instagramName';
    return null;
  }

  UserHive toUserHive() {
    return UserHive(
      id: id,
      instagramName: instagramName,
      fullName: fullName,
      isPublic: isPublic,
      phoneNumber: phoneNumber,
      profilePicture: profilePicture,
      isBanned: isBanned,
      lastSeen: lastSeen,
      isOnline: isOnline,
      firebaseUid: firebaseUid,
      registeredAt: createdAt,
    );
  }
}
