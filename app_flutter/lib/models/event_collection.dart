import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

@immutable
class EventCollection {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String color;
  final bool isPublic;
  final bool isShared;
  final List<String> eventIds;
  final List<String> sharedWithUserIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const EventCollection({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.color = '#2196F3',
    this.isPublic = false,
    this.isShared = false,
    this.eventIds = const [],
    this.sharedWithUserIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory EventCollection.fromJson(Map<String, dynamic> json) {
    return EventCollection(
      id: json['id'].toString(),
      ownerId: json['owner_id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#2196F3',
      isPublic: json['is_public'] ?? false,
      isShared: json['is_shared'] ?? false,
      eventIds: List<String>.from(json['event_ids'] ?? []),
      sharedWithUserIds: List<String>.from(json['shared_with_user_ids'] ?? []),
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
      updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'color': color,
      'is_public': isPublic,
      'is_shared': isShared,
      'event_ids': eventIds,
      'shared_with_user_ids': sharedWithUserIds,
      'created_at': DateTimeUtils.toNormalizedIso8601String(createdAt),
      'updated_at': DateTimeUtils.toNormalizedIso8601String(updatedAt),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt != null
          ? DateTimeUtils.toNormalizedIso8601String(deletedAt!)
          : null,
    };
  }

  EventCollection copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? color,
    bool? isPublic,
    bool? isShared,
    List<String>? eventIds,
    List<String>? sharedWithUserIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return EventCollection(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isPublic: isPublic ?? this.isPublic,
      isShared: isShared ?? this.isShared,
      eventIds: eventIds ?? this.eventIds,
      sharedWithUserIds: sharedWithUserIds ?? this.sharedWithUserIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventCollection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EventCollection(id: $id, name: $name, eventCount: ${eventIds.length})';
  }

  bool get isValidName => name.trim().isNotEmpty && name.length <= 100;
  bool get isValidDescription =>
      description == null || description!.length <= 500;
  bool get isValidColor =>
      color.isNotEmpty && color.startsWith('#') && color.length == 7;
  bool get isValid => isValidName && isValidDescription && isValidColor;

  bool isOwnedBy(String userId) => ownerId == userId;
  bool isSharedWith(String userId) => sharedWithUserIds.contains(userId);
  bool hasAccessBy(String userId) =>
      isOwnedBy(userId) || (isPublic && !isDeleted) || isSharedWith(userId);

  bool containsEvent(String eventId) => eventIds.contains(eventId);
  int get eventCount => eventIds.length;
  bool get isEmpty => eventIds.isEmpty;
  bool get isNotEmpty => eventIds.isNotEmpty;

  EventCollection addEvent(String eventId) {
    if (containsEvent(eventId)) return this;

    return copyWith(
      eventIds: [...eventIds, eventId],
      updatedAt: DateTime.now(),
    );
  }

  EventCollection removeEvent(String eventId) {
    if (!containsEvent(eventId)) return this;

    return copyWith(
      eventIds: eventIds.where((id) => id != eventId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  EventCollection shareWith(String userId) {
    if (isSharedWith(userId)) return this;

    return copyWith(
      sharedWithUserIds: [...sharedWithUserIds, userId],
      isShared: true,
      updatedAt: DateTime.now(),
    );
  }

  EventCollection unshareWith(String userId) {
    if (!isSharedWith(userId)) return this;

    final newSharedList = sharedWithUserIds
        .where((id) => id != userId)
        .toList();

    return copyWith(
      sharedWithUserIds: newSharedList,
      isShared: newSharedList.isNotEmpty,
      updatedAt: DateTime.now(),
    );
  }

  EventCollection markAsDeleted() {
    return copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  EventCollection restore() {
    return copyWith(
      isDeleted: false,
      deletedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> get stats => {
    'event_count': eventCount,
    'is_shared': isShared,
    'shared_with_count': sharedWithUserIds.length,
    'is_public': isPublic,
    'is_deleted': isDeleted,
    'created_days_ago': DateTime.now().difference(createdAt).inDays,
    'last_updated_days_ago': DateTime.now().difference(updatedAt).inDays,
  };

  String get displayName => name.isEmpty ? 'Untitled Collection' : name;
  String get shortDescription => description != null && description!.length > 50
      ? '${description!.substring(0, 50)}...'
      : description ?? '';
}
