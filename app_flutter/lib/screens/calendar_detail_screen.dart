import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/domain/event.dart';
import '../models/domain/calendar.dart';
import '../core/state/app_state.dart';
import '../widgets/event_list_item.dart';
import '../widgets/searchable_list.dart';
import 'event_detail_screen.dart';
import 'create_edit_event_screen.dart';
import 'calendar_members_screen.dart';
import '../ui/styles/app_styles.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../utils/calendar_permissions.dart';
import '../utils/event_operations.dart';
import '../utils/calendar_operations.dart';
import '../utils/event_date_utils.dart';
import '../utils/error_message_parser.dart';
import '../widgets/event_date_section.dart';
import '../services/config_service.dart';

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
  bool _isProcessingLeave = false;
  bool _isUpdatingDiscoverable = false;
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;

  int get currentUserId => ConfigService.instance.currentUserId;

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

  bool get _canAddEvents {
    final calendar = _calendar;
    if (calendar == null) return false;

    // Owner can always add events
    if (_isOwner) return true;

    // Check if user is admin via membership
    // Note: This is a simplified check - actual implementation would need
    // to check CalendarMembership for this user
    return false;
  }

  bool get _canManageMembers {
    final calendar = _calendar;
    if (calendar == null) return false;

    // Only owner can manage members for now
    // TODO: Allow admins to manage members
    return _isOwner;
  }

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
    _loadMembers();
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
          _ownerName =
              owner?.displayName ?? owner?.instagramUsername ?? 'Usuario';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ownerName = 'Usuario';
        });
      }
    }
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final repository = ref.read(calendarRepositoryProvider);
      final memberships = await repository.fetchCalendarMemberships(
        widget.calendarId,
      );

      if (!mounted) return;

      setState(() {
        _members = memberships;
        _isLoadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMembers = false;
      });
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
        title: Text(_isOwner ? l10n.deleteCalendar : l10n.leaveCalendar),
        content: Text(
          _isOwner
              ? '¿Estás seguro de que quieres eliminar el calendario "$calendarName"?'
              : '¿Estás seguro de que quieres abandonar el calendario "$calendarName"?',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_isOwner ? l10n.delete : l10n.leave),
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
      print(
        '🔴 [DEBUG] ${_isOwner ? "Deleting" : "Leaving"} calendar ${calendar.id}',
      );

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

  Future<void> _updateDiscoverable(bool value) async {
    if (_isUpdatingDiscoverable) return;

    setState(() => _isUpdatingDiscoverable = true);

    try {
      final calendar = _calendar;
      if (calendar == null) return;

      await ref.read(calendarRepositoryProvider).updateCalendar(
        calendar.id,
        {'is_discoverable': value},
      );

      if (!mounted) return;

      final message = value
          ? 'Calendario ahora es discoverable'
          : 'Calendario ahora es privado (link only)';

      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: message,
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorMessageParser.parse(e, context);
      DialogHelpers.showErrorDialogWithIcon(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDiscoverable = false);
      }
    }
  }

  void _createEvent() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CreateEditEventScreen(
          preselectedCalendarId: widget.calendarId,
        ),
      ),
    );
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
            minimumSize: Size.zero,
            onPressed: _isProcessingLeave ? null : _showLeaveConfirmation,
            child: Text(
              _isOwner ? context.l10n.delete : context.l10n.leave,
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
    final calendar = _calendar;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // Share Hash Section (only for public calendars)
        if (calendar != null &&
            calendar.isPublic &&
            calendar.shareHash != null) ...[
          SliverToBoxAdapter(child: _buildShareHashSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // Discoverable Toggle (only for public calendars owned by current user)
        if (calendar != null && calendar.isPublic && _isOwner) ...[
          SliverToBoxAdapter(child: _buildDiscoverableToggle()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // Create Event Button (only if user has permissions)
        if (_canAddEvents) ...[
          SliverToBoxAdapter(child: _buildCreateEventButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // Members Section
        if (!_isLoadingMembers && _members.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildMembersSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // Event count
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

  Widget _buildShareHashSection() {
    final calendar = _calendar;
    if (calendar == null || calendar.shareHash == null) {
      return const SizedBox.shrink();
    }

    final hashCode = '#${calendar.shareHash}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppStyles.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.square_arrow_up,
                color: AppStyles.primary600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Compartir calendario',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.grey700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hashCode,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                        color: AppStyles.primary600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comparte este código para que otros puedan suscribirse a tu calendario',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppStyles.grey600,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: hashCode));
                  PlatformDialogHelpers.showSnackBar(
                    context: context,
                    message: 'Código copiado: $hashCode',
                  );
                },
                child: Icon(
                  CupertinoIcons.doc_on_clipboard,
                  color: AppStyles.primary600,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverableToggle() {
    final calendar = _calendar;
    if (calendar == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.grey200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discoverable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppStyles.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  calendar.isDiscoverable
                      ? context.l10n.appearsInSearch
                      : context.l10n.onlyViaShareLink,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey600,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: calendar.isDiscoverable,
            onChanged: _isUpdatingDiscoverable ? null : _updateDiscoverable,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    final l10n = context.l10n;
    final canManage = _canManageMembers;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.person_2, size: 20, color: AppStyles.grey700),
              const SizedBox(width: 8),
              Text(
                l10n.calendarMembers,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.grey700,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppStyles.blue600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_members.length}',
                  style: TextStyle(
                    color: AppStyles.blue600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.noMembers,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            )
          else
            ..._members.map(
              (member) => _buildMemberTile(member, canManage),
            ),
          if (canManage) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _navigateToInviteMembers,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppStyles.blue600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.person_add,
                      color: AppStyles.blue600,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.addMembers,
                      style: TextStyle(
                        color: AppStyles.blue600,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> memberData, bool canManage) {
    final user = memberData['user'] as Map<String, dynamic>?;
    final role = memberData['role'] as String? ?? 'member';
    final userId = memberData['user_id'] as int;

    final isOwner = role == 'owner';
    final isAdmin = role == 'admin';
    final canModifyThisMember = canManage && !isOwner && userId != currentUserId;

    final displayName = user?['display_name'] ??
                       user?['instagram_username'] ??
                       'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppStyles.cardBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppStyles.grey300.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Simple avatar placeholder (can be replaced with UserAvatar widget)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppStyles.blue600.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: AppStyles.blue600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: AppStyles.black87,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (isOwner)
                  Text(
                    context.l10n.owner,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppStyles.purple600,
                      decoration: TextDecoration.none,
                    ),
                  )
                else if (isAdmin)
                  Text(
                    context.l10n.calendarAdmin,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppStyles.blue600,
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
          if (canModifyThisMember) ...[
            // Toggle admin button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _isProcessingLeave
                  ? null
                  : () => isAdmin
                        ? _removeAdmin(memberData)
                        : _grantAdmin(memberData),
              child: Icon(
                isAdmin ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: _isProcessingLeave
                    ? AppStyles.grey400
                    : (isAdmin ? AppStyles.blue600 : AppStyles.grey600),
                size: 20,
              ),
            ),
            // Remove member button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _isProcessingLeave
                  ? null
                  : () => _removeMember(memberData),
              child: Icon(
                CupertinoIcons.minus_circle,
                color: _isProcessingLeave ? AppStyles.grey400 : AppStyles.red600,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToInviteMembers() async {
    final calendar = _calendar;
    if (calendar == null) return;

    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CalendarMembersScreen(
          calendarId: widget.calendarId,
          calendarName: calendar.name,
        ),
      ),
    );

    // Reload members if any were added
    if (result == true || mounted) {
      _loadMembers();
    }
  }

  Future<void> _grantAdmin(Map<String, dynamic> memberData) async {
    final l10n = context.l10n;
    final user = memberData['user'] as Map<String, dynamic>?;
    final displayName = user?['display_name'] ?? user?['instagram_username'] ?? 'Unknown';
    final membershipId = memberData['id'] as int;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.makeAdmin),
        content: Text(l10n.confirmMakeAdmin(displayName)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessingLeave = true);

      try {
        final repo = ref.read(calendarRepositoryProvider);
        await repo.updateMemberRole(membershipId, 'admin');

        if (mounted) {
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.memberMadeAdmin(displayName),
          );
          await _loadMembers(); // Reload to show updated role
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = ErrorMessageParser.parse(e, context);
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: errorMessage,
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessingLeave = false);
        }
      }
    }
  }

  Future<void> _removeAdmin(Map<String, dynamic> memberData) async {
    final l10n = context.l10n;
    final user = memberData['user'] as Map<String, dynamic>?;
    final displayName = user?['display_name'] ?? user?['instagram_username'] ?? 'Unknown';
    final membershipId = memberData['id'] as int;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.removeAdmin),
        content: Text(l10n.confirmRemoveAdmin(displayName)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessingLeave = true);

      try {
        final repo = ref.read(calendarRepositoryProvider);
        await repo.updateMemberRole(membershipId, 'member');

        if (mounted) {
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.memberRemovedAdmin(displayName),
          );
          await _loadMembers(); // Reload to show updated role
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = ErrorMessageParser.parse(e, context);
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: errorMessage,
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessingLeave = false);
        }
      }
    }
  }

  Future<void> _removeMember(Map<String, dynamic> memberData) async {
    final l10n = context.l10n;
    final user = memberData['user'] as Map<String, dynamic>?;
    final displayName = user?['display_name'] ?? user?['instagram_username'] ?? 'Unknown';
    final membershipId = memberData['id'] as int;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.removeMember),
        content: Text(l10n.confirmRemoveMember(displayName)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessingLeave = true);

      try {
        final repo = ref.read(calendarRepositoryProvider);
        await repo.removeMember(membershipId);

        if (mounted) {
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.memberRemoved(displayName),
          );
          await _loadMembers(); // Reload to update list
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = ErrorMessageParser.parse(e, context);
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: errorMessage,
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessingLeave = false);
        }
      }
    }
  }

  Widget _buildCreateEventButton() {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: AppStyles.primaryColor,
        borderRadius: BorderRadius.circular(12),
        onPressed: _createEvent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.add_circled_solid,
              color: CupertinoColors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.createEvent,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
