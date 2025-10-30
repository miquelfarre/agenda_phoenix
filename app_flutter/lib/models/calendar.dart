import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

@immutable
class Calendar {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String color;
  final bool isDefault;
  final bool isShared;
  final bool deleteAssociatedEvents;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Calendar({required this.id, required this.ownerId, required this.name, this.description, required this.color, this.isDefault = false, this.isShared = false, this.deleteAssociatedEvents = false, required this.createdAt, required this.updatedAt});

  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      id: json['id'].toString(),
      ownerId: json['owner_id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#2196F3',
      isDefault: json['is_default'] ?? false,
      isShared: json['is_shared'] ?? false,
      deleteAssociatedEvents: json['delete_associated_events'] ?? false,
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
      'color': color,
      'is_default': isDefault,
      'is_shared': isShared,
      'delete_associated_events': deleteAssociatedEvents,
      'created_at': DateTimeUtils.toNormalizedIso8601String(createdAt),
      'updated_at': DateTimeUtils.toNormalizedIso8601String(updatedAt),
    };
  }

  Calendar copyWith({String? id, String? ownerId, String? name, String? description, String? color, bool? isDefault, bool? isShared, bool? deleteAssociatedEvents, DateTime? createdAt, DateTime? updatedAt}) {
    return Calendar(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isShared: isShared ?? this.isShared,
      deleteAssociatedEvents: deleteAssociatedEvents ?? this.deleteAssociatedEvents,
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
    return 'Calendar(id: $id, name: $name, ownerId: $ownerId, isDefault: $isDefault)';
  }

  bool get isValidName => name.trim().isNotEmpty && name.length <= 100;
  bool get isValidColor => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color);

  bool isOwnedBy(String userId) => ownerId == userId;
  bool canBeDeleted() => !isDefault;
}
