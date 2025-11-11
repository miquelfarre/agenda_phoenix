import 'package:hive_ce/hive.dart';
import '../domain/event.dart';

part 'event_hive.g.dart';

@HiveType(typeId: 0)
class EventHive extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime startDate;

  @HiveField(5)
  String eventType;

  @HiveField(6)
  int ownerId;

  @HiveField(7)
  int? calendarId;

  @HiveField(8)
  int? parentRecurringEventId;

  @HiveField(9)
  DateTime? createdAt;

  @HiveField(10)
  DateTime? updatedAt;

  @HiveField(11)
  String? ownerName;

  @HiveField(12)
  String? calendarName;

  @HiveField(13)
  String? personalNote;

  EventHive({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    this.eventType = 'regular',
    required this.ownerId,
    this.calendarId,
    this.parentRecurringEventId,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.calendarName,
    this.personalNote,
  });

  factory EventHive.fromEvent(Event event) {
    return EventHive(
      id: event.id ?? 0,
      name: event.name,
      description: event.description,
      startDate: event.startDate,
      eventType: event.eventType,
      ownerId: event.ownerId,
      calendarId: event.calendarId,
      parentRecurringEventId: event.parentRecurringEventId,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      ownerName: event.ownerName,
      calendarName: event.calendarName,
      personalNote: event.personalNote,
    );
  }

  Event toEvent() {
    return Event(
      id: id,
      name: name,
      description: description,
      startDate: startDate,
      eventType: eventType,
      ownerId: ownerId,
      calendarId: calendarId,
      parentRecurringEventId: parentRecurringEventId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ownerName: ownerName,
      calendarName: calendarName,
      personalNote: personalNote,
    );
  }
}
