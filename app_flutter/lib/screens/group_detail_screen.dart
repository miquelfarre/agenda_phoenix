import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/domain/group.dart';
import '../models/domain/user.dart';
import '../services/config_service.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/helpers/platform/platform_widgets.dart';
import '../ui/styles/app_styles.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import '../core/state/app_state.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;
  final Group? initialGroup; // For optimistic UI

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.initialGroup,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with WidgetsBindingObserver {
  Group? _currentGroup;
  bool _isProcessing = false;

  int get currentUserId => ConfigService.instance.currentUserId;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.initialGroup;
    WidgetsBinding.instance.addObserver(this);
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
      ref.invalidate(groupsStreamProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsStreamProvider);

    return AdaptivePageScaffold(
      key: const Key('group_detail_screen_scaffold'),
      title: _currentGroup?.name ?? context.l10n.groupDetails,
      actions: [
        // Edit button (only for creator/admin)
        if (_currentGroup != null &&
            _currentGroup!.canManageGroup(currentUserId))
          CupertinoButton(
            key: const Key('group_detail_edit_button'),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: _isProcessing
                ? null
                : () => _navigateToEdit(_currentGroup!),
            child: Icon(
              CupertinoIcons.pencil,
              color: _isProcessing ? AppStyles.grey400 : AppStyles.primary600,
            ),
          ),
      ],
      body: groupsAsync.when(
        data: (groups) {
          final group = groups.cast<Group?>().firstWhere(
            (g) => g?.id == widget.groupId,
            orElse: () => null,
          );

          if (group == null) {
            return EmptyState(
              icon: CupertinoIcons.exclamationmark_triangle,
              message: context.l10n.groupNotFound,
            );
          }

          // Update local reference for title and actions
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentGroup?.id != group.id) {
              setState(() {
                _currentGroup = group;
              });
            }
          });

          return _buildContent(group);
        },
        loading: () =>
            Center(child: PlatformWidgets.platformLoadingIndicator()),
        error: (error, stack) => EmptyState(
          icon: CupertinoIcons.exclamationmark_triangle,
          message: error.toString(),
        ),
      ),
    );
  }

  Widget _buildContent(Group group) {
    final l10n = context.l10n;
    final canManage = group.canManageGroup(currentUserId);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group info card
            _buildInfoCard(group, l10n),
            const SizedBox(height: 16),

            // Members section
            _buildMembersSection(group, l10n, canManage),
            const SizedBox(height: 24),

            // Add members button (for creator/admin)
            if (canManage) ...[
              AdaptiveButton(
                key: const Key('group_detail_add_members_button'),
                config: AdaptiveButtonConfig.primary(),
                text: l10n.addMembers,
                icon: CupertinoIcons.person_add,
                onPressed: _isProcessing
                    ? null
                    : () => _navigateToAddMembers(group),
              ),
              const SizedBox(height: 16),
            ],

            // Leave group button (for non-owner members)
            if (!group.isOwner(currentUserId) &&
                group.isMember(currentUserId)) ...[
              AdaptiveButton(
                key: const Key('group_detail_leave_button'),
                config: AdaptiveButtonConfig.secondary(),
                text: l10n.leaveGroup,
                icon: CupertinoIcons.arrow_right_square,
                onPressed: _isProcessing ? null : () => _leaveGroup(group),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Group group, l10n) {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppStyles.purple600,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  CupertinoIcons.group,
                  color: AppStyles.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.black87,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.membersLabel(group.totalMemberCount),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppStyles.grey600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.groupDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppStyles.black87,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group.description,
              style: TextStyle(
                fontSize: 14,
                color: AppStyles.grey700,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersSection(Group group, l10n, bool canManage) {
    // Combine owner, admins, and members
    final allMembers = <User>[];
    final addedIds = <int>{};

    // Add owner first
    if (group.owner != null && !addedIds.contains(group.owner!.id)) {
      allMembers.add(group.owner!);
      addedIds.add(group.owner!.id);
    }

    // Add admins
    for (var admin in group.admins) {
      if (!addedIds.contains(admin.id)) {
        allMembers.add(admin);
        addedIds.add(admin.id);
      }
    }

    // Add regular members
    for (var member in group.members) {
      if (!addedIds.contains(member.id)) {
        allMembers.add(member);
        addedIds.add(member.id);
      }
    }

    return Container(
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
                l10n.groupMembers,
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
              (member) => _buildMemberTile(member, group, canManage),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(User member, Group group, bool canManage) {
    final isOwner = group.isOwner(member.id);
    final isAdmin = group.admins.any((a) => a.id == member.id);
    final canModifyThisMember =
        canManage && !isOwner && member.id != currentUserId;

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
          UserAvatar(user: member, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: AppStyles.black87,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (isOwner)
                  Text(
                    context.l10n.creator,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppStyles.purple600,
                      decoration: TextDecoration.none,
                    ),
                  )
                else if (isAdmin)
                  Text(
                    context.l10n.groupAdmin,
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
              key: Key('group_member_${member.id}_toggle_admin_button'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _isProcessing
                  ? null
                  : () => isAdmin
                        ? _removeAdmin(member, group)
                        : _grantAdmin(member, group),
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
              key: Key('group_member_${member.id}_remove_button'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _isProcessing
                  ? null
                  : () => _removeMember(member, group),
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

  Future<void> _navigateToEdit(Group group) async {
    final result = await context.push(
      '/people/groups/${group.id}/edit',
      extra: group,
    );
    if (result == true && mounted) {
      // Group was deleted, go back
      context.pop();
    }
  }

  Future<void> _navigateToAddMembers(Group group) async {
    await context.push('/people/groups/${group.id}/add-members', extra: group);
    // No need to refresh - Realtime handles it
  }

  Future<void> _grantAdmin(User member, Group group) async {
    final l10n = context.l10n;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.makeAdmin),
        content: Text(l10n.confirmMakeAdmin(member.displayName)),
        actions: [
          CupertinoDialogAction(
            key: const Key('grant_admin_cancel_button'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            key: const Key('grant_admin_confirm_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      try {
        final repo = ref.read(groupRepositoryProvider);
        await repo.grantAdminPermission(groupId: group.id, userId: member.id);

        if (mounted) {
          PlatformWidgets.showSnackBar(
            message: l10n.memberMadeAdmin(member.displayName),
            isError: false,
          );
        }
      } catch (e) {
        if (mounted) {
          PlatformWidgets.showSnackBar(
            message: '${l10n.error}: ${e.toString()}',
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

  Future<void> _removeAdmin(User member, Group group) async {
    final l10n = context.l10n;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.removeAdmin),
        content: Text(l10n.confirmRemoveAdmin(member.displayName)),
        actions: [
          CupertinoDialogAction(
            key: const Key('remove_admin_cancel_button'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            key: const Key('remove_admin_confirm_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      try {
        final repo = ref.read(groupRepositoryProvider);
        await repo.removeAdminPermission(groupId: group.id, userId: member.id);

        if (mounted) {
          PlatformWidgets.showSnackBar(
            message: l10n.memberRemovedAdmin(member.displayName),
            isError: false,
          );
        }
      } catch (e) {
        if (mounted) {
          PlatformWidgets.showSnackBar(
            message: '${l10n.error}: ${e.toString()}',
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

  Future<void> _removeMember(User member, Group group) async {
    final l10n = context.l10n;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteFromGroup),
        content: Text(l10n.confirmRemoveFromGroup(member.displayName)),
        actions: [
          CupertinoDialogAction(
            key: const Key('remove_member_cancel_button'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            key: const Key('remove_member_confirm_button'),
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
        final repo = ref.read(groupRepositoryProvider);
        await repo.removeMemberFromGroup(
          groupId: group.id,
          memberUserId: member.id,
        );

        if (mounted) {
          PlatformWidgets.showSnackBar(
            message: l10n.memberRemovedFromGroup(member.displayName),
            isError: false,
          );
        }
      } catch (e) {
        if (mounted) {
          PlatformWidgets.showSnackBar(
            message: '${l10n.error}: ${e.toString()}',
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

  Future<void> _leaveGroup(Group group) async {
    final l10n = context.l10n;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.leaveGroup),
        content: Text(l10n.confirmLeaveGroup(group.name)),
        actions: [
          CupertinoDialogAction(
            key: const Key('leave_group_cancel_button'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            key: const Key('leave_group_confirm_button'),
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.leave),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      try {
        final repo = ref.read(groupRepositoryProvider);
        await repo.removeMemberFromGroup(
          groupId: group.id,
          memberUserId: currentUserId,
        );

        if (mounted) {
          context.pop(); // Go back to groups list
          PlatformWidgets.showSnackBar(
            message: l10n.leftGroup(group.name),
            isError: false,
          );
        }
      } catch (e) {
        if (mounted) {
          PlatformWidgets.showSnackBar(
            message: '${l10n.error}: ${e.toString()}',
            isError: true,
          );
        }
        setState(() => _isProcessing = false);
      }
    }
  }
}
