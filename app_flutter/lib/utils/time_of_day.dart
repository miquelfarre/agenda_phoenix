import 'package:flutter/widgets.dart';

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.now() => TimeOfDay.fromDateTime(DateTime.now());

  factory TimeOfDay.fromDateTime(DateTime dt) =>
      TimeOfDay(hour: dt.hour, minute: dt.minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String format(BuildContext context) {
    return toString();
  }
}
