import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/subscription.dart';
import '../models/public_user_events_composite.dart';
import '../services/config_service.dart';
import '../services/composite_sync_service.dart';
import '../core/state/app_state.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../widgets/event_card.dart';
import '../widgets/event_card/event_card_config.dart';
import 'event_detail_screen.dart';

class PublicUserEventsScreen extends ConsumerStatefulWidget {
  final User publicUser;

  const PublicUserEventsScreen({super.key, required this.publicUser});

  @override
  ConsumerState<PublicUserEventsScreen> createState() =>
      _PublicUserEventsScreenState();
}

class _PublicUserEventsScreenState
    extends ConsumerState<PublicUserEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isProcessingSubscription = false;

  final Set<int> _hiddenEventIds = <int>{};

  PublicUserEventsComposite? _composite;
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
    if (_isLoading && !_isProcessingSubscription) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final composite = await CompositeSyncService.instance
          .smartSyncPublicUserEvents(widget.publicUser.id);
      if (mounted) {
        setState(() {
          _composite = composite;
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
    await CompositeSyncService.instance.clearPublicUserEventsCache(
      widget.publicUser.id,
    );

    _hiddenEventIds.clear();
    await _loadData();
  }

  Future<void> _subscribeToUser() async {
    if (_isProcessingSubscription) return;
    setState(() => _isProcessingSubscription = true);
    try {
      final subscriptionsNotifier = ref.read(subscriptionsProvider.notifier);
      await subscriptionsNotifier.createSubscription(
        Subscription(
          id: 0,
          userId: ConfigService.instance.currentUserId,
          subscribedToId: widget.publicUser.id,
          subscribed: widget.publicUser,
        ),
      );

      if (mounted) {
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.subscribedSuccessfully,
        );
      }

      await CompositeSyncService.instance.clearPublicUserEventsCache(
        widget.publicUser.id,
      );
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
    if (_isProcessingSubscription) return;
    setState(() => _isProcessingSubscription = true);
    try {
      final subscriptionsAsync = ref.read(subscriptionsProvider);
      final subscriptions = subscriptionsAsync.maybeWhen(
        data: (data) => data,
        orElse: () => <Subscription>[],
      );

      final currentUserId = ConfigService.instance.currentUserId;
      final subscription = subscriptions.firstWhere(
        (sub) =>
            sub.userId == currentUserId &&
            sub.subscribedToId == widget.publicUser.id,
        orElse: () => throw Exception('Subscription not found'),
      );

      final subscriptionsNotifier = ref.read(subscriptionsProvider.notifier);
      await subscriptionsNotifier.deleteSubscription(subscription.id);

      if (mounted) {
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.unsubscribedSuccessfully,
        );
      }

      await CompositeSyncService.instance.clearPublicUserEventsCache(
        widget.publicUser.id,
      );
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
    final isSubscribed = _composite?.isSubscribed ?? false;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '${AppLocalizations.of(context)!.events} - ${widget.publicUser.fullName ?? widget.publicUser.instagramName ?? 'User'}',
          style: const TextStyle(fontSize: 16),
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onPressed: _isProcessingSubscription
              ? null
              : isSubscribed
              ? _unsubscribeFromUser
              : _subscribeToUser,
          child: Text(
            isSubscribed
                ? AppLocalizations.of(context)!.unfollow
                : AppLocalizations.of(context)!.follow,
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: SafeArea(child: _buildContent(isSubscribed)),
    );
  }

  Widget _buildContent(bool isSubscribed) {
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

    final events = _composite?.events ?? [];

    List<Event> baseEvents = events;
    if (!isSubscribed) {
      baseEvents = events;
    }

    baseEvents = baseEvents
        .where((e) => e.id == null || !_hiddenEventIds.contains(e.id))
        .toList();

    final eventsToShow = _applySearchAndStatusFilters(baseEvents);

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
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final event = eventsToShow[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: EventCard(
                  event: event,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => EventDetailScreen(event: event),
                      ),
                    );
                  },
                  config: EventCardConfig.readOnly().copyWith(showOwner: false),
                ),
              );
            }, childCount: eventsToShow.length),
          ),
      ],
    );
  }
}
