import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/user.dart';
import '../models/domain/group.dart';
import '../core/state/app_state.dart';
import '../widgets/selectable_card.dart';
import '../widgets/empty_state.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class InviteCalendarMembersScreen extends ConsumerStatefulWidget {
  final int calendarId;
  final String calendarName;

  const InviteCalendarMembersScreen({
    super.key,
    required this.calendarId,
    required this.calendarName,
  });

  @override
  ConsumerState<InviteCalendarMembersScreen> createState() =>
      _InviteCalendarMembersScreenState();
}

class _InviteCalendarMembersScreenState
    extends ConsumerState<InviteCalendarMembersScreen> {
  List<User> _availableUsers = [];
  List<Group> _groups = [];
  Set<int> selectedUserIds = {};
  Set<int> selectedGroupIds = {};
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String _selectedRole = 'member';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final groupRepo = ref.read(groupRepositoryProvider);

      // Fetch all users (except current user and existing members)
      final users = await userRepo.fetchUsers();
      final groups = await groupRepo.fetchGroups();

      if (!mounted) return;

      setState(() {
        _availableUsers = users;
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

  Future<void> _sendInvites() async {
    if (selectedUserIds.isEmpty && selectedGroupIds.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final repository = ref.read(calendarRepositoryProvider);

      await repository.addMembersBulk(
        calendarId: widget.calendarId,
        userIds: selectedUserIds.toList(),
        groupIds: selectedGroupIds.toList(),
        role: _selectedRole,
      );

      if (!mounted) return;

      // Success - go back
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      // Show error
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to add members: ${e.toString()}'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedUserIds.isNotEmpty || selectedGroupIds.isNotEmpty;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Invite Members'),
        previousPageTitle: widget.calendarName,
        trailing: hasSelection
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isSending ? null : _sendInvites,
                child: _isSending
                    ? const CupertinoActivityIndicator()
                    : const Text('Invite'),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Role selector
            Container(
              padding: const EdgeInsets.all(16),
              color: CupertinoColors.systemBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Role',
                    style: AppStyles.cardTitle,
                  ),
                  const SizedBox(height: 8),
                  CupertinoSegmentedControl<String>(
                    groupValue: _selectedRole,
                    onValueChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                    children: const {
                      'member': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Member'),
                      ),
                      'admin': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Admin'),
                      ),
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_error != null) {
      return EmptyState(
        icon: CupertinoIcons.exclamationmark_triangle,
        message: 'Error',
        subtitle: _error!,
      );
    }

    if (_availableUsers.isEmpty && _groups.isEmpty) {
      return const EmptyState(
        icon: CupertinoIcons.person_2,
        message: 'No users available',
        subtitle: 'All users are already members',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_availableUsers.isNotEmpty) ...[
          Text(
            'Users',
            style: AppStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          ..._availableUsers.map((user) {
            final isSelected = selectedUserIds.contains(user.id);
            return SelectableCard(
              isSelected: isSelected,
              onTap: () => _toggleUser(user.id!),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: CupertinoColors.systemGrey4,
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.displayName,
                      style: AppStyles.bodyText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
        if (_groups.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Groups',
            style: AppStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          ..._groups.map((group) {
            final isSelected = selectedGroupIds.contains(group.id);
            return SelectableCard(
              isSelected: isSelected,
              onTap: () => _toggleGroup(group.id!),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.group,
                    size: 24,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.name,
                      style: AppStyles.bodyText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
