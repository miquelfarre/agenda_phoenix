import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

@immutable
class Contact {
  final int id;
  final int? ownerId;
  final String name;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contact({
    required this.id,
    this.ownerId,
    required this.name,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int?,
      name: json['name'] as String,
      phone: json['phone'] as String,
      createdAt: json['created_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
        other.id == id &&
        other.phone == phone;
  }

  @override
  int get hashCode => Object.hash(id, phone);

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phone: $phone)';
  }
}
