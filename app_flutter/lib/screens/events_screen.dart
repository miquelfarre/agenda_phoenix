import 'package:eventypop/ui/helpers/platform/platform_detection.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/event.dart';
import '../models/event_list_composite.dart' as composite;
import '../core/state/app_state.dart';
import '../widgets/event_list_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import 'event_detail_screen.dart';
import 'create_edit_event_screen.dart';

import '../services/config_service.dart';
import '../services/event_service.dart';
import '../services/supabase_service.dart';
import '../widgets/adaptive/adaptive_button.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:flutter/material.dart';
import '../core/monitoring/performance_monitor.dart';

// Helper class to store event item with interaction type
class EventItemWithType {
  final composite.EventListItem item;
  final String? interactionType;

  EventItemWithType(this.item, this.interactionType);
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
  composite.EventListComposite? _composite;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _loadData();
  }

  Future<void> _loadData() async {
    print('🔵 [EventsScreen] _loadData START');
    setState(() => _isLoading = true);
    try {
      print('🔵 [EventsScreen] Loading events from Supabase...');
      final userId = ConfigService.instance.currentUserId;
      final eventsData = await SupabaseService.instance.fetchEventsForUser(userId);

      // Convert Supabase data to EventListItem
      final eventItems = <EventItemWithType>[];
      for (final data in eventsData) {
        final interactions = (data['interactions'] as List?) ?? [];
        final myInteraction = interactions.firstWhere(
          (i) => i['user_id'] == userId,
          orElse: () => null,
        );

        final interactionType = myInteraction?['interaction_type'] as String?;
        final invitationStatus = myInteraction?['status'] as String?;

        final item = composite.EventListItem(
          id: data['id'],
          title: data['name'] ?? 'Untitled',
          description: data['description'],
          date: DateTime.parse(data['start_date']),
          isPublished: data['event_type'] != 'draft',
          isBirthday: data['event_type'] == 'birthday',
          isRecurring: data['event_type'] == 'recurring',
          ownerId: data['owner_id'],
          owner: data['owner'],
          invitationStatus: invitationStatus,
          inviterId: myInteraction?['invited_by_user_id'],
          inviter: null,
          attendeeCount: interactions.where((i) => i['status'] == 'accepted').length,
          attendees: interactions.where((i) => i['status'] == 'accepted').toList(),
          calendarId: data['calendar_id'],
          calendarName: data['calendar']?['name'],
          calendarColor: null,
        );

        eventItems.add(EventItemWithType(item, interactionType));
      }

      // Calculate filters
      final myEvents = eventItems.where((e) => e.item.ownerId == userId && e.interactionType == null).length;
      final invitations = eventItems.where((e) =>
        e.interactionType == 'invited' && e.item.invitationStatus == 'pending'
      ).length;
      final subscribed = eventItems.where((e) =>
        e.interactionType == 'subscribed' ||
        (e.interactionType == 'joined' && e.item.invitationStatus == 'accepted')
      ).length;

      final filters = composite.FilterCounts(
        all: eventItems.length,
        my: myEvents,
        subscribed: subscribed,
        invitations: invitations,
      );

      // Extract just the items for the composite
      final justItems = eventItems.map((e) => e.item).toList();

      final compositeData = composite.EventListComposite(
        events: justItems,
        filters: filters,
        checksum: DateTime.now().millisecondsSinceEpoch.toString(), // No longer used
      );

      print('🔵 [EventsScreen] Loaded ${justItems.length} events from Supabase');

      if (mounted) {
        setState(() {
          _composite = compositeData;
          _isLoading = false;
        });
        print('🔵 [EventsScreen] setState completed, _isLoading=false');
      }
    } catch (e) {
      print('🔴 [EventsScreen] ERROR in _loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    Widget body = _buildBody(context, isIOS: isIOS);

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
                config: const AdaptiveButtonConfig(
                  variant: ButtonVariant.fab,
                  size: ButtonSize.medium,
                  fullWidth: false,
                  iconPosition: IconPosition.only,
                ),
                icon: CupertinoIcons.add,
                onPressed: _showCreateEventOptions,
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, {required bool isIOS}) {
    return SafeArea(child: _buildContent(isIOS));
  }

  Widget _buildContent(bool isIOS) {
    if (_isLoading || _composite == null) {
      return Center(child: PlatformWidgets.platformLoadingIndicator());
    }

    final bool isFiltered = _currentFilter != 'all' || _searchQuery.isNotEmpty;

    final allEvents = _composite!.events.map((item) => item.toEvent()).toList();

    List<Event> events = _applyEventTypeFilter(allEvents, _currentFilter);
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
                final authAsync = ref.watch(
                  authProvider.select(
                    (state) => state.whenData((s) => s.currentUser),
                  ),
                );
                String greeting = authAsync.maybeWhen(
                  data: (user) {
                    final name = user?.displayName.trim();
                    return name != null && name.isNotEmpty
                        ? 'Hello $name!'
                        : 'Hello!';
                  },
                  loading: () {
                    return 'Hello!';
                  },
                  error: (err, stack) {
                    return 'Hello!';
                  },
                  orElse: () => 'Hello!',
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
          child: _buildEventTypeFilters(context, allEvents, isFiltered),
        ),

        _buildSliverContent(events, isFiltered, isIOS),
      ],
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
      date = DateTime.parse('${dateStr}T00:00:00');
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
              onTap: _navigateToEventDetail,
              onDelete: _deleteEvent,
              navigateAfterDelete: false,
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

  Widget _buildEventTypeFilters(
    BuildContext context,
    List<Event> allEvents,
    bool isFiltered,
  ) {
    final l10n = context.l10n;
    final currentFilter = _currentFilter;

    final filters = _composite?.filters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      child: Row(
        children: [
          _buildFilterChip(
            'all',
            l10n.allEvents,
            filters?.all ?? allEvents.length,
            currentFilter == 'all',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'my',
            l10n.myEventsFilter,
            filters?.my ?? 0,
            currentFilter == 'my',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'subscribed',
            l10n.subscribedEvents,
            filters?.subscribed ?? 0,
            currentFilter == 'subscribed',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'invitations',
            l10n.invitationEvents,
            filters?.invitations ?? 0,
            currentFilter == 'invitations',
          ),
        ],
      ),
    );
  }

  List<Event> _applyEventTypeFilter(List<Event> events, String filter) {
    final userId = ConfigService.instance.currentUserId;

    switch (filter) {
      case 'my':
        return events.where((e) => e.ownerId == userId).toList();
      case 'subscribed':
        return events
            .where((e) => e.ownerId != userId && e.owner?.isPublic == true)
            .toList();
      case 'invitations':
        return events
            .where((e) => e.ownerId != userId && e.owner?.isPublic != true)
            .toList();
      case 'all':
      default:
        return events;
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
      suffixIcon: _searchController.text.isNotEmpty
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
    await PerformanceMonitor.instance.trackPerformance(
      'navigation_event_detail',
      () async {
        await Navigator.of(context).push(
          PlatformNavigation.platformPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      metadata: {'event_id': event.id, 'screen_name': 'EventsScreen'},
    );
  }

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    await PerformanceMonitor.instance.trackPerformance(
      'events_screen_delete',
      () async {
        try {
          final currentUserId = ConfigService.instance.currentUserId;
          final isOwner = event.ownerId == currentUserId;

          if (isOwner) {
            await EventService().deleteEvent(event.id!);
          } else {}

          // Supabase handles caching automatically via realtime
          await _loadData();
        } catch (e) {
          rethrow;
        }
      },
      metadata: {
        'event_id': event.id,
        'screen_name': 'EventsScreen',
        'should_navigate': shouldNavigate,
      },
    );
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
