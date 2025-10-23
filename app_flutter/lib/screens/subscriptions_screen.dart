import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../models/subscription.dart';
import '../models/subscription_list_composite.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/composite_sync_service.dart';
import '../services/subscription_service.dart';
import '../widgets/event_card.dart';
import '../widgets/event_card/event_card_config.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/platform_refresh.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/l10n/app_localizations.dart';
import 'subscription_detail_screen.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';

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

  SubscriptionListComposite? _composite;
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
      final composite = await CompositeSyncService.instance
          .smartSyncSubscriptions();
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

  List<Subscription> _applySearchFilter(
    List<Subscription> subscriptions,
    String query,
  ) {
    if (query.isEmpty) return subscriptions;

    final lowerQuery = query.toLowerCase();
    return subscriptions.where((subscription) {
      if (subscription.subscribed == null) return false;

      final user = subscription.subscribed!;

      final matchesInstagram =
          user.instagramName?.toLowerCase().contains(lowerQuery) ?? false;

      final matchesFullName =
          user.fullName?.toLowerCase().contains(lowerQuery) ?? false;

      return matchesInstagram || matchesFullName;
    }).toList();
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
    List<Subscription> subscriptions,
    bool isIOS,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    if (subscriptions.isEmpty) {
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
          await CompositeSyncService.instance.clearCache();
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
          final subscription = subscriptions[subIndex];
          return _buildSubscriptionItem(subscription, isIOS, l10n, ref);
        }, childCount: subscriptions.length + 1),
      ),
      child: Container(),
    );
  }

  Widget _buildSubscriptionItem(
    Subscription subscription,
    bool isIOS,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    User? user = subscription.subscribed;

    user ??= User(
      id: subscription.subscribedToId,
      fullName: null,
      instagramName: 'user_${subscription.subscribedToId}',
      phoneNumber: null,
      isPublic: false,
      profilePicture: null,
    );

    final uniqueEventId = subscription.id > 0 ? -subscription.id : -1000000;
    final displayTitle = user.displayName.isNotEmpty
        ? user.displayName
        : user.fullName ?? user.instagramName ?? l10n.unknownUser;

    final subscriptionListItem = _composite?.subscriptions.firstWhere(
      (item) => item.id == subscription.id,
      orElse: () => SubscriptionListItem(
        id: subscription.id,
        userId: subscription.userId,
        subscribedToId: subscription.subscribedToId,
        subscribedTo: null,
        futureEventCount: 0,
      ),
    );
    final userEventCount = subscriptionListItem?.futureEventCount ?? 0;

    final displaySubtitle = userEventCount == 1
        ? '1 ${l10n.event}'
        : '$userEventCount ${l10n.events}';

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
          _showSubscriptionDetails(subscription);
        },
        config: EventCardConfig(
          showChevron: true,
          onDelete: (_, {bool shouldNavigate = false}) {
            _removeSubscription(subscription, ref);
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
                        await CompositeSyncService.instance.clearCache();
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

          final subscriptions =
              _composite?.subscriptions
                  .map((item) => item.toSubscription())
                  .toList() ??
              [];

          final filteredSubscriptions = _applySearchFilter(
            subscriptions,
            _searchQuery,
          );

          return _buildScrollableContent(
            filteredSubscriptions,
            isIOS,
            l10n,
            ref,
          );
        },
      ),
    );
  }

  void _showSubscriptionDetails(Subscription subscription) {
    Navigator.of(context).push(
      PlatformNavigation.platformPageRoute(
        builder: (_) => SubscriptionDetailScreen(subscription: subscription),
      ),
    );
  }

  Future<void> _removeSubscription(
    Subscription subscription,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    try {
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
