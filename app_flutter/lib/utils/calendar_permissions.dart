import '../models/calendar.dart';
import '../repositories/calendar_repository.dart';
import '../services/config_service.dart';

/// Utility class for checking calendar permissions
///
/// Handles logic for determining if a user can edit/delete a calendar
/// based on ownership or admin role in CalendarMembership
class CalendarPermissions {
  /// Check if the current user can edit the calendar
  ///
  /// Returns true if user is:
  /// - Calendar owner, OR
  /// - Calendar admin (CalendarMembership with role='admin', status='accepted')
  static Future<bool> canEdit({
    required Calendar calendar,
    required CalendarRepository repository,
  }) async {
    final userId = ConfigService.instance.currentUserId;
    final isOwner = calendar.ownerId == userId;

    if (isOwner) return true;

    // Check if user is admin of this calendar
    try {
      final memberships = await repository.fetchCalendarMemberships(calendar.id);
      final userMembership = memberships.firstWhere(
        (m) => m['user_id'].toString() == userId.toString(),
        orElse: () => <String, dynamic>{},
      );
      return userMembership['role'] == 'admin' && userMembership['status'] == 'accepted';
    } catch (e) {
      return false;
    }
  }

  /// Check if the current user is the owner of the calendar
  static bool isOwner(Calendar calendar) {
    final userId = ConfigService.instance.currentUserId;
    return calendar.ownerId == userId;
  }

  /// Check if user can delete the calendar
  ///
  /// Same as canEdit - owners and admins can delete
  static Future<bool> canDelete({
    required Calendar calendar,
    required CalendarRepository repository,
  }) {
    return canEdit(calendar: calendar, repository: repository);
  }
}
