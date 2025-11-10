import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../models/domain/user.dart';
import '../core/state/app_state.dart';
import '../widgets/subscription_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/searchable_list.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/l10n/app_localizations.dart';
import 'subscription_detail_screen.dart';
import '../utils/error_message_parser.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Widget _buildScrollableContent(
    List<User> users,
    bool isIOS,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        if (users.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              message: l10n.noSubscriptions,
              icon: isIOS ? CupertinoIcons.person_2 : CupertinoIcons.person_2,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final user = users[index];
              return _buildUserItem(user, isIOS, l10n, ref);
            }, childCount: users.length),
          ),
      ],
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
    PlatformDialogHelpers.showSnackBar(context: context, message: message);
  }

  void _showErrorMessage(String message) {
    PlatformDialogHelpers.showSnackBar(
      context: context,
      message: message,
      isError: true,
    );
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
      body: subscriptionsAsync.when(
        data: (users) {
          return SafeArea(
            child: SearchableList<User>(
              items: users,
              filterFunction: (user, query) {
                return (user.contactName?.toLowerCase().contains(query) ??
                        false) ||
                    (user.instagramName?.toLowerCase().contains(query) ??
                        false);
              },
              listBuilder: (context, filteredUsers) {
                return _buildScrollableContent(filteredUsers, isIOS, l10n, ref);
              },
              searchPlaceholder: l10n.searchSubscriptions,
            ),
          );
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
    );
  }

  void _showUserDetails(User user) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => SubscriptionDetailScreen(publicUser: user),
      ),
    );
  }

  Future<void> _removeUser(User user, WidgetRef ref) async {
    final l10n = context.l10n;
    final currentContext = context;
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .deleteSubscription(targetUserId: user.id);
      final userName = user.contactName ?? user.instagramName ?? 'Usuario';
      _showSuccessMessage(l10n.unsubscribedFrom(userName));
    } catch (e) {
      // ignore: use_build_context_synchronously
      final errorMessage = ErrorMessageParser.parse(e, currentContext);
      _showErrorMessage(errorMessage);
    }
  }
}
