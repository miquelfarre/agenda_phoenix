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
  @HiveField(9)
  String? firebaseUid;
  @HiveField(10)
  DateTime? registeredAt;
  @HiveField(11)
  DateTime? updatedAt;

  UserHive({required this.id, this.instagramName, this.fullName, required this.isPublic, this.phoneNumber, this.profilePicture, this.isBanned = false, this.lastSeen, this.isOnline = false, this.firebaseUid, this.registeredAt, DateTime? updatedAt}) : updatedAt = updatedAt ?? DateTime.now();

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
    firebaseUid: json['firebase_uid'],
    registeredAt: json['registered_at'] != null ? (json['registered_at'] is String ? DateTimeUtils.parseAndNormalize(json['registered_at']) : json['registered_at']) : null,
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
    'firebase_uid': firebaseUid,
    'registered_at': registeredAt?.toIso8601String(),
  };

  User toUser() {
    return User(
      id: id,
      firebaseUid: firebaseUid,
      phoneNumber: phoneNumber,
      instagramName: instagramName,
      email: null,
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
    );
  }
}
