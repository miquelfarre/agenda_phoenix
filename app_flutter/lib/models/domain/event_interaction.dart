import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';
import 'user.dart';

@immutable
class EventInteraction {
  final int? id;
  final int userId;
  final int eventId;
  final User? user;

  // Invitation fields
  final int? invitedByUserId;
  final User? inviter;
  final int? invitedViaGroupId;

  // Interaction metadata
  final String?
  interactionType; // 'invited', 'requested', 'joined', 'subscribed'
  final String? status; // 'pending', 'accepted', 'rejected'
  final String? role; // 'owner', 'admin', null (member)
  final String? cancellationNote;
  final bool isAttending;

  // Read tracking
  final DateTime? readAt;

  // Personal notes
  final String? personalNote;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventInteraction({
    this.id,
    required this.userId,
    required this.eventId,
    this.user,
    this.invitedByUserId,
    this.inviter,
    this.invitedViaGroupId,
    this.interactionType,
    this.status,
    this.role,
    this.cancellationNote,
    this.isAttending = false,
    this.readAt,
    this.personalNote,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed getters
  bool get hasNote => personalNote != null && personalNote!.isNotEmpty;
  bool get wasInvited =>
      invitedByUserId != null || interactionType == 'invited';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'rejected';
  bool get hasDecided => isAccepted || isDeclined;
  bool get hasAnyInteraction => wasInvited || readAt != null || hasNote;
  bool get isEventAdmin => role == 'admin';
  bool get isEventOwner => role == 'owner';
  bool get isNew =>
      readAt == null &&
      createdAt.isAfter(DateTime.now().subtract(Duration(hours: 24)));

  factory EventInteraction.fromJson(Map<String, dynamic> json) {
    return EventInteraction(
      id: json['id'],
      userId: json['user_id'],
      eventId: json['event_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      invitedByUserId: json['invited_by_user_id'],
      inviter: json['inviter'] != null ? User.fromJson(json['inviter']) : null,
      invitedViaGroupId: json['invited_via_group_id'],
      interactionType: json['interaction_type'],
      status: json['status'],
      role: json['role'],
      cancellationNote: json['cancellation_note'],
      isAttending: json['is_attending'] == true,
      readAt: json['read_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['read_at'])
          : null,
      personalNote: json['personal_note'],
      createdAt: json['created_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'event_id': eventId,
      if (user != null) 'user': user!.toJson(),
      if (invitedByUserId != null) 'invited_by_user_id': invitedByUserId,
      if (inviter != null) 'inviter': inviter!.toJson(),
      if (invitedViaGroupId != null) 'invited_via_group_id': invitedViaGroupId,
      if (interactionType != null) 'interaction_type': interactionType,
      if (status != null) 'status': status,
      if (role != null) 'role': role,
      if (cancellationNote != null) 'cancellation_note': cancellationNote,
      'is_attending': isAttending,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      if (personalNote != null) 'personal_note': personalNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'EventInteraction(userId: $userId, eventId: $eventId, '
        'type: $interactionType, status: $status, role: $role, '
        'isNew: $isNew, hasNote: $hasNote)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventInteraction &&
        other.id == id &&
        other.userId == userId &&
        other.eventId == eventId &&
        other.user == user &&
        other.invitedByUserId == invitedByUserId &&
        other.inviter == inviter &&
        other.invitedViaGroupId == invitedViaGroupId &&
        other.interactionType == interactionType &&
        other.status == status &&
        other.role == role &&
        other.cancellationNote == cancellationNote &&
        other.isAttending == isAttending &&
        other.readAt == readAt &&
        other.personalNote == personalNote &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      eventId,
      user,
      invitedByUserId,
      inviter,
      invitedViaGroupId,
      interactionType,
      status,
      role,
      cancellationNote,
      isAttending,
      readAt,
      personalNote,
      createdAt,
      updatedAt,
    );
  }
}
