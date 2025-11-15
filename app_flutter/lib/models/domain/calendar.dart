import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';
import 'user.dart';

@immutable
class Calendar {
  final int id;
  final int ownerId;
  final User? owner;
  final List<User> members;
  final List<User> admins;
  final String name;
  final String? description;
  final bool deleteAssociatedEvents;
  final bool isPublic;
  final bool isDiscoverable;
  final String? shareHash;
  final String? category;
  final int subscriberCount;
  final DateTime? startDate; // For temporal calendars (e.g., "Olympics 2024")
  final DateTime? endDate; // For temporal calendars
  final DateTime createdAt;
  final DateTime updatedAt;
  // Access info for filtering
  final String? accessType; // 'owned', 'membership', 'subscription'
  final bool? ownerIsPublic; // True if owner is a public user

  const Calendar({
    required this.id,
    required this.ownerId,
    this.owner,
    this.members = const [],
    this.admins = const [],
    required this.name,
    this.description,
    this.deleteAssociatedEvents = false,
    this.isPublic = false,
    this.isDiscoverable = true,
    this.shareHash,
    this.category,
    this.subscriberCount = 0,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.accessType,
    this.ownerIsPublic,
  });

  factory Calendar.fromJson(Map<String, dynamic> json) {
    // Support both optimized response (with owner_name, member_count, admin_count)
    // and full response (with owner, members, admins objects)
    User? ownerObject;
    List<User> membersList = [];
    List<User> adminsList = [];

    // Parse owner - prefer full object if available, otherwise create minimal from owner_name
    if (json['owner'] != null) {
      ownerObject = User.fromJson(json['owner']);
    } else if (json['owner_name'] != null) {
      // Optimized response - create minimal owner object with just name
      ownerObject = User(
        id: json['owner_id'] as int,
        displayName: json['owner_name'] as String,
        authProvider: '',
        authId: '',
        isPublic: json['owner_is_public'] ?? false,
      );
    }

    // Parse members - prefer full list if available, otherwise empty list
    if (json['members'] != null && json['members'] is List) {
      membersList = (json['members'] as List)
          .map((m) => User.fromJson(m))
          .toList();
    }
    // Note: member_count is available but we don't use it for the members list

    // Parse admins - prefer full list if available, otherwise empty list
    if (json['admins'] != null && json['admins'] is List) {
      adminsList = (json['admins'] as List)
          .map((a) => User.fromJson(a))
          .toList();
    }
    // Note: admin_count is available but we don't use it for the admins list

    return Calendar(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      owner: ownerObject,
      members: membersList,
      admins: adminsList,
      name: json['name'] ?? '',
      description: json['description'],
      deleteAssociatedEvents: json['delete_associated_events'] ?? false,
      isPublic: json['is_public'] ?? false,
      isDiscoverable: json['is_discoverable'] ?? true,
      shareHash: json['share_hash'],
      category: json['category'],
      subscriberCount: json['subscriber_count'] ?? 0,
      startDate: json['start_date'] != null
          ? DateTimeUtils.parseAndNormalize(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTimeUtils.parseAndNormalize(json['end_date'])
          : null,
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
      updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
      accessType: json['access_type'],
      ownerIsPublic: json['owner_is_public'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'owner': owner?.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'admins': admins.map((a) => a.toJson()).toList(),
      'name': name,
      'description': description,
      'delete_associated_events': deleteAssociatedEvents,
      'is_public': isPublic,
      'is_discoverable': isDiscoverable,
      'share_hash': shareHash,
      'category': category,
      'subscriber_count': subscriberCount,
      if (startDate != null)
        'start_date': DateTimeUtils.toNormalizedIso8601String(startDate!),
      if (endDate != null)
        'end_date': DateTimeUtils.toNormalizedIso8601String(endDate!),
      'created_at': DateTimeUtils.toNormalizedIso8601String(createdAt),
      'updated_at': DateTimeUtils.toNormalizedIso8601String(updatedAt),
      if (accessType != null) 'access_type': accessType,
      if (ownerIsPublic != null) 'owner_is_public': ownerIsPublic,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Calendar && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Calendar(id: $id, name: $name, ownerId: $ownerId)';
  }

  bool get isValidName => name.trim().isNotEmpty && name.length <= 100;

  bool isOwnedBy(int userId) => ownerId == userId;

  bool isAdmin(int userId) {
    return ownerId == userId || admins.any((admin) => admin.id == userId);
  }

  bool isMember(int userId) {
    return members.any((member) => member.id == userId);
  }

  bool canManageCalendar(int userId) {
    return isAdmin(userId);
  }

  bool isOwner(int userId) {
    return ownerId == userId;
  }

  int get totalMemberCount {
    final uniqueIds = <int>{};
    if (owner != null) uniqueIds.add(owner!.id);
    for (var admin in admins) {
      uniqueIds.add(admin.id);
    }
    for (var member in members) {
      uniqueIds.add(member.id);
    }
    return uniqueIds.length;
  }
}
