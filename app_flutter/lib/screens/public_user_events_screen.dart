import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../widgets/event_list_item.dart';
import 'event_detail_screen.dart';
import '../core/state/app_state.dart';

class PublicUserEventsScreen extends ConsumerStatefulWidget {
  final User publicUser;

  const PublicUserEventsScreen({super.key, required this.publicUser});

  @override
  ConsumerState<PublicUserEventsScreen> createState() => _PublicUserEventsScreenState();
}

class _PublicUserEventsScreenState extends ConsumerState<PublicUserEventsScreen> {
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
      final eventsData = await ApiClient().fetchUserEvents(widget.publicUser.id);
      final events = eventsData.map((e) => Event.fromJson(e)).toList();

      // Check if user is subscribed by looking at interactions in events
      bool isSubscribed = false;
      for (final eventData in eventsData) {
        if (eventData['interaction'] != null) {
          final interaction = eventData['interaction'] as Map<String, dynamic>;
          if (interaction['interaction_type'] == 'subscribed') {
            isSubscribed = true;
            break;
          }
        }
      }

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
      // Use new bulk subscribe endpoint
      await ApiClient().post('/users/${widget.publicUser.id}/subscribe');

      if (mounted) {
        PlatformDialogHelpers.showSnackBar(context: context, message: AppLocalizations.of(context)!.subscribedSuccessfully);
      }

      // Realtime handles refresh automatically via SubscriptionRepository

      await _loadData();
    } catch (e) {
      if (mounted) {
        PlatformDialogHelpers.showSnackBar(context: context, message: 'Error: ${e.toString()}', isError: true);
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
      // Use new bulk unsubscribe endpoint
      await ApiClient().delete('/users/${widget.publicUser.id}/subscribe');

      if (mounted) {
        PlatformDialogHelpers.showSnackBar(context: context, message: AppLocalizations.of(context)!.unsubscribedSuccessfully);
      }

      // Realtime handles refresh automatically via SubscriptionRepository

      await _loadData();
    } catch (e) {
      if (mounted) {
        PlatformDialogHelpers.showSnackBar(context: context, message: 'Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessingSubscription = false);
    }
  }

  List<Event> _applySearchAndStatusFilters(List<Event> events) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<Event> result = events;

    if (query.isNotEmpty) {
      result = result.where((event) => event.title.toLowerCase().contains(query) || (event.description?.toLowerCase().contains(query) ?? false));
    }

    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${AppLocalizations.of(context)!.events} - ${widget.publicUser.fullName ?? widget.publicUser.instagramName ?? 'User'}', style: const TextStyle(fontSize: 16)),
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
          child: Text(_isSubscribed ? AppLocalizations.of(context)!.unfollow : AppLocalizations.of(context)!.follow),
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
            Text(AppLocalizations.of(context)!.errorLoadingEvents, style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 16)),
            const SizedBox(height: 16),
            CupertinoButton(onPressed: _refreshEvents, child: Text(AppLocalizations.of(context)!.retry)),
          ],
        ),
      );
    }

    List<Event> baseEvents = _events;

    baseEvents = baseEvents.where((e) => e.id == null || !_hiddenEventIds.contains(e.id)).toList();

    final eventsToShow = _applySearchAndStatusFilters(baseEvents);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(controller: _searchController, placeholder: AppLocalizations.of(context)!.searchEvents, backgroundColor: CupertinoColors.systemGrey6.resolveFrom(context)),
          ),
        ),

        if (eventsToShow.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.calendar, size: 64, color: CupertinoColors.systemGrey),
                  const SizedBox(height: 16),
                  Text(_searchController.text.isNotEmpty ? AppLocalizations.of(context)!.noEventsFound : AppLocalizations.of(context)!.noEvents, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final event = eventsToShow[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: EventListItem(
                  event: event,
                  onTap: (event) {
                    Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => EventDetailScreen(event: event)));
                  },
                  onDelete: _deleteEvent,
                ),
              );
            }, childCount: eventsToShow.length),
          ),
      ],
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
