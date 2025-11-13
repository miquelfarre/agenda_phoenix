import 'package:flutter/foundation.dart';
import 'user.dart';
import '../../services/config_service.dart';

class OwnerStub {
  final int id;
  final String displayName;
  final bool isPublic;
  final String? profilePictureUrl;

  OwnerStub({
    required this.id,
    required this.displayName,
    this.isPublic = false,
    this.profilePictureUrl,
  });

  User toUser() {
    return User(
      id: id,
      displayName: displayName,
      isPublic: isPublic,
      profilePictureUrl: profilePictureUrl,
    );
  }
}

@immutable
class Event {
  final int? id;
  final String name;
  final String? description;
  final DateTime startDate;
  final String eventType;
  final int ownerId;
  final int? calendarId;
  final int? parentRecurringEventId;
  final DateTime? recurrenceEndDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? ownerName;
  final String? ownerProfilePicture;
  final bool? isOwnerPublic;
  final String? calendarName;
  final String? calendarColor;
  final bool? isBirthdayEvent;
  final List<dynamic>? attendeesList;
  final Map<String, dynamic>? interactionData; // Interaction data from backend
  final String?
  personalNote; // Personal note (local, different from interaction note)
  final String? clientTempId;

  const Event({
    this.id,
    required this.name,
    this.description,
    required this.startDate,
    this.eventType = 'regular',
    required this.ownerId,
    this.calendarId,
    this.parentRecurringEventId,
    this.recurrenceEndDate,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.ownerProfilePicture,
    this.isOwnerPublic,
    this.calendarName,
    this.calendarColor,
    this.isBirthdayEvent,
    this.attendeesList,
    this.interactionData,
    this.personalNote,
    this.clientTempId,
  });

  String get title => name;
  DateTime get date => startDate;

  bool get isRecurring => eventType == 'recurring';

  bool get isBirthday => isBirthdayEvent ?? false;
  bool get isRecurringEvent => isRecurring;

  OwnerStub? get owner => OwnerStub(
    id: ownerId,
    displayName: ownerName ?? 'Usuario',
    isPublic: isOwnerPublic ?? false,
    profilePictureUrl: ownerProfilePicture,
  );

  List<dynamic> get attendees => attendeesList ?? [];
  bool get canInviteUsers {
    final currentUserId = ConfigService.instance.currentUserId;
    // Can invite if: owner OR admin
    return ownerId == currentUserId || interactionRole == 'admin';
  }

  List<dynamic> get recurrencePatterns => [];

  // Interaction getters (from backend data)
  String? get interactionType =>
      interactionData?['interaction_type'] as String?;
  String? get interactionStatus => interactionData?['status'] as String?;
  String? get interactionRole => interactionData?['role'] as String?;
  int? get invitedByUserId => interactionData?['invited_by_user_id'] as int?;
  String? get invitationNote => interactionData?['note'] as String?;
  bool get isNewInteraction => interactionData?['is_new'] as bool? ?? false;

  // Convenience getters
  bool get wasInvited => interactionType == 'invited';
  bool get isInvitationPending => wasInvited && interactionStatus == 'pending';
  bool get isInvitationAccepted =>
      wasInvited && interactionStatus == 'accepted';
  bool get isInvitationRejected =>
      wasInvited && interactionStatus == 'rejected';
  bool get isSubscribedEvent => interactionType == 'subscribed';
  bool get isJoinedEvent => interactionType == 'joined';

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      eventType: json['event_type'] as String? ?? 'regular',
      ownerId: json['owner_id'] as int,
      calendarId: json['calendar_id'] as int?,
      parentRecurringEventId: json['parent_recurring_event_id'] as int?,
      recurrenceEndDate: json['recurrence_end_date'] != null
          ? DateTime.parse(json['recurrence_end_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      ownerName: json['owner_name'] as String?,
      ownerProfilePicture: json['owner_profile_picture'] as String?,
      isOwnerPublic: json['is_owner_public'] as bool?,
      calendarName: json['calendar_name'] as String?,
      calendarColor: json['calendar_color'] as String?,
      isBirthdayEvent: json['is_birthday'] as bool?,
      attendeesList: json['attendees'] as List<dynamic>?,
      interactionData: json['interaction'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'start_date': startDate.toIso8601String(),
      'event_type': eventType,
      'owner_id': ownerId,
      if (calendarId != null) 'calendar_id': calendarId,
      if (parentRecurringEventId != null)
        'parent_recurring_event_id': parentRecurringEventId,
      if (recurrenceEndDate != null)
        'recurrence_end_date': recurrenceEndDate!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Event copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? startDate,
    String? eventType,
    int? ownerId,
    int? calendarId,
    int? parentRecurringEventId,
    DateTime? recurrenceEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerName,
    String? ownerProfilePicture,
    bool? isOwnerPublic,
    String? calendarName,
    String? calendarColor,
    bool? isBirthdayEvent,
    List<dynamic>? attendeesList,
    Map<String, dynamic>? interactionData,
    String? personalNote,
    String? clientTempId,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      eventType: eventType ?? this.eventType,
      ownerId: ownerId ?? this.ownerId,
      calendarId: calendarId ?? this.calendarId,
      parentRecurringEventId:
          parentRecurringEventId ?? this.parentRecurringEventId,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerName: ownerName ?? this.ownerName,
      ownerProfilePicture: ownerProfilePicture ?? this.ownerProfilePicture,
      isOwnerPublic: isOwnerPublic ?? this.isOwnerPublic,
      calendarName: calendarName ?? this.calendarName,
      calendarColor: calendarColor ?? this.calendarColor,
      isBirthdayEvent: isBirthdayEvent ?? this.isBirthdayEvent,
      attendeesList: attendeesList ?? this.attendeesList,
      interactionData: interactionData ?? this.interactionData,
      personalNote: personalNote ?? this.personalNote,
      clientTempId: clientTempId ?? this.clientTempId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.name == name &&
        other.startDate == startDate &&
        other.ownerId == ownerId;
  }

  @override
  int get hashCode => Object.hash(id, name, startDate, ownerId);

  @override
  String toString() {
    return 'Event(id: $id, name: $name, startDate: $startDate, ownerId: $ownerId)';
  }
}
