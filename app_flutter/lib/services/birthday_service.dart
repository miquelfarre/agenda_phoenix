import 'package:hive_ce/hive.dart';
import '../models/birthday_event.dart';
import '../models/birthday_event_hive.dart';
import 'api_client.dart';
import 'sync_service.dart';
import '../utils/app_exceptions.dart';

class BirthdayService {
  static final BirthdayService _instance = BirthdayService._internal();
  factory BirthdayService() => _instance;
  BirthdayService._internal();

  static const String _boxName = 'birthday_events';
  Box<BirthdayEventHive>? _box;

  Future<void> initialize() async {
    try {
      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box<BirthdayEventHive>(_boxName)
          : await Hive.openBox<BirthdayEventHive>(_boxName);
    } catch (e) {
      rethrow;
    }
  }

  List<BirthdayEvent> getLocalBirthdayEvents() {
    if (_box == null) {
      return [];
    }

    try {
      return _box!.values.map((hive) => hive.toBirthdayEvent()).toList()
        ..sort((a, b) {
          final nextA = a.getNextBirthday();
          final nextB = b.getNextBirthday();
          return nextA.compareTo(nextB);
        });
    } catch (e) {
      return [];
    }
  }

  BirthdayEvent? getLocalBirthdayEvent(String id) {
    if (_box == null) return null;

    try {
      final hive = _box!.get(id);
      return hive?.toBirthdayEvent();
    } catch (e) {
      return null;
    }
  }

  List<BirthdayEvent> getBirthdayEventsForUser(String userId) {
    return getLocalBirthdayEvents()
        .where((event) => event.userId == userId)
        .toList();
  }

  List<BirthdayEvent> getUpcomingBirthdays([int days = 30]) {
    final cutoffDate = DateTime.now().add(Duration(days: days));

    return getLocalBirthdayEvents().where((event) {
      final nextBirthday = event.getNextBirthday();
      return nextBirthday.isBefore(cutoffDate) ||
          nextBirthday.isAtSameMomentAs(cutoffDate);
    }).toList();
  }

  List<BirthdayEvent> getTodaysBirthdays() {
    return getLocalBirthdayEvents()
        .where((event) => event.isBirthdayToday)
        .toList();
  }

  List<BirthdayEvent> getThisWeeksBirthdays() {
    return getLocalBirthdayEvents()
        .where((event) => event.isBirthdayThisWeek)
        .toList();
  }

  Future<List<BirthdayEvent>> fetchBirthdayEvents() async {
    try {
      final response = await ApiClientFactory.instance.get(
        '/api/v1/birthday-events',
      );
      final birthdayEvents = <BirthdayEvent>[];

      for (final item in response as List) {
        final birthdayEvent = BirthdayEvent.fromJson(item);
        birthdayEvents.add(birthdayEvent);

        try {
          await SyncService.syncEvents();
        } catch (e) {
          // Ignore sync errors
        }
      }

      return birthdayEvents;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch birthday events: ${e.toString()}');
    }
  }

  Future<BirthdayEvent> createBirthdayEvent({
    required String celebrantName,
    required DateTime birthDate,
    bool recurring = true,
    String? notes,
  }) async {
    try {
      final data = {
        'celebrant_name': celebrantName,
        'birth_date': birthDate.toIso8601String(),
        'recurring': recurring,
        'notes': notes,
      };

      final response = await ApiClientFactory.instance.post(
        '/api/v1/birthday-events',
        body: data,
      );
      final birthdayEvent = BirthdayEvent.fromJson(response);

      try {
        await SyncService.syncEvents();
      } catch (e) {
        // Ignore sync errors
      }

      return birthdayEvent;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create birthday event: ${e.toString()}');
    }
  }

  Future<BirthdayEvent> updateBirthdayEvent(
    String id, {
    String? celebrantName,
    DateTime? birthDate,
    bool? recurring,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (celebrantName != null) data['celebrant_name'] = celebrantName;
      if (birthDate != null) data['birth_date'] = birthDate.toIso8601String();
      if (recurring != null) data['recurring'] = recurring;
      if (notes != null) data['notes'] = notes;

      final response = await ApiClientFactory.instance.put(
        '/api/v1/birthday-events/$id',
        body: data,
      );
      final birthdayEvent = BirthdayEvent.fromJson(response);

      try {
        await SyncService.syncEvents();
      } catch (e) {
        // Ignore sync errors
      }

      return birthdayEvent;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update birthday event: ${e.toString()}');
    }
  }

  Future<void> deleteBirthdayEvent(String id) async {
    try {
      await ApiClientFactory.instance.delete('/api/v1/birthday-events/$id');

      try {
        await SyncService.syncEvents();
      } catch (e) {
        // Ignore sync errors
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete birthday event: ${e.toString()}');
    }
  }

  bool isOwnedByUser(String birthdayEventId, String userId) {
    final event = getLocalBirthdayEvent(birthdayEventId);
    return event?.isCreatedBy(userId) ?? false;
  }

  Map<String, dynamic> getBirthdayStats() {
    final events = getLocalBirthdayEvents();
    final today = DateTime.now();

    return {
      'total': events.length,
      'today': getTodaysBirthdays().length,
      'this_week': getThisWeeksBirthdays().length,
      'this_month': events.where((event) {
        final nextBirthday = event.getNextBirthday();
        return nextBirthday.month == today.month &&
            nextBirthday.year == today.year;
      }).length,
      'upcoming_30_days': getUpcomingBirthdays(30).length,
    };
  }

  Future<void> clearLocalData() async {
    try {
      await _box?.clear();
    } catch (e) {
      // Ignore sync errors
    }
  }
}
