import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';
import 'user_hive.dart';

@immutable
class User {
  final int id;

  final int? contactId;
  final String? instagramName;
  final String authProvider;
  final String authId;
  final bool isPublic;
  final bool isAdmin;
  final String? profilePicture;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? contactName;
  final String? contactPhone;

  final String? phone;

  final bool isActive;
  final bool isBanned;
  final DateTime? lastSeen;
  final bool isOnline;
  final String defaultTimezone;
  final String defaultCountryCode;
  final String defaultCity;

  final int? newEventsCount;
  final int? totalEventsCount;
  final int? subscribersCount;

  const User({
    required this.id,
    this.contactId,
    this.instagramName,
    this.authProvider = 'phone',
    this.authId = '',
    required this.isPublic,
    this.isAdmin = false,
    this.profilePicture,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.contactName,
    this.contactPhone,
    this.phone,
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

    final String? backendPhone = json['phone'] as String?;
    final String? phone =
        backendPhone ?? (authProvider == 'phone' ? authId : json['contact_phone'] as String?);

    return User(
      id: json['id'] as int,
      contactId: json['contact_id'] as int?,
      instagramName: json['instagram_name'] as String?,
      authProvider: authProvider,
      authId: authId,
      isPublic: isPublic,
      isAdmin: json['is_admin'] as bool? ?? false,
      profilePicture: json['profile_picture'] as String?,
      lastLogin: json['last_login'] != null
          ? DateTimeUtils.parseAndNormalize(json['last_login'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : null,
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      phone: phone,
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
      'contact_id': contactId,
      if (instagramName != null) 'instagram_name': instagramName,
      if (phone != null) 'phone': phone,
      'auth_provider': authProvider,
      'auth_id': authId,
      'is_public': isPublic,
      'is_admin': isAdmin,
      'profile_picture': profilePicture,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (contactName != null) 'contact_name': contactName,
      if (contactPhone != null) 'contact_phone': contactPhone,
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

  String get displayName {
    if (isPublic) {
      if (instagramName?.isNotEmpty == true) return instagramName!;
      return 'Usuario #$id';
    }

    if (contactName?.isNotEmpty == true) return contactName!;
    return 'Usuario #$id';
  }

  String? get displaySubtitle {
    if (isPublic && instagramName?.isNotEmpty == true) {
      return '@$instagramName';
    }

    if (!isPublic && phone?.isNotEmpty == true) {
      return phone;
    }

    return null;
  }

  UserHive toUserHive() {
    return UserHive(
      id: id,
      instagramName: instagramName,
      name: contactName,
      isPublic: isPublic,
      phone: phone,
      profilePicture: profilePicture,
      isBanned: isBanned,
      lastSeen: lastSeen,
      isOnline: isOnline,
      registeredAt: createdAt,
      authProvider: authProvider,
      authId: authId,
      contactId: contactId,
      isAdmin: isAdmin,
      username: contactName,
    );
  }

  User copyWith({
    int? id,
    int? contactId,
    String? instagramName,
    String? authProvider,
    String? authId,
    bool? isPublic,
    bool? isAdmin,
    String? profilePicture,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contactName,
    String? contactPhone,
    String? phone,
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
      contactId: contactId ?? this.contactId,
      instagramName: instagramName ?? this.instagramName,
      authProvider: authProvider ?? this.authProvider,
      authId: authId ?? this.authId,
      isPublic: isPublic ?? this.isPublic,
      isAdmin: isAdmin ?? this.isAdmin,
      profilePicture: profilePicture ?? this.profilePicture,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      phone: phone ?? this.phone,
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
}
