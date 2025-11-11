import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../models/domain/event.dart';
import '../models/domain/calendar.dart';
import '../core/state/app_state.dart';
import '../widgets/event_list_item.dart';
import '../widgets/searchable_list.dart';
import 'event_detail_screen.dart';
import '../ui/styles/app_styles.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../utils/calendar_permissions.dart';
import '../utils/event_operations.dart';
import '../utils/calendar_operations.dart';
import '../utils/event_date_utils.dart';
import '../widgets/event_date_section.dart';

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
  String? _ownerName;
  bool _isLoadingOwner = true;
  bool _isProcessingLeave = false;

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

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    // Wait a bit for the calendar to be available from the stream
    await Future.delayed(const Duration(milliseconds: 100));

    final calendar = _calendar;
    if (calendar == null || calendar.ownerId == 0) {
      // Retry once more after a delay
      await Future.delayed(const Duration(milliseconds: 200));
      final calendarRetry = _calendar;
      if (calendarRetry == null || calendarRetry.ownerId == 0) {
        if (mounted) {
          setState(() {
            _ownerName = null;
            _isLoadingOwner = false;
          });
        }
        return;
      }
    }

    final calendarToUse = _calendar!;

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final owner = await userRepo.getUserById(calendarToUse.ownerId);

      if (mounted) {
        setState(() {
          _ownerName = owner?.displayName ??
                       owner?.instagramUsername ??
                       'Usuario';
          _isLoadingOwner = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ownerName = 'Usuario';
          _isLoadingOwner = false;
        });
      }
    }
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

  Future<void> _showLeaveConfirmation() async {
    if (_isProcessingLeave) return;

    final l10n = context.l10n;
    final calendar = _calendar;
    if (calendar == null) return;

    final calendarName = widget.calendarName;

    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(_isOwner ? 'Eliminar calendario' : 'Abandonar calendario'),
        content: Text(
          _isOwner
              ? '¿Estás seguro de que quieres eliminar el calendario "$calendarName"?'
              : '¿Estás seguro de que quieres abandonar el calendario "$calendarName"?',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_isOwner ? 'Eliminar' : 'Abandonar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return; // User cancelled
    }

    _deleteOrLeaveCalendar(calendar);
  }

  Future<void> _deleteOrLeaveCalendar(Calendar calendar) async {
    setState(() => _isProcessingLeave = true);

    try {
      print('🔴 [DEBUG] ${_isOwner ? "Deleting" : "Leaving"} calendar ${calendar.id}');

      await CalendarOperations.deleteOrLeaveCalendar(
        calendar: calendar,
        repository: ref.read(calendarRepositoryProvider),
        context: context,
        shouldNavigate: true, // Navigate back to calendars list
        showSuccessMessage: true,
      );

      print('🔴 [DEBUG] Calendar operation completed successfully');
      // Realtime will automatically update the calendars list
    } catch (e) {
      print('🔴 [DEBUG] Error during calendar operation: $e');
      rethrow;
    } finally {
      if (mounted) setState(() => _isProcessingLeave = false);
    }
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

    final calendarColor = _parseCalendarColor();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
            if (_ownerName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _ownerName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: _isProcessingLeave
                ? CupertinoColors.systemGrey5.resolveFrom(context)
                : AppStyles.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minSize: 0,
            onPressed: _isProcessingLeave ? null : _showLeaveConfirmation,
            child: Text(
              _isOwner ? 'Eliminar' : 'Abandonar',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SearchableList<Event>(
          items: calendarEvents,
          filterFunction: (event, query) {
            return event.title.toLowerCase().contains(query) ||
                (event.description?.toLowerCase().contains(query) ?? false);
          },
          listBuilder: (context, filteredEvents) {
            return _buildContent(context, filteredEvents);
          },
          searchPlaceholder: AppLocalizations.of(context)!.searchEvents,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Event> eventsToShow) {
    final groupedEvents = EventDateUtils.groupEventsByDate(eventsToShow);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
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
                    AppLocalizations.of(context)!.noEventsFound,
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
            return SliverToBoxAdapter(child: _buildDateGroup(context, group));
          }),
      ],
    );
  }

  Widget _buildDateGroup(BuildContext context, Map<String, dynamic> group) {
    return EventDateSection(
      dateGroup: group,
      eventBuilder: (event) {
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
      },
    );
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
