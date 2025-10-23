import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/invite_users_composite.dart';
import '../services/composite_sync_service.dart';
import '../services/event_interaction_service.dart';
import '../widgets/selectable_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/platform_refresh.dart';
import '../services/config_service.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'package:flutter/material.dart';

class InviteUsersScreen extends ConsumerStatefulWidget {
  final Event event;
  const InviteUsersScreen({super.key, required this.event});

  @override
  ConsumerState<InviteUsersScreen> createState() => _InviteUsersScreenState();
}

class _InviteUsersScreenState extends ConsumerState<InviteUsersScreen>
    with WidgetsBindingObserver {
  InviteUsersComposite? _composite;
  final Set<int> _recentlyInvitedUserIds = {};
  Set<int> selectedUserIds = {};
  Set<int> selectedGroupIds = {};
  bool _isLoading = false;
  bool isSending = false;
  String? _error;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
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
      _loadData();
    }
  }

  Future<void> _loadData() async {
    print('🔵 [InviteUsersScreen] _loadData START');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!ConfigService.instance.hasUser) {
        final l10n = context.l10n;
        setState(() {
          _error = l10n.userNotLoggedIn;
          _isLoading = false;
        });
        return;
      }

      final eventId = widget.event.id;
      if (eventId == null) {
        setState(() {
          _error = 'Event ID is missing';
          _isLoading = false;
        });
        return;
      }

      print('🔵 [InviteUsersScreen] Calling smartSyncInviteUsers...');
      final composite = await CompositeSyncService.instance
          .smartSyncInviteUsers(eventId);
      print(
        '🔵 [InviteUsersScreen] smartSyncInviteUsers completed, available users: ${composite.availableUsers.length}',
      );

      if (mounted) {
        setState(() {
          _composite = composite;
          _isLoading = false;
        });
        print('🔵 [InviteUsersScreen] setState completed, _isLoading=false');
      }
    } catch (e) {
      print('🔴 [InviteUsersScreen] ERROR: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleUser(int userId) {
    setState(() {
      selectedUserIds.contains(userId)
          ? selectedUserIds.remove(userId)
          : selectedUserIds.add(userId);
    });
  }

  void _toggleGroup(int groupId) {
    setState(() {
      selectedGroupIds.contains(groupId)
          ? selectedGroupIds.remove(groupId)
          : selectedGroupIds.add(groupId);
    });
  }

  List<User> _getFilteredUsers() {
    if (_composite == null) return [];

    final users = _composite!.availableUsers;

    final filteredUsers = users.where((user) {
      return !_recentlyInvitedUserIds.contains(user.id);
    }).toList();

    if (searchQuery.isEmpty) return filteredUsers;

    final query = searchQuery.toLowerCase();
    return filteredUsers.where((user) {
      return user.displayName.toLowerCase().contains(query) ||
          (user.displaySubtitle?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<Group> _getFilteredGroups() {
    if (_composite == null) return [];

    final groups = _composite!.groups;

    final groupStates = {
      for (var state in _composite!.groupStates) state.groupId: state,
    };

    final filteredGroups = groups.where((group) {
      final state = groupStates[group.id];
      return state != null &&
          state.state != 'fully_invited' &&
          state.state != 'empty';
    }).toList();

    if (searchQuery.isEmpty) return filteredGroups;

    final query = searchQuery.toLowerCase();
    return filteredGroups.where((group) {
      return group.name.toLowerCase().contains(query) ||
          group.description.toLowerCase().contains(query);
    }).toList();
  }

  Map<int, GroupInviteState> _getGroupStatesMap() {
    if (_composite == null) return {};
    return {for (var state in _composite!.groupStates) state.groupId: state};
  }

  Widget _buildSearchField() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: CupertinoSearchTextField(
        placeholder: l10n.search,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: TextStyle(color: AppStyles.grey700),
        backgroundColor: AppStyles.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(child: _buildContent());
  }

  Widget _buildContent() {
    final l10n = context.l10n;
    if (_isLoading) {
      return Center(
        child: PlatformWidgets.platformLoadingIndicator(radius: 16),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlatformWidgets.platformIcon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: AppStyles.grey500,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appErrorLoadingData,
              style: AppStyles.cardTitle.copyWith(color: AppStyles.grey700),
            ),
            const SizedBox(height: 8),
            Text(
              _error!.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AppStyles.bodyTextSmall.copyWith(color: AppStyles.grey600),
            ),
            const SizedBox(height: 24),
            PlatformWidgets.platformButton(
              onPressed: _loadData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final users = _getFilteredUsers();
    final groups = _getFilteredGroups();
    final groupStates = _getGroupStatesMap();

    if (users.isEmpty && groups.isEmpty && searchQuery.isEmpty) {
      return EmptyState(
        message: l10n.noUsersOrGroupsAvailable,
        icon: CupertinoIcons.person_badge_plus,
      );
    }

    return PlatformRefresh(
      onRefresh: () async {
        await CompositeSyncService.instance.clearInviteUsersCache(
          widget.event.id!,
        );
        await _loadData();
      },
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        children: [
          _buildSearchField(),
          if (searchQuery.isNotEmpty && users.isEmpty && groups.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: EmptyState(
                message: l10n.noSearchResults,
                icon: CupertinoIcons.search,
              ),
            ),
          ],
          if (users.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Text(
                l10n.users,
                style: AppStyles.cardTitle.copyWith(color: AppStyles.grey700),
              ),
            ),
            ...users.map((user) {
              final isSelected = selectedUserIds.contains(user.id);
              return SelectableCard(
                title: user.displayName,
                subtitle: user.displaySubtitle,
                icon: CupertinoIcons.person,
                color: AppStyles.blue600,
                selected: isSelected,
                onTap: () => _toggleUser(user.id),
                onChanged: (_) => _toggleUser(user.id),
              );
            }),
          ],
          if (groups.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Text(
                l10n.groups,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  decoration: TextDecoration.none,
                ).copyWith(color: AppStyles.grey700),
              ),
            ),
            ...groups.map((group) {
              final isSelected = selectedGroupIds.contains(group.id);
              final groupState = groupStates[group.id];

              String subtitle = group.description;
              if (groupState != null && groupState.isPartiallyInvited) {
                final badgeText =
                    '${groupState.invitedMembers}/${groupState.totalMembers} invitados';
                subtitle = subtitle.isNotEmpty
                    ? '$badgeText • $subtitle'
                    : badgeText;
              }

              return SelectableCard(
                title: group.name,
                subtitle: subtitle,
                icon: CupertinoIcons.person_2,
                color: AppStyles.blue600,
                selected: isSelected,
                onTap: () => _toggleGroup(group.id),
                onChanged: (_) => _toggleGroup(group.id),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _sendInvitations() async {
    if (isSending) {
      return;
    }

    if (selectedUserIds.isEmpty && selectedGroupIds.isEmpty) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final eventId = widget.event.id;
      if (eventId == null) {
        throw Exception('Event ID is missing');
      }

      final allUserIds = <int>{...selectedUserIds};

      for (final groupId in selectedGroupIds) {
        final group = _composite?.groups.firstWhere((g) => g.id == groupId);
        if (group != null) {
          for (final member in group.members) {
            allUserIds.add(member.id);
          }
        }
      }

      final interactionService = EventInteractionService();
      int successCount = 0;
      int errorCount = 0;

      for (final userId in allUserIds) {
        try {
          await interactionService.sendInvitation(eventId, userId);
          successCount++;

          _recentlyInvitedUserIds.add(userId);
        } catch (e) {
          errorCount++;
          print('Failed to invite user $userId: $e');
        }
      }

      if (mounted) {
        setState(() {
          isSending = false;
          selectedUserIds.clear();
          selectedGroupIds.clear();
        });

        final l10n = context.l10n;
        if (successCount > 0) {
          PlatformWidgets.showSnackBar(
            message: '$successCount ${l10n.invitationsSent}',
            isError: false,
          );
        }

        if (errorCount > 0) {
          PlatformWidgets.showSnackBar(
            message: '$errorCount invitations failed',
            isError: true,
          );
        }

        if (successCount > 0 && errorCount == 0) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSending = false;
        });

        PlatformWidgets.showSnackBar(
          message: 'Error sending invitations: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdaptivePageScaffold(
      title: l10n.inviteToEvent,
      actions: _buildActions(),
      body: _buildBody(context),
    );
  }

  List<Widget> _buildActions() {
    final l10n = context.l10n;
    if (isSending) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: PlatformWidgets.platformLoadingIndicator(
              radius: 10,
              color: AppStyles.white,
            ),
          ),
        ),
      ];
    }

    if (selectedUserIds.isEmpty && selectedGroupIds.isEmpty) {
      return [];
    }

    return [
      Tooltip(
        message: l10n.sendInvitations,
        child: AdaptiveButton(
          config: const AdaptiveButtonConfig(
            variant: ButtonVariant.text,
            size: ButtonSize.medium,
            fullWidth: false,
            iconPosition: IconPosition.leading,
          ),
          text: PlatformWidgets.isIOS ? l10n.send : null,
          icon: PlatformWidgets.isIOS ? null : CupertinoIcons.paperplane,
          onPressed: _sendInvitations,
        ),
      ),
    ];
  }
}
