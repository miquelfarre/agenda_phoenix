import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';
import '../persistence/user_hive.dart';

@immutable
class User {
  final int id;

  // NEW FIELDS - Backend sends these
  final String displayName;
  final String? instagramUsername;
  final String? profilePictureUrl;
  final String? phone;

  // Core fields
  final String authProvider;
  final String authId;
  final bool isPublic;
  final bool isAdmin;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Status fields
  final bool isActive;
  final bool isBanned;
  final DateTime? lastSeen;
  final bool isOnline;

  // Location fields
  final String defaultTimezone;
  final String defaultCountryCode;
  final String defaultCity;

  // Stats fields
  final int? newEventsCount;
  final int? totalEventsCount;
  final int? subscribersCount;

  const User({
    required this.id,
    required this.displayName,
    this.instagramUsername,
    this.profilePictureUrl,
    this.phone,
    this.authProvider = 'phone',
    this.authId = '',
    required this.isPublic,
    this.isAdmin = false,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isBanned = false,
    this.lastSeen,
    this.isOnline = false,
    this.defaultTimezone = 'Europe/Madrid',
    this.defaultCountryCode = 'ES',
    this.defaultCity = 'Madrid',
    this.newEventsCount,
    this.totalEventsCount,
    this.subscribersCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final bool isPublic = json['is_public'] as bool? ?? false;
    final String authProvider = json['auth_provider'] as String? ?? 'phone';
    final String authId = json['auth_id'] as String? ?? '';

    // Get displayName from backend (required field)
    final String displayName =
        json['display_name'] as String? ?? 'Usuario #${json['id']}';

    return User(
      id: json['id'] as int,
      displayName: displayName,
      instagramUsername: json['instagram_username'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      phone: json['phone'] as String?,
      authProvider: authProvider,
      authId: authId,
      isPublic: isPublic,
      isAdmin: json['is_admin'] as bool? ?? false,
      lastLogin: json['last_login'] != null
          ? DateTimeUtils.parseAndNormalize(json['last_login'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : null,
      isActive: json['is_active'] as bool? ?? true,
      isBanned: json['is_banned'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTimeUtils.parseAndNormalize(json['last_seen'])
          : null,
      isOnline: json['is_online'] as bool? ?? false,
      defaultTimezone: json['default_timezone'] as String? ?? 'Europe/Madrid',
      defaultCountryCode: json['default_country_code'] as String? ?? 'ES',
      defaultCity: json['default_city'] as String? ?? 'Madrid',
      newEventsCount: json['new_events_count'] as int?,
      totalEventsCount: json['total_events_count'] as int?,
      subscribersCount: json['subscribers_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      if (instagramUsername != null) 'instagram_username': instagramUsername,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      if (phone != null) 'phone': phone,
      'auth_provider': authProvider,
      'auth_id': authId,
      'is_public': isPublic,
      'is_admin': isAdmin,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'is_banned': isBanned,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      'is_online': isOnline,
      'default_timezone': defaultTimezone,
      'default_country_code': defaultCountryCode,
      'default_city': defaultCity,
      if (newEventsCount != null) 'new_events_count': newEventsCount,
      if (totalEventsCount != null) 'total_events_count': totalEventsCount,
      if (subscribersCount != null) 'subscribers_count': subscribersCount,
    };
  }

  String? get displaySubtitle {
    if (isPublic && instagramUsername?.isNotEmpty == true) {
      return '@$instagramUsername';
    }

    if (!isPublic && phone?.isNotEmpty == true) {
      return phone;
    }

    return null;
  }

  UserHive toUserHive() {
    return UserHive(
      id: id,
      instagramName: instagramUsername,
      name: displayName,
      isPublic: isPublic,
      phone: phone,
      profilePicture: profilePictureUrl,
      isBanned: isBanned,
      lastSeen: lastSeen,
      isOnline: isOnline,
      registeredAt: createdAt,
      authProvider: authProvider,
      authId: authId,
      contactId: null,
      isAdmin: isAdmin,
      username: displayName,
    );
  }

  User copyWith({
    int? id,
    String? displayName,
    String? instagramUsername,
    String? profilePictureUrl,
    String? phone,
    String? authProvider,
    String? authId,
    bool? isPublic,
    bool? isAdmin,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isBanned,
    DateTime? lastSeen,
    bool? isOnline,
    String? defaultTimezone,
    String? defaultCountryCode,
    String? defaultCity,
    int? newEventsCount,
    int? totalEventsCount,
    int? subscribersCount,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phone: phone ?? this.phone,
      authProvider: authProvider ?? this.authProvider,
      authId: authId ?? this.authId,
      isPublic: isPublic ?? this.isPublic,
      isAdmin: isAdmin ?? this.isAdmin,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      defaultTimezone: defaultTimezone ?? this.defaultTimezone,
      defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
      defaultCity: defaultCity ?? this.defaultCity,
      newEventsCount: newEventsCount ?? this.newEventsCount,
      totalEventsCount: totalEventsCount ?? this.totalEventsCount,
      subscribersCount: subscribersCount ?? this.subscribersCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.displayName == displayName &&
        other.isPublic == isPublic;
  }

  @override
  int get hashCode => Object.hash(id, displayName, isPublic);

  @override
  String toString() {
    return 'User(id: $id, displayName: $displayName, isPublic: $isPublic)';
  }
}
