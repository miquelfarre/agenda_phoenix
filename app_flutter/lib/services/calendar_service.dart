import 'package:hive_ce/hive.dart';
import '../models/calendar.dart';
import '../models/calendar_hive.dart';
import '../models/calendar_share.dart';
import '../models/calendar_share_hive.dart';
import 'api_client.dart';
import '../utils/app_exceptions.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  static const String _calendarsBoxName = 'calendars';
  static const String _sharesBoxName = 'calendar_shares';

  Box<CalendarHive>? _calendarsBox;
  Box<CalendarShareHive>? _sharesBox;

  Future<void> initialize() async {
    try {
      _calendarsBox = Hive.isBoxOpen(_calendarsBoxName) ? Hive.box<CalendarHive>(_calendarsBoxName) : await Hive.openBox<CalendarHive>(_calendarsBoxName);
      _sharesBox = Hive.isBoxOpen(_sharesBoxName) ? Hive.box<CalendarShareHive>(_sharesBoxName) : await Hive.openBox<CalendarShareHive>(_sharesBoxName);
    } catch (e) {
      rethrow;
    }
  }

  List<Calendar> getLocalCalendars() {
    if (_calendarsBox == null) {
      return [];
    }

    try {
      return _calendarsBox!.values.map((hive) => hive.toCalendar()).toList()..sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
    } catch (e) {
      return [];
    }
  }

  Calendar? getLocalCalendar(String id) {
    if (_calendarsBox == null) return null;

    try {
      final hive = _calendarsBox!.get(id);
      return hive?.toCalendar();
    } catch (e) {
      return null;
    }
  }

  Calendar? getDefaultCalendar() {
    return getLocalCalendars().where((cal) => cal.isDefault).firstOrNull;
  }

  Future<List<Calendar>> fetchCalendars() async {
    try {
      final response = await ApiClientFactory.instance.get('/api/v1/calendars');
      final calendars = <Calendar>[];

      for (final item in response as List) {
        final calendar = Calendar.fromJson(item);
        calendars.add(calendar);

        await _storeCalendarLocally(calendar);
      }

      return calendars;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch calendars: ${e.toString()}');
    }
  }

  Future<Calendar> createCalendar({required String name, String? description, String color = '#2196F3', bool isPublic = false, bool isShareable = true}) async {
    try {
      final data = {'name': name, 'description': description, 'color': color, 'is_public': isPublic, 'is_shareable': isShareable};

      final response = await ApiClientFactory.instance.post('/api/v1/calendars', body: data);
      final calendar = Calendar.fromJson(response);

      await _storeCalendarLocally(calendar);

      return calendar;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create calendar: ${e.toString()}');
    }
  }

  Future<Calendar> updateCalendar(String id, {String? name, String? description, String? color, bool? isDefault}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (color != null) data['color'] = color;
      if (isDefault != null) data['is_default'] = isDefault;

      final response = await ApiClientFactory.instance.put('/api/v1/calendars/$id', body: data);
      final calendar = Calendar.fromJson(response);

      await _storeCalendarLocally(calendar);

      return calendar;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update calendar: ${e.toString()}');
    }
  }

  Future<void> deleteCalendar(String id) async {
    try {
      final calendar = getLocalCalendar(id);
      if (calendar?.isDefault == true) {
        throw ValidationException(message: 'Cannot delete default calendar');
      }

      await ApiClientFactory.instance.delete('/api/v1/calendars/$id');

      await _calendarsBox?.delete(id);
    } catch (e) {
      if (e is ApiException || e is ValidationException) rethrow;
      throw ApiException('Failed to delete calendar: ${e.toString()}');
    }
  }

  Future<CalendarShare> shareCalendar({required String calendarId, required String userId, required CalendarPermission permission}) async {
    try {
      String role = permission == CalendarPermission.admin ? 'admin' : 'member';
      final data = {'user_id': userId, 'role': role};

      final response = await ApiClientFactory.instance.post('/api/v1/calendars/$calendarId/memberships', body: data);
      final share = CalendarShare.fromJson(response);

      await _storeShareLocally(share);

      return share;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to share calendar: ${e.toString()}');
    }
  }

  List<CalendarShare> getCalendarShares(String calendarId) {
    if (_sharesBox == null) return [];

    try {
      return _sharesBox!.values.where((share) => share.calendarId == calendarId).map((hive) => hive.toCalendarShare()).toList();
    } catch (e) {
      return [];
    }
  }

  bool hasPermission(String calendarId, String userId, CalendarPermission requiredPermission) {
    final calendar = getLocalCalendar(calendarId);
    if (calendar == null) return false;

    if (calendar.isOwnedBy(userId)) return true;

    final shares = getCalendarShares(calendarId);
    final userShare = shares.where((share) => share.sharedWithUserId == userId).firstOrNull;

    if (userShare == null) return false;

    return switch (requiredPermission) {
      CalendarPermission.view => userShare.canView,
      CalendarPermission.edit => userShare.canEdit,
      CalendarPermission.admin => userShare.canAdmin,
    };
  }

  Future<void> _storeCalendarLocally(Calendar calendar) async {
    if (_calendarsBox == null) return;

    try {
      final hive = CalendarHive.fromCalendar(calendar);
      await _calendarsBox!.put(calendar.id, hive);
    } catch (e) {
      // Ignore sync errors
    }
  }

  Future<void> _storeShareLocally(CalendarShare share) async {
    if (_sharesBox == null) return;

    try {
      final hive = CalendarShareHive.fromCalendarShare(share);
      await _sharesBox!.put(share.id, hive);
    } catch (e) {
      // Ignore sync errors
    }
  }

  Future<List<Calendar>> fetchPublicCalendars({String? search}) async {
    try {
      final queryParams = <String, String>{'is_public': 'true'};
      if (search != null) queryParams['search'] = search;

      final response = await ApiClientFactory.instance.get('/api/v1/calendars', queryParams: queryParams);

      final calendars = <Calendar>[];
      for (final item in response as List) {
        calendars.add(Calendar.fromJson(item));
      }

      return calendars;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch public calendars: ${e.toString()}');
    }
  }

  Future<List<Calendar>> fetchAvailableCalendars() async {
    try {
      final response = await ApiClientFactory.instance.get('/api/v1/calendars');

      final calendars = <Calendar>[];
      for (final item in response as List) {
        final calendar = Calendar.fromJson(item);
        calendars.add(calendar);

        await _storeCalendarLocally(calendar);
      }

      return calendars;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch available calendars: ${e.toString()}');
    }
  }

  Future<void> subscribeToCalendar(int calendarId) async {
    try {
      await ApiClientFactory.instance.post('/api/v1/calendars/$calendarId/memberships');

      await fetchAvailableCalendars();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to subscribe to calendar: ${e.toString()}');
    }
  }

  Future<void> unsubscribeFromCalendar(int calendarId) async {
    try {
      // Get memberships for this calendar
      final memberships = await ApiClientFactory.instance.get('/api/v1/calendars/$calendarId/memberships');

      if (memberships is! List || memberships.isEmpty) {
        throw ApiException('No membership found for calendar $calendarId');
      }

      // Find current user's membership
      // Assuming the API returns only the current user's membership or we need to filter
      // For now, delete the first one (likely the user's own membership)
      final membershipId = memberships[0]['id'];

      await ApiClientFactory.instance.delete('/api/v1/calendars/$calendarId/memberships/$membershipId');

      await _calendarsBox?.delete(calendarId.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to unsubscribe from calendar: ${e.toString()}');
    }
  }

  Future<void> clearLocalData() async {
    try {
      await _calendarsBox?.clear();
      await _sharesBox?.clear();
    } catch (e) {
      // Ignore sync errors
    }
  }
}
