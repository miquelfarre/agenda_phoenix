import 'package:flutter/cupertino.dart';
import '../models/calendar.dart';
import '../repositories/calendar_repository.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import 'calendar_permissions.dart';
import 'error_message_parser.dart';

/// Utility class for common calendar operations
///
/// Centralizes logic for delete/leave operations that were duplicated
/// across multiple screens (calendars_screen, calendar_events_screen)
class CalendarOperations {
  /// Delete or leave a calendar based on user ownership
  ///
  /// If user is the owner, deletes the calendar completely.
  /// Otherwise, leaves the calendar (unsubscribes).
  ///
  /// Shows success/error messages automatically.
  /// Optionally navigates back after operation.
  static Future<bool> deleteOrLeaveCalendar({
    required Calendar calendar,
    required CalendarRepository repository,
    required BuildContext context,
    bool shouldNavigate = false,
    bool showSuccessMessage = true,
  }) async {
    print('🗑️ [CalendarOperations] Initiating delete/leave for calendar: "${calendar.name}" (ID: ${calendar.id})');

    try {
      final isOwner = CalendarPermissions.isOwner(calendar);
      print('👤 [CalendarOperations] Is Owner: $isOwner');

      if (isOwner) {
        // User is owner - DELETE calendar
        print('🗑️ [CalendarOperations] User is owner. DELETING calendar.');
        await repository.deleteCalendar(int.parse(calendar.id));
        print('✅ [CalendarOperations] Calendar DELETED successfully');

        if (showSuccessMessage && context.mounted) {
          final l10n = context.l10n;
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.success,
          );
        }
      } else {
        // User is not owner - LEAVE calendar
        print('👋 [CalendarOperations] User is not owner. LEAVING calendar.');

        if (calendar.shareHash != null) {
          // Public calendar - unsubscribe by share_hash
          print('📤 [CalendarOperations] Public calendar - unsubscribing by share_hash');
          await repository.unsubscribeByShareHash(calendar.shareHash!);
        } else {
          // Private calendar - remove membership
          print('📤 [CalendarOperations] Private calendar - removing membership');
          await repository.unsubscribeFromCalendar(int.parse(calendar.id));
        }
        print('✅ [CalendarOperations] Calendar LEFT successfully');

        if (showSuccessMessage && context.mounted) {
          final l10n = context.l10n;
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.calendarLeft,
          );
        }
      }

      // Navigate back if requested
      if (shouldNavigate && context.mounted) {
        print('➡️ [CalendarOperations] Navigating back.');
        Navigator.of(context).pop();
      }

      print('✅ [CalendarOperations] Operation completed for calendar ID: ${calendar.id}');
      return true;
    } catch (e, stackTrace) {
      print('❌ [CalendarOperations] Error: $e');
      print('📍 [CalendarOperations] Stack trace: $stackTrace');

      if (context.mounted) {
        final errorMessage = ErrorMessageParser.parse(e, context);
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }

      return false;
    }
  }

  /// Confirm and delete/leave calendar with dialog
  ///
  /// Shows confirmation dialog before performing the operation.
  /// Returns true if operation was successful, false otherwise.
  static Future<bool> confirmAndDeleteOrLeave({
    required Calendar calendar,
    required CalendarRepository repository,
    required BuildContext context,
    bool shouldNavigate = false,
  }) async {
    final l10n = context.l10n;
    final isOwner = CalendarPermissions.isOwner(calendar);

    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(isOwner ? l10n.deleteCalendar : l10n.leaveCalendar),
        content: Text(
          isOwner
            ? l10n.confirmDeleteCalendarWithEvents
            : l10n.confirmLeaveCalendar,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isOwner ? l10n.delete : l10n.leave),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      return await deleteOrLeaveCalendar(
        calendar: calendar,
        repository: repository,
        context: context,
        shouldNavigate: shouldNavigate,
      );
    }

    return false;
  }
}
