library;

import 'event.dart';

class EventListComposite {
  final List<EventListItem> events;
  final FilterCounts filters;
  final String checksum;

  EventListComposite({
    required this.events,
    required this.filters,
    required this.checksum,
  });

  factory EventListComposite.fromJson(Map<String, dynamic> json) {
    return EventListComposite(
      events: (json['events'] as List)
          .map((e) => EventListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      filters: FilterCounts.fromJson(json['filters'] as Map<String, dynamic>),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
      'filters': filters.toJson(),
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}

class EventListItem {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final bool isPublished;
  final bool isBirthday;
  final bool isRecurring;
  final int ownerId;
  final dynamic owner;
  final String? invitationStatus;
  final int? inviterId;
  final dynamic inviter;
  final int attendeeCount;
  final List<dynamic> attendees;

  final int? calendarId;
  final String? calendarName;
  final String? calendarColor;

  EventListItem({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.isPublished,
    required this.isBirthday,
    required this.isRecurring,
    required this.ownerId,
    required this.owner,
    this.invitationStatus,
    this.inviterId,
    this.inviter,
    required this.attendeeCount,
    this.attendees = const [],
    this.calendarId,
    this.calendarName,
    this.calendarColor,
  });

  factory EventListItem.fromJson(Map<String, dynamic> json) {
    return EventListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      isPublished: json['is_published'] as bool? ?? false,
      isBirthday: json['is_birthday'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? false,
      ownerId: json['owner_id'] as int,
      owner: json['owner'],
      invitationStatus: json['invitation_status'] as String?,
      inviterId: json['inviter_id'] as int?,
      inviter: json['inviter'],
      attendeeCount: json['attendee_count'] as int? ?? 0,
      attendees: (json['attendees'] as List? ?? []),
      calendarId: json['calendar_id'] as int?,
      calendarName: json['calendar_name'] as String?,
      calendarColor: json['calendar_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'is_published': isPublished,
      'is_birthday': isBirthday,
      'is_recurring': isRecurring,
      'owner_id': ownerId,
      'owner': owner,
      'invitation_status': invitationStatus,
      'inviter_id': inviterId,
      'inviter': inviter,
      'attendee_count': attendeeCount,
      'attendees': attendees,
      'calendar_id': calendarId,
      'calendar_name': calendarName,
      'calendar_color': calendarColor,
    };
  }

  Event toEvent() {
    return Event(
      id: id,
      name: title,
      description: description ?? '',
      startDate: date,
      ownerId: ownerId,
      eventType: isRecurring ? 'recurring' : 'regular',
      calendarId: calendarId,
      ownerName: calendarName,
    );
  }
}

class FilterCounts {
  final int all;
  final int my;
  final int subscribed;
  final int invitations;

  FilterCounts({
    required this.all,
    required this.my,
    required this.subscribed,
    required this.invitations,
  });

  factory FilterCounts.fromJson(Map<String, dynamic> json) {
    return FilterCounts(
      all: json['all'] as int? ?? 0,
      my: json['my'] as int? ?? 0,
      subscribed: json['subscribed'] as int? ?? 0,
      invitations: json['invitations'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all': all,
      'my': my,
      'subscribed': subscribed,
      'invitations': invitations,
    };
  }
}
