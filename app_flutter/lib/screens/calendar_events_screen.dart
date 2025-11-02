import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/calendar.dart';
import '../core/state/app_state.dart';
import '../widgets/event_list_item.dart';
import 'event_detail_screen.dart';
import '../ui/styles/app_styles.dart';
import '../services/config_service.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/helpers/platform/dialog_helpers.dart';

class CalendarEventsScreen extends ConsumerStatefulWidget {
  final int calendarId;
  final String calendarName;
  final String? calendarColor;

  const CalendarEventsScreen({super.key, required this.calendarId, required this.calendarName, this.calendarColor});

  @override
  ConsumerState<CalendarEventsScreen> createState() => _CalendarEventsScreenState();
}

class _CalendarEventsScreenState extends ConsumerState<CalendarEventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    if (mounted) setState(() {});
  }

  List<Event> _applySearchFilter(List<Event> events) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return events;

    return events.where((event) {
      return event.title.toLowerCase().contains(query) || (event.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Calendar? get _calendar {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    return calendarsAsync.maybeWhen(
      data: (calendars) => calendars.firstWhere(
        (cal) => cal.id == widget.calendarId.toString(),
        orElse: () => Calendar(
          id: widget.calendarId.toString(),
          name: widget.calendarName,
          ownerId: '',
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      orElse: () => null,
    );
  }

  bool get _isOwner {
    final calendar = _calendar;
    if (calendar == null) return false;
    final userId = ConfigService.instance.currentUserId;
    return calendar.ownerId == userId.toString();
  }

  Color _parseCalendarColor() {
    if (widget.calendarColor == null) return AppStyles.blue600;

    try {
      String hexColor = widget.calendarColor!.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppStyles.blue600;
    }
  }

  Future<void> _showCalendarOptions() async {
    final l10n = context.l10n;
    final calendar = _calendar;
    if (calendar == null) return;

    // Verify permissions: owner OR admin
    final userId = ConfigService.instance.currentUserId;
    final isOwner = calendar.ownerId == userId.toString();

    bool canEdit = isOwner;
    if (!isOwner) {
      // Check if user is admin of this calendar
      try {
        final calendarRepository = ref.read(calendarRepositoryProvider);
        final memberships = await calendarRepository.fetchCalendarMemberships(widget.calendarId);
        final userMembership = memberships.firstWhere(
          (m) => m['user_id'].toString() == userId.toString(),
          orElse: () => <String, dynamic>{},
        );
        canEdit = userMembership['role'] == 'admin' && userMembership['status'] == 'accepted';
      } catch (e) {
        canEdit = false;
      }
    }

    final actions = <CupertinoActionSheetAction>[
      // Show edit option if user is owner OR admin
      if (canEdit)
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            context.push('/calendars/${widget.calendarId}/edit');
          },
          child: Text(l10n.editCalendar),
        ),
      CupertinoActionSheetAction(
        isDestructiveAction: true,
        onPressed: () {
          Navigator.pop(context);
          _deleteOrLeaveCalendar(calendar);
        },
        child: Text(_isOwner ? l10n.deleteCalendar : l10n.leaveCalendar),
      ),
    ];

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: actions,
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Future<void> _deleteOrLeaveCalendar(Calendar calendar) async {
    final l10n = context.l10n;
    final userId = ConfigService.instance.currentUserId;
    final isOwner = calendar.ownerId == userId.toString();

    try {
      final repository = ref.read(calendarRepositoryProvider);

      if (isOwner) {
        // Owner: eliminar el calendario completo
        await repository.deleteCalendar(int.parse(calendar.id));
        if (mounted) {
          PlatformDialogHelpers.showSnackBar(context: context, message: l10n.success);
          context.pop(); // Volver a la lista de calendarios
        }
      } else {
        // No owner: dejar el calendario
        if (calendar.shareHash != null) {
          await repository.unsubscribeByShareHash(calendar.shareHash!);
        } else {
          await repository.unsubscribeFromCalendar(int.parse(calendar.id));
        }
        if (mounted) {
          PlatformDialogHelpers.showSnackBar(context: context, message: l10n.calendarLeft);
          context.pop(); // Volver a la lista de calendarios
        }
      }
      // Realtime will automatically update the calendars list
    } catch (e) {
      if (mounted) {
        String cleanError = e.toString().replaceFirst('Exception: ', '');
        PlatformDialogHelpers.showSnackBar(context: context, message: cleanError, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(eventsStreamProvider);
    final allEvents = allEventsAsync.when(data: (events) => events, loading: () => <Event>[], error: (error, stack) => <Event>[]);

    final calendarEvents = allEvents.where((event) => event.calendarId == widget.calendarId).toList();

    calendarEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    final eventsToShow = _applySearchFilter(calendarEvents);

    final calendarColor = _parseCalendarColor();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: calendarColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(widget.calendarName, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showCalendarOptions,
          child: const Icon(CupertinoIcons.ellipsis_circle, size: 28),
        ),
      ),
      child: SafeArea(child: _buildContent(eventsToShow)),
    );
  }

  Widget _buildContent(List<Event> eventsToShow) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(controller: _searchController, placeholder: AppLocalizations.of(context)!.searchEvents, backgroundColor: CupertinoColors.systemGrey6.resolveFrom(context)),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${eventsToShow.length} ${eventsToShow.length == 1 ? AppLocalizations.of(context)!.event : AppLocalizations.of(context)!.events}',
                  style: TextStyle(fontSize: 14, color: AppStyles.grey600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

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
                  showDate: true,
                ),
              );
            }, childCount: eventsToShow.length),
          ),
      ],
    );
  }

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    final l10n = context.l10n;
    print('🗑️ [CalendarEventsScreen._deleteEvent] Initiating delete for event: "${event.name}" (ID: ${event.id})');
    try {
      if (event.id == null) {
        print('❌ [CalendarEventsScreen._deleteEvent] Error: Event ID is null.');
        throw Exception('Event ID is null');
      }

      final currentUserId = ConfigService.instance.currentUserId;
      final isOwner = event.ownerId == currentUserId;
      final isAdmin = event.interactionType == 'joined' && event.interactionRole == 'admin';
      print('👤 [CalendarEventsScreen._deleteEvent] User ID: $currentUserId, Owner ID: ${event.ownerId}, Is Owner: $isOwner, Is Admin: $isAdmin');

      if (isOwner || isAdmin) {
        print('🗑️ [CalendarEventsScreen._deleteEvent] User has permission. DELETING event via eventRepositoryProvider.');
        await ref.read(eventRepositoryProvider).deleteEvent(event.id!);
        print('✅ [CalendarEventsScreen._deleteEvent] Event DELETED successfully');
        if (mounted) {
          PlatformDialogHelpers.showSnackBar(context: context, message: l10n.success);
        }
      } else {
        print('👋 [CalendarEventsScreen._deleteEvent] User is not owner/admin. LEAVING event via eventRepositoryProvider.');
        await ref.read(eventRepositoryProvider).leaveEvent(event.id!);
        print('✅ [CalendarEventsScreen._deleteEvent] Event LEFT successfully');
        if (mounted) {
          PlatformDialogHelpers.showSnackBar(context: context, message: l10n.success);
        }
      }

      print('✅ [CalendarEventsScreen._deleteEvent] Operation completed for event ID: ${event.id}');
      // EventRepository handles updates via Realtime
    } catch (e, s) {
      print('❌ [CalendarEventsScreen._deleteEvent] Error: $e');
      print('STACK TRACE: $s');
      if (mounted) {
        String cleanError = e.toString().replaceFirst('Exception: ', '');
        PlatformDialogHelpers.showSnackBar(context: context, message: cleanError, isError: true);
      }
    }
  }
}
