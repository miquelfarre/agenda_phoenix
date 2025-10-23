import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/event_hive.dart';
import '../utils/datetime_utils.dart';

class HashingUtils {
  HashingUtils._();

  static String md5Of(String data) => md5.convert(utf8.encode(data)).toString();

  static String canonicalEventsJson(List<EventHive> events) {
    final buffer = StringBuffer('[');
    for (int i = 0; i < events.length; i++) {
      if (i > 0) buffer.write(',');
      final e = events[i];
      buffer.write('{');
      buffer.write('"id":${e.id},');
      buffer.write('"name":"${e.name}",');
      buffer.write('"description":"${e.description ?? ''}",');
      buffer.write(
        '"start_date":"${DateTimeUtils.toNormalizedIso8601String(e.startDate)}",',
      );
      if (e.endDate != null) {
        buffer.write(
          '"end_date":"${DateTimeUtils.toNormalizedIso8601String(e.endDate!)}",',
        );
      } else {
        buffer.write('"end_date":null,');
      }
      buffer.write('"event_type":"${e.eventType}",');
      buffer.write('"owner_id":${e.ownerId},');
      if (e.calendarId != null) {
        buffer.write('"calendar_id":${e.calendarId},');
      } else {
        buffer.write('"calendar_id":null,');
      }
      if (e.parentRecurringEventId != null) {
        buffer.write('"parent_recurring_event_id":${e.parentRecurringEventId}');
      } else {
        buffer.write('"parent_recurring_event_id":null');
      }
      buffer.write('}');
    }
    buffer.write(']');
    return buffer.toString();
  }

  static String eventsHash(List<EventHive> events) {
    if (events.isEmpty) return md5Of('[]');
    events.sort((a, b) => a.id.compareTo(b.id));
    return md5Of(canonicalEventsJson(events));
  }
}
