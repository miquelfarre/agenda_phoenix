import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/user.dart';
import '../models/domain/group.dart';
import '../core/state/app_state.dart';
import '../widgets/selectable_card.dart';
import '../widgets/empty_state.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class InviteEventParticipantsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventName;

  const InviteEventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<InviteEventParticipantsScreen> createState() =>
      _InviteEventParticipantsScreenState();
}

class _InviteEventParticipantsScreenState
    extends ConsumerState<InviteEventParticipantsScreen> {
  List<User> _availableUsers = [];
  List<Group> _groups = [];
  Set<int> selectedUserIds = {};
  Set<int> selectedGroupIds = {};
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String _selectedRole = 'attendee';

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
      final apiClient = ref.read(apiClientProvider);

      // Fetch all users and groups
      final usersData = await apiClient.fetchUsers();
      final groupsData = await apiClient.fetchGroups();

      if (!mounted) return;

      setState(() {
        _availableUsers = usersData.map((data) => User.fromJson(data)).toList();
        _groups = groupsData.map((data) => Group.fromJson(data)).toList();
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

  Future<void> _addParticipants() async {
    if (selectedUserIds.isEmpty && selectedGroupIds.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);

      await repository.addParticipantsBulk(
        eventId: widget.eventId,
        userIds: selectedUserIds.toList(),
        groupIds: selectedGroupIds.toList(),
        role: _selectedRole,
      );

      if (!mounted) return;

      // Success - go back
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      // Show error
      final l10n = context.l10n;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.error),
          content: Text('${l10n.failedToAddParticipants}: ${e.toString()}'),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.ok),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasSelection = selectedUserIds.isNotEmpty || selectedGroupIds.isNotEmpty;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.addParticipants),
        trailing: hasSelection
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isSending ? null : _addParticipants,
                child: _isSending
                    ? const CupertinoActivityIndicator()
                    : Text(l10n.add),
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
                    l10n.role,
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
                    children: {
                      'attendee': Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(l10n.attendee),
                      ),
                      'admin': Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(l10n.admin),
                      ),
                    },
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: CupertinoColors.separator,
            ),
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
    final l10n = context.l10n;

    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_error != null) {
      return EmptyState(
        icon: CupertinoIcons.exclamationmark_triangle,
        message: l10n.error,
        subtitle: _error!,
      );
    }

    if (_availableUsers.isEmpty && _groups.isEmpty) {
      return EmptyState(
        icon: CupertinoIcons.person_2,
        message: l10n.noUsersAvailable,
        subtitle: l10n.allUsersAlreadyParticipating,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_availableUsers.isNotEmpty) ...[
          Text(
            l10n.users,
            style: AppStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          ..._availableUsers.map((user) {
            final isSelected = selectedUserIds.contains(user.id);
            return SelectableCard(
              title: user.displayName,
              subtitle: user.instagramUsername ?? user.phone,
              icon: CupertinoIcons.person,
              color: AppStyles.blue600,
              selected: isSelected,
              onTap: () => _toggleUser(user.id),
              onChanged: (_) => _toggleUser(user.id),
            );
          }),
        ],
        if (_groups.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.groups,
            style: AppStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          ..._groups.map((group) {
            final isSelected = selectedGroupIds.contains(group.id);
            return SelectableCard(
              title: group.name,
              subtitle: null,
              icon: CupertinoIcons.group,
              color: AppStyles.green600,
              selected: isSelected,
              onTap: () => _toggleGroup(group.id),
              onChanged: (_) => _toggleGroup(group.id),
            );
          }),
        ],
      ],
    );
  }
}
