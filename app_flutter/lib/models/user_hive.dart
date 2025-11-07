import 'package:hive_ce/hive.dart';
import '../utils/datetime_utils.dart';
import 'user.dart';

part 'user_hive.g.dart';

@HiveType(typeId: 26)
class UserHive extends HiveObject {
  @HiveField(0)
  int id;
  @HiveField(1)
  String? instagramName;
  @HiveField(2)
  String? fullName;
  @HiveField(3)
  bool isPublic;
  @HiveField(4)
  String? phoneNumber;
  @HiveField(5)
  String? profilePicture;
  @HiveField(6)
  bool isBanned;
  @HiveField(7)
  DateTime? lastSeen;
  @HiveField(8)
  bool isOnline;
  @HiveField(10)
  DateTime? registeredAt;
  @HiveField(11)
  DateTime? updatedAt;
  @HiveField(12)
  int? newEventsCount;
  @HiveField(13)
  int? totalEventsCount;
  @HiveField(14)
  int? subscribersCount;
  @HiveField(15)
  String authProvider;
  @HiveField(16)
  String authId;
  @HiveField(17)
  int? contactId;
  @HiveField(18)
  bool isAdmin;
  @HiveField(19)
  String? username;

  UserHive({
    required this.id,
    this.instagramName,
    this.fullName,
    required this.isPublic,
    this.phoneNumber,
    this.profilePicture,
    this.isBanned = false,
    this.lastSeen,
    this.isOnline = false,
    this.registeredAt,
    DateTime? updatedAt,
    this.newEventsCount,
    this.totalEventsCount,
    this.subscribersCount,
    this.authProvider = 'phone',
    this.authId = '',
    this.contactId,
    this.isAdmin = false,
    this.username,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory UserHive.fromJson(Map<String, dynamic> json) => UserHive(
    id: json['id'],
    instagramName: json['instagram_name'],
    fullName: json['full_name'],
    isPublic: json['is_public'] ?? false,
    phoneNumber: json['phone_number'],
    profilePicture: json['profile_picture'],
    isBanned: json['is_banned'] ?? false,
    lastSeen: json['last_seen'] != null ? (json['last_seen'] is String ? DateTimeUtils.parseAndNormalize(json['last_seen']) : json['last_seen']) : null,
    isOnline: json['is_online'] ?? false,
    registeredAt: json['registered_at'] != null ? (json['registered_at'] is String ? DateTimeUtils.parseAndNormalize(json['registered_at']) : json['registered_at']) : null,
    newEventsCount: json['new_events_count'],
    totalEventsCount: json['total_events_count'],
    subscribersCount: json['subscribers_count'],
    authProvider: json['auth_provider'] ?? 'phone',
    authId: json['auth_id'] ?? '',
    contactId: json['contact_id'],
    isAdmin: json['is_admin'] ?? false,
    username: json['username'],
  );

  factory UserHive.fromUser(User user) => UserHive(
    id: user.id,
    instagramName: user.instagramName,
    fullName: user.fullName,
    isPublic: user.isPublic,
    phoneNumber: user.phoneNumber,
    profilePicture: user.profilePicture,
    isBanned: user.isBanned,
    lastSeen: user.lastSeen,
    isOnline: user.isOnline,
    registeredAt: user.createdAt,
    newEventsCount: user.newEventsCount,
    totalEventsCount: user.totalEventsCount,
    subscribersCount: user.subscribersCount,
    authProvider: user.authProvider,
    authId: user.authId,
    contactId: user.contactId,
    isAdmin: user.isAdmin,
    username: user.username,
  );

  Map<String, dynamic> toUserJson() => {
    'id': id,
    'instagram_name': instagramName,
    'full_name': fullName,
    'is_public': isPublic,
    'phone_number': phoneNumber,
    'profile_picture': profilePicture,
    'is_banned': isBanned,
    'last_seen': lastSeen?.toIso8601String(),
    'is_online': isOnline,
    'registered_at': registeredAt?.toIso8601String(),
    'auth_provider': authProvider,
    'auth_id': authId,
    'contact_id': contactId,
    'is_admin': isAdmin,
    'username': username,
  };

  User toUser() {
    return User(
      id: id,
      phoneNumber: phoneNumber,
      instagramName: instagramName,
      fullName: fullName,
      isPublic: isPublic,
      isActive: true,
      profilePicture: profilePicture,
      isBanned: isBanned,
      lastSeen: lastSeen,
      isOnline: isOnline,
      defaultTimezone: 'Europe/Madrid',
      defaultCountryCode: 'ES',
      defaultCity: 'Madrid',
      createdAt: registeredAt,
      newEventsCount: newEventsCount,
      totalEventsCount: totalEventsCount,
      subscribersCount: subscribersCount,
      authProvider: authProvider,
      authId: authId,
      contactId: contactId,
      isAdmin: isAdmin,
      username: username,
    );
  }
}
