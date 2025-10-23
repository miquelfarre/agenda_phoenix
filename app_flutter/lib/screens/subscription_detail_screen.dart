import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../models/subscription.dart';
import '../models/event.dart';
import '../models/subscription_detail_composite.dart';
import '../services/composite_sync_service.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/events_list.dart';
import 'event_detail_screen.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailScreen({super.key, required this.subscription});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  SubscriptionDetailComposite? _composite;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('🔵 [SubscriptionDetailScreen] _loadData START');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print(
        '🔵 [SubscriptionDetailScreen] Calling smartSyncSubscriptionDetail...',
      );
      final composite = await CompositeSyncService.instance
          .smartSyncSubscriptionDetail(widget.subscription.id);
      print(
        '🔵 [SubscriptionDetailScreen] smartSyncSubscriptionDetail completed, events count: ${composite.publicEvents.length}',
      );

      if (mounted) {
        setState(() {
          _composite = composite;
          _isLoading = false;
        });
        print(
          '🔵 [SubscriptionDetailScreen] setState completed, _isLoading=false',
        );
      }
    } catch (e) {
      print('🔴 [SubscriptionDetailScreen] ERROR: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.subscription.subscribed?.displayName.isNotEmpty == true
        ? widget.subscription.subscribed!.displayName
        : (widget.subscription.subscribed?.fullName ??
              widget.subscription.subscribed?.instagramName ??
              l10n.unknownUser);

    return AdaptivePageScaffold(
      title: title,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;

    if (_isLoading) {
      return Center(
        child: PlatformWidgets.platformLoadingIndicator(radius: 16),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.exclamationmark_triangle,
                color: AppStyles.grey500,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _error!.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppStyles.grey700),
              ),
            ],
          ),
        ),
      );
    }

    final events = _composite?.publicEvents ?? [];

    if (events.isEmpty) {
      return EmptyState(message: l10n.noEvents, icon: CupertinoIcons.calendar);
    }

    return EventsList(
      events: events,
      onEventTap: _openEventDetail,
      onDelete: (Event event, {bool shouldNavigate = false}) async {},
      navigateAfterDelete: false,
      onRefresh: () async {
        await _loadData();
      },
    );
  }

  void _openEventDetail(Event event) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      PlatformNavigation.platformPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );

    if (!mounted) return;

    await _loadData();

    if (!mounted) return;

    if (_composite?.publicEvents.isEmpty ?? true) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}
