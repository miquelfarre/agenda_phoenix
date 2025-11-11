import 'package:intl/intl.dart';

class DayOption {
  final int day;
  final int dayOfWeek;
  final String dayName;
  final String displayName;

  DayOption({
    required this.day,
    required this.dayOfWeek,
    required this.dayName,
    required this.displayName,
  }) : assert(day >= 1 && day <= 31, 'Day must be between 1 and 31'),
       assert(
         dayOfWeek >= 1 && dayOfWeek <= 7,
         'Day of week must be between 1 and 7',
       );

  factory DayOption.fromDateTime(DateTime date, String locale) {
    final dayNameFormatter = DateFormat('E', locale);
    final dayName = dayNameFormatter.format(date);

    return DayOption(
      day: date.day,
      dayOfWeek: date.weekday,
      dayName: dayName,
      displayName: '$dayName ${date.day}',
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'dayOfWeek': dayOfWeek,
    'dayName': dayName,
    'displayName': displayName,
  };

  factory DayOption.fromJson(Map<String, dynamic> json) => DayOption(
    day: json['day'] as int,
    dayOfWeek: json['dayOfWeek'] as int,
    dayName: json['dayName'] as String,
    displayName: json['displayName'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayOption &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          dayOfWeek == other.dayOfWeek;

  @override
  int get hashCode => day.hashCode ^ dayOfWeek.hashCode;

  @override
  String toString() => 'DayOption($displayName)';
}
