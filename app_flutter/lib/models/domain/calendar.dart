import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';

@immutable
class Calendar {
  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final bool deleteAssociatedEvents;
  final bool isPublic;
  final bool isDiscoverable;
  final String? shareHash;
  final String? category;
  final int subscriberCount;
  final DateTime? startDate; // For temporal calendars (e.g., "Olympics 2024")
  final DateTime? endDate; // For temporal calendars
  final DateTime createdAt;
  final DateTime updatedAt;

  const Calendar({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.deleteAssociatedEvents = false,
    this.isPublic = false,
    this.isDiscoverable = true,
    this.shareHash,
    this.category,
    this.subscriberCount = 0,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      name: json['name'] ?? '',
      description: json['description'],
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
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
      updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'delete_associated_events': deleteAssociatedEvents,
      'is_public': isPublic,
      'is_discoverable': isDiscoverable,
      'share_hash': shareHash,
      'category': category,
      'subscriber_count': subscriberCount,
      if (startDate != null)
        'start_date': DateTimeUtils.toNormalizedIso8601String(startDate!),
      if (endDate != null)
        'end_date': DateTimeUtils.toNormalizedIso8601String(endDate!),
      'created_at': DateTimeUtils.toNormalizedIso8601String(createdAt),
      'updated_at': DateTimeUtils.toNormalizedIso8601String(updatedAt),
    };
  }

  Calendar copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? description,
    bool? deleteAssociatedEvents,
    bool? isPublic,
    bool? isDiscoverable,
    String? shareHash,
    String? category,
    int? subscriberCount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Calendar(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      deleteAssociatedEvents:
          deleteAssociatedEvents ?? this.deleteAssociatedEvents,
      isPublic: isPublic ?? this.isPublic,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      shareHash: shareHash ?? this.shareHash,
      category: category ?? this.category,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Calendar && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Calendar(id: $id, name: $name, ownerId: $ownerId)';
  }

  bool get isValidName => name.trim().isNotEmpty && name.length <= 100;

  bool isOwnedBy(int userId) => ownerId == userId;
}
