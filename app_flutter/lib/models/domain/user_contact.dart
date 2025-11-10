// UserContact model - Represents a contact from the user's device
//
// Each user has their own contact list (from their phone).
// When a contact registers in the app, the relation is created with registered_user_id.
//
// Example:
// - Sonia has Juan (+34666) in her phone → UserContact(owner_id=sonia.id, phone_number="+34666", contact_name="Juan")
// - Juan registers → UserContact.registered_user_id is updated to juan.id
// - Miquel also has Juan → UserContact(owner_id=miquel.id, phone_number="+34666", contact_name="Juanito")
// - Both point to the same registered_user_id

class UserContact {
  final int id;
  final int ownerId;
  final String contactName;
  final String phoneNumber;
  final int? registeredUserId;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional enriched data from registered user
  final RegisteredUserInfo? registeredUser;

  bool get isRegistered => registeredUserId != null;

  UserContact({
    required this.id,
    required this.ownerId,
    required this.contactName,
    required this.phoneNumber,
    this.registeredUserId,
    this.lastSyncedAt,
    this.createdAt,
    this.updatedAt,
    this.registeredUser,
  });

  factory UserContact.fromJson(Map<String, dynamic> json) {
    return UserContact(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      contactName: json['contact_name'] as String,
      phoneNumber: json['phone_number'] as String,
      registeredUserId: json['registered_user_id'] as int?,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      registeredUser: json['registered_user'] != null
          ? RegisteredUserInfo.fromJson(
              json['registered_user'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'registered_user_id': registeredUserId,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (registeredUser != null) 'registered_user': registeredUser!.toJson(),
    };
  }

  UserContact copyWith({
    int? id,
    int? ownerId,
    String? contactName,
    String? phoneNumber,
    int? registeredUserId,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    RegisteredUserInfo? registeredUser,
  }) {
    return UserContact(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      registeredUserId: registeredUserId ?? this.registeredUserId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      registeredUser: registeredUser ?? this.registeredUser,
    );
  }
}

/// Registered user basic info (enriched data)
class RegisteredUserInfo {
  final int id;
  final String displayName;
  final String? profilePictureUrl;

  RegisteredUserInfo({
    required this.id,
    required this.displayName,
    this.profilePictureUrl,
  });

  factory RegisteredUserInfo.fromJson(Map<String, dynamic> json) {
    return RegisteredUserInfo(
      id: json['id'] as int,
      displayName: json['display_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'profile_picture_url': profilePictureUrl,
    };
  }
}

/// Contact sync request
class ContactSyncRequest {
  final List<ContactInfo> contacts;

  ContactSyncRequest({required this.contacts});

  Map<String, dynamic> toJson() {
    return {'contacts': contacts.map((c) => c.toJson()).toList()};
  }
}

/// Contact info from device
class ContactInfo {
  final String contactName;
  final String phoneNumber;

  ContactInfo({required this.contactName, required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'contact_name': contactName, 'phone_number': phoneNumber};
  }
}

/// Contact sync response
class ContactSyncResponse {
  final int syncedCount;
  final int registeredCount;
  final List<RegisteredContactInfo> registeredContacts;

  ContactSyncResponse({
    required this.syncedCount,
    required this.registeredCount,
    required this.registeredContacts,
  });

  factory ContactSyncResponse.fromJson(Map<String, dynamic> json) {
    return ContactSyncResponse(
      syncedCount: json['synced_count'] as int,
      registeredCount: json['registered_count'] as int,
      registeredContacts: (json['registered_contacts'] as List<dynamic>)
          .map(
            (item) =>
                RegisteredContactInfo.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

/// Registered contact info (returned after sync)
class RegisteredContactInfo {
  final int userId;
  final String displayName;
  final String phone;
  final String? profilePictureUrl;
  final String contactName;

  RegisteredContactInfo({
    required this.userId,
    required this.displayName,
    required this.phone,
    this.profilePictureUrl,
    required this.contactName,
  });

  factory RegisteredContactInfo.fromJson(Map<String, dynamic> json) {
    return RegisteredContactInfo(
      userId: json['user_id'] as int,
      displayName: json['display_name'] as String,
      phone: json['phone'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      contactName: json['contact_name'] as String,
    );
  }
}
