class DateTimeUtils {
  static DateTime normalizeToFiveMinuteInterval(DateTime dateTime) {
    final totalMinutes = dateTime.hour * 60 + dateTime.minute;
    final roundedTotal = (totalMinutes / 5).round() * 5;
    final deltaMinutes = roundedTotal - totalMinutes;

    final newDt = dateTime.add(Duration(minutes: deltaMinutes));

    return DateTime(
      newDt.year,
      newDt.month,
      newDt.day,
      newDt.hour,
      newDt.minute,
    );
  }

  static String toNormalizedIso8601String(DateTime dateTime) {
    final normalized = normalizeToFiveMinuteInterval(dateTime);

    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}T'
        '${normalized.hour.toString().padLeft(2, '0')}:'
        '${normalized.minute.toString().padLeft(2, '0')}:00';
  }

  static DateTime parseAndNormalize(dynamic dateInput) {
    if (dateInput is DateTime) {
      return normalizeToFiveMinuteInterval(dateInput);
    }
    if (dateInput is String) {
      final parsed = DateTime.parse(dateInput);
      return normalizeToFiveMinuteInterval(parsed);
    }
    throw FormatException(
      'Unsupported date input type: ${dateInput.runtimeType}',
    );
  }

  static String formatForDisplay(DateTime dateTime) {
    final normalized = normalizeToFiveMinuteInterval(dateTime);
    return '${normalized.day.toString().padLeft(2, '0')}/'
        '${normalized.month.toString().padLeft(2, '0')}/'
        '${normalized.year} '
        '${normalized.hour.toString().padLeft(2, '0')}:'
        '${normalized.minute.toString().padLeft(2, '0')}';
  }

  static bool isValidFiveMinuteInterval(DateTime dateTime) {
    return dateTime.minute % 5 == 0 &&
        dateTime.second == 0 &&
        dateTime.millisecond == 0 &&
        dateTime.microsecond == 0;
  }

  static List<DateTime> generateTimeOptions(DateTime baseDate) {
    final options = <DateTime>[];

    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 5) {
        options.add(
          DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute),
        );
      }
    }

    return options;
  }

  static String formatBirthdayDate(DateTime date, String locale) {
    final months = locale.startsWith('es')
        ? [
            'enero',
            'febrero',
            'marzo',
            'abril',
            'mayo',
            'junio',
            'julio',
            'agosto',
            'septiembre',
            'octubre',
            'noviembre',
            'diciembre',
          ]
        : [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];

    if (locale.startsWith('es')) {
      return '${date.day} de ${months[date.month - 1]}';
    } else {
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
