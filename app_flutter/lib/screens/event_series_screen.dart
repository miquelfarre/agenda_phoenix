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
import '../services/config_service.dart';

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
    print('🗑️ [EventSeriesScreen._deleteEvent] Initiating delete for event: "${event.name}" (ID: ${event.id})');
    try {
      if (event.id == null) {
        print('❌ [EventSeriesScreen._deleteEvent] Error: Event ID is null.');
        throw Exception('Event ID is null');
      }

      final currentUserId = ConfigService.instance.currentUserId;
      final isOwner = event.ownerId == currentUserId;
      final isAdmin = event.interactionType == 'joined' && event.interactionRole == 'admin';
      print('👤 [EventSeriesScreen._deleteEvent] User ID: $currentUserId, Owner ID: ${event.ownerId}, Is Owner: $isOwner, Is Admin: $isAdmin');

      if (isOwner || isAdmin) {
        print('🗑️ [EventSeriesScreen._deleteEvent] User has permission. DELETING event via eventRepositoryProvider.');
        await ref.read(eventRepositoryProvider).deleteEvent(event.id!);
        print('✅ [EventSeriesScreen._deleteEvent] Event DELETED successfully');
      } else {
        print('👋 [EventSeriesScreen._deleteEvent] User is not owner/admin. LEAVING event via eventRepositoryProvider.');
        await ref.read(eventRepositoryProvider).leaveEvent(event.id!);
        print('✅ [EventSeriesScreen._deleteEvent] Event LEFT successfully');
      }

      // Update local list
      if (mounted) {
        setState(() {
          _events.removeWhere((e) => e.id == event.id);
        });
      }

      print('✅ [EventSeriesScreen._deleteEvent] Event removed from series list. Remaining: ${_events.length}');
    } catch (e, s) {
      print('❌ [EventSeriesScreen._deleteEvent] Error: $e');
      print('STACK TRACE: $s');
      rethrow;
    }
  }
}
