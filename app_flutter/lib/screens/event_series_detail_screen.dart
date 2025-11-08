import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/event.dart';
import '../widgets/event_list_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import 'event_detail_screen.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../core/state/app_state.dart';
import '../utils/event_operations.dart';

class EventSeriesDetailScreen extends ConsumerStatefulWidget {
  final List<Event> events;
  final String seriesName;

  const EventSeriesDetailScreen({
    super.key,
    required this.events,
    required this.seriesName,
  });

  @override
  ConsumerState<EventSeriesDetailScreen> createState() => _EventSeriesDetailScreenState();
}

class _EventSeriesDetailScreenState extends ConsumerState<EventSeriesDetailScreen> {
  late List<Event> _events;

  @override
  void initState() {
    super.initState();
    _events = List<Event>.from(widget.events);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Sort events by date
    final sortedEvents = List<Event>.from(_events)
      ..sort((a, b) => a.date.compareTo(b.date));

    final groupedEvents = _groupEventsByDate(sortedEvents);

    return AdaptivePageScaffold(
      title: l10n.eventSeries,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.seriesName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.grey700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sortedEvents.length} ${sortedEvents.length == 1 ? l10n.event : l10n.events}',
                    style: TextStyle(fontSize: 14, color: AppStyles.grey600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sortedEvents.isEmpty
                  ? Center(
                      child: EmptyState(
                        message: l10n.noEventsInSeries,
                        icon: CupertinoIcons.calendar,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: groupedEvents.length,
                      itemBuilder: (context, index) {
                        final group = groupedEvents[index];
                        return _buildDateGroup(context, group);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
        if (a.isBirthday && !b.isBirthday) return -1;
        if (!a.isBirthday && b.isBirthday) return 1;

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
      date = DateTime.parse('${dateStr}T00:00:00');
    } catch (_) {
      date = DateTime.now();
    }

    final formattedDate = _formatDate(context, date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              formattedDate,
              style: AppStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppStyles.grey700,
              ),
            ),
          ),
          ...events.map((event) {
            return EventListItem(
              event: event,
              onTap: (event) => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              ),
              onDelete: _deleteEvent,
              navigateAfterDelete: false,
              showNewBadge: false,
              hideInvitationStatus: true,
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
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

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    final success = await EventOperations.deleteOrLeaveEvent(
      event: event,
      repository: ref.read(eventRepositoryProvider),
      context: context,
      shouldNavigate: shouldNavigate,
      showSuccessMessage: true,
    );

    // Update local list if operation was successful
    if (success && mounted) {
      setState(() {
        _events.removeWhere((e) => e.id == event.id);
      });
    }
  }
}
