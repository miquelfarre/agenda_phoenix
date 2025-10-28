import 'package:hive_ce/hive.dart';

part 'user_event_note_hive.g.dart';

@HiveType(typeId: 10)
class UserEventNoteHive extends HiveObject {
  @HiveField(0)
  int userId;

  @HiveField(1)
  int eventId;

  @HiveField(2)
  String note;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  UserEventNoteHive({
    required this.userId,
    required this.eventId,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserEventNoteHive.fromJson(Map<String, dynamic> json) {
    return UserEventNoteHive(
      userId: json['user_id'],
      eventId: json['event_id'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'event_id': eventId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get hiveKey => '${userId}_$eventId';

  static String createHiveKey(int userId, int eventId) => '${userId}_$eventId';
}
