import 'package:hive_ce/hive.dart';
import '../domain/calendar.dart';
import '../../utils/datetime_utils.dart';

part 'calendar_hive.g.dart';

@HiveType(typeId: 30)
class CalendarHive extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int ownerId;

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

  @HiveField(15)
  DateTime? startDate;

  @HiveField(16)
  DateTime? endDate;

  CalendarHive({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deleteAssociatedEvents = false,
    this.isPublic = false,
    this.isDiscoverable = true,
    this.shareHash,
    this.category,
    this.subscriberCount = 0,
    this.startDate,
    this.endDate,
  });

  factory CalendarHive.fromJson(Map<String, dynamic> json) => CalendarHive(
    id: json['id'] as int,
    ownerId: json['owner_id'] as int,
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
    startDate: json['start_date'] != null
        ? DateTimeUtils.parseAndNormalize(json['start_date'])
        : null,
    endDate: json['end_date'] != null
        ? DateTimeUtils.parseAndNormalize(json['end_date'])
        : null,
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
    if (startDate != null) 'start_date': startDate!.toIso8601String(),
    if (endDate != null) 'end_date': endDate!.toIso8601String(),
  };

  Calendar toCalendar() {
    return Calendar(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      deleteAssociatedEvents: deleteAssociatedEvents,
      isPublic: isPublic,
      isDiscoverable: isDiscoverable,
      shareHash: shareHash,
      category: category,
      subscriberCount: subscriberCount,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
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
      startDate: calendar.startDate,
      endDate: calendar.endDate,
      createdAt: calendar.createdAt,
      updatedAt: calendar.updatedAt,
    );
  }
}
