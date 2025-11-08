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
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../utils/calendar_permissions.dart';
import '../utils/event_operations.dart';
import '../utils/calendar_operations.dart';

class CalendarDetailScreen extends ConsumerStatefulWidget {
  final int calendarId;
  final String calendarName;
  final String? calendarColor;

  const CalendarDetailScreen({
    super.key,
    required this.calendarId,
    required this.calendarName,
    this.calendarColor,
  });

  @override
  ConsumerState<CalendarDetailScreen> createState() =>
      _CalendarDetailScreenState();
}

class _CalendarDetailScreenState extends ConsumerState<CalendarDetailScreen> {
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
      return event.title.toLowerCase().contains(query) ||
          (event.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Calendar? get _calendar {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    return calendarsAsync.maybeWhen(
      data: (calendars) => calendars.firstWhere(
        (cal) => cal.id == widget.calendarId,
        orElse: () => Calendar(
          id: widget.calendarId,
          name: widget.calendarName,
          ownerId: 0,
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
    return CalendarPermissions.isOwner(calendar);
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

    // Check if user has edit permissions (owner OR admin)
    final calendarRepository = ref.read(calendarRepositoryProvider);
    final canEdit = await CalendarPermissions.canEdit(
      calendar: calendar,
      repository: calendarRepository,
    );

    if (!mounted) return;

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
    await CalendarOperations.deleteOrLeaveCalendar(
      calendar: calendar,
      repository: ref.read(calendarRepositoryProvider),
      context: context,
      shouldNavigate: true, // Navigate back to calendars list
      showSuccessMessage: true,
    );
    // Realtime will automatically update the calendars list
  }

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(eventsStreamProvider);
    final allEvents = allEventsAsync.when(
      data: (events) => events,
      loading: () => <Event>[],
      error: (error, stack) => <Event>[],
    );

    final calendarEvents = allEvents
        .where((event) => event.calendarId == widget.calendarId)
        .toList();

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
              decoration: BoxDecoration(
                color: calendarColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.calendarName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
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
    final groupedEvents = _groupEventsByDate(eventsToShow);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: AppLocalizations.of(context)!.searchEvents,
              backgroundColor: CupertinoColors.systemGrey6.resolveFrom(context),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${eventsToShow.length} ${eventsToShow.length == 1 ? AppLocalizations.of(context)!.event : AppLocalizations.of(context)!.events}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey600,
                    fontWeight: FontWeight.w500,
                  ),
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
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? AppLocalizations.of(context)!.noEventsFound
                        : AppLocalizations.of(context)!.noEvents,
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...groupedEvents.map((group) {
            return SliverToBoxAdapter(
              child: _buildDateGroup(context, group),
            );
          }),
      ],
    );
  }

  List<Map<String, dynamic>> _groupEventsByDate(List<Event> events) {
    final Map<String, List<Event>> groupedMap = {};

    for (final event in events) {
      final eventDate = event.date;
      final dateKey =
          '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(event);
    }

    for (final eventList in groupedMap.values) {
      eventList.sort((a, b) {
        if (a.isBirthday && !b.isBirthday) return -1;
        if (!a.isBirthday && b.isBirthday) return 1;

        final timeA = a.date;
        final timeB = b.date;
        return timeA.compareTo(timeB);
      });
    }

    final groupedList = groupedMap.entries.map((entry) {
      return {'date': entry.key, 'events': entry.value};
    }).toList();

    groupedList.sort(
      (a, b) => (a['date'] as String).compareTo(b['date'] as String),
    );

    return groupedList;
  }

  Widget _buildDateGroup(BuildContext context, Map<String, dynamic> group) {
    final dateStr = group['date'] as String;
    final events = group['events'] as List<Event>;

    DateTime date;
    try {
      date = DateTime.parse('${dateStr}T00:00:00');
    } catch (_) {
      date = DateTime.now();
    }

    final formattedDate = _formatDate(context, date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              formattedDate,
              style: AppStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppStyles.grey700,
              ),
            ),
          ),
          ...events.map((event) {
            return EventListItem(
              event: event,
              onTap: (event) {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => EventDetailScreen(event: event),
                  ),
                );
              },
              onDelete: _deleteEvent,
              navigateAfterDelete: false,
              hideCalendarBadge: true,
              hideInvitationStatus: true,
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return l10n.today;
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return l10n.tomorrow;
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      return l10n.yesterday;
    } else {
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

      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];

      return '$weekday, ${date.day} ${l10n.dotSeparator} $month';
    }
  }

  Future<void> _deleteEvent(Event event, {bool shouldNavigate = false}) async {
    await EventOperations.deleteOrLeaveEvent(
      event: event,
      repository: ref.read(eventRepositoryProvider),
      context: context,
      shouldNavigate: shouldNavigate,
      showSuccessMessage: true,
    );
    // EventRepository handles updates via Realtime
  }
}
