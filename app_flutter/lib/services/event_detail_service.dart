import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../core/state/app_state.dart';

final eventDetailServiceProvider = Provider((ref) => EventDetailService(ref));

class EventDetailService {
  final Ref _ref;

  EventDetailService(this._ref);

  bool canUserInviteToEvent(Event event, int userId) {
    if (event.ownerId == userId) {
      return true;
    }

    if (event.owner?.isPublic == true) {
      return false;
    }

    return false;
  }

  bool canUserEditEvent(Event event, int userId) {
    if (event.ownerId != userId) {
      return false;
    }

    if (event.startDate.isBefore(DateTime.now())) {
      return false;
    }

    return true;
  }

  bool canUserDeleteEvent(Event event, int userId) {
    if (event.ownerId != userId) {
      return false;
    }

    return true;
  }

  Future<List<Event>> getFutureEventsFromOrganizer(Event event) async {
    if (event.owner?.isPublic != true) {
      return [];
    }

    try {
      final allEvents = _ref.read(eventStateProvider);
      final futureEvents = allEvents
          .where(
            (e) =>
                e.ownerId == event.ownerId &&
                e.id != event.id &&
                e.startDate.isAfter(DateTime.now()),
          )
          .take(5)
          .toList();

      futureEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      return futureEvents;
    } catch (error) {
      return [];
    }
  }

  String? validateInvitationMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return null;
    }

    final trimmed = message.trim();

    if (trimmed.length > 500) {
      return 'Invitation message is too long (max 500 characters)';
    }

    final lowercased = trimmed.toLowerCase();
    final inappropriateWords = ['spam', 'scam', 'virus'];

    for (final word in inappropriateWords) {
      if (lowercased.contains(word)) {
        return 'Invitation message contains inappropriate content';
      }
    }

    return null;
  }

  String formatEventDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays == -1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return '${_formatWeekday(dateTime)} at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatWeekday(DateTime dateTime) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[dateTime.weekday - 1];
  }
}
