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

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  bool deleteAssociatedEvents;

  @HiveField(10)
  bool isPublic;

  @HiveField(11)
  String? shareHash;

  @HiveField(12)
  String? category;

  @HiveField(13)
  int subscriberCount;

  @HiveField(14)
  bool isDiscoverable;

  CalendarHive({required this.id, required this.ownerId, required this.name, this.description, required this.createdAt, required this.updatedAt, this.deleteAssociatedEvents = false, this.isPublic = false, this.isDiscoverable = true, this.shareHash, this.category, this.subscriberCount = 0});

  factory CalendarHive.fromJson(Map<String, dynamic> json) => CalendarHive(
    id: json['id'].toString(),
    ownerId: json['owner_id'].toString(),
    name: json['name'] ?? '',
    description: json['description'],
    createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
    updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
    deleteAssociatedEvents: json['delete_associated_events'] ?? false,
    isPublic: json['is_public'] ?? false,
    isDiscoverable: json['is_discoverable'] ?? true,
    shareHash: json['share_hash'],
    category: json['category'],
    subscriberCount: json['subscriber_count'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'delete_associated_events': deleteAssociatedEvents,
    'is_public': isPublic,
    'is_discoverable': isDiscoverable,
    'share_hash': shareHash,
    'category': category,
    'subscriber_count': subscriberCount,
  };

  Calendar toCalendar() {
    return Calendar(id: id, ownerId: ownerId, name: name, description: description, deleteAssociatedEvents: deleteAssociatedEvents, isPublic: isPublic, isDiscoverable: isDiscoverable, shareHash: shareHash, category: category, subscriberCount: subscriberCount, createdAt: createdAt, updatedAt: updatedAt);
  }

  static CalendarHive fromCalendar(Calendar calendar) {
    return CalendarHive(
      id: calendar.id,
      ownerId: calendar.ownerId,
      name: calendar.name,
      description: calendar.description,
      deleteAssociatedEvents: calendar.deleteAssociatedEvents,
      isPublic: calendar.isPublic,
      isDiscoverable: calendar.isDiscoverable,
      shareHash: calendar.shareHash,
      category: calendar.category,
      subscriberCount: calendar.subscriberCount,
      createdAt: calendar.createdAt,
      updatedAt: calendar.updatedAt,
    );
  }
}
