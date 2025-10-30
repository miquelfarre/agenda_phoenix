import 'dart:math';
import '../models/month_option.dart';
import '../models/day_option.dart';
import '../models/time_option.dart';

class DateRangeCalculator {
  static DateTime calculateMaxDate(DateTime today, int months) {
    final totalMonths = today.month + months;
    final targetYear = today.year + ((totalMonths - 1) ~/ 12);
    final targetMonth = totalMonths % 12 == 0 ? 12 : totalMonths % 12;

    final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    final targetDay = min(today.day, daysInTargetMonth);

    return DateTime(targetYear, targetMonth, targetDay);
  }

  static List<MonthOption> generateMonthOptions(DateTime start, DateTime end, String locale) {
    final options = <MonthOption>[];
    var current = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      options.add(MonthOption.fromDateTime(current, locale));
      current = DateTime(current.year, current.month + 1, 1);
    }

    return options;
  }

  static List<DayOption> generateDayOptions(int month, int year, String locale) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final options = <DayOption>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      options.add(DayOption.fromDateTime(date, locale));
    }

    return options;
  }

  static List<TimeOption> generateTimeOptions() {
    final options = <TimeOption>[];
    const intervals = [0, 15, 30, 45];

    for (int hour = 0; hour < 24; hour++) {
      for (int minute in intervals) {
        options.add(TimeOption.fromTime(hour, minute));
      }
    }

    return options;
  }

  static DateTime roundToNext15Min(DateTime time) {
    final minute = time.minute;
    final remainder = minute % 15;

    if (remainder == 0) {
      return time;
    }

    final minutesToAdd = 15 - remainder;
    final rounded = time.add(Duration(minutes: minutesToAdd));

    return DateTime(rounded.year, rounded.month, rounded.day, rounded.hour, rounded.minute);
  }

  static int getTimeOptionIndex(DateTime time, List<TimeOption> options) {
    final rounded = roundToNext15Min(time);
    final targetHour = rounded.hour;
    final targetMinute = rounded.minute;

    for (int i = 0; i < options.length; i++) {
      if (options[i].hour == targetHour && options[i].minute == targetMinute) {
        return i;
      }
    }

    return 0;
  }
}
