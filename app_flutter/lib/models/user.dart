import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';
import 'user_hive.dart';

@immutable
class User {
  final int id;

  // Backend fields - Authentication
  final int? contactId; // FK to Contact table
  final String? username; // Display name for private users (phone auth)
  final String? instagramName; // Instagram username for public users
  final String authProvider; // 'phone' | 'instagram' (default: 'phone')
  final String authId; // Phone number or Instagram user ID (default: '')
  final bool isPublic;
  final bool isAdmin;
  final String? profilePicture;
  final DateTime? lastLogin;
  final DateTime?
  createdAt; // When user registered (nullable for backward compatibility)
  final DateTime?
  updatedAt; // Last profile update (nullable for backward compatibility)

  // Backend enriched fields (only when enriched=true)
  final String? contactName; // From Contact table
  final String? contactPhone; // From Contact table

  // Computed/helper fields
  final String?
  phoneNumber; // Helper: derived from authId if phone auth, or contactPhone
  final String? fullName; // Helper: same as contactName

  // Client-side fields (not synced to backend)
  final bool isActive; // Client-side state
  final bool isBanned; // Client-side (TODO: sync with backend AppBan)
  final DateTime? lastSeen; // Client-side presence
  final bool isOnline; // Client-side presence
  final String defaultTimezone; // Client preference
  final String defaultCountryCode; // Client preference
  final String defaultCity; // Client preference

  // Subscription statistics (only present in /users/{id}/subscriptions endpoint)
  final int? newEventsCount;
  final int? totalEventsCount;
  final int? subscribersCount;

  const User({
    required this.id,
    // Backend fields
    this.contactId,
    this.username,
    this.instagramName,
    this.authProvider = 'phone', // Default to phone auth
    this.authId = '', // Default to empty string
    required this.isPublic,
    this.isAdmin = false,
    this.profilePicture,
    this.lastLogin,
    this.createdAt, // Nullable for backward compatibility
    this.updatedAt, // Nullable for backward compatibility
    // Enriched fields
    this.contactName,
    this.contactPhone,
    // Helper fields
    this.phoneNumber,
    this.fullName,
    // Client-side fields
    this.isActive = true,
    this.isBanned = false,
    this.lastSeen,
    this.isOnline = false,
    this.defaultTimezone = 'Europe/Madrid',
    this.defaultCountryCode = 'ES',
    this.defaultCity = 'Madrid',
    // Stats
    this.newEventsCount,
    this.totalEventsCount,
    this.subscribersCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final bool isPublic = json['is_public'] as bool? ?? false;
    final String? backendUsername = json['username'] as String?;

    // Map backend "username" field to correct Flutter field based on isPublic
    final String? username = !isPublic
        ? backendUsername
        : null; // Private users
    final String? instagramName = isPublic
        ? backendUsername
        : null; // Public users

    // Contact fields (enriched response)
    final String? contactName = json['contact_name'] as String?;
    final String? contactPhone = json['contact_phone'] as String?;

    // Auth fields
    final String authProvider = json['auth_provider'] as String? ?? 'phone';
    final String authId = json['auth_id'] as String? ?? '';

    // Compute phoneNumber helper
    final String? phoneNumber = authProvider == 'phone' ? authId : contactPhone;

    return User(
      id: json['id'] as int,
      // Backend fields
      contactId: json['contact_id'] as int?,
      username: username,
      instagramName: instagramName,
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
      // Enriched fields
      contactName: contactName,
      contactPhone: contactPhone,
      // Helper fields
      phoneNumber: phoneNumber,
      fullName: contactName, // fullName is just contactName
      // Client-side fields (preserve if present, use defaults otherwise)
      isActive: json['is_active'] as bool? ?? true,
      isBanned: json['is_banned'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTimeUtils.parseAndNormalize(json['last_seen'])
          : null,
      isOnline: json['is_online'] as bool? ?? false,
      defaultTimezone: json['default_timezone'] as String? ?? 'Europe/Madrid',
      defaultCountryCode: json['default_country_code'] as String? ?? 'ES',
      defaultCity: json['default_city'] as String? ?? 'Madrid',
      // Stats
      newEventsCount: json['new_events_count'] as int?,
      totalEventsCount: json['total_events_count'] as int?,
      subscribersCount: json['subscribers_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    // Map Flutter fields back to backend format
    final String? backendUsername = isPublic ? instagramName : username;

    return {
      'id': id,
      // Backend fields
      'contact_id': contactId,
      'username': backendUsername, // Unified field in backend
      'auth_provider': authProvider,
      'auth_id': authId,
      'is_public': isPublic,
      'is_admin': isAdmin,
      'profile_picture': profilePicture,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Enriched fields (if present)
      if (contactName != null) 'contact_name': contactName,
      if (contactPhone != null) 'contact_phone': contactPhone,
      // Client-side fields (for local storage only)
      'is_active': isActive,
      'is_banned': isBanned,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      'is_online': isOnline,
      'default_timezone': defaultTimezone,
      'default_country_code': defaultCountryCode,
      'default_city': defaultCity,
      // Stats
      if (newEventsCount != null) 'new_events_count': newEventsCount,
      if (totalEventsCount != null) 'total_events_count': totalEventsCount,
      if (subscribersCount != null) 'subscribers_count': subscribersCount,
    };
  }

  String get displayName {
    // Public users (Instagram)
    if (isPublic) {
      if (instagramName?.isNotEmpty == true) return instagramName!;
      return 'Usuario #$id';
    }

    // Private users (Phone)
    if (username?.isNotEmpty == true) return username!;
    if (fullName?.isNotEmpty == true) return fullName!;
    return 'Usuario #$id';
  }

  String? get displaySubtitle {
    // Public users show @instagram
    if (isPublic && instagramName?.isNotEmpty == true) {
      return '@$instagramName';
    }

    // Private users show phone number
    if (!isPublic && phoneNumber?.isNotEmpty == true) {
      return phoneNumber;
    }

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
      registeredAt: createdAt,
    );
  }

  User copyWith({
    int? id,
    int? contactId,
    String? username,
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
    String? phoneNumber,
    String? fullName,
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
      username: username ?? this.username,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
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
