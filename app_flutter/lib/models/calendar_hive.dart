import 'package:hive_ce/hive.dart';
import 'calendar.dart';
import '../utils/datetime_utils.dart';

part 'calendar_hive.g.dart';

@HiveType(typeId: 30)
class CalendarHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String ownerId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String color;

  @HiveField(5)
  bool isDefault;

  @HiveField(6)
  bool isShared;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  bool deleteAssociatedEvents;

  CalendarHive({required this.id, required this.ownerId, required this.name, this.description, required this.color, this.isDefault = false, this.isShared = false, required this.createdAt, required this.updatedAt, this.deleteAssociatedEvents = false});

  factory CalendarHive.fromJson(Map<String, dynamic> json) => CalendarHive(
    id: json['id'].toString(),
    ownerId: json['owner_id'].toString(),
    name: json['name'] ?? '',
    description: json['description'],
    color: json['color'] ?? '#2196F3',
    isDefault: json['is_default'] ?? false,
    isShared: json['is_shared'] ?? false,
    createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
    updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
    deleteAssociatedEvents: json['delete_associated_events'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'description': description,
    'color': color,
    'is_default': isDefault,
    'is_shared': isShared,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'delete_associated_events': deleteAssociatedEvents,
  };

  Calendar toCalendar() {
    return Calendar(id: id, ownerId: ownerId, name: name, description: description, color: color, isDefault: isDefault, isShared: isShared, deleteAssociatedEvents: deleteAssociatedEvents, createdAt: createdAt, updatedAt: updatedAt);
  }

  static CalendarHive fromCalendar(Calendar calendar) {
    return CalendarHive(
      id: calendar.id,
      ownerId: calendar.ownerId,
      name: calendar.name,
      description: calendar.description,
      color: calendar.color,
      isDefault: calendar.isDefault,
      isShared: calendar.isShared,
      deleteAssociatedEvents: calendar.deleteAssociatedEvents,
      createdAt: calendar.createdAt,
      updatedAt: calendar.updatedAt,
    );
  }
}
