import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../widgets/event_list_item.dart';
import '../widgets/searchable_list.dart';
import 'event_detail_screen.dart';
import '../core/state/app_state.dart';
import '../utils/event_date_utils.dart';
import '../widgets/event_date_section.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final User publicUser;

  const SubscriptionDetailScreen({super.key, required this.publicUser});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  bool _isProcessingSubscription = false;

  final Set<int> _hiddenEventIds = <int>{};

  List<Event> _events = [];
  bool _isSubscribed = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
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

    return SearchableList<Event>(
      items: baseEvents,
      filterFunction: (event, query) {
        return event.title.toLowerCase().contains(query) ||
            (event.description?.toLowerCase().contains(query) ?? false);
      },
      listBuilder: (context, filteredEvents) {
        return _buildEventsList(context, filteredEvents);
      },
      searchPlaceholder: AppLocalizations.of(context)!.searchEvents,
    );
  }

  Widget _buildEventsList(BuildContext context, List<Event> eventsToShow) {
    final groupedEvents = EventDateUtils.groupEventsByDate(eventsToShow);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
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
                    AppLocalizations.of(context)!.noEventsFound,
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

  Widget _buildDateGroup(BuildContext context, Map<String, dynamic> group) {
    return EventDateSection(
      dateGroup: group,
      eventBuilder: (event) {
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
      },
    );
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
