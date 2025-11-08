import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

@immutable
class EventCancellation {
  final int id;
  final int eventId; // Not FK - event might be deleted
  final String eventName; // Store name for reference
  final int cancelledByUserId;
  final String? message; // Optional cancellation message
  final DateTime cancelledAt;

  const EventCancellation({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.cancelledByUserId,
    this.message,
    required this.cancelledAt,
  });

  bool get hasMessage => message != null && message!.isNotEmpty;

  factory EventCancellation.fromJson(Map<String, dynamic> json) {
    return EventCancellation(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      eventName: json['event_name'] as String,
      cancelledByUserId: json['cancelled_by_user_id'] as int,
      message: json['message'] as String?,
      cancelledAt: json['cancelled_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['cancelled_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'event_name': eventName,
      'cancelled_by_user_id': cancelledByUserId,
      if (message != null) 'message': message,
      'cancelled_at': cancelledAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventCancellation &&
        other.id == id &&
        other.eventId == eventId &&
        other.cancelledByUserId == cancelledByUserId;
  }

  @override
  int get hashCode => Object.hash(id, eventId, cancelledByUserId);

  @override
  String toString() {
    return 'EventCancellation(id: $id, eventId: $eventId, '
        'eventName: $eventName, cancelledBy: $cancelledByUserId)';
  }
}
