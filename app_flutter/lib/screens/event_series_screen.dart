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

class EventSeriesScreen extends ConsumerStatefulWidget {
  final List<Event> events;
  final String seriesName;

  const EventSeriesScreen({super.key, required this.events, required this.seriesName});

  @override
  ConsumerState<EventSeriesScreen> createState() => _EventSeriesScreenState();
}

class _EventSeriesScreenState extends ConsumerState<EventSeriesScreen> {
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
    final sortedEvents = List<Event>.from(_events)..sort((a, b) => a.date.compareTo(b.date));

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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppStyles.grey700),
                  ),
                  const SizedBox(height: 8),
                  Text('${sortedEvents.length} ${sortedEvents.length == 1 ? l10n.event : l10n.events}', style: TextStyle(fontSize: 14, color: AppStyles.grey600)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sortedEvents.isEmpty
                  ? Center(
                      child: EmptyState(message: l10n.noEventsInSeries, icon: CupertinoIcons.calendar),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: sortedEvents.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final event = sortedEvents[index];
                        return EventListItem(
                          event: event,
                          onTap: (event) => Navigator.of(context).push(
                            CupertinoPageRoute(builder: (context) => EventDetailScreen(event: event)),
                          ),
                          onDelete: _deleteEvent,
                          showDate: true,
                          showNewBadge: false,
                          hideInvitationStatus: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    print('🗑️ [EventSeriesScreen._deleteEvent] Delegating to EventOperations');

    final success = await EventOperations.deleteOrLeaveEvent(
      event: event,
      repository: ref.read(eventRepositoryProvider),
      context: context,
      shouldNavigate: shouldNavigate,
      showSuccessMessage: false,
    );

    // Update local list if operation was successful
    if (success && mounted) {
      setState(() {
        _events.removeWhere((e) => e.id == event.id);
      });
      print('✅ [EventSeriesScreen._deleteEvent] Event removed from series list. Remaining: ${_events.length}');
    }
  }
}
