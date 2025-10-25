import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../models/subscription.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../core/state/app_state.dart';
import '../services/api_client.dart';
import '../services/subscription_service.dart';
import '../services/config_service.dart';
import '../repositories/event_repository.dart';
import '../widgets/event_card.dart';
import '../widgets/event_card/event_card_config.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/platform_refresh.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/l10n/app_localizations.dart';
import 'public_user_events_screen.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = ConfigService.instance.currentUserId;

      // Get all "subscribed" interactions for this user
      final interactionsData = await ApiClient().fetchInteractions(
        userId: userId,
        interactionType: 'subscribed',
      );

      // Get cached events from EventRepository to avoid N+1 queries
      final eventRepository = EventRepository();
      final cachedEvents = eventRepository.getLocalEvents();
      final eventsMap = {for (var e in cachedEvents) if (e.id != null) e.id!: e};

      // Extract unique owner IDs from events
      final Map<int, Map<String, dynamic>> ownersMap = {};

      for (final interactionData in interactionsData) {
        final eventId = interactionData['event_id'] as int?;
        if (eventId != null) {
          // Look up event from cache instead of making individual API calls
          final cachedEvent = eventsMap[eventId];
          if (cachedEvent != null) {
            final ownerId = cachedEvent.ownerId;
            if (ownerId != null && ownerId > 0) {
              final isPublic = cachedEvent.isOwnerPublic ?? false;
              if (isPublic && !ownersMap.containsKey(ownerId)) {
                ownersMap[ownerId] = {
                  'id': ownerId,
                  'full_name': cachedEvent.ownerName,
                  'profile_picture': cachedEvent.ownerProfilePicture,
                  'is_public': isPublic,
                };
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _subscriptions = ownersMap.values.toList();
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

  Widget _buildSearchField(bool isIOS) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PlatformWidgets.platformTextField(
        controller: _searchController,
        placeholder: l10n.searchSubscriptions,
        prefixIcon: PlatformWidgets.platformIcon(
          CupertinoIcons.search,
          color: AppStyles.grey600,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? CupertinoButton(
                key: const Key('subscriptions_search_clear_button'),
                padding: EdgeInsets.zero,
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: PlatformWidgets.platformIcon(
                  CupertinoIcons.clear_circled_solid,
                  color: AppStyles.grey600,
                  size: 18,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildScrollableContent(
    List<User> users,
    bool isIOS,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    if (users.isEmpty) {
      return CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSearchField(isIOS)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              message: l10n.noSubscriptions,
              icon: isIOS ? CupertinoIcons.person_2 : CupertinoIcons.person_2,
            ),
          ),
        ],
      );
    }

    return PlatformRefresh(
      onRefresh: () async {
        _isRefreshing = true;
        try {
          await _loadData();
        } finally {
          if (mounted) _isRefreshing = false;
        }
      },
      sliverChild: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return _buildSearchField(isIOS);
          }

          final subIndex = index - 1;
          final user = users[subIndex];
          return _buildUserItem(user, isIOS, l10n, ref);
        }, childCount: users.length + 1),
      ),
      child: Container(),
    );
  }

  Widget _buildUserItem(
    User user,
    bool isIOS,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    final displayTitle = user.displayName.isNotEmpty
        ? user.displayName
        : user.fullName ?? user.instagramName ?? l10n.unknownUser;

    final displaySubtitle = l10n.publicUser;

    final uniqueEventId = -user.id;

    final fakeEvent = Event(
      id: uniqueEventId,
      name: displayTitle,
      description: displaySubtitle,
      startDate: DateTime.now(),
      ownerId: 0,
      eventType: 'regular',
    );

    String initials = '?';
    if (user.fullName?.isNotEmpty == true) {
      final nameParts = user.fullName!.trim().split(' ');
      if (nameParts.length >= 2) {
        initials =
            nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else {
        initials = nameParts[0][0].toUpperCase();
      }
    } else if (user.instagramName?.isNotEmpty == true) {
      initials = user.instagramName![0].toUpperCase();
    } else if (user.id > 0) {
      initials = user.id.toString()[0];
    }

    final customAvatar = Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            initials,
            style: AppStyles.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppStyles.blue600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: EventCard(
        event: fakeEvent,
        onTap: () {
          _showUserDetails(user);
        },
        config: EventCardConfig(
          showChevron: true,
          onDelete: (_, {bool shouldNavigate = false}) {
            _removeUser(user, ref);
          },
          customAvatar: customAvatar,
          customTitle: displayTitle,
          customSubtitle: displaySubtitle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted && !_isRefreshing) {
      _isRefreshing = true;
      _loadData().then((_) {
        if (mounted) _isRefreshing = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    PlatformDialogHelpers.showSnackBar(message: message);
  }

  void _showErrorMessage(String message) {
    PlatformDialogHelpers.showSnackBar(message: message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    Navigator.of(context);
    final isIOS = PlatformWidgets.isIOS;

    final l10n = context.l10n;

    return AdaptivePageScaffold(
      key: const Key('subscriptions_screen_scaffold'),
      title: PlatformWidgets.isIOS ? null : l10n.subscriptions,
      actions: [
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CupertinoButton(
              key: const Key('subscriptions_refresh_button'),
              padding: const EdgeInsets.all(8),
              onPressed: _isRefreshing
                  ? null
                  : () async {
                      if (!_isRefreshing) {
                        _isRefreshing = true;
                        await _loadData();
                        if (mounted) _isRefreshing = false;
                      }
                    },
              child: PlatformWidgets.platformIcon(
                CupertinoIcons.refresh,
                size: 20,
              ),
            ),
          ),
      ],
      body: _buildBody(context, isIOS: isIOS, l10n: l10n),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isIOS,
    required AppLocalizations l10n,
  }) {
    return SafeArea(
      child: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.error}: $_error',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: _loadData,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final users = _subscriptions.map((data) {
            return User.fromJson(data);
          }).toList();

          final filteredUsers = users.where((user) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return (user.fullName?.toLowerCase().contains(query) ?? false) ||
                (user.instagramName?.toLowerCase().contains(query) ?? false);
          }).toList();

          return _buildScrollableContent(filteredUsers, isIOS, l10n, ref);
        },
      ),
    );
  }

  void _showUserDetails(User user) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => PublicUserEventsScreen(publicUser: user),
      ),
    );
  }

  Future<void> _removeUser(User user, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      final subscriptionsAsync = ref.read(subscriptionsProvider);
      final subscriptions = subscriptionsAsync.maybeWhen(
        data: (data) => data,
        orElse: () => <Subscription>[],
      );

      final currentUserId = ConfigService.instance.currentUserId;
      final subscription = subscriptions.firstWhere(
        (sub) => sub.userId == currentUserId && sub.subscribedToId == user.id,
        orElse: () => throw Exception('Subscription not found'),
      );

      await SubscriptionService().deleteSubscription(
        subscriptionId: subscription.id,
      );

      _showSuccessMessage(l10n.unsubscribedSuccessfully);

      await _loadData();
    } catch (e) {
      String cleanError = e.toString().replaceFirst('Exception: ', '');
      _showErrorMessage(cleanError);
    }
  }
}
