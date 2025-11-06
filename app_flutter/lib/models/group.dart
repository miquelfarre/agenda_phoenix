import 'package:flutter/foundation.dart';
import 'user.dart';
import '../utils/datetime_utils.dart';

@immutable
class Group {
  final int id;
  final String name;
  final String description;
  final int ownerId;
  final User? owner;
  final List<User> members;
  final List<User> admins;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Group({required this.id, required this.name, required this.description, required this.ownerId, this.owner, this.members = const [], this.admins = const [], required this.createdAt, this.updatedAt});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      ownerId: json['owner_id'],
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      members: json['members'] != null ? (json['members'] as List).map((m) => User.fromJson(m)).toList() : [],
      admins: json['admins'] != null ? (json['admins'] as List).map((a) => User.fromJson(a)).toList() : [],
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTimeUtils.parseAndNormalize(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'owner': owner?.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'admins': admins.map((a) => a.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool isAdmin(int userId) {
    return ownerId == userId || admins.any((admin) => admin.id == userId);
  }

  bool isMember(int userId) {
    return members.any((member) => member.id == userId);
  }

  bool canManageGroup(int userId) {
    return isAdmin(userId);
  }

  bool isOwner(int userId) {
    return ownerId == userId;
  }

  // Deprecated: Use isOwner instead
  bool isCreator(int userId) {
    return isOwner(userId);
  }

  int get totalMemberCount {
    final uniqueIds = <int>{};
    uniqueIds.add(ownerId);
    uniqueIds.addAll(admins.map((a) => a.id));
    uniqueIds.addAll(members.map((m) => m.id));
    return uniqueIds.length;
  }

  String get memberCountText {
    final count = totalMemberCount;
    return count == 1 ? '1 miembro' : '$count miembros';
  }

  Group copyWith({int? id, String? name, String? description, int? ownerId, User? owner, List<User>? members, List<User>? admins, DateTime? createdAt, DateTime? updatedAt}) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Group(id: $id, name: $name, ownerId: $ownerId, memberCount: $totalMemberCount)';
  }
}

enum GroupState { empty, available, partiallyInvited, fullyInvited }

extension GroupInvitationState on Group {
  GroupState invitationState(Set<int> invitedUserIds) {
    if (members.isEmpty) return GroupState.empty;

    final invitedCount = members.where((member) => invitedUserIds.contains(member.id)).length;

    if (invitedCount == members.length) {
      return GroupState.fullyInvited;
    } else if (invitedCount > 0) {
      return GroupState.partiallyInvited;
    } else {
      return GroupState.available;
    }
  }

  int invitedMemberCount(Set<int> invitedUserIds) {
    return members.where((member) => invitedUserIds.contains(member.id)).length;
  }
}
