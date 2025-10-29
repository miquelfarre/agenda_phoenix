import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../core/state/app_state.dart';
import '../widgets/subscription_card.dart';
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
  String _searchQuery = '';

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
        await ref.read(subscriptionRepositoryProvider).refresh();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SubscriptionCard(
        user: user,
        onTap: () => _showUserDetails(user),
        onDelete: () => _removeUser(user, ref),
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

    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(subscriptionRepositoryProvider).refresh();
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
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);

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
              onPressed: () {
                ref.read(subscriptionRepositoryProvider).refresh();
              },
              child: PlatformWidgets.platformIcon(
                CupertinoIcons.refresh,
                size: 20,
              ),
            ),
          ),
      ],
      body: SafeArea(
        child: subscriptionsAsync.when(
          data: (users) {
            final filteredUsers = users.where((user) {
              if (_searchQuery.isEmpty) return true;
              final query = _searchQuery.toLowerCase();
              return (user.fullName?.toLowerCase().contains(query) ?? false) ||
                  (user.instagramName?.toLowerCase().contains(query) ?? false);
            }).toList();

            return _buildScrollableContent(filteredUsers, isIOS, l10n, ref);
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${l10n.error}: $error',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    ref.read(subscriptionRepositoryProvider).refresh();
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
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
      // Use new bulk unsubscribe endpoint
      await ApiClient().delete('/users/${user.id}/subscribe');

      _showSuccessMessage(l10n.unsubscribedSuccessfully);

      // Manually remove from cache for immediate UI update
      ref.read(subscriptionRepositoryProvider).removeSubscriptionFromCache(user.id);
    } catch (e) {
      String cleanError = e.toString().replaceFirst('Exception: ', '');
      _showErrorMessage(cleanError);
    }
  }
}
