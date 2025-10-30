import 'package:eventypop/ui/helpers/platform/platform_detection.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/event.dart';
import '../core/state/app_state.dart';
import '../widgets/event_list_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import 'event_detail_screen.dart';
import 'create_edit_event_screen.dart';

import '../services/config_service.dart';
import '../widgets/adaptive/adaptive_button.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:flutter/material.dart';

// Helper class to store event with interaction type
class EventWithInteraction {
  final Event event;
  final String? interactionType;
  final String? invitationStatus;
  final bool isAttending;

  EventWithInteraction(this.event, this.interactionType, this.invitationStatus, {this.isAttending = false});
}

// Helper class to store event data with filter counts
class EventsData {
  final List<EventWithInteraction> events;
  final int myEventsCount;
  final int invitationsCount;
  final int subscribedCount;
  final int allCount;

  EventsData({required this.events, required this.myEventsCount, required this.invitationsCount, required this.subscribedCount, required this.allCount});
}

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // Build EventsData from event list (pure function)
  static EventsData _buildEventsData(List<Event> events) {
    final userId = ConfigService.instance.currentUserId;

    final eventItems = <EventWithInteraction>[];
    for (final event in events) {
      final eventOwnerId = event.ownerId;
      final isOwner = eventOwnerId == userId;

      String? interactionType;
      String? invitationStatus;
      bool isAttending = false;

      if (!isOwner && event.interactionData != null) {
        interactionType = event.interactionData!['interaction_type'] as String?;
        invitationStatus = event.interactionData!['status'] as String?;
        isAttending = event.interactionData!['is_attending'] as bool? ?? false;
      }

      eventItems.add(EventWithInteraction(event, interactionType, invitationStatus, isAttending: isAttending));
    }

    final myEvents = eventItems.where((e) => e.event.ownerId == userId || (e.event.ownerId != userId && e.interactionType == 'joined' && e.event.interactionRole == 'admin') || (e.invitationStatus == 'rejected' && e.isAttending)).length;
    final invitations = eventItems.where((e) => e.event.ownerId != userId && e.interactionType == 'invited' && !(e.invitationStatus == 'rejected' && e.isAttending)).length;
    final subscribed = eventItems.where((e) => e.event.ownerId != userId && e.interactionType == 'subscribed').length;

    return EventsData(events: eventItems, myEventsCount: myEvents, invitationsCount: invitations, subscribedCount: subscribed, allCount: eventItems.length);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformDetection.isIOS;
    final l10n = context.l10n;

    // Watch events from StreamProvider
    final eventsAsync = ref.watch(eventsStreamProvider);

    Widget body = eventsAsync.when(
      data: (events) => _buildBody(context, eventsData: _buildEventsData(events), isIOS: isIOS),
      loading: () => Center(child: PlatformWidgets.platformLoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );

    if (isIOS) {
      body = Stack(
        children: [
          body,
          Positioned(
            bottom: 100,
            right: 20,
            child: Tooltip(
              message: l10n.createEvent,
              child: AdaptiveButton(
                config: const AdaptiveButtonConfig(variant: ButtonVariant.fab, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only),
                icon: CupertinoIcons.add,
                onPressed: _showCreateEventOptions,
              ),
            ),
          ),
        ],
      );
    }

    return AdaptivePageScaffold(
      key: const Key('events_screen_scaffold'),
      title: isIOS ? null : l10n.events,
      body: body,
      floatingActionButton: !isIOS
          ? Tooltip(
              message: l10n.createEvent,
              child: AdaptiveButton(
                config: const AdaptiveButtonConfig(variant: ButtonVariant.fab, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only),
                icon: CupertinoIcons.add,
                onPressed: _showCreateEventOptions,
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, {required EventsData eventsData, required bool isIOS}) {
    return SafeArea(child: _buildContent(eventsData, isIOS));
  }

  Widget _buildContent(EventsData eventsData, bool isIOS) {
    final bool isFiltered = _currentFilter != 'all' || _searchQuery.isNotEmpty;

    // Get all events for filter chips
    final allEvents = eventsData.events.map((item) => item.event).toList();

    // Filter with interaction data first
    List<EventWithInteraction> filteredItems = _applyEventTypeFilterWithInteraction(eventsData.events, _currentFilter);

    // Then extract events and apply search
    List<Event> events = filteredItems.map((item) => item.event).toList();
    if (_searchQuery.isNotEmpty) {
      events = _applySearchFilter(events, _searchQuery);
    }

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Consumer(
              builder: (context, ref, _) {
                final authAsync = ref.watch(currentUserStreamProvider);
                final l10n = context.l10n;
                String greeting = authAsync.maybeWhen(
                  data: (user) {
                    final name = user?.displayName.trim();
                    return name != null && name.isNotEmpty ? l10n.helloWithName(name) : l10n.hello;
                  },
                  loading: () {
                    return l10n.hello;
                  },
                  error: (err, stack) {
                    return l10n.hello;
                  },
                  orElse: () => l10n.hello,
                );
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    greeting,
                    style: AppStyles.headlineSmall.copyWith(color: AppStyles.grey700, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.all(16.0), child: _buildSearchField(isIOS)),
        ),

        SliverToBoxAdapter(child: _buildEventTypeFilters(context, eventsData, allEvents, isFiltered)),

        _buildSliverContent(events, isFiltered, isIOS),
      ],
    );
  }

  Widget _buildSliverContent(List<Event> events, bool isFiltered, bool isIOS) {
    if (events.isEmpty && isFiltered) {
      return SliverFillRemaining(hasScrollBody: false, child: _buildNoSearchResults(isIOS));
    } else if (events.isEmpty) {
      return SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(isIOS));
    } else {
      return _buildSliverEventsList(events);
    }
  }

  Widget _buildSliverEventsList(List<Event> events) {
    final groupedEvents = _groupEventsByDate(events);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final group = groupedEvents[index];
        return _buildDateGroup(context, group);
      }, childCount: groupedEvents.length),
    );
  }

  List<Map<String, dynamic>> _groupEventsByDate(List<Event> events) {
    final Map<String, List<Event>> groupedMap = {};

    for (final event in events) {
      final eventDate = event.date;
      final dateKey = '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

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

    groupedList.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return groupedList;
  }

  Widget _buildDateGroup(BuildContext context, Map<String, dynamic> group) {
    final dateStr = group['date'] as String;
    final events = group['events'] as List<Event>;

    DateTime date;
    try {
      date = DateTime.parse('${dateStr}T00:00:00');
    } catch (_) {
      // Fallback: use current date if parsing fails
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
              style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppStyles.grey700),
            ),
          ),
          ...events.map((event) {
            // Show invitation status badge ONLY for invitations
            final isInvitation = event.interactionType == 'invited';
            final shouldShowStatus = _currentFilter == 'invitations' || (_currentFilter == 'all' && isInvitation);

            return EventListItem(event: event, onTap: _navigateToEventDetail, onDelete: _deleteEvent, navigateAfterDelete: false, hideInvitationStatus: !shouldShowStatus);
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
      final weekdays = [l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];
      final months = [l10n.january, l10n.february, l10n.march, l10n.april, l10n.may, l10n.june, l10n.july, l10n.august, l10n.september, l10n.october, l10n.november, l10n.december];

      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];

      return '$weekday, ${date.day} ${l10n.dotSeparator} $month';
    }
  }

  Widget _buildEventTypeFilters(BuildContext context, EventsData eventsData, List<Event> allEvents, bool isFiltered) {
    final l10n = context.l10n;
    final currentFilter = _currentFilter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      child: Row(
        children: [
          _buildFilterChip('all', l10n.allEvents, eventsData.allCount, currentFilter == 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('my', l10n.myEventsFilter, eventsData.myEventsCount, currentFilter == 'my'),
          const SizedBox(width: 8),
          _buildFilterChip('subscribed', l10n.subscribedEvents, eventsData.subscribedCount, currentFilter == 'subscribed'),
          const SizedBox(width: 8),
          _buildFilterChip('invitations', l10n.invitationEvents, eventsData.invitationsCount, currentFilter == 'invitations'),
        ],
      ),
    );
  }

  List<EventWithInteraction> _applyEventTypeFilterWithInteraction(List<EventWithInteraction> items, String filter) {
    final userId = ConfigService.instance.currentUserId;

    switch (filter) {
      case 'my':
        // My Events: events I own + events where I'm admin + events with rejected invitation but attending
        return items.where((item) => item.event.ownerId == userId || (item.event.ownerId != userId && item.interactionType == 'joined' && item.event.interactionRole == 'admin') || (item.invitationStatus == 'rejected' && item.isAttending)).toList();
      case 'subscribed':
        return items.where((item) => item.event.ownerId != userId && item.interactionType == 'subscribed').toList();
      case 'invitations':
        return items.where((item) => item.event.ownerId != userId && item.interactionType == 'invited' && !(item.invitationStatus == 'rejected' && item.isAttending)).toList();
      case 'all':
      default:
        return items;
    }
  }

  List<Event> _applySearchFilter(List<Event> events, String query) {
    if (query.isEmpty) return events;

    final lowerQuery = query.toLowerCase();
    return events.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) || (event.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Widget _buildFilterChip(String value, String label, int? count, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppStyles.blue600 : AppStyles.grey100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppStyles.blue600 : AppStyles.grey300, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppStyles.bodyTextSmall.copyWith(color: isSelected ? AppStyles.white : AppStyles.grey700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                textAlign: TextAlign.center,
              ),
              if (count != null) ...[
                const SizedBox(height: 2),
                Text(
                  count.toString(),
                  style: AppStyles.bodyTextSmall.copyWith(color: isSelected ? AppStyles.white : AppStyles.grey600, fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isIOS) {
    final l10n = context.l10n;
    return PlatformWidgets.platformTextField(
      controller: _searchController,
      placeholder: l10n.searchEvents,
      prefixIcon: PlatformWidgets.platformIcon(CupertinoIcons.search, color: AppStyles.grey600),
      suffixIcon: _searchQuery.isNotEmpty
          ? AdaptiveButton(
              key: const Key('events_search_clear_button'),
              config: const AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.small, fullWidth: false, iconPosition: IconPosition.only),
              icon: CupertinoIcons.clear,
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            )
          : null,
    );
  }

  Widget _buildNoSearchResults(bool isIOS) {
    final l10n = context.l10n;
    return EmptyState(message: l10n.noEventsFound, icon: CupertinoIcons.search);
  }

  Widget _buildEmptyState(bool isIOS) {
    final l10n = context.l10n;
    return EmptyState(message: l10n.noEvents, icon: CupertinoIcons.calendar);
  }

  void _navigateToEventDetail(Event event) async {
    await Navigator.of(context).push(PlatformNavigation.platformPageRoute(builder: (context) => EventDetailScreen(event: event)));
  }

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    print('🗑️ [_deleteEvent] Initiating delete for event: "${event.name}" (ID: ${event.id})');
    try {
      if (event.id == null) {
        print('❌ [_deleteEvent] Error: Event ID is null.');
        throw Exception('Event ID is null');
      }

      final currentUserId = ConfigService.instance.currentUserId;
      final isOwner = event.ownerId == currentUserId;
      final isAdmin = event.interactionType == 'joined' && event.interactionRole == 'admin';
      print('👤 [_deleteEvent] User ID: $currentUserId, Owner ID: ${event.ownerId}, Is Owner: $isOwner, Is Admin: $isAdmin');

      if (isOwner || isAdmin) {
        print('🗑️ [_deleteEvent] User has permission. DELETING event via eventRepositoryProvider.');
        await ref.read(eventRepositoryProvider).deleteEvent(event.id!);
        print('✅ [_deleteEvent] Event DELETED successfully');
      } else {
        print('👋 [_deleteEvent] User is not owner/admin. LEAVING event via eventRepositoryProvider.');
        await ref.read(eventRepositoryProvider).leaveEvent(event.id!);
        print('✅ [_deleteEvent] Event LEFT successfully');
      }

      if (shouldNavigate && mounted) {
        print('➡️ [_deleteEvent] Navigating back.');
        Navigator.of(context).pop();
      }

      print('✅ [_deleteEvent] Operation completed for event ID: ${event.id}');
      // EventRepository handles updates via Realtime, but we manually remove
      // for non-owners as RLS policies can prevent the DELETE event from broadcasting.
    } catch (e, s) {
      print('❌ [_deleteEvent] Error: $e');
      print('STACK TRACE: $s');
      rethrow;
    }
  }

  void _navigateToCreateEvent() async {
    await Navigator.of(context).push(PlatformNavigation.platformPageRoute(builder: (context) => const CreateEditEventScreen()));
  }

  void _showCreateEventOptions() {
    _navigateToCreateEvent();
  }
}
