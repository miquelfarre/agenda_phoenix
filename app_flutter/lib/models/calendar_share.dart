import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

enum CalendarPermission {
  view('view'),
  edit('edit'),
  admin('admin');

  const CalendarPermission(this.value);
  final String value;

  static CalendarPermission fromString(String value) {
    return CalendarPermission.values.firstWhere(
      (permission) => permission.value == value,
      orElse: () => CalendarPermission.view,
    );
  }
}

@immutable
class CalendarShare {
  final String id;
  final String calendarId;
  final String sharedWithUserId;
  final CalendarPermission permission;
  final DateTime createdAt;

  const CalendarShare({
    required this.id,
    required this.calendarId,
    required this.sharedWithUserId,
    required this.permission,
    required this.createdAt,
  });

  factory CalendarShare.fromJson(Map<String, dynamic> json) {
    return CalendarShare(
      id: json['id'].toString(),
      calendarId: json['calendar_id'].toString(),
      sharedWithUserId: json['shared_with_user_id'].toString(),
      permission: CalendarPermission.fromString(json['permission'] ?? 'view'),
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calendar_id': calendarId,
      'shared_with_user_id': sharedWithUserId,
      'permission': permission.value,
      'created_at': DateTimeUtils.toNormalizedIso8601String(createdAt),
    };
  }

  CalendarShare copyWith({
    String? id,
    String? calendarId,
    String? sharedWithUserId,
    CalendarPermission? permission,
    DateTime? createdAt,
  }) {
    return CalendarShare(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      sharedWithUserId: sharedWithUserId ?? this.sharedWithUserId,
      permission: permission ?? this.permission,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarShare &&
        other.id == id &&
        other.calendarId == calendarId &&
        other.sharedWithUserId == sharedWithUserId;
  }

  @override
  int get hashCode => Object.hash(id, calendarId, sharedWithUserId);

  @override
  String toString() {
    return 'CalendarShare(id: $id, calendarId: $calendarId, permission: ${permission.value})';
  }

  bool get canView => true;
  bool get canEdit =>
      permission == CalendarPermission.edit ||
      permission == CalendarPermission.admin;
  bool get canAdmin => permission == CalendarPermission.admin;
  bool get canShare => permission == CalendarPermission.admin;
  bool get canDelete => permission == CalendarPermission.admin;
}
