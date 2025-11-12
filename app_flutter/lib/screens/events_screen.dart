import 'package:eventypop/ui/helpers/platform/platform_detection.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/domain/event.dart';
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
import '../utils/event_permissions.dart';
import '../utils/event_operations.dart';
import '../widgets/voice_command_button.dart';
import '../utils/event_date_utils.dart';
import '../widgets/event_date_section.dart';

// Helper class to store event with interaction type
class EventWithInteraction {
  final Event event;
  final String? interactionType;
  final String? invitationStatus;
  final bool isAttending;

  EventWithInteraction(
    this.event,
    this.interactionType,
    this.invitationStatus, {
    this.isAttending = false,
  });
}

// Helper class to store event data with filter counts
class EventsData {
  final List<EventWithInteraction> events;
  final int myEventsCount;
  final int invitationsCount;
  final int subscribedCount;
  final int allCount;

  EventsData({
    required this.events,
    required this.myEventsCount,
    required this.invitationsCount,
    required this.subscribedCount,
    required this.allCount,
  });
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

  // Helper functions to classify events clearly
  static bool _isMyEvent(EventWithInteraction item) {
    // Events I own or can edit
    return EventPermissions.canEdit(event: item.event);
  }

  static bool _isAcceptedInvitation(EventWithInteraction item) {
    // I was invited and accepted
    return item.interactionType == 'invited' &&
        item.invitationStatus == 'accepted';
  }

  static bool _isAcceptedJoin(EventWithInteraction item) {
    // I joined publicly and it was accepted
    return item.interactionType == 'joined' &&
        item.invitationStatus == 'accepted';
  }

  static bool _isAcceptedRequest(EventWithInteraction item) {
    // I requested to join and it was accepted
    return item.interactionType == 'requested' &&
        item.invitationStatus == 'accepted';
  }

  static bool _isRejectedButAttending(EventWithInteraction item) {
    // Special case: rejected invitation but still attending
    return item.invitationStatus == 'rejected' && item.isAttending;
  }

  static bool _isPendingInvitation(EventWithInteraction item, int userId) {
    // I received an invitation that's pending or rejected (but not attending)
    return item.event.ownerId != userId &&
        item.interactionType == 'invited' &&
        item.invitationStatus != 'accepted' &&
        !_isRejectedButAttending(item);
  }

  static bool _isPendingRequest(EventWithInteraction item, int userId) {
    // I requested to join and it's pending or rejected
    return item.event.ownerId != userId &&
        item.interactionType == 'requested' &&
        item.invitationStatus != 'accepted';
  }

  static bool _isSubscription(EventWithInteraction item, int userId) {
    // I'm subscribed to someone's public calendar
    // OR this event comes from a subscribed calendar
    return item.event.ownerId != userId &&
        (item.interactionType == 'subscribed' ||
            item.interactionType == 'subscribed_calendar');
  }

  static bool _isCalendarMember(EventWithInteraction item) {
    // I'm a member of a calendar that contains this event
    return item.interactionType == 'calendar' &&
        item.invitationStatus == 'accepted';
  }

  static bool _belongsToMyEvents(EventWithInteraction item) {
    // All events that should appear in "My Events" filter
    return _isMyEvent(item) ||
        _isAcceptedInvitation(item) ||
        _isAcceptedJoin(item) ||
        _isAcceptedRequest(item) ||
        _isRejectedButAttending(item) ||
        _isCalendarMember(item);
  }

  static bool _belongsToInvitations(EventWithInteraction item, int userId) {
    // All events that should appear in "Invitations" filter
    return _isPendingInvitation(item, userId) ||
        _isPendingRequest(item, userId);
  }

  static bool _belongsToSubscriptions(EventWithInteraction item, int userId) {
    // All events that should appear in "Subscriptions" filter
    return _isSubscription(item, userId);
  }

  // Build EventsData from event list (pure function)
  static EventsData _buildEventsData(List<Event> events) {
    final userId = ConfigService.instance.currentUserId;

    print('🔍 [DEBUG] Total events received from backend: ${events.length}');

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

      eventItems.add(
        EventWithInteraction(
          event,
          interactionType,
          invitationStatus,
          isAttending: isAttending,
        ),
      );
    }

    // Count events for each filter using helper functions
    final myEvents = eventItems.where(_belongsToMyEvents).length;
    final invitations = eventItems
        .where((e) => _belongsToInvitations(e, userId))
        .length;
    final subscribed = eventItems
        .where((e) => _belongsToSubscriptions(e, userId))
        .length;

    print('🔍 [DEBUG] Event counts:');
    print('  - My Events: $myEvents');
    print('  - Invitations: $invitations');
    print('  - Subscriptions: $subscribed');
    print('  - All: ${eventItems.length}');
    print('  - Sum (My+Inv+Subs): ${myEvents + invitations + subscribed}');
    print(
      '  - Difference (All - Sum): ${eventItems.length - (myEvents + invitations + subscribed)}',
    );

    // Debug: find events that don't belong to any category
    final uncategorized = eventItems
        .where(
          (e) =>
              !_belongsToMyEvents(e) &&
              !_belongsToInvitations(e, userId) &&
              !_belongsToSubscriptions(e, userId),
        )
        .toList();

    if (uncategorized.isNotEmpty) {
      print('⚠️  [DEBUG] Found ${uncategorized.length} uncategorized events:');
      for (var item in uncategorized.take(5)) {
        print('    - Event: ${item.event.name}');
        print('      owner_id: ${item.event.ownerId} (current: $userId)');
        print('      interaction_type: ${item.interactionType}');
        print('      status: ${item.invitationStatus}');
        print('      is_attending: ${item.isAttending}');
      }
    }

    return EventsData(
      events: eventItems,
      myEventsCount: myEvents,
      invitationsCount: invitations,
      subscribedCount: subscribed,
      allCount: eventItems.length,
    );
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
      data: (events) => _buildBody(
        context,
        eventsData: _buildEventsData(events),
        isIOS: isIOS,
      ),
      loading: () => Center(child: PlatformWidgets.platformLoadingIndicator()),
      error: (e, _) => Center(child: Text('${context.l10n.error}: $e')),
    );

    if (isIOS) {
      body = Stack(
        children: [
          body,
          // Botón de crear evento
          Positioned(
            bottom: 100,
            right: 20,
            child: Tooltip(
              message: l10n.createEvent,
              child: AdaptiveButton(
                config: const AdaptiveButtonConfig(
                  variant: ButtonVariant.fab,
                  size: ButtonSize.medium,
                  fullWidth: false,
                  iconPosition: IconPosition.only,
                ),
                icon: CupertinoIcons.add,
                onPressed: _showCreateEventOptions,
              ),
            ),
          ),
          // Botón de comandos de voz
          Positioned(
            bottom: 20,
            right: 20,
            child: VoiceCommandFab(
              onCommandExecuted: (result) {
                // Refrescar lista de eventos
                ref.invalidate(eventsStreamProvider);
              },
            ),
          ),
        ],
      );
    }

    return AdaptivePageScaffold(
      key: const Key('events_screen_scaffold'),
      title: l10n.events,
      body: body,
      floatingActionButton: !isIOS
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Botón de comandos de voz
                VoiceCommandFab(
                  onCommandExecuted: (result) {
                    // Refrescar lista de eventos
                    ref.invalidate(eventsStreamProvider);
                  },
                ),
                const SizedBox(height: 16),
                // Botón de crear evento
                Tooltip(
                  message: l10n.createEvent,
                  child: AdaptiveButton(
                    config: const AdaptiveButtonConfig(
                      variant: ButtonVariant.fab,
                      size: ButtonSize.medium,
                      fullWidth: false,
                      iconPosition: IconPosition.only,
                    ),
                    icon: CupertinoIcons.add,
                    onPressed: _showCreateEventOptions,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required EventsData eventsData,
    required bool isIOS,
  }) {
    return SafeArea(child: _buildContent(eventsData, isIOS));
  }

  Widget _buildContent(EventsData eventsData, bool isIOS) {
    final bool isFiltered = _currentFilter != 'all' || _searchQuery.isNotEmpty;

    // Get all events for filter chips
    final allEvents = eventsData.events.map((item) => item.event).toList();

    // Filter with interaction data first
    List<EventWithInteraction> filteredItems =
        _applyEventTypeFilterWithInteraction(eventsData.events, _currentFilter);

    // Then extract events and apply search
    List<Event> events = filteredItems.map((item) => item.event).toList();
    if (_searchQuery.isNotEmpty) {
      events = _applySearchFilter(events, _searchQuery);
    }

    return SafeArea(
      child: CustomScrollView(
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
                      return name != null && name.isNotEmpty
                          ? l10n.helloWithName(name)
                          : l10n.hello;
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
                      style: AppStyles.headlineSmall.copyWith(
                        color: AppStyles.grey700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchField(isIOS),
            ),
          ),

          SliverToBoxAdapter(
            child: _buildEventTypeFilters(
              context,
              eventsData,
              allEvents,
              isFiltered,
            ),
          ),

          _buildSliverContent(events, isFiltered, isIOS),
        ],
      ),
    );
  }

  Widget _buildSliverContent(List<Event> events, bool isFiltered, bool isIOS) {
    if (events.isEmpty && isFiltered) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildNoSearchResults(isIOS),
      );
    } else if (events.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(isIOS),
      );
    } else {
      return _buildSliverEventsList(events);
    }
  }

  Widget _buildSliverEventsList(List<Event> events) {
    final groupedEvents = EventDateUtils.groupEventsByDate(events);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final group = groupedEvents[index];
        return _buildDateGroup(context, group);
      }, childCount: groupedEvents.length),
    );
  }

  Widget _buildDateGroup(BuildContext context, Map<String, dynamic> group) {
    return EventDateSection(
      dateGroup: group,
      eventBuilder: (event) {
        // Show invitation status badge ONLY for invitations
        final isInvitation = event.interactionType == 'invited';
        final shouldShowStatus =
            _currentFilter == 'invitations' ||
            (_currentFilter == 'all' && isInvitation);

        return EventListItem(
          event: event,
          onTap: _navigateToEventDetail,
          onDelete: _deleteEvent,
          navigateAfterDelete: false,
          hideInvitationStatus: !shouldShowStatus,
        );
      },
    );
  }

  Widget _buildEventTypeFilters(
    BuildContext context,
    EventsData eventsData,
    List<Event> allEvents,
    bool isFiltered,
  ) {
    final l10n = context.l10n;
    final currentFilter = _currentFilter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      child: Row(
        children: [
          _buildFilterChip(
            'all',
            l10n.allEvents,
            eventsData.allCount,
            currentFilter == 'all',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'my',
            l10n.myEventsFilter,
            eventsData.myEventsCount,
            currentFilter == 'my',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'subscribed',
            l10n.subscribedEvents,
            eventsData.subscribedCount,
            currentFilter == 'subscribed',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'invitations',
            l10n.invitationEvents,
            eventsData.invitationsCount,
            currentFilter == 'invitations',
          ),
        ],
      ),
    );
  }

  List<EventWithInteraction> _applyEventTypeFilterWithInteraction(
    List<EventWithInteraction> items,
    String filter,
  ) {
    final userId = ConfigService.instance.currentUserId;

    switch (filter) {
      case 'my':
        // My Events: All events I own or am participating in
        return items.where(_belongsToMyEvents).toList();

      case 'subscribed':
        // Subscriptions: Events from public calendars I follow
        return items
            .where((item) => _belongsToSubscriptions(item, userId))
            .toList();

      case 'invitations':
        // Invitations: Pending invitations and requests
        return items
            .where((item) => _belongsToInvitations(item, userId))
            .toList();

      case 'all':
      default:
        // All events without filtering
        return items;
    }
  }

  List<Event> _applySearchFilter(List<Event> events, String query) {
    if (query.isEmpty) return events;

    final lowerQuery = query.toLowerCase();
    return events.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
          (event.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Widget _buildFilterChip(
    String value,
    String label,
    int? count,
    bool isSelected,
  ) {
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
            border: Border.all(
              color: isSelected ? AppStyles.blue600 : AppStyles.grey300,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppStyles.bodyTextSmall.copyWith(
                  color: isSelected ? AppStyles.white : AppStyles.grey700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (count != null) ...[
                const SizedBox(height: 2),
                Text(
                  count.toString(),
                  style: AppStyles.bodyTextSmall.copyWith(
                    color: isSelected ? AppStyles.white : AppStyles.grey600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
      prefixIcon: PlatformWidgets.platformIcon(
        CupertinoIcons.search,
        color: AppStyles.grey600,
      ),
      suffixIcon: _searchQuery.isNotEmpty
          ? AdaptiveButton(
              key: const Key('events_search_clear_button'),
              config: const AdaptiveButtonConfig(
                variant: ButtonVariant.icon,
                size: ButtonSize.small,
                fullWidth: false,
                iconPosition: IconPosition.only,
              ),
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
    await Navigator.of(context).push(
      PlatformNavigation.platformPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    await EventOperations.deleteOrLeaveEvent(
      event: event,
      repository: ref.read(eventRepositoryProvider),
      context: context,
      shouldNavigate: shouldNavigate,
      showSuccessMessage: true,
    );
    // EventRepository handles updates via Realtime, but we manually remove
    // for non-owners as RLS policies can prevent the DELETE event from broadcasting.
  }

  void _navigateToCreateEvent() async {
    await Navigator.of(context).push(
      PlatformNavigation.platformPageRoute(
        builder: (context) => const CreateEditEventScreen(),
      ),
    );
  }

  void _showCreateEventOptions() {
    _navigateToCreateEvent();
  }
}
