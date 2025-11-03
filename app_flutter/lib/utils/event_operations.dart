import 'package:flutter/cupertino.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import 'event_permissions.dart';
import 'error_message_parser.dart';

/// Utility class for common event operations
///
/// Centralizes logic for delete/leave operations that were duplicated
/// across multiple screens (events_screen, calendar_events_screen, event_series_screen)
class EventOperations {
  /// Delete or leave an event based on user permissions
  ///
  /// If user has edit permissions (owner/admin), deletes the event.
  /// Otherwise, leaves the event (removes user's interaction).
  ///
  /// Shows success/error messages automatically.
  /// Optionally navigates back after operation.
  static Future<bool> deleteOrLeaveEvent({
    required Event event,
    required EventRepository repository,
    required BuildContext context,
    bool shouldNavigate = false,
    bool showSuccessMessage = true,
  }) async {
    print('🗑️ [EventOperations] Initiating delete/leave for event: "${event.name}" (ID: ${event.id})');

    try {
      if (event.id == null) {
        print('❌ [EventOperations] Error: Event ID is null.');
        throw Exception('Event ID is null');
      }

      final canEdit = EventPermissions.canEdit(event: event);
      print('👤 [EventOperations] Can Edit: $canEdit');

      if (canEdit) {
        // User has permission - DELETE event
        print('🗑️ [EventOperations] User has permission. DELETING event.');
        await repository.deleteEvent(event.id!);
        print('✅ [EventOperations] Event DELETED successfully');

        if (showSuccessMessage && context.mounted) {
          final l10n = context.l10n;
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.success,
          );
        }
      } else {
        // User is participant - LEAVE event
        print('👋 [EventOperations] User is not owner/admin. LEAVING event.');
        await repository.leaveEvent(event.id!);
        print('✅ [EventOperations] Event LEFT successfully');

        if (showSuccessMessage && context.mounted) {
          final l10n = context.l10n;
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.success,
          );
        }
      }

      // Navigate back if requested
      if (shouldNavigate && context.mounted) {
        print('➡️ [EventOperations] Navigating back.');
        Navigator.of(context).pop();
      }

      print('✅ [EventOperations] Operation completed for event ID: ${event.id}');
      return true;
    } catch (e, stackTrace) {
      print('❌ [EventOperations] Error: $e');
      print('📍 [EventOperations] Stack trace: $stackTrace');

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

  /// Confirm and delete/leave event with dialog
  ///
  /// Shows confirmation dialog before performing the operation.
  /// Returns true if operation was successful, false otherwise.
  static Future<bool> confirmAndDeleteOrLeave({
    required Event event,
    required EventRepository repository,
    required BuildContext context,
    bool shouldNavigate = false,
  }) async {
    final l10n = context.l10n;
    final canEdit = EventPermissions.canEdit(event: event);

    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(canEdit ? l10n.deleteEvent : l10n.leaveEvent),
        content: Text(
          canEdit
            ? l10n.confirmCancelEvent
            : l10n.confirmRemoveFromList,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(canEdit ? l10n.delete : l10n.leave),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      return await deleteOrLeaveEvent(
        event: event,
        repository: repository,
        context: context,
        shouldNavigate: shouldNavigate,
      );
    }

    return false;
  }
}
