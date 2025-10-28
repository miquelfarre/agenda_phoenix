import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../utils/app_exceptions.dart';

class TimezoneService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  static DateTime convertFromUtc(DateTime utcDateTime, String timezoneName) {
    if (!_initialized) {
      throw const InitializationException(message: 'TimezoneService not initialized. Call initialize() first.');
    }

    final location = tz.getLocation(timezoneName);
    final utcTzDateTime = tz.TZDateTime.from(utcDateTime, tz.UTC);
    return tz.TZDateTime.from(utcTzDateTime, location);
  }

  static DateTime convertToUtc(DateTime localDateTime, String timezoneName) {
    if (!_initialized) {
      throw const InitializationException(message: 'TimezoneService not initialized. Call initialize() first.');
    }

    final location = tz.getLocation(timezoneName);
    final localTzDateTime = tz.TZDateTime(location, localDateTime.year, localDateTime.month, localDateTime.day, localDateTime.hour, localDateTime.minute, localDateTime.second);

    return localTzDateTime.toUtc();
  }

  static String getCurrentOffset(String timezoneName) {
    if (!_initialized) {
      throw const InitializationException(message: 'TimezoneService not initialized. Call initialize() first.');
    }

    try {
      final location = tz.getLocation(timezoneName);
      final now = tz.TZDateTime.now(location);
      final offsetInMinutes = now.timeZoneOffset.inMinutes;
      final hours = offsetInMinutes ~/ 60;
      final minutes = offsetInMinutes % 60;

      final sign = hours >= 0 ? '+' : '';
      return 'GMT$sign$hours${minutes != 0 ? ':${minutes.abs().toString().padLeft(2, '0')}' : ''}';
    } catch (e) {
      return 'GMT+0';
    }
  }

  static Map<String, dynamic> getTimezoneInfo(String timezoneName, DateTime? dateTime) {
    if (!_initialized) {
      throw const InitializationException(message: 'TimezoneService not initialized. Call initialize() first.');
    }

    try {
      final location = tz.getLocation(timezoneName);
      final targetDate = dateTime ?? DateTime.now();
      final tzDateTime = tz.TZDateTime.from(targetDate, location);

      return {'timezone': timezoneName, 'offset': getCurrentOffset(timezoneName), 'abbreviation': tzDateTime.timeZoneName, 'isDst': _isDstActive(location, targetDate)};
    } catch (e) {
      return {'timezone': timezoneName, 'offset': 'GMT+0', 'abbreviation': 'UTC', 'isDst': false};
    }
  }

  static bool _isDstActive(tz.Location location, DateTime dateTime) {
    try {
      final tzDateTime = tz.TZDateTime.from(dateTime, location);

      final janDateTime = tz.TZDateTime(location, dateTime.year, 1, 1);

      return tzDateTime.timeZoneOffset != janDateTime.timeZoneOffset;
    } catch (e) {
      return false;
    }
  }
}
