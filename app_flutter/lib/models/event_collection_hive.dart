import 'package:hive_ce/hive.dart';
import 'event_collection.dart';
import '../utils/datetime_utils.dart';

part 'event_collection_hive.g.dart';

@HiveType(typeId: 33)
class EventCollectionHive extends HiveObject {
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
  bool isPublic;

  @HiveField(6)
  bool isShared;

  @HiveField(7)
  List<String> eventIds;

  @HiveField(8)
  List<String> sharedWithUserIds;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  bool isDeleted;

  @HiveField(12)
  DateTime? deletedAt;

  EventCollectionHive({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.color,
    required this.isPublic,
    required this.isShared,
    required this.eventIds,
    required this.sharedWithUserIds,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.deletedAt,
  });

  factory EventCollectionHive.fromJson(Map<String, dynamic> json) =>
      EventCollectionHive(
        id: json['id'].toString(),
        ownerId: json['owner_id'].toString(),
        name: json['name'] ?? '',
        description: json['description'],
        color: json['color'] ?? '#2196F3',
        isPublic: json['is_public'] ?? false,
        isShared: json['is_shared'] ?? false,
        eventIds: List<String>.from(json['event_ids'] ?? []),
        sharedWithUserIds: List<String>.from(
          json['shared_with_user_ids'] ?? [],
        ),
        createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
        updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
        isDeleted: json['is_deleted'] ?? false,
        deletedAt: json['deleted_at'] != null
            ? DateTimeUtils.parseAndNormalize(json['deleted_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'description': description,
    'color': color,
    'is_public': isPublic,
    'is_shared': isShared,
    'event_ids': eventIds,
    'shared_with_user_ids': sharedWithUserIds,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_deleted': isDeleted,
    'deleted_at': deletedAt?.toIso8601String(),
  };

  EventCollection toEventCollection() {
    return EventCollection(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      color: color,
      isPublic: isPublic,
      isShared: isShared,
      eventIds: eventIds,
      sharedWithUserIds: sharedWithUserIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
    );
  }

  static EventCollectionHive fromEventCollection(EventCollection collection) {
    return EventCollectionHive(
      id: collection.id,
      ownerId: collection.ownerId,
      name: collection.name,
      description: collection.description,
      color: collection.color,
      isPublic: collection.isPublic,
      isShared: collection.isShared,
      eventIds: collection.eventIds,
      sharedWithUserIds: collection.sharedWithUserIds,
      createdAt: collection.createdAt,
      updatedAt: collection.updatedAt,
      isDeleted: collection.isDeleted,
      deletedAt: collection.deletedAt,
    );
  }
}
