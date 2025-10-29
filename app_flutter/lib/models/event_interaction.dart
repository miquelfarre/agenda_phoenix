import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';
import 'user.dart';

@immutable
class EventInteraction {
  final int? id; // Primary key from database
  final int userId;
  final int eventId;
  final User? user;

  final int? inviterId;
  final User? inviter;
  final String? invitationMessage;
  final DateTime? invitedAt;

  final String? participationStatus;
  final DateTime? participationDecidedAt;
  final String? decisionMessage;
  final DateTime? postponeUntil;

  final bool isAttending;

  final bool isEventAdmin;

  final bool viewed;
  final DateTime? firstViewedAt;
  final DateTime? lastViewedAt;

  final String? personalNote;
  final DateTime? noteUpdatedAt;

  final bool favorited;
  final DateTime? favoritedAt;
  final bool hidden;
  final DateTime? hiddenAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const EventInteraction({
    this.id,
    required this.userId,
    required this.eventId,
    this.user,
    this.inviterId,
    this.inviter,
    this.invitationMessage,
    this.invitedAt,
    this.participationStatus,
    this.participationDecidedAt,
    this.decisionMessage,
    this.postponeUntil,
    this.isAttending = false,
    this.isEventAdmin = false,
    this.viewed = false,
    this.firstViewedAt,
    this.lastViewedAt,
    this.personalNote,
    this.noteUpdatedAt,
    this.favorited = false,
    this.favoritedAt,
    this.hidden = false,
    this.hiddenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasNote => personalNote != null && personalNote!.isNotEmpty;

  bool get wasInvited => inviterId != null;

  bool get isPending => participationStatus == 'pending';

  bool get isAccepted => participationStatus == 'accepted';

  bool get isDeclined => participationStatus == 'declined';

  bool get isPostponed => participationStatus == 'postponed';

  bool get hasDecided => isAccepted || isDeclined;

  bool get hasAnyInteraction =>
      wasInvited || viewed || hasNote || favorited || hidden;

  factory EventInteraction.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    final isAdmin = role == 'admin';
    final readAt = json['read_at'];
    final isViewed = readAt != null;

    return EventInteraction(
      id: json['id'],
      userId: json['user_id'],
      eventId: json['event_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      inviterId: json['invited_by_user_id'],
      inviter: json['inviter'] != null ? User.fromJson(json['inviter']) : null,
      invitationMessage: json['note'],
      invitedAt: json['created_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['created_at'])
          : null,
      participationStatus: json['status'],
      participationDecidedAt: json['updated_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : null,
      decisionMessage: json['rejection_message'],
      postponeUntil: null,
      isAttending: false,
      isEventAdmin: isAdmin,
      viewed: isViewed,
      firstViewedAt: readAt != null
          ? DateTimeUtils.parseAndNormalize(readAt)
          : null,
      lastViewedAt: readAt != null
          ? DateTimeUtils.parseAndNormalize(readAt)
          : null,
      personalNote: json['note'],
      noteUpdatedAt: json['updated_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : null,
      favorited: false,
      favoritedAt: null,
      hidden: false,
      hiddenAt: null,
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
      updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'event_id': eventId,
      'user': user?.toJson(),
      'inviter_id': inviterId,
      'inviter': inviter?.toJson(),
      'invitation_message': invitationMessage,
      'invited_at': invitedAt?.toIso8601String(),
      'participation_status': participationStatus,
      'participation_decided_at': participationDecidedAt?.toIso8601String(),
      'decision_message': decisionMessage,
      'postpone_until': postponeUntil?.toIso8601String(),
      'is_attending': isAttending,
      'is_event_admin': isEventAdmin,
      'viewed': viewed,
      'first_viewed_at': firstViewedAt?.toIso8601String(),
      'last_viewed_at': lastViewedAt?.toIso8601String(),
      'personal_note': personalNote,
      'note_updated_at': noteUpdatedAt?.toIso8601String(),
      'favorited': favorited,
      'favorited_at': favoritedAt?.toIso8601String(),
      'hidden': hidden,
      'hidden_at': hiddenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EventInteraction copyWith({
    int? id,
    int? userId,
    int? eventId,
    User? user,
    int? inviterId,
    User? inviter,
    String? invitationMessage,
    DateTime? invitedAt,
    String? participationStatus,
    DateTime? participationDecidedAt,
    String? decisionMessage,
    DateTime? postponeUntil,
    bool? isAttending,
    bool? isEventAdmin,
    bool? viewed,
    DateTime? firstViewedAt,
    DateTime? lastViewedAt,
    String? personalNote,
    DateTime? noteUpdatedAt,
    bool? favorited,
    DateTime? favoritedAt,
    bool? hidden,
    DateTime? hiddenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventInteraction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      user: user ?? this.user,
      inviterId: inviterId ?? this.inviterId,
      inviter: inviter ?? this.inviter,
      invitationMessage: invitationMessage ?? this.invitationMessage,
      invitedAt: invitedAt ?? this.invitedAt,
      participationStatus: participationStatus ?? this.participationStatus,
      participationDecidedAt:
          participationDecidedAt ?? this.participationDecidedAt,
      decisionMessage: decisionMessage ?? this.decisionMessage,
      postponeUntil: postponeUntil ?? this.postponeUntil,
      isAttending: isAttending ?? this.isAttending,
      isEventAdmin: isEventAdmin ?? this.isEventAdmin,
      viewed: viewed ?? this.viewed,
      firstViewedAt: firstViewedAt ?? this.firstViewedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      personalNote: personalNote ?? this.personalNote,
      noteUpdatedAt: noteUpdatedAt ?? this.noteUpdatedAt,
      favorited: favorited ?? this.favorited,
      favoritedAt: favoritedAt ?? this.favoritedAt,
      hidden: hidden ?? this.hidden,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EventInteraction(userId: $userId, eventId: $eventId, '
        'status: $participationStatus, viewed: $viewed, '
        'hasNote: $hasNote, favorited: $favorited, hidden: $hidden)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventInteraction &&
        other.id == id &&
        other.userId == userId &&
        other.eventId == eventId &&
        other.user == user &&
        other.inviterId == inviterId &&
        other.inviter == inviter &&
        other.invitationMessage == invitationMessage &&
        other.invitedAt == invitedAt &&
        other.participationStatus == participationStatus &&
        other.participationDecidedAt == participationDecidedAt &&
        other.decisionMessage == decisionMessage &&
        other.postponeUntil == postponeUntil &&
        other.isAttending == isAttending &&
        other.isEventAdmin == isEventAdmin &&
        other.viewed == viewed &&
        other.firstViewedAt == firstViewedAt &&
        other.lastViewedAt == lastViewedAt &&
        other.personalNote == personalNote &&
        other.noteUpdatedAt == noteUpdatedAt &&
        other.favorited == favorited &&
        other.favoritedAt == favoritedAt &&
        other.hidden == hidden &&
        other.hiddenAt == hiddenAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      userId,
      eventId,
      user,
      inviterId,
      inviter,
      invitationMessage,
      invitedAt,
      participationStatus,
      participationDecidedAt,
      decisionMessage,
      postponeUntil,
      isAttending,
      isEventAdmin,
      viewed,
      firstViewedAt,
      lastViewedAt,
      personalNote,
      noteUpdatedAt,
      favorited,
      favoritedAt,
      hidden,
      hiddenAt,
      createdAt,
      updatedAt,
    ]);
  }
}
