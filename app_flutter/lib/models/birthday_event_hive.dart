import 'package:hive_ce/hive.dart';
import 'birthday_event.dart';
import '../utils/datetime_utils.dart';

part 'birthday_event_hive.g.dart';

@HiveType(typeId: 32)
class BirthdayEventHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String celebrantName;

  @HiveField(3)
  DateTime birthDate;

  @HiveField(4)
  bool recurring;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  BirthdayEventHive({
    required this.id,
    required this.userId,
    required this.celebrantName,
    required this.birthDate,
    this.recurring = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BirthdayEventHive.fromJson(Map<String, dynamic> json) =>
      BirthdayEventHive(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        celebrantName: json['celebrant_name'] ?? '',
        birthDate: DateTimeUtils.parseAndNormalize(json['birth_date']),
        recurring: json['recurring'] ?? true,
        notes: json['notes'],
        createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
        updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'celebrant_name': celebrantName,
    'birth_date': birthDate.toIso8601String(),
    'recurring': recurring,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  BirthdayEvent toBirthdayEvent() {
    return BirthdayEvent(
      id: id,
      userId: userId,
      celebrantName: celebrantName,
      birthDate: birthDate,
      recurring: recurring,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static BirthdayEventHive fromBirthdayEvent(BirthdayEvent birthdayEvent) {
    return BirthdayEventHive(
      id: birthdayEvent.id,
      userId: birthdayEvent.userId,
      celebrantName: birthdayEvent.celebrantName,
      birthDate: birthdayEvent.birthDate,
      recurring: birthdayEvent.recurring,
      notes: birthdayEvent.notes,
      createdAt: birthdayEvent.createdAt,
      updatedAt: birthdayEvent.updatedAt,
    );
  }
}
