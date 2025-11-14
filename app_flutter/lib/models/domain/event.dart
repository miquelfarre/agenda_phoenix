import 'package:flutter/foundation.dart';
import 'user.dart';
import '../../services/config_service.dart';

@immutable
class Event {
  final int? id;
  final String name;
  final String? description;
  final DateTime startDate;
  final String timezone;
  final String eventType;
  final int ownerId;
  final User? owner;
  final List<User> members;
  final List<User> admins;
  final int? calendarId;
  final int? parentRecurringEventId;
  final DateTime? recurrenceEndDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? calendarName;
  final String? calendarColor;
  final bool? isBirthdayEvent;
  final List<dynamic>? attendeesList;
  final Map<String, dynamic>? interactionData;
  final String? personalNote;
  final String? clientTempId;

  const Event({
    this.id,
    required this.name,
    this.description,
    required this.startDate,
    this.timezone = 'Europe/Madrid',
    this.eventType = 'regular',
    required this.ownerId,
    this.owner,
    this.members = const [],
    this.admins = const [],
    this.calendarId,
    this.parentRecurringEventId,
    this.recurrenceEndDate,
    this.createdAt,
    this.updatedAt,
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

  List<dynamic> get attendees => attendeesList ?? [];

  bool get canInviteUsers {
    final currentUserId = ConfigService.instance.currentUserId;
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
    String? personalNote;
    final interactionData = json['interaction'] as Map<String, dynamic>?;
    if (interactionData != null) {
      personalNote = interactionData['personal_note'] as String?;
    }

    return Event(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      timezone: json['timezone'] as String? ?? 'Europe/Madrid',
      eventType: json['event_type'] as String? ?? 'regular',
      ownerId: json['owner_id'] as int,
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      members: json['members'] != null
          ? (json['members'] as List).map((m) => User.fromJson(m)).toList()
          : [],
      admins: json['admins'] != null
          ? (json['admins'] as List).map((a) => User.fromJson(a)).toList()
          : [],
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
      calendarName: json['calendar_name'] as String?,
      calendarColor: json['calendar_color'] as String?,
      isBirthdayEvent: json['is_birthday'] as bool?,
      attendeesList: json['attendees'] as List<dynamic>?,
      interactionData: interactionData,
      personalNote: personalNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'start_date': startDate.toIso8601String(),
      'timezone': timezone,
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

  // Membership helper methods
  bool isOwner(int userId) => ownerId == userId;

  bool isAdmin(int userId) {
    return ownerId == userId || admins.any((admin) => admin.id == userId);
  }

  bool isMember(int userId) {
    return members.any((member) => member.id == userId);
  }

  bool canManageEvent(int userId) {
    return isAdmin(userId);
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
