import 'package:flutter/foundation.dart';
import 'user.dart';

class _OwnerStub {
  final int id;
  final String? fullName;
  final bool isPublic;
  final String? profilePicture;

  _OwnerStub({
    required this.id,
    this.fullName,
    this.isPublic = false,
    this.profilePicture,
  });

  User toUser() {
    return User(
      id: id,
      fullName: fullName ?? 'Unknown',
      isPublic: isPublic,
      profilePicture: profilePicture,
    );
  }
}

@immutable
class Event {
  final int? id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String eventType;
  final int ownerId;
  final int? calendarId;
  final int? parentRecurringEventId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? ownerName;
  final String? calendarName;
  final String? personalNote;
  final String? clientTempId;

  const Event({
    this.id,
    required this.name,
    this.description,
    required this.startDate,
    this.endDate,
    this.eventType = 'regular',
    required this.ownerId,
    this.calendarId,
    this.parentRecurringEventId,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.calendarName,
    this.personalNote,
    this.clientTempId,
  });

  String get title => name;
  DateTime get date => startDate;

  bool get isRecurring => eventType == 'recurring';

  bool get isBirthday => false;
  bool get isRecurringEvent => isRecurring;

  _OwnerStub? get owner => _OwnerStub(
    id: ownerId,
    fullName: ownerName,
    isPublic: false,
    profilePicture: null,
  );

  List<dynamic> get attendees => [];
  bool get canInviteUsers => true;
  String? get calendarColor => null;
  List<dynamic> get recurrencePatterns => [];

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      eventType: json['event_type'] as String? ?? 'regular',
      ownerId: json['owner_id'] as int,
      calendarId: json['calendar_id'] as int?,
      parentRecurringEventId: json['parent_recurring_event_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      ownerName: json['owner_name'] as String?,
      calendarName: json['calendar_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'event_type': eventType,
      'owner_id': ownerId,
      if (calendarId != null) 'calendar_id': calendarId,
      if (parentRecurringEventId != null)
        'parent_recurring_event_id': parentRecurringEventId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Event copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    int? ownerId,
    int? calendarId,
    int? parentRecurringEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerName,
    String? calendarName,
    String? personalNote,
    String? clientTempId,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      eventType: eventType ?? this.eventType,
      ownerId: ownerId ?? this.ownerId,
      calendarId: calendarId ?? this.calendarId,
      parentRecurringEventId:
          parentRecurringEventId ?? this.parentRecurringEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerName: ownerName ?? this.ownerName,
      calendarName: calendarName ?? this.calendarName,
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
