library;

import 'event.dart';
import 'user.dart';
import 'event_interaction.dart';

class EventDetailComposite {
  final Event event;
  final PersonalNoteDetail? personalNote;
  final EventInteraction? userInvitation;
  final List<InvitationWithUserDetail> otherInvitations;
  final List<EventSimpleForComposite> upcomingEvents;
  final List<User> attendees;
  final String checksum;

  EventDetailComposite({
    required this.event,
    this.personalNote,
    this.userInvitation,
    required this.otherInvitations,
    required this.upcomingEvents,
    required this.attendees,
    required this.checksum,
  });

  factory EventDetailComposite.fromJson(Map<String, dynamic> json) {
    return EventDetailComposite(
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      personalNote: json['personal_note'] != null
          ? PersonalNoteDetail.fromJson(
              json['personal_note'] as Map<String, dynamic>,
            )
          : null,
      userInvitation: json['user_invitation'] != null
          ? EventInteraction.fromJson(
              json['user_invitation'] as Map<String, dynamic>,
            )
          : null,
      otherInvitations: (json['other_invitations'] as List? ?? [])
          .map(
            (e) => InvitationWithUserDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      upcomingEvents: (json['upcoming_events'] as List? ?? [])
          .map(
            (e) => EventSimpleForComposite.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      attendees: (json['attendees'] as List? ?? [])
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'personal_note': personalNote?.toJson(),
      'user_invitation': userInvitation?.toJson(),
      'other_invitations': otherInvitations.map((e) => e.toJson()).toList(),
      'upcoming_events': upcomingEvents.map((e) => e.toJson()).toList(),
      'attendees': attendees.map((e) => e.toJson()).toList(),
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}

class PersonalNoteDetail {
  final String note;
  final DateTime updatedAt;

  PersonalNoteDetail({required this.note, required this.updatedAt});

  factory PersonalNoteDetail.fromJson(Map<String, dynamic> json) {
    return PersonalNoteDetail(
      note: json['note'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'note': note, 'updated_at': updatedAt.toIso8601String()};
  }
}

class InvitationWithUserDetail {
  final int id;
  final String status;
  final User invitedUser;
  final int inviterId;
  final DateTime createdAt;
  final String? decisionMessage;
  final DateTime? decisionAt;

  InvitationWithUserDetail({
    required this.id,
    required this.status,
    required this.invitedUser,
    required this.inviterId,
    required this.createdAt,
    this.decisionMessage,
    this.decisionAt,
  });

  factory InvitationWithUserDetail.fromJson(Map<String, dynamic> json) {
    return InvitationWithUserDetail(
      id: json['id'] as int,
      status: json['status'] as String,
      invitedUser: User.fromJson(json['invited_user'] as Map<String, dynamic>),
      inviterId: json['inviter_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      decisionMessage: json['decision_message'] as String?,
      decisionAt: json['decision_at'] != null
          ? DateTime.parse(json['decision_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'invited_user': invitedUser.toJson(),
      'inviter_id': inviterId,
      'created_at': createdAt.toIso8601String(),
      'decision_message': decisionMessage,
      'decision_at': decisionAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'declined';
}

class EventSimpleForComposite {
  final int id;
  final String title;
  final DateTime date;
  final bool isPublished;

  EventSimpleForComposite({
    required this.id,
    required this.title,
    required this.date,
    required this.isPublished,
  });

  factory EventSimpleForComposite.fromJson(Map<String, dynamic> json) {
    return EventSimpleForComposite(
      id: json['id'] as int,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      isPublished: json['is_published'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'is_published': isPublished,
    };
  }

  Event toEvent() {
    return Event(
      id: id,
      name: title,
      description: '',
      startDate: date,
      ownerId: 0,
      eventType: 'regular',
    );
  }
}
