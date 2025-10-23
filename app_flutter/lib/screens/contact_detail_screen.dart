import 'dart:async';
import 'package:flutter/cupertino.dart' hide Column;
import 'package:flutter/widgets.dart' show Column;
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../core/state/app_state.dart';
import '../services/config_service.dart';
import '../services/supabase_service.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/user_avatar.dart';
import '../widgets/event_card.dart';
import '../widgets/event_card/event_card_config.dart';
import '../widgets/empty_state.dart';
import '../widgets/platform_refresh.dart';
import 'event_detail_screen.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/l10n/app_localizations.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../widgets/adaptive/configs/button_config.dart';

class ContactDetailScreen extends ConsumerStatefulWidget {
  final User contact;
  final List<Event>? excludedEventIds;

  const ContactDetailScreen({
    super.key,
    required this.contact,
    this.excludedEventIds,
  });

  @override
  ConsumerState<ContactDetailScreen> createState() =>
      _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _contactData;
  bool _isLoading = false;
  String? _error;

  bool _blockingUser = false;
  final Set<int> _hiddenEventIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContactDetail();
    });
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
      () async {
        await _loadContactDetail();
      }();
    }
  }

  Future<void> _loadContactDetail() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await SupabaseService.instance.fetchContactDetail(
        widget.contact.id,
      );

      if (mounted) {
        setState(() {
          _contactData = data;
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

  List<Event> _filterAvailableEvents(List<Event> allEvents) {
    final excludedIds = <int>{};
    if (widget.excludedEventIds != null) {
      excludedIds.addAll(
        widget.excludedEventIds!
            .map((e) => e.id)
            .where((id) => id != null)
            .cast<int>(),
      );
    }

    final allExcludedIds = {...excludedIds, ..._hiddenEventIds};

    final filteredEvents = allEvents.where((event) {
      return event.id != null && !allExcludedIds.contains(event.id!);
    }).toList();

    return filteredEvents;
  }

  void _navigateToEventDetail(Event event) {
    Navigator.of(context).pushScreen(context, EventDetailScreen(event: event));
  }

  void _showBlockConfirmation() {
    final l10n = context.l10n;
    final safeContext = context;
    final contactName = widget.contact.displayName;
    Future<void> handleBlockConfirmation() async {
      final confirmed = await PlatformWidgets.showPlatformConfirmDialog(
        safeContext,
        title: l10n.blockUser,
        message: l10n.confirmBlockUser(contactName),
        confirmText: l10n.blockUser,
        cancelText: l10n.cancel,
        isDestructive: true,
      );
      if (confirmed == true) {
        _blockUser();
      }
    }

    handleBlockConfirmation();
  }

  Future<void> _blockUser() async {
    if (_blockingUser) return;

    final safeContact = widget.contact;
    final l10n = context.l10n;
    final blockedUsersNotifier = ref.read(blockedUsersProvider.notifier);
    if (!ConfigService.instance.hasUser) {
      _showMessage(l10n.userNotLoggedIn);
      return;
    }

    setState(() {
      _blockingUser = true;
    });

    try {
      await blockedUsersNotifier.blockUser(safeContact.id);
      if (!mounted) return;

      if (!mounted) return;

      _showMessage(l10n.userBlockedSuccessfully, isSuccess: true);
      Navigator.of(context).pop('blocked');
    } catch (e) {
      if (mounted) {
        _showMessage(l10n.errorBlockingUserDetail(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _blockingUser = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    PlatformWidgets.showSnackBar(
      context: context,
      message: message,
      isError: !isSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformWidgets.isIOS;

    return AdaptivePageScaffold(
      title: widget.contact.displayName,
      body: SafeArea(child: _buildBody(isIOS, l10n)),
    );
  }

  Widget _buildBody(bool isIOS, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isIOS
                ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
                : AppStyles.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              UserAvatar(
                user: widget.contact,
                radius: 30,
                showOnlineIndicator: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contact.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.black87,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (widget.contact.instagramName?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${widget.contact.instagramName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppStyles.grey600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return Center(
                  child: PlatformWidgets.platformLoadingIndicator(),
                );
              }

              if (_error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading data',
                        style: TextStyle(
                          color: AppStyles.grey600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: _loadContactDetail,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              final allEvents = ref.watch(eventStateProvider);
              final contactEvents = allEvents
                  .where(
                    (e) => e.attendees.any(
                      (a) =>
                          (a is User && a.id == widget.contact.id) ||
                          (a is Map && a['id'] == widget.contact.id),
                    ),
                  )
                  .toList();
              final availableEvents = _filterAvailableEvents(contactEvents);

              return PlatformRefresh(
                onRefresh: () async {
                  await _loadContactDetail();
                },
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.events,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.black87,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),

                    if (availableEvents.isEmpty)
                      SliverToBoxAdapter(
                        child: EmptyState(
                          message: l10n.noEventsMessage,
                          icon: CupertinoIcons.calendar,
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index == availableEvents.length) {
                            return Container(
                              margin: const EdgeInsets.all(16),
                              width: double.infinity,
                              child: AdaptiveButton(
                                config:
                                    AdaptiveButtonConfigExtended.destructive(),
                                text: l10n.blockUser,
                                enabled: !_blockingUser,
                                onPressed: _showBlockConfirmation,
                              ),
                            );
                          }

                          final event = availableEvents[index];
                          return EventCard(
                            event: event,
                            onTap: () => _navigateToEventDetail(event),
                            config: EventCardConfig(
                              onDelete:
                                  (event, {bool shouldNavigate = false}) =>
                                      _hideEvent(event),
                            ),
                          );
                        }, childCount: availableEvents.length + 1),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _hideEvent(Event event) {
    if (event.id != null) {
      setState(() {
        _hiddenEventIds.add(event.id!);
      });

      final l10n = context.l10n;
      PlatformWidgets.showSnackBar(
        context: context,
        message: l10n.eventHidden(event.title),
        duration: const Duration(seconds: 2),
      );
    }
  }
}
