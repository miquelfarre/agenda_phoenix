import 'package:hive_ce/hive.dart';

part 'event_note_hive.g.dart';

@HiveType(typeId: 7)
class EventNoteHive extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int userId;

  @HiveField(2)
  int eventId;

  @HiveField(3)
  String? note;

  @HiveField(4)
  DateTime? createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  @HiveField(6)
  bool isPending;

  EventNoteHive({this.id, required this.userId, required this.eventId, this.note, this.createdAt, this.updatedAt, this.isPending = false});

  EventNoteHive copyWith({int? id, int? userId, int? eventId, String? note, DateTime? createdAt, DateTime? updatedAt, bool? isPending}) {
    return EventNoteHive(id: id ?? this.id, userId: userId ?? this.userId, eventId: eventId ?? this.eventId, note: note ?? this.note, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt, isPending: isPending ?? this.isPending);
  }

  @override
  String toString() {
    return 'EventNoteHive(id: $id, userId: $userId, eventId: $eventId, note: $note, isPending: $isPending)';
  }
}
