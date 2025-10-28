import 'package:eventypop/utils/datetime_utils.dart';

class RecurrencePattern {
  final int? id;
  final int eventId;
  final int dayOfWeek;
  final String time;
  final DateTime? createdAt;

  RecurrencePattern({this.id, required this.eventId, required this.dayOfWeek, required this.time, this.createdAt});

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(id: json['id'], eventId: json['event_id'], dayOfWeek: json['day_of_week'], time: json['time'], createdAt: json['created_at'] != null ? (json['created_at'] is String ? DateTimeUtils.parseAndNormalize(json['created_at']) : json['created_at']) : null);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'event_id': eventId, 'day_of_week': dayOfWeek, 'time': time, 'created_at': createdAt?.toIso8601String()};
  }

  bool get isValidDayOfWeek => dayOfWeek >= 0 && dayOfWeek < 7;

  RecurrencePattern copyWith({int? id, int? eventId, int? dayOfWeek, String? time, DateTime? createdAt}) {
    return RecurrencePattern(id: id ?? this.id, eventId: eventId ?? this.eventId, dayOfWeek: dayOfWeek ?? this.dayOfWeek, time: time ?? this.time, createdAt: createdAt ?? this.createdAt);
  }

  RecurrencePattern ensureFiveMinuteInterval() {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return this;
      final minute = int.tryParse(parts[1]) ?? 0;
      final normalizedMinute = (minute / 5).round() * 5;
      if (minute == normalizedMinute) return this;
      final newMinuteStr = normalizedMinute.toString().padLeft(2, '0');
      final newTime = '${parts[0]}:$newMinuteStr:00';
      return copyWith(time: newTime);
    } catch (_) {
      return this;
    }
  }
}
