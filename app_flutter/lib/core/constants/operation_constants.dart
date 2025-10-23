class OperationPriorities {
  OperationPriorities._();

  static const int lowest = 1;
  static const int veryLow = 2;
  static const int low = 3;
  static const int belowNormal = 4;
  static const int normal = 5;
  static const int aboveNormal = 6;
  static const int medium = 7;
  static const int high = 8;
  static const int veryHigh = 9;
  static const int urgent = 10;
  static const int critical = 11;

  static const int backgroundSync = low;
  static const int userAction = normal;
  static const int createEntity = aboveNormal;
  static const int updateEntity = medium;
  static const int deleteEntity = high;
  static const int invitation = medium;
  static const int subscription = medium;
  static const int notification = aboveNormal;
  static const int groupOperation = veryHigh;
}

class EntityTypes {
  EntityTypes._();

  static const String event = 'event';
  static const String group = 'group';
  static const String notification = 'notification';
  static const String invitation = 'invitation';
  static const String subscription = 'subscription';
  static const String contact = 'contact';
  static const String user = 'user';
  static const String eventNote = 'event_note';
  static const String settings = 'settings';
}

class DeletionMarkers {
  DeletionMarkers._();

  static const String deleted = '[DELETED]';
  static const String seriesDeleted = '[SERIES DELETED]';
  static const String removedFromGroup = '[REMOVED]';
  static const String cancelledEvent = '[CANCELLED]';

  static bool isDeleted(String? value) {
    if (value == null) return false;
    return value.startsWith(deleted) ||
        value.startsWith(seriesDeleted) ||
        value.startsWith(removedFromGroup) ||
        value.startsWith(cancelledEvent);
  }

  static String markAsDeleted(String value, [String marker = deleted]) {
    if (isDeleted(value)) return value;
    return '$marker $value';
  }

  static String removeMarker(String value) {
    for (final marker in [
      deleted,
      seriesDeleted,
      removedFromGroup,
      cancelledEvent,
    ]) {
      if (value.startsWith(marker)) {
        return value.substring(marker.length).trim();
      }
    }
    return value;
  }
}

class HiveBoxNames {
  HiveBoxNames._();

  static const String events = 'events';
  static const String notifications = 'notifications';
  static const String subscriptions = 'subscriptions';
  static const String invitations = 'invitations';
  static const String groups = 'groups';
  static const String contacts = 'contacts';
  static const String eventNotes = 'event_notes';
  static const String pendingOperations = 'pending_operations';
  static const String optimisticUpdates = 'optimistic_updates';
  static const String syncMetadata = 'sync_metadata';
  static const String settings = 'settings';
}

class Timeouts {
  Timeouts._();

  static const Duration veryShort = Duration(seconds: 5);
  static const Duration short = Duration(seconds: 10);
  static const Duration medium = Duration(seconds: 30);
  static const Duration long = Duration(seconds: 60);
  static const Duration veryLong = Duration(minutes: 2);
  static const Duration extraLong = Duration(minutes: 5);

  static const Duration apiCall = medium;
  static const Duration firebaseAuth = long;
  static const Duration sync = veryLong;
  static const Duration offlineOperation = short;
}

class EventOps {
  EventOps._();

  static const String create = 'create_event';
  static const String update = 'update_event';
  static const String delete = 'delete_event';
  static const String createRecurring = 'create_recurring_event';
  static const String acceptInvitation = 'accept_invitation';
  static const String rejectInvitation = 'reject_invitation';
  static const String leave = 'leave_event';
  static const String saveNote = 'save_event_note';
  static const String deleteNote = 'delete_event_note';
}

class GroupOps {
  GroupOps._();

  static const String create = 'create_group';
  static const String update = 'update_group';
  static const String delete = 'delete_group';
  static const String addMember = 'add_member_to_group';
  static const String removeMember = 'remove_member_from_group';
  static const String makeAdmin = 'make_admin';
  static const String removeAdmin = 'remove_admin';
  static const String leave = 'leave_group';
}

class InvitationOps {
  InvitationOps._();

  static const String send = 'send_invitation';
  static const String accept = 'accept_invitation';
  static const String reject = 'reject_invitation';
  static const String cancel = 'cancel_invitation';
  static const String decide = 'decide_invitation';
  static const String postpone = 'postpone_invitation';
}

class NotificationOps {
  NotificationOps._();

  static const String markAsSeen = 'mark_notification_seen';
  static const String markAsRead = 'mark_notification_read';
  static const String delete = 'delete_notification';
  static const String sendEventChange = 'send_event_change_notification';
}
