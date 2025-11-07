import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';
import 'user.dart';

@immutable
class CalendarMembership {
  final int id;
  final int calendarId;
  final int userId;
  final String role;  // 'owner', 'admin', 'member'
  final String status;  // 'pending', 'accepted', 'rejected'
  final int? invitedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional enriched fields (only when enriched=true)
  final String? calendarName;
  final int? calendarOwnerId;
  final User? user;  // User object when enriched
  final User? inviter;  // Inviter user object when enriched

  const CalendarMembership({
    required this.id,
    required this.calendarId,
    required this.userId,
    required this.role,
    required this.status,
    this.invitedByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.calendarName,
    this.calendarOwnerId,
    this.user,
    this.inviter,
  });

  factory CalendarMembership.fromJson(Map<String, dynamic> json) {
    return CalendarMembership(
      id: json['id'] as int,
      calendarId: json['calendar_id'] as int,
      userId: json['user_id'] as int,
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'pending',
      invitedByUserId: json['invited_by_user_id'] as int?,
      createdAt: json['created_at'] is String
          ? DateTimeUtils.parseAndNormalize(json['created_at'])
          : json['created_at'] as DateTime,
      updatedAt: json['updated_at'] is String
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : json['updated_at'] as DateTime,
      calendarName: json['calendar_name'] as String?,
      calendarOwnerId: json['calendar_owner_id'] as int?,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      inviter: json['inviter'] != null ? User.fromJson(json['inviter'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'calendar_id': calendarId,
        'user_id': userId,
        'role': role,
        'status': status,
        'invited_by_user_id': invitedByUserId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (calendarName != null) 'calendar_name': calendarName,
        if (calendarOwnerId != null) 'calendar_owner_id': calendarOwnerId,
        if (user != null) 'user': user!.toJson(),
        if (inviter != null) 'inviter': inviter!.toJson(),
      };

  CalendarMembership copyWith({
    int? id,
    int? calendarId,
    int? userId,
    String? role,
    String? status,
    int? invitedByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? calendarName,
    int? calendarOwnerId,
    User? user,
    User? inviter,
  }) {
    return CalendarMembership(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      calendarName: calendarName ?? this.calendarName,
      calendarOwnerId: calendarOwnerId ?? this.calendarOwnerId,
      user: user ?? this.user,
      inviter: inviter ?? this.inviter,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
  bool get hasAdminPrivileges => isOwner || isAdmin;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarMembership &&
        other.id == id &&
        other.calendarId == calendarId &&
        other.userId == userId &&
        other.role == role &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, calendarId, userId, role, status);

  @override
  String toString() {
    return 'CalendarMembership(id: $id, calendarId: $calendarId, userId: $userId, role: $role, status: $status)';
  }
}
