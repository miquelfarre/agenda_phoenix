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
    print('📊 [PublicUserEvents] _loadData START');
    print('📊 [PublicUserEvents] _isLoading: $_isLoading, _isProcessingSubscription: $_isProcessingSubscription');

    if (_isLoading && !_isProcessingSubscription) {
      print('⚠️ [PublicUserEvents] Already loading and not processing subscription, returning');
      return;
    }

    print('📊 [PublicUserEvents] Setting _isLoading = true');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📊 [PublicUserEvents] Fetching events for user ${widget.publicUser.id}');
      final eventsData = await ApiClient().fetchUserEvents(widget.publicUser.id);
      final events = eventsData.map((e) => Event.fromJson(e)).toList();
      print('✅ [PublicUserEvents] Fetched ${events.length} events');

      // Check if user is subscribed by looking at interactions in events
      bool isSubscribed = false;
      print('📊 [PublicUserEvents] Checking subscription status in events...');
      for (final eventData in eventsData) {
        if (eventData['interaction'] != null) {
          final interaction = eventData['interaction'] as Map<String, dynamic>;
          print('📊 [PublicUserEvents] Found interaction: ${interaction['interaction_type']}');
          if (interaction['interaction_type'] == 'subscribed') {
            isSubscribed = true;
            print('✅ [PublicUserEvents] User IS subscribed (found in event interaction)');
            break;
          }
        }
      }
      print('📊 [PublicUserEvents] Subscription status: $isSubscribed');

      if (mounted) {
        print('📊 [PublicUserEvents] Setting state with events and subscription status');
        setState(() {
          _events = events;
          _isSubscribed = isSubscribed;
          _isLoading = false;
        });
        print('✅ [PublicUserEvents] State updated: _isSubscribed=$isSubscribed, events count=${events.length}');
      }
    } catch (e) {
      print('❌ [PublicUserEvents] ERROR in _loadData: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
    print('📊 [PublicUserEvents] _loadData END');
  }

  Future<void> _refreshEvents() async {
    _hiddenEventIds.clear();
    await _loadData();
  }

  Future<void> _subscribeToUser() async {
    print('🟢 [PublicUserEvents] _subscribeToUser START - userId: ${widget.publicUser.id}');
    if (_isProcessingSubscription) {
      print('⚠️ [PublicUserEvents] Already processing subscription, returning');
      return;
    }

    print('🟢 [PublicUserEvents] Setting _isProcessingSubscription = true');
    setState(() => _isProcessingSubscription = true);

    try {
      print('🟢 [PublicUserEvents] Calling API POST /users/${widget.publicUser.id}/subscribe');
      // Use new bulk subscribe endpoint
      await ApiClient().post('/users/${widget.publicUser.id}/subscribe');
      print('✅ [PublicUserEvents] API call successful');

      if (mounted) {
        print('🟢 [PublicUserEvents] Showing success message');
        PlatformDialogHelpers.showSnackBar(context: context, message: AppLocalizations.of(context)!.subscribedSuccessfully);
      }

      print('🟢 [PublicUserEvents] Realtime handles subscriptions automatically');
      // Realtime handles refresh automatically via SubscriptionRepository

      print('🟢 [PublicUserEvents] Reloading local data...');
      await _loadData();
      print('✅ [PublicUserEvents] Local data reloaded');
    } catch (e) {
      print('❌ [PublicUserEvents] ERROR in _subscribeToUser: $e');
      print('❌ [PublicUserEvents] Stack trace: ${StackTrace.current}');
      if (mounted) {
        PlatformDialogHelpers.showSnackBar(context: context, message: 'Error: ${e.toString()}', isError: true);
      }
    } finally {
      print('🟢 [PublicUserEvents] Setting _isProcessingSubscription = false');
      if (mounted) setState(() => _isProcessingSubscription = false);
    }
    print('🟢 [PublicUserEvents] _subscribeToUser END');
  }

  Future<void> _unsubscribeFromUser() async {
    print('🔴 [PublicUserEvents] _unsubscribeFromUser START - userId: ${widget.publicUser.id}');
    if (_isProcessingSubscription) {
      print('⚠️ [PublicUserEvents] Already processing subscription, returning');
      return;
    }

    print('🔴 [PublicUserEvents] Setting _isProcessingSubscription = true');
    setState(() => _isProcessingSubscription = true);

    try {
      print('🔴 [PublicUserEvents] Calling API DELETE /users/${widget.publicUser.id}/subscribe');
      // Use new bulk unsubscribe endpoint
      await ApiClient().delete('/users/${widget.publicUser.id}/subscribe');
      print('✅ [PublicUserEvents] API DELETE call successful');

      if (mounted) {
        print('🔴 [PublicUserEvents] Showing success message');
        PlatformDialogHelpers.showSnackBar(context: context, message: AppLocalizations.of(context)!.unsubscribedSuccessfully);
      }

      print('🔴 [PublicUserEvents] Realtime handles subscriptions automatically');
      // Realtime handles refresh automatically via SubscriptionRepository

      print('🔴 [PublicUserEvents] Reloading local data...');
      await _loadData();
      print('✅ [PublicUserEvents] Local data reloaded');
    } catch (e) {
      print('❌ [PublicUserEvents] ERROR in _unsubscribeFromUser: $e');
      print('❌ [PublicUserEvents] Stack trace: ${StackTrace.current}');
      if (mounted) {
        PlatformDialogHelpers.showSnackBar(context: context, message: 'Error: ${e.toString()}', isError: true);
      }
    } finally {
      print('🔴 [PublicUserEvents] Setting _isProcessingSubscription = false');
      if (mounted) setState(() => _isProcessingSubscription = false);
    }
    print('🔴 [PublicUserEvents] _unsubscribeFromUser END');
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
    print('🎨 [PublicUserEvents] BUILD - _isSubscribed: $_isSubscribed, _isProcessingSubscription: $_isProcessingSubscription');
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${AppLocalizations.of(context)!.events} - ${widget.publicUser.fullName ?? widget.publicUser.instagramName ?? 'User'}', style: const TextStyle(fontSize: 16)),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onPressed: _isProcessingSubscription
              ? null
              : _isSubscribed
              ? () {
                  print('🔘 [PublicUserEvents] UNFOLLOW button pressed');
                  _unsubscribeFromUser();
                }
              : () {
                  print('🔘 [PublicUserEvents] FOLLOW button pressed');
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
    print('👋 [PublicUserEventsScreen._deleteEvent] Initiating LEAVE for public user event: "${event.name}" (ID: ${event.id})');
    try {
      if (event.id == null) {
        print('❌ [PublicUserEventsScreen._deleteEvent] Error: Event ID is null.');
        throw Exception('Event ID is null');
      }

      // Public user events can only be LEFT, never DELETED
      // (user is never owner/admin of public user events)
      print('👋 [PublicUserEventsScreen._deleteEvent] LEAVING public user event via eventRepositoryProvider...');
      await ref.read(eventRepositoryProvider).leaveEvent(event.id!);
      print('✅ [PublicUserEventsScreen._deleteEvent] Event LEFT successfully');

      // Remove from local list
      if (mounted) {
        setState(() {
          _events.removeWhere((e) => e.id == event.id);
        });
      }

      print('✅ [PublicUserEventsScreen._deleteEvent] Operation completed for event ID: ${event.id}');
    } catch (e, s) {
      print('❌ [PublicUserEventsScreen._deleteEvent] Error: $e');
      print('STACK TRACE: $s');
      rethrow;
    }
  }
}
