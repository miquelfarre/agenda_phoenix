import 'package:hive_ce/hive.dart';
import '../domain/user_contact.dart';

part 'user_contact_hive.g.dart';

@HiveType(typeId: 31)
class UserContactHive extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int ownerId;

  @HiveField(2)
  String contactName;

  @HiveField(3)
  String phoneNumber;

  @HiveField(4)
  int? registeredUserId;

  @HiveField(5)
  DateTime? lastSyncedAt;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  // Enriched registered user data
  @HiveField(8)
  int? registeredUserIdEnriched;

  @HiveField(9)
  String? registeredUserDisplayName;

  @HiveField(10)
  String? registeredUserProfilePictureUrl;

  UserContactHive({
    required this.id,
    required this.ownerId,
    required this.contactName,
    required this.phoneNumber,
    this.registeredUserId,
    this.lastSyncedAt,
    this.createdAt,
    this.updatedAt,
    this.registeredUserIdEnriched,
    this.registeredUserDisplayName,
    this.registeredUserProfilePictureUrl,
  });

  factory UserContactHive.fromUserContact(UserContact contact) {
    return UserContactHive(
      id: contact.id,
      ownerId: contact.ownerId,
      contactName: contact.contactName,
      phoneNumber: contact.phoneNumber,
      registeredUserId: contact.registeredUserId,
      lastSyncedAt: contact.lastSyncedAt,
      createdAt: contact.createdAt,
      updatedAt: contact.updatedAt,
      registeredUserIdEnriched: contact.registeredUser?.id,
      registeredUserDisplayName: contact.registeredUser?.displayName,
      registeredUserProfilePictureUrl:
          contact.registeredUser?.profilePictureUrl,
    );
  }

  UserContact toUserContact() {
    RegisteredUserInfo? registeredUser;
    if (registeredUserIdEnriched != null && registeredUserDisplayName != null) {
      registeredUser = RegisteredUserInfo(
        id: registeredUserIdEnriched!,
        displayName: registeredUserDisplayName!,
        profilePictureUrl: registeredUserProfilePictureUrl,
      );
    }

    return UserContact(
      id: id,
      ownerId: ownerId,
      contactName: contactName,
      phoneNumber: phoneNumber,
      registeredUserId: registeredUserId,
      lastSyncedAt: lastSyncedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      registeredUser: registeredUser,
    );
  }
}
