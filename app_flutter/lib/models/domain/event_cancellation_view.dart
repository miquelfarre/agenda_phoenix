import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';

@immutable
class EventCancellationView {
  final int id;
  final int cancellationId;
  final int userId;
  final DateTime viewedAt;

  const EventCancellationView({
    required this.id,
    required this.cancellationId,
    required this.userId,
    required this.viewedAt,
  });

  factory EventCancellationView.fromJson(Map<String, dynamic> json) {
    return EventCancellationView(
      id: json['id'] as int,
      cancellationId: json['cancellation_id'] as int,
      userId: json['user_id'] as int,
      viewedAt: json['viewed_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['viewed_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cancellation_id': cancellationId,
      'user_id': userId,
      'viewed_at': viewedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventCancellationView &&
        other.id == id &&
        other.cancellationId == cancellationId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, cancellationId, userId);

  @override
  String toString() {
    return 'EventCancellationView(id: $id, cancellationId: $cancellationId, userId: $userId)';
  }
}
