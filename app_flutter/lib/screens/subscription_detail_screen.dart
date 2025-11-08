import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../widgets/event_list_item.dart';
import 'event_detail_screen.dart';
import '../core/state/app_state.dart';
import '../ui/styles/app_styles.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final User publicUser;

  const SubscriptionDetailScreen({super.key, required this.publicUser});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isProcessingSubscription = false;

  final Set<int> _hiddenEventIds = <int>{};

  List<Event> _events = [];
  bool _isSubscribed = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEvents);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    if (_isLoading && !_isProcessingSubscription) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
      final events = await subscriptionRepo.fetchUserEvents(
        widget.publicUser.id,
      );

      // Check if user is subscribed by looking at the subscriptions stream
      final subscriptionsAsync = ref.read(subscriptionsStreamProvider);
      final subscriptions = subscriptionsAsync.when(
        data: (subs) => subs,
        loading: () => <User>[],
        error: (error, stack) => <User>[],
      );
      final isSubscribed = subscriptions.any(
        (sub) => sub.id == widget.publicUser.id,
      );

      if (mounted) {
        setState(() {
          _events = events;
          _isSubscribed = isSubscribed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEvents() async {
    _hiddenEventIds.clear();
    await _loadData();
  }

  Future<void> _subscribeToUser() async {
    if (_isProcessingSubscription) {
      return;
    }

    setState(() => _isProcessingSubscription = true);

    try {
      final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
      await subscriptionRepo.subscribeToUser(widget.publicUser.id);

      if (mounted) {
        final userName = widget.publicUser.contactName ??
                        widget.publicUser.instagramName ??
                        'Usuario';
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.subscribedTo(userName),
        );
      }

      // Realtime handles refresh automatically via SubscriptionRepository

      await _loadData();
    } catch (e) {
      if (mounted) {
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: 'Error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingSubscription = false);
    }
  }

  Future<void> _unsubscribeFromUser() async {
    if (_isProcessingSubscription) {
      return;
    }

    setState(() => _isProcessingSubscription = true);

    try {
      final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
      await subscriptionRepo.unsubscribeFromUser(widget.publicUser.id);

      if (mounted) {
        final userName = widget.publicUser.contactName ??
                        widget.publicUser.instagramName ??
                        'Usuario';
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.unsubscribedFrom(userName),
        );
      }

      // Realtime handles refresh automatically via SubscriptionRepository

      await _loadData();
    } catch (e) {
      if (mounted) {
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: 'Error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingSubscription = false);
    }
  }

  List<Event> _applySearchAndStatusFilters(List<Event> events) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<Event> result = events;

    if (query.isNotEmpty) {
      result = result.where(
        (event) =>
            event.title.toLowerCase().contains(query) ||
            (event.description?.toLowerCase().contains(query) ?? false),
      );
    }

    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '${AppLocalizations.of(context)!.events} - ${widget.publicUser.contactName ?? widget.publicUser.instagramName ?? 'User'}',
          style: const TextStyle(fontSize: 16),
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onPressed: _isProcessingSubscription
              ? null
              : _isSubscribed
              ? () {
                  _unsubscribeFromUser();
                }
              : () {
                  _subscribeToUser();
                },
          child: Text(
            _isSubscribed
                ? AppLocalizations.of(context)!.unfollow
                : AppLocalizations.of(context)!.follow,
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.errorLoadingEvents,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _refreshEvents,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    List<Event> baseEvents = _events;

    baseEvents = baseEvents
        .where((e) => e.id == null || !_hiddenEventIds.contains(e.id))
        .toList();

    final eventsToShow = _applySearchAndStatusFilters(baseEvents);
    final groupedEvents = _groupEventsByDate(eventsToShow);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: AppLocalizations.of(context)!.searchEvents,
              backgroundColor: CupertinoColors.systemGrey6.resolveFrom(context),
            ),
          ),
        ),

        if (eventsToShow.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? AppLocalizations.of(context)!.noEventsFound
                        : AppLocalizations.of(context)!.noEvents,
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...groupedEvents.map((group) {
            return SliverToBoxAdapter(
              child: _buildDateGroup(context, group),
            );
          }),
      ],
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
              onTap: (event) {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => EventDetailScreen(event: event),
                  ),
                );
              },
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

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    try {
      if (event.id == null) {
        throw Exception('Event ID is null');
      }

      // Public user events can only be LEFT, never DELETED
      // (user is never owner/admin of public user events)
      await ref.read(eventRepositoryProvider).leaveEvent(event.id!);

      // Remove from local list
      if (mounted) {
        setState(() {
          _events.removeWhere((e) => e.id == event.id);
        });
      }
    } catch (e, _) {
      rethrow;
    }
  }
}
