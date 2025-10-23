import 'package:timezone/timezone.dart' as tz;
import 'month_option.dart';
import 'day_option.dart';
import 'time_option.dart';

class DateTimeSelection {
  final DateTime selectedDate;
  final String timezone;
  final int month;
  final int year;
  final int day;
  final int hour;
  final int minute;

  DateTimeSelection({
    required this.selectedDate,
    required this.timezone,
    required this.month,
    required this.year,
    required this.day,
    required this.hour,
    required this.minute,
  });

  factory DateTimeSelection.fromOptions(
    MonthOption monthOption,
    DayOption dayOption,
    TimeOption timeOption,
    String timezone,
  ) {
    final selectedDate = DateTime(
      monthOption.year,
      monthOption.month,
      dayOption.day,
      timeOption.hour,
      timeOption.minute,
    );

    return DateTimeSelection(
      selectedDate: selectedDate,
      timezone: timezone,
      month: monthOption.month,
      year: monthOption.year,
      day: dayOption.day,
      hour: timeOption.hour,
      minute: timeOption.minute,
    );
  }

  factory DateTimeSelection.fromDateTime(DateTime date, String timezone) {
    return DateTimeSelection(
      selectedDate: date,
      timezone: timezone,
      month: date.month,
      year: date.year,
      day: date.day,
      hour: date.hour,
      minute: date.minute,
    );
  }

  tz.TZDateTime toTZDateTime() {
    final location = tz.getLocation(timezone);
    return tz.TZDateTime(location, year, month, day, hour, minute);
  }

  DateTime toUTC() {
    return toTZDateTime().toUtc();
  }

  bool isValid() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = DateTime(
      today.year + ((today.month + 30) ~/ 12),
      ((today.month + 30) % 12) == 0 ? 12 : ((today.month + 30) % 12),
      today.day,
    );

    return !selectedDate.isBefore(today) && !selectedDate.isAfter(maxDate);
  }

  Map<String, dynamic> toJson() => {
    'selectedDate': selectedDate.toIso8601String(),
    'timezone': timezone,
    'month': month,
    'year': year,
    'day': day,
    'hour': hour,
    'minute': minute,
  };

  factory DateTimeSelection.fromJson(Map<String, dynamic> json) {
    return DateTimeSelection(
      selectedDate: DateTime.parse(json['selectedDate'] as String),
      timezone: json['timezone'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      day: json['day'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  @override
  String toString() =>
      'DateTimeSelection($year-$month-$day $hour:$minute $timezone)';
}
