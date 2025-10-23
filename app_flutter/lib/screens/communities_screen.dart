import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/helpers/platform/platform_detection.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../core/providers/calendar_provider.dart';
import '../core/providers/calendar_subscription_provider.dart';
import '../models/calendar.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showingPublicCalendars = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformDetection.isIOS;

    Widget body = _showingPublicCalendars
        ? _buildPublicCalendarsView()
        : _buildMyCalendarsView();

    if (isIOS && !_showingPublicCalendars) {
      body = Stack(
        children: [
          body,
          Positioned(
            bottom: 100,
            right: 20,
            child: AdaptiveButton(
              config: const AdaptiveButtonConfig(
                variant: ButtonVariant.fab,
                size: ButtonSize.medium,
                fullWidth: false,
                iconPosition: IconPosition.only,
              ),
              icon: CupertinoIcons.add,
              onPressed: () => context.push('/communities/create'),
            ),
          ),
        ],
      );
    }

    return AdaptivePageScaffold(
      title: isIOS ? null : l10n.communities,
      body: body,
    );
  }

  Widget _buildMyCalendarsView() {
    final calendarsAsync = ref.watch(availableCalendarsProvider);

    return calendarsAsync.when(
      data: (calendars) {
        if (calendars.isEmpty) {
          return EmptyState(
            icon: CupertinoIcons.rectangle_stack_person_crop,
            message: context.l10n.noCalendarsYet,
            subtitle:
                'Organize your events by creating calendars or subscribe to public ones',
            actionLabel: 'Create Calendar',
            onAction: () => context.push('/communities/create'),
          );
        }

        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: calendars.length + 1,
                itemBuilder: (context, index) {
                  if (index == calendars.length) {
                    return _buildSearchPublicButton();
                  }
                  return _buildCalendarItem(calendars[index]);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) {
        return EmptyState(
          icon: CupertinoIcons.exclamationmark_triangle,
          message: error.toString(),
        );
      },
    );
  }

  Widget _buildPublicCalendarsView() {
    final searchQuery = _searchController.text.isEmpty
        ? null
        : _searchController.text;
    final publicCalendarsAsync = ref.watch(
      publicCalendarsProvider(searchQuery),
    );

    return Column(
      children: [
        _buildSearchBar(),
        _buildBackToMyCalendarsButton(),
        Expanded(
          child: publicCalendarsAsync.when(
            data: (calendars) {
              if (calendars.isEmpty) {
                return EmptyState(
                  icon: CupertinoIcons.search,
                  message: searchQuery != null
                      ? 'No calendars found'
                      : 'No public calendars available',
                  subtitle: searchQuery != null
                      ? 'Try searching for a different name or keyword'
                      : 'Public calendars will appear here when available',
                );
              }

              return ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: calendars.length,
                itemBuilder: (context, index) {
                  return _buildPublicCalendarItem(calendars[index]);
                },
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (error, stack) => EmptyState(
              icon: CupertinoIcons.exclamationmark_triangle,
              message: error.toString(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: _showingPublicCalendars
            ? context.l10n.searchPublicCalendars
            : 'Search calendars',
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSearchPublicButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CupertinoButton.filled(
        onPressed: () {
          setState(() {
            _showingPublicCalendars = true;
          });
        },
        child: Text(context.l10n.searchPublicCalendars),
      ),
    );
  }

  Widget _buildBackToMyCalendarsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            _showingPublicCalendars = false;
            _searchController.clear();
          });
        },
        child: Row(
          children: [
            const Icon(CupertinoIcons.back, size: 20),
            const SizedBox(width: 8),
            Text(context.l10n.myCalendars),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarItem(Calendar calendar) {
    return CupertinoListTile(
      onTap: () => context.push('/communities/${calendar.id}/edit'),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _parseColor(calendar.color),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(calendar.name),
      subtitle: calendar.description != null
          ? Text(
              calendar.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(CupertinoIcons.chevron_right),
    );
  }

  Widget _buildPublicCalendarItem(Calendar calendar) {
    final subscriptionNotifier = ref.watch(
      calendarSubscriptionNotifierProvider.notifier,
    );
    final isSubscribed = subscriptionNotifier.isSubscribed(
      int.parse(calendar.id),
    );

    return CupertinoListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _parseColor(calendar.color),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(calendar.name),
      subtitle: calendar.description != null
          ? Text(
              calendar.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onPressed: () async {
          try {
            if (isSubscribed) {
              await subscriptionNotifier.unsubscribe(int.parse(calendar.id));
              _showSuccess('Unsubscribed from ${calendar.name}');
            } else {
              await subscriptionNotifier.subscribe(int.parse(calendar.id));
              _showSuccess('Subscribed to ${calendar.name}');
            }
          } catch (e) {
            final operation = isSubscribed
                ? 'unsubscribe from'
                : 'subscribe to';
            final errorMessage = _parseErrorMessage(e, operation);
            _showError(errorMessage);
          }
        },
        child: Text(
          isSubscribed
              ? context.l10n.unsubscribeFromCalendar
              : context.l10n.subscribeToCalendar,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return CupertinoColors.systemBlue;
    }
  }

  String _parseErrorMessage(dynamic error, String operation) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorStr.contains('500') || errorStr.contains('server error')) {
      return 'Server error. Please try again later.';
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Session expired. Please login again.';
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'You don\'t have permission to $operation this calendar.';
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Calendar not found. It may have been deleted.';
    }

    if (errorStr.contains('already subscribed')) {
      return 'You are already subscribed to this calendar.';
    }

    if (errorStr.contains('not subscribed')) {
      return 'You are not subscribed to this calendar.';
    }

    return 'Failed to $operation calendar. Please try again.';
  }

  void _showError(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: const [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: const [
            Icon(
              CupertinoIcons.checkmark_circle,
              color: CupertinoColors.systemGreen,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
