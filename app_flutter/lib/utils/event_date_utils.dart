import 'package:flutter/cupertino.dart';
import '../models/domain/event.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';

/// Utility class for event date operations
///
/// Provides methods for grouping events by date and formatting dates
/// in a localized, human-readable format.
class EventDateUtils {
  /// Groups a list of events by date
  ///
  /// Events are grouped by date (year-month-day) and sorted chronologically.
  /// Within each day, birthdays appear first, followed by other events sorted by time.
  ///
  /// Returns a list of maps with 'date' (String) and 'events' (List of Event) keys.
  static List<Map<String, dynamic>> groupEventsByDate(List<Event> events) {
    final Map<String, List<Event>> groupedMap = {};

    for (final event in events) {
      final eventDate = event.date;
      final dateKey =
          '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(event);
    }

    // Sort events within each day: birthdays first, then by time
    for (final eventList in groupedMap.values) {
      eventList.sort((a, b) {
        if (a.isBirthday && !b.isBirthday) return -1;
        if (!a.isBirthday && b.isBirthday) return 1;

        final timeA = a.date;
        final timeB = b.date;
        return timeA.compareTo(timeB);
      });
    }

    // Convert to list format and sort by date
    final groupedList = groupedMap.entries.map((entry) {
      return {'date': entry.key, 'events': entry.value};
    }).toList();

    groupedList.sort(
      (a, b) => (a['date'] as String).compareTo(b['date'] as String),
    );

    return groupedList;
  }

  /// Formats a date in a localized, human-readable format
  ///
  /// Returns:
  /// - "Hoy" / "Today" for current day
  /// - "Mañana" / "Tomorrow" for next day
  /// - "Ayer" / "Yesterday" for previous day
  /// - "Lunes, 15 · Enero" for other dates (day of week, day number · month)
  static String formatEventDate(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return l10n.today;
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return l10n.tomorrow;
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      return l10n.yesterday;
    } else {
      final weekdays = [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];
      final months = [
        l10n.january,
        l10n.february,
        l10n.march,
        l10n.april,
        l10n.may,
        l10n.june,
        l10n.july,
        l10n.august,
        l10n.september,
        l10n.october,
        l10n.november,
        l10n.december,
      ];

      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];

      return '$weekday, ${date.day} ${l10n.dotSeparator} $month';
    }
  }

  /// Parses a date string (yyyy-MM-dd) into a DateTime object
  ///
  /// Returns the parsed date or DateTime.now() if parsing fails.
  static DateTime parseDateString(String dateStr) {
    try {
      return DateTime.parse('${dateStr}T00:00:00');
    } catch (_) {
      return DateTime.now();
    }
  }
}
