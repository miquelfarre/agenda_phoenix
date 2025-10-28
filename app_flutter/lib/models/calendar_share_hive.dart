import 'package:hive_ce/hive.dart';
import 'calendar_share.dart';
import '../utils/datetime_utils.dart';

part 'calendar_share_hive.g.dart';

@HiveType(typeId: 31)
class CalendarShareHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String calendarId;

  @HiveField(2)
  String sharedWithUserId;

  @HiveField(3)
  String permission;

  @HiveField(4)
  DateTime createdAt;

  CalendarShareHive({required this.id, required this.calendarId, required this.sharedWithUserId, required this.permission, required this.createdAt});

  factory CalendarShareHive.fromJson(Map<String, dynamic> json) =>
      CalendarShareHive(id: json['id'].toString(), calendarId: json['calendar_id'].toString(), sharedWithUserId: json['shared_with_user_id'].toString(), permission: json['permission'] ?? 'view', createdAt: DateTimeUtils.parseAndNormalize(json['created_at']));

  Map<String, dynamic> toJson() => {'id': id, 'calendar_id': calendarId, 'shared_with_user_id': sharedWithUserId, 'permission': permission, 'created_at': createdAt.toIso8601String()};

  CalendarShare toCalendarShare() {
    return CalendarShare(id: id, calendarId: calendarId, sharedWithUserId: sharedWithUserId, permission: CalendarPermission.fromString(permission), createdAt: createdAt);
  }

  static CalendarShareHive fromCalendarShare(CalendarShare calendarShare) {
    return CalendarShareHive(id: calendarShare.id, calendarId: calendarShare.calendarId, sharedWithUserId: calendarShare.sharedWithUserId, permission: calendarShare.permission.value, createdAt: calendarShare.createdAt);
  }
}
