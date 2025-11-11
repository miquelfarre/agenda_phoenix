import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';

@immutable
class EventBan {
  final int id;
  final int eventId;
  final int userId;
  final int bannedBy;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventBan({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.bannedBy,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventBan.fromJson(Map<String, dynamic> json) {
    return EventBan(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      userId: json['user_id'] as int,
      bannedBy: json['banned_by'] as int,
      reason: json['reason'] as String?,
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
      'event_id': eventId,
      'user_id': userId,
      'banned_by': bannedBy,
      if (reason != null) 'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventBan &&
        other.id == id &&
        other.eventId == eventId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, eventId, userId);

  @override
  String toString() {
    return 'EventBan(id: $id, eventId: $eventId, userId: $userId, bannedBy: $bannedBy)';
  }
}
