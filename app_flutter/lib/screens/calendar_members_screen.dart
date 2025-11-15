import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/app_state.dart';
import '../models/domain/calendar.dart';
import '../models/domain/user.dart';
import '../widgets/empty_state.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../utils/error_message_parser.dart';
import '../services/config_service.dart';
import 'invite_calendar_members_screen.dart';

class CalendarMembersScreen extends ConsumerStatefulWidget {
  final int calendarId;
  final String calendarName;

  const CalendarMembersScreen({
    super.key,
    required this.calendarId,
    required this.calendarName,
  });

  @override
  ConsumerState<CalendarMembersScreen> createState() =>
      _CalendarMembersScreenState();
}

class _CalendarMembersScreenState extends ConsumerState<CalendarMembersScreen> {
  bool _isProcessing = false;

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

  bool get _canManageMembers {
    final calendar = _calendar;
    if (calendar == null) return false;
    return calendar.canManageCalendar(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calendarsAsync = ref.watch(calendarsStreamProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.calendarName),
      ),
      child: SafeArea(
        child: calendarsAsync.when(
          data: (calendars) {
            final calendar = calendars.firstWhere(
              (cal) => cal.id == widget.calendarId,
              orElse: () => Calendar(
                id: widget.calendarId,
                name: widget.calendarName,
                ownerId: 0,
                isPublic: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            return _buildMembersSection(calendar);
          },
          loading: () => const Center(
            child: CupertinoActivityIndicator(),
          ),
          error: (error, stack) => EmptyState(
            icon: CupertinoIcons.exclamationmark_triangle,
            message: l10n.error,
            subtitle: error.toString(),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection(Calendar calendar) {
    final l10n = context.l10n;
    final canManage = _canManageMembers;

    // Combine owner, admins, and members
    final allMembers = <User>[];
    final addedIds = <int>{};

    // Add owner first
    if (calendar.owner != null && !addedIds.contains(calendar.owner!.id)) {
      allMembers.add(calendar.owner!);
      addedIds.add(calendar.owner!.id);
    }

    // Add admins
    for (var admin in calendar.admins) {
      if (!addedIds.contains(admin.id)) {
        allMembers.add(admin);
        addedIds.add(admin.id);
      }
    }

    // Add regular members
    for (var member in calendar.members) {
      if (!addedIds.contains(member.id)) {
        allMembers.add(member);
        addedIds.add(member.id);
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
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
                  '${allMembers.length}',
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
          if (allMembers.isEmpty)
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
            ...allMembers.map(
              (member) => _buildMemberTile(member, calendar, canManage),
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

  Widget _buildMemberTile(User member, Calendar calendar, bool canManage) {
    final isOwner = calendar.isOwner(member.id);
    final isAdmin = calendar.admins.any((a) => a.id == member.id);
    final canModifyThisMember = canManage && !isOwner && member.id != currentUserId;

    final displayName = member.displayName.isNotEmpty
        ? member.displayName
        : (member.instagramUsername ?? 'Unknown');

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
          // Simple avatar placeholder
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
              onPressed: _isProcessing
                  ? null
                  : () => isAdmin
                        ? _removeAdmin(member)
                        : _grantAdmin(member),
              child: Icon(
                isAdmin ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: _isProcessing
                    ? AppStyles.grey400
                    : (isAdmin ? AppStyles.blue600 : AppStyles.grey600),
                size: 20,
              ),
            ),
            // Remove member button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _isProcessing
                  ? null
                  : () => _removeMember(member),
              child: Icon(
                CupertinoIcons.minus_circle,
                color: _isProcessing ? AppStyles.grey400 : AppStyles.red600,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToInviteMembers() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => InviteCalendarMembersScreen(
          calendarId: widget.calendarId,
          calendarName: widget.calendarName,
        ),
      ),
    );

    // No need to reload - realtime will update automatically
  }

  Future<void> _grantAdmin(User member) async {
    final l10n = context.l10n;
    final displayName = member.displayName.isNotEmpty
        ? member.displayName
        : (member.instagramUsername ?? 'Unknown');

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
      setState(() => _isProcessing = true);

      try {
        final repo = ref.read(calendarRepositoryProvider);

        // Get membershipId from memberships
        final memberships = await repo.fetchCalendarMemberships(widget.calendarId);
        final membership = memberships.firstWhere(
          (m) => m['user_id'] == member.id,
          orElse: () => throw Exception('Membership not found'),
        );
        final membershipId = membership['id'] as int;

        await repo.updateMemberRole(membershipId, 'admin');

        if (mounted) {
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.memberMadeAdmin(displayName),
          );
          // No need to reload - realtime will update automatically
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
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _removeAdmin(User member) async {
    final l10n = context.l10n;
    final displayName = member.displayName.isNotEmpty
        ? member.displayName
        : (member.instagramUsername ?? 'Unknown');

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
      setState(() => _isProcessing = true);

      try {
        final repo = ref.read(calendarRepositoryProvider);

        // Get membershipId from memberships
        final memberships = await repo.fetchCalendarMemberships(widget.calendarId);
        final membership = memberships.firstWhere(
          (m) => m['user_id'] == member.id,
          orElse: () => throw Exception('Membership not found'),
        );
        final membershipId = membership['id'] as int;

        await repo.updateMemberRole(membershipId, 'member');

        if (mounted) {
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.memberRemovedAdmin(displayName),
          );
          // No need to reload - realtime will update automatically
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
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _removeMember(User member) async {
    final l10n = context.l10n;
    final displayName = member.displayName.isNotEmpty
        ? member.displayName
        : (member.instagramUsername ?? 'Unknown');

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
      setState(() => _isProcessing = true);

      try {
        final repo = ref.read(calendarRepositoryProvider);

        // Get membershipId from memberships
        final memberships = await repo.fetchCalendarMemberships(widget.calendarId);
        final membership = memberships.firstWhere(
          (m) => m['user_id'] == member.id,
          orElse: () => throw Exception('Membership not found'),
        );
        final membershipId = membership['id'] as int;

        await repo.removeMember(membershipId);

        if (mounted) {
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: l10n.memberRemoved(displayName),
          );
          // No need to reload - realtime will update automatically
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
          setState(() => _isProcessing = false);
        }
      }
    }
  }
}
