import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/event_interaction.dart';
import '../models/recurrence_pattern.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/supabase_service.dart';
import '../core/state/app_state.dart';
import 'create_edit_event_screen.dart';
import 'invite_users_screen.dart';
import '../services/config_service.dart';
import '../widgets/event_card.dart';
import '../widgets/event_card/event_card_config.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/event_detail_actions.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../widgets/adaptive/configs/button_config.dart';
import '../widgets/personal_note_widget.dart';
import '../widgets/user_avatar.dart';
import 'public_user_events_screen.dart';
import 'calendar_events_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen>
    with WidgetsBindingObserver {
  late Event currentEvent;

  int get currentUserId => ConfigService.instance.currentUserId;

  bool get isEventOwner => currentEvent.ownerId == currentUserId;

  bool _sendCancellationNotification = false;
  final TextEditingController _cancellationNotificationController =
      TextEditingController();

  final TextEditingController _decisionMessageController =
      TextEditingController();

  String? _ephemeralMessage;
  Color? _ephemeralMessageColor;
  Timer? _ephemeralTimer;

  Event? _detailedEvent;
  List<EventInteraction>? _otherInvitations;
  bool _isLoadingComposite = false;

  EventInteraction? _interaction;

  Future<void> _loadDetailData() async {
    if (!mounted || _isLoadingComposite) return;
    final eventId = currentEvent.id;
    if (eventId == null) return;

    setState(() {
      _isLoadingComposite = true;
    });

    try {
      final data = await SupabaseService.instance.fetchEventDetail(
        eventId,
        currentUserId,
      );

      final Event detailedEvent = Event.fromJson(data);

      EventInteraction? interaction;
      if (!isEventOwner && data['interactions'] != null) {
        final interactions = (data['interactions'] as List)
            .map((i) => EventInteraction.fromJson(i))
            .where((i) => i.userId == currentUserId)
            .toList();
        if (interactions.isNotEmpty) {
          interaction = interactions.first;
        }
      }

      List<EventInteraction>? otherInvitations;
      if (isEventOwner && data['interactions'] != null) {
        otherInvitations = (data['interactions'] as List)
            .map((i) => EventInteraction.fromJson(i))
            .where((i) => i.userId != currentUserId)
            .toList();
      }

      if (mounted) {
        setState(() {
          _detailedEvent = detailedEvent;
          _otherInvitations = otherInvitations;
          _interaction = interaction;
          currentEvent = detailedEvent;
          _isLoadingComposite = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComposite = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    currentEvent = widget.event;

    if (currentEvent.owner?.isPublic == true) {}

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDetailData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancellationNotificationController.dispose();
    _decisionMessageController.dispose();
    _ephemeralTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted) {
      _loadDetailData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _detailedEvent ?? currentEvent;

    return AdaptivePageScaffold(title: event.title, body: _buildContent());
  }

  Widget _buildContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_ephemeralMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      _ephemeralMessageColor ??
                      AppStyles.colorWithOpacity(AppStyles.blue, 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppStyles.colorWithOpacity(
                      (_ephemeralMessageColor ?? AppStyles.blue),
                      0.4,
                    ),
                  ),
                ),
                child: Text(
                  _ephemeralMessage!,
                  style: TextStyle(color: AppStyles.black87, fontSize: 14),
                ),
              ),
            _buildInfoSection(),
            const SizedBox(height: 16),

            _buildAttendeesSection(),

            const SizedBox(height: 24),

            if (!isEventOwner &&
                _interaction != null &&
                _interaction!.wasInvited)
              _buildParticipationStatusButtons(),

            _buildAdditionalActions(),

            PersonalNoteWidget(
              event: _detailedEvent ?? currentEvent,
              onEventUpdated: (updated) {
                setState(() {
                  currentEvent = updated;
                });
              },
            ),
            const SizedBox(height: 24),

            if (isEventOwner) _buildInvitedUsersList(),

            _buildActionButtons(),
            if ((_detailedEvent ?? currentEvent).owner?.isPublic == true &&
                !isEventOwner) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton(
                  config: AdaptiveButtonConfig.secondary(),
                  text: context.l10n.viewOrganizerEvents,
                  onPressed: () => _viewPublicUserEvents(),
                ),
              ),
            ],

            if (isEventOwner) ...[
              const SizedBox(height: 24),
              _buildCancellationNotificationSection(),
            ] else ...[
              const SizedBox(height: 24),
              _buildRemoveFromListButton(),
            ],

            if (widget.event.owner?.isPublic == true &&
                widget.event.owner?.fullName != null) ...[
              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, child) {
                  return _buildPublicUserFutureEvents();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final l10n = context.l10n;

    final event = _detailedEvent ?? currentEvent;

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.owner?.isPublic == true &&
              event.owner?.fullName != null) ...[
            _buildOrganizerRow(),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            l10n.eventDescription,
            (event.description == null || event.description!.isEmpty)
                ? l10n.noDescription
                : event.description!,
          ),

          _buildEventBadges(),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.eventDate, _formatDateTime(event.date)),

          if (!isEventOwner &&
              _interaction != null &&
              _interaction!.wasInvited &&
              _interaction!.inviter != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Invited by', _interaction!.inviter!.displayName),
          ],

          if (!isEventOwner &&
              _interaction != null &&
              _interaction!.wasInvited &&
              _interaction!.participationStatus != 'pending') ...[
            const SizedBox(height: 8),
            _buildParticipationStatusRow(),
          ],

          if (event.isRecurringEvent) ...[
            const SizedBox(height: 8),
            _buildRecurrenceInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganizerRow() {
    final l10n = context.l10n;

    final event = _detailedEvent ?? currentEvent;
    final owner = event.owner!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        UserAvatar(user: owner.toUser(), radius: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.organizer,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.grey600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                owner.fullName!,
                style: TextStyle(fontSize: 16, color: AppStyles.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppStyles.grey600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, color: AppStyles.black87)),
        ],
      ),
    );
  }

  Widget _buildEventBadges() {
    final l10n = context.l10n;
    final event = _detailedEvent ?? currentEvent;
    final List<Widget> badges = [];

    if (event.calendarId != null && event.calendarName != null) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.calendarColor != null)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _parseColor(event.calendarColor!),
                    shape: BoxShape.circle,
                  ),
                ),
              if (event.calendarColor != null) const SizedBox(width: 6),
              Text(
                event.calendarName!,
                style: AppStyles.bodyText.copyWith(
                  fontSize: 13,
                  color: AppStyles.blue600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (event.isBirthday) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.gift,
                size: 13,
                color: AppStyles.orange600,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.isBirthday,
                style: AppStyles.bodyText.copyWith(
                  fontSize: 13,
                  color: AppStyles.orange600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (event.isRecurring) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.green600, 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppStyles.colorWithOpacity(AppStyles.green600, 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.repeat,
                size: 13,
                color: AppStyles.green600,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.recurring,
                style: AppStyles.bodyText.copyWith(
                  fontSize: 13,
                  color: AppStyles.green600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 6, runSpacing: 6, children: badges),
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppStyles.blue600;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final weekdays = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];
    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (locale.startsWith('en')) {
      String ordinal(int d) {
        final mod100 = d % 100;
        if (mod100 >= 11 && mod100 <= 13) return 'th';
        switch (d % 10) {
          case 1:
            return 'st';
          case 2:
            return 'nd';
          case 3:
            return 'rd';
          default:
            return 'th';
        }
      }

      final h24 = dateTime.hour;
      final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
      final period = h24 < 12 ? 'AM' : 'PM';
      final timeStr = '${h12.toString()}:$minute $period';
      final dayStr = '${dateTime.day}${ordinal(dateTime.day)}';
      return '$weekday, $dayStr of $month ${dateTime.year} at $timeStr';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    return '$weekday, ${dateTime.day} de $month de ${dateTime.year} a las $hour:$minute';
  }

  Widget _buildAttendeesSection() {
    final event = _detailedEvent ?? currentEvent;

    final List<User> attendeeUsers = [];
    for (final a in event.attendees) {
      if (a is User) {
        attendeeUsers.add(a);
      } else if (a is Map<String, dynamic>) {
        try {
          attendeeUsers.add(User.fromJson(a));
        } catch (_) {}
      }
    }

    final otherAttendees = attendeeUsers
        .where((u) => u.id != currentUserId)
        .toList();

    if (otherAttendees.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.person_3,
                color: AppStyles.blue600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendees',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.grey700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${otherAttendees.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppStyles.blue600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: otherAttendees.map((user) {
              final initials = (user.fullName ?? '').trim().isNotEmpty
                  ? user.fullName!
                        .trim()
                        .split(RegExp(r"\s+"))
                        .first[0]
                        .toUpperCase()
                  : '?';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppStyles.blue600,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppStyles.bodyText.copyWith(
                          color: AppStyles.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      user.fullName?.split(' ').first ?? 'User',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppStyles.grey600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final event = _detailedEvent ?? currentEvent;

    return EventDetailActions(
      isEventOwner: isEventOwner,
      canInvite: event.canInviteUsers,
      onEdit: () => _editEvent(context),
      onInvite: () => _navigateToInviteScreen(),
    );
  }

  void _navigateToInviteScreen() {
    final event = _detailedEvent ?? currentEvent;

    print('🔵 [EventDetailScreen] _navigateToInviteScreen called');
    print('🔵 [EventDetailScreen] event.id: ${event.id}');
    print('🔵 [EventDetailScreen] event.title: ${event.title}');
    print(
      '🔵 [EventDetailScreen] event.canInviteUsers: ${event.canInviteUsers}',
    );

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          print('🔵 [EventDetailScreen] Building InviteUsersScreen');
          return InviteUsersScreen(event: event);
        },
      ),
    );

    print('🔵 [EventDetailScreen] Navigation push completed');
  }

  Future<void> _editEvent(BuildContext context) async {
    final updatedEvent = await Navigator.of(
      context,
    ).pushScreen(context, CreateEditEventScreen(eventToEdit: currentEvent));

    if (updatedEvent != null) {
      await ref.read(eventStateProvider.notifier).refresh();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    final eventService = EventService();
    await eventService.deleteEvent(event.id!);

    if (shouldNavigate && mounted) {
      Navigator.of(context).pop();
    }

    if (!shouldNavigate && currentEvent.owner?.isPublic == true) {}
  }

  Future<void> _leaveEvent(Event event, {bool shouldNavigate = false}) async {
    await ref.read(eventStateProvider.notifier).refresh();

    await _loadDetailData();

    if (shouldNavigate && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildPublicUserFutureEvents() {
    final l10n = context.l10n;

    final event = _detailedEvent ?? currentEvent;
    final publicUserId = event.owner?.id;

    if (publicUserId == null) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        final allEvents = ref.watch(eventStateProvider);

        final now = DateTime.now();
        final futureEvents = allEvents
            .where(
              (e) =>
                  e.date.isAfter(now) &&
                  e.id != event.id &&
                  (e.owner?.id == publicUserId),
            )
            .toList();

        futureEvents.sort((a, b) => a.date.compareTo(b.date));
        final limitedEvents = futureEvents.length > 5
            ? futureEvents.take(5).toList()
            : futureEvents;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.upcomingEventsOf(event.owner!.fullName!),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppStyles.grey700,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            if (limitedEvents.isEmpty) ...[
              EmptyState(
                message: l10n.noUpcomingEventsScheduled,
                icon: CupertinoIcons.calendar,
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: limitedEvents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final futureEvent = limitedEvents[index];
                  return EventCard(
                    event: futureEvent,
                    onTap: () {
                      Navigator.of(context).pushScreen(
                        context,
                        EventDetailScreen(event: futureEvent),
                      );
                    },
                    config: EventCardConfig(
                      navigateAfterDelete: false,
                      onDelete: _deleteEvent,
                      onEdit: null,
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCancellationNotificationSection() {
    final isIOS = PlatformWidgets.isIOS;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIOS ? AppStyles.cardBackgroundColor : AppStyles.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.bell,
                color: AppStyles.orange600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.notifyCancellation,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.black87,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            l10n.sendCancellationNotification,
            style: TextStyle(
              fontSize: 14,
              color: AppStyles.grey600,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              PlatformWidgets.platformSwitch(
                value: _sendCancellationNotification,
                onChanged: (value) {
                  setState(() {
                    _sendCancellationNotification = value;
                    if (!value) {
                      _cancellationNotificationController.clear();
                    }
                  });
                },
              ),
              const SizedBox(width: 12),
              Text(
                l10n.sendNotification,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppStyles.black87,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),

          if (_sendCancellationNotification) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppStyles.grey300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PlatformWidgets.platformTextField(
                controller: _cancellationNotificationController,
                placeholder: l10n.customMessageOptional,
                maxLines: 3,
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AdaptiveButton(
              config: AdaptiveButtonConfigExtended.destructive(),
              text: l10n.deleteEvent,
              icon: CupertinoIcons.delete,
              onPressed: () => _deleteEvent(currentEvent, shouldNavigate: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveFromListButton() {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: AdaptiveButton(
        config: AdaptiveButtonConfigExtended.destructive(),
        text: l10n.removeFromMyList,
        icon: CupertinoIcons.minus_circle,
        onPressed: () => _leaveEvent(currentEvent, shouldNavigate: true),
      ),
    );
  }

  void _showEphemeralMessage(
    String message, {
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    _ephemeralTimer?.cancel();
    setState(() {
      _ephemeralMessage = message;
      _ephemeralMessageColor = color;
    });
    _ephemeralTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        _ephemeralMessage = null;
        _ephemeralMessageColor = null;
      });
    });
  }

  Widget _buildRecurrenceInfo() {
    final l10n = context.l10n;
    final locale = l10n.localeName;

    final event = _detailedEvent ?? currentEvent;

    if (event.recurrencePatterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(l10n.event, l10n.recurringEvent),
        const SizedBox(height: 8),
        _buildInfoRow(
          l10n.recurrencePatterns,
          _formatRecurrencePatterns([], locale),
        ),
      ],
    );
  }

  String _formatRecurrencePatterns(
    List<RecurrencePattern> patterns,
    String locale,
  ) {
    final l10n = context.l10n;
    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    if (patterns.isEmpty) return '';

    final formattedDays = <String>[];
    String? commonTime;

    for (final pattern in patterns) {
      final dayIndex = pattern.dayOfWeek;
      final time = pattern.time;

      if (dayIndex >= 0 && dayIndex < dayNames.length) {
        final name = dayNames[dayIndex];
        formattedDays.add(locale.startsWith('es') ? name.toLowerCase() : name);
      }

      commonTime ??= _formatPatternTime(time, locale);
    }

    if (formattedDays.isEmpty) return l10n.recurringEvent;

    String joinWithAnd(List<String> items) {
      if (items.length <= 1) return items.join();
      final last = items.last;
      final head = items.sublist(0, items.length - 1).join(', ');
      final andWord = l10n.andWord;
      return head.isEmpty ? last : '$head $andWord $last';
    }

    final everyWord = l10n.everyWord;
    final atWord = l10n.atWord;

    final daysText = joinWithAnd(formattedDays);
    final timePart = commonTime != null ? ' $atWord $commonTime' : '';
    return '$everyWord $daysText$timePart';
  }

  String _formatTime24To12(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;

      final hour24 = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final period = hour24 < 12 ? 'AM' : 'PM';

      return '${hour12.toString()}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  String _formatPatternTime(String time24, String locale) {
    if (locale.startsWith('en')) return _formatTime24To12(time24);

    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      final hour = int.parse(parts[0]).toString().padLeft(2, '0');
      final minute = int.parse(parts[1]).toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return time24;
    }
  }

  Widget _buildAdditionalActions() {
    final event = _detailedEvent ?? currentEvent;
    final actions = <Widget>[];

    if (event.calendarId != null && event.calendarName != null) {
      actions.addAll(_buildCalendarEventActions());
    }

    if (event.parentRecurringEventId != null) {
      actions.addAll(_buildParentEventActions());
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...actions, const SizedBox(height: 16)],
    );
  }

  List<Widget> _buildCalendarEventActions() {
    return [
      AdaptiveButton(
        config: AdaptiveButtonConfig.secondary(),
        text: context.l10n.viewCalendarEvents,
        icon: CupertinoIcons.calendar,
        onPressed: () => _viewCalendarEvents(),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildParentEventActions() {
    final l10n = context.l10n;
    return [
      AdaptiveButton(
        config: AdaptiveButtonConfig.secondary(),
        text: l10n.viewEventSeries,
        icon: CupertinoIcons.link,
        onPressed: () => _viewParentEventSeries(),
      ),
      const SizedBox(height: 8),
    ];
  }

  void _viewCalendarEvents() {
    final event = _detailedEvent ?? currentEvent;

    if (event.calendarId != null && event.calendarName != null) {
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (context) => CalendarEventsScreen(
            calendarId: event.calendarId!,
            calendarName: event.calendarName!,
            calendarColor: event.calendarColor,
          ),
        ),
      );
    }
  }

  void _viewPublicUserEvents() {
    final event = _detailedEvent ?? currentEvent;

    if (event.owner != null) {
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (context) =>
              PublicUserEventsScreen(publicUser: event.owner!.toUser()),
        ),
      );
    }
  }

  void _viewParentEventSeries() {}

  Widget _buildInvitedUsersList() {
    if (_otherInvitations == null || _otherInvitations!.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final invitations = _otherInvitations!;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.zero,
          decoration: AppStyles.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlatformWidgets.platformIcon(
                    CupertinoIcons.person_2,
                    color: AppStyles.blue600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.invitedUsers, style: AppStyles.cardTitle),
                ],
              ),
              const SizedBox(height: 16),
              ...invitations.where((invitation) => invitation.user != null).map(
                (invitation) {
                  final user = invitation.user!;
                  final status = invitation.participationStatus ?? 'pending';

                  final statusColor = _getStatusColor(status);
                  final statusText = _getStatusText(status);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        UserAvatar(user: user, radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppStyles.black87,
                                ),
                              ),
                              if (user.displaySubtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user.displaySubtitle!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppStyles.grey600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppStyles.colorWithOpacity(statusColor, 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppStyles.colorWithOpacity(
                                statusColor,
                                0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppStyles.green600;
      case 'declined':
        return AppStyles.red600;
      case 'postponed':
        return AppStyles.orange600;
      case 'pending':
      default:
        return AppStyles.grey600;
    }
  }

  String _getStatusText(String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'accepted':
        return l10n.accepted;
      case 'declined':
        return l10n.declined;
      case 'postponed':
        return l10n.postponed;
      case 'pending':
      default:
        return l10n.pending;
    }
  }

  Widget _buildParticipationStatusRow() {
    final l10n = context.l10n;
    if (_interaction == null) return const SizedBox.shrink();

    final status = _interaction!.participationStatus ?? 'pending';
    final isDeclinedButAttending =
        status == 'declined' && (_interaction!.isAttending == true);

    String statusText;
    Color statusColor;

    if (isDeclinedButAttending) {
      statusText = l10n.acceptEventButRejectInvitation;
      statusColor = AppStyles.blue600;
    } else {
      statusText = _getStatusText(status);
      statusColor = _getStatusColor(status);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.invitationStatus,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppStyles.grey600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppStyles.colorWithOpacity(statusColor, 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppStyles.colorWithOpacity(statusColor, 0.3),
              ),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationStatusButtons() {
    final l10n = context.l10n;

    final event = _detailedEvent ?? currentEvent;
    final isPublicEvent = event.owner?.isPublic == true;

    if (_interaction == null) return const SizedBox.shrink();

    final status = _interaction!.participationStatus ?? 'pending';
    final isAccepted = status == 'accepted';
    final isDeclined = status == 'declined';
    final isDeclinedNotAttending =
        isDeclined && (_interaction!.isAttending == false);
    final isDeclinedButAttending =
        isDeclined && (_interaction!.isAttending == true);

    return Column(
      children: [
        Container(
          margin: EdgeInsets.zero,
          decoration: AppStyles.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.changeInvitationStatus,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.grey700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusButton(
                      icon: isAccepted
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      label: l10n.accept,
                      color: AppStyles.green600,
                      isActive: isAccepted,
                      onTap: () => _updateParticipationStatus(
                        'accepted',
                        isAttending: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: _buildStatusButton(
                      icon: isDeclinedNotAttending
                          ? CupertinoIcons.xmark_circle_fill
                          : CupertinoIcons.xmark,
                      label: l10n.decline,
                      color: AppStyles.red600,
                      isActive: isDeclinedNotAttending,
                      onTap: () => _updateParticipationStatus(
                        'declined',
                        isAttending: false,
                      ),
                    ),
                  ),

                  if (isPublicEvent) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusButton(
                        icon: isDeclinedButAttending
                            ? CupertinoIcons.person_2_fill
                            : CupertinoIcons.person_2,
                        label: l10n.attendIndependently,
                        color: AppStyles.blue600,
                        isActive: isDeclinedButAttending,
                        onTap: () => _updateParticipationStatus(
                          'declined',
                          isAttending: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppStyles.colorWithOpacity(color, 0.15)
              : AppStyles.colorWithOpacity(color, 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : AppStyles.colorWithOpacity(color, 0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateParticipationStatus(
    String status, {
    required bool isAttending,
  }) async {
    if (currentEvent.id == null) return;

    try {
      await ref
          .read(eventInteractionsProvider.notifier)
          .updateParticipationStatus(
            currentEvent.id!,
            status,
            isAttending: isAttending,
          );

      await _loadDetailData();
      await ref.read(eventStateProvider.notifier).refresh();

      if (mounted) {
        final l10n = context.l10n;
        String message;
        Color messageColor;

        if (status == 'accepted') {
          message = l10n.invitationAccepted;
          messageColor = AppStyles.green600;
        } else if (status == 'declined' && isAttending) {
          message = l10n.acceptEventButRejectInvitationAck;
          messageColor = AppStyles.blue600;
        } else {
          message = 'Invitation declined';
          messageColor = AppStyles.red600;
        }

        _showEphemeralMessage(message, color: messageColor);
      }
    } catch (e) {
      if (mounted) {
        _showEphemeralMessage(
          'Error updating status: $e',
          color: AppStyles.errorColor,
        );
      }
    }
  }
}
