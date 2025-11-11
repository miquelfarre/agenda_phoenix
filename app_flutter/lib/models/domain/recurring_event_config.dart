import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';

@immutable
class RecurringEventConfig {
  final int id;
  final int eventId;
  final String recurrenceType; // 'daily', 'weekly', 'monthly', 'yearly'
  final Map<String, dynamic>? schedule; // Type-specific configuration (JSON)
  final DateTime? recurrenceEndDate; // NULL = perpetual/infinite recurrence
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringEventConfig({
    required this.id,
    required this.eventId,
    required this.recurrenceType,
    this.schedule,
    this.recurrenceEndDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPerpetual => recurrenceEndDate == null;

  factory RecurringEventConfig.fromJson(Map<String, dynamic> json) {
    return RecurringEventConfig(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      recurrenceType: json['recurrence_type'] as String? ?? 'weekly',
      schedule: json['schedule'] as Map<String, dynamic>?,
      recurrenceEndDate: json['recurrence_end_date'] != null
          ? DateTimeUtils.parseAndNormalize(json['recurrence_end_date'])
          : null,
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
      'recurrence_type': recurrenceType,
      if (schedule != null) 'schedule': schedule,
      if (recurrenceEndDate != null)
        'recurrence_end_date': recurrenceEndDate!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringEventConfig &&
        other.id == id &&
        other.eventId == eventId &&
        other.recurrenceType == recurrenceType &&
        other.recurrenceEndDate == recurrenceEndDate;
  }

  @override
  int get hashCode =>
      Object.hash(id, eventId, recurrenceType, recurrenceEndDate);

  @override
  String toString() {
    return 'RecurringEventConfig(id: $id, eventId: $eventId, type: $recurrenceType, '
        'perpetual: $isPerpetual)';
  }
}
