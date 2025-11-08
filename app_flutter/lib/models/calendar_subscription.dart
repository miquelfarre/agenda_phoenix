import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

@immutable
class CalendarSubscription {
  final int id;
  final int calendarId;
  final int userId;
  final String status; // 'active', 'paused'
  final DateTime subscribedAt;
  final DateTime updatedAt;

  // Optional enriched fields (only when enriched=true)
  final String? calendarName;
  final String? calendarDescription;
  final String? calendarCategory;
  final int? calendarOwnerId;
  final String? calendarOwnerName;
  final int? subscriberCount;

  const CalendarSubscription({
    required this.id,
    required this.calendarId,
    required this.userId,
    required this.status,
    required this.subscribedAt,
    required this.updatedAt,
    this.calendarName,
    this.calendarDescription,
    this.calendarCategory,
    this.calendarOwnerId,
    this.calendarOwnerName,
    this.subscriberCount,
  });

  factory CalendarSubscription.fromJson(Map<String, dynamic> json) {
    return CalendarSubscription(
      id: json['id'] as int,
      calendarId: json['calendar_id'] as int,
      userId: json['user_id'] as int,
      status: json['status'] as String? ?? 'active',
      subscribedAt: json['subscribed_at'] is String
          ? DateTimeUtils.parseAndNormalize(json['subscribed_at'])
          : json['subscribed_at'] as DateTime,
      updatedAt: json['updated_at'] is String
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : json['updated_at'] as DateTime,
      calendarName: json['calendar_name'] as String?,
      calendarDescription: json['calendar_description'] as String?,
      calendarCategory: json['calendar_category'] as String?,
      calendarOwnerId: json['calendar_owner_id'] as int?,
      calendarOwnerName: json['calendar_owner_name'] as String?,
      subscriberCount: json['calendar_subscriber_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'calendar_id': calendarId,
    'user_id': userId,
    'status': status,
    'subscribed_at': subscribedAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (calendarName != null) 'calendar_name': calendarName,
    if (calendarDescription != null)
      'calendar_description': calendarDescription,
    if (calendarCategory != null) 'calendar_category': calendarCategory,
    if (calendarOwnerId != null) 'calendar_owner_id': calendarOwnerId,
    if (calendarOwnerName != null) 'calendar_owner_name': calendarOwnerName,
    if (subscriberCount != null) 'calendar_subscriber_count': subscriberCount,
  };

  CalendarSubscription copyWith({
    int? id,
    int? calendarId,
    int? userId,
    String? status,
    DateTime? subscribedAt,
    DateTime? updatedAt,
    String? calendarName,
    String? calendarDescription,
    String? calendarCategory,
    int? calendarOwnerId,
    String? calendarOwnerName,
    int? subscriberCount,
  }) {
    return CalendarSubscription(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      calendarName: calendarName ?? this.calendarName,
      calendarDescription: calendarDescription ?? this.calendarDescription,
      calendarCategory: calendarCategory ?? this.calendarCategory,
      calendarOwnerId: calendarOwnerId ?? this.calendarOwnerId,
      calendarOwnerName: calendarOwnerName ?? this.calendarOwnerName,
      subscriberCount: subscriberCount ?? this.subscriberCount,
    );
  }

  // Helper getters
  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarSubscription &&
        other.id == id &&
        other.calendarId == calendarId &&
        other.userId == userId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, calendarId, userId, status);

  @override
  String toString() {
    return 'CalendarSubscription(id: $id, calendarId: $calendarId, userId: $userId, status: $status)';
  }
}
