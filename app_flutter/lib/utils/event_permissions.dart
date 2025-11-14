import '../models/domain/event.dart';
import '../services/config_service.dart';

/// Utility class for checking event permissions
///
/// Handles logic for determining if a user can edit/delete an event
/// based on ownership or admin role in event interaction
class EventPermissions {
  /// Check if the current user can edit/delete the event
  ///
  /// Returns true if user is:
  /// - Event owner, OR
  /// - Event admin (interaction_type='joined', role='admin')
  static bool canEdit({required Event event}) {
    final currentUserId = ConfigService.instance.currentUserId;
    final isOwner = event.ownerId == currentUserId;

    if (isOwner) return true;

    // Check if user is admin of this event (joined with admin role)
    final isAdmin =
        event.interactionType == 'joined' && event.interactionRole == 'admin';

    return isAdmin;
  }

  /// Check if the current user is the owner of the event
  static bool isOwner(Event event) {
    final currentUserId = ConfigService.instance.currentUserId;
    return event.ownerId == currentUserId;
  }

  /// Check if user can delete the event
  ///
  /// Same as canEdit - owners and admins can delete
  static bool canDelete({required Event event}) {
    return canEdit(event: event);
  }

  /// Check if user can invite others to the event
  ///
  /// Uses the existing canInviteUsers getter from Event model
  static bool canInvite(Event event) {
    return event.canInviteUsers;
  }

  /// Check if the current user can manage event participants
  ///
  /// Returns true if user is:
  /// - Event owner, OR
  /// - Event admin (interaction_type='joined', role='admin')
  static bool canManageParticipants({required Event event}) {
    return canEdit(event: event);
  }
}
