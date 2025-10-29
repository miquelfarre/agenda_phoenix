import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import '../models/event.dart';

import '../widgets/empty_state.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

import 'event_date_header.dart';
import 'event_list_item.dart';
import '../utils/datetime_utils.dart';

class EventsList extends StatelessWidget {
  final List<Event> events;
  final EventTapCallback onEventTap;
  final EventActionCallback onDelete;
  final bool navigateAfterDelete;
  final Widget? header;

  const EventsList({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.onDelete,
    this.navigateAfterDelete = false,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (events.isEmpty) {
      return EmptyState(
        message: l10n.noEvents,
        icon: PlatformDetection.isIOS
            ? CupertinoIcons.calendar
            : CupertinoIcons.calendar,
      );
    }

    final groupedEvents = _groupEventsByDate(events);

    final hasHeader = header != null;

    final listView = ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        top: PlatformDetection.isIOS ? 12.0 : 8.0,
        left: 8.0,
        right: 8.0,
      ),
      itemCount: groupedEvents.length + (hasHeader ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: header!,
          );
        }
        final effectiveIndex = hasHeader ? index - 1 : index;
        final group = groupedEvents[effectiveIndex];
        return _buildDateGroup(context, group);
      },
    );

    return SafeArea(top: true, bottom: false, child: listView);
  }

  List<Map<String, dynamic>> _groupEventsByDate(List<Event> events) {
    final Map<String, List<Event>> groupedMap = {};

    for (final event in events) {
      final eventDate = event.date;
      final dateKey =
          '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(event);
    }

    for (final eventList in groupedMap.values) {
      eventList.sort((a, b) {
        final timeA = a.date;
        final timeB = b.date;
        return timeA.compareTo(timeB);
      });
    }

    final groupedList = groupedMap.entries.map((entry) {
      return {'date': entry.key, 'events': entry.value};
    }).toList();

    groupedList.sort(
      (a, b) => (a['date'] as String).compareTo(b['date'] as String),
    );

    return groupedList;
  }

  Widget _buildDateGroup(BuildContext context, Map<String, dynamic> group) {
    final dateStr = group['date'] as String;
    final events = group['events'] as List<Event>;

    DateTime date;
    try {
      date = DateTimeUtils.parseAndNormalize('${dateStr}T00:00:00');
    } catch (_) {
      date = DateTimeUtils.parseAndNormalize('${dateStr}T00:00:00');
    }
    final formattedDate = _formatDate(context, date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventDateHeader(text: formattedDate),
        ...events.map((event) {
          return EventListItem(
            event: event,
            onTap: onEventTap,
            onDelete: onDelete,
            navigateAfterDelete: navigateAfterDelete,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return l10n.today;
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return l10n.tomorrow;
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      return l10n.yesterday;
    } else {
      final weekdays = [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];
      final months = [
        l10n.january,
        l10n.february,
        l10n.march,
        l10n.april,
        l10n.may,
        l10n.june,
        l10n.july,
        l10n.august,
        l10n.september,
        l10n.october,
        l10n.november,
        l10n.december,
      ];

      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];

      return '$weekday, ${date.day} ${l10n.dotSeparator} $month';
    }
  }
}
