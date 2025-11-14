import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/app_state.dart';
import '../widgets/empty_state.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
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
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(calendarRepositoryProvider);
      final memberships = await repository.fetchCalendarMemberships(
        widget.calendarId,
      );

      if (!mounted) return;

      setState(() {
        _members = memberships;
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.calendarName),
        previousPageTitle: context.l10n.calendars,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToInvite,
          child: const Icon(CupertinoIcons.person_add),
        ),
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  void _navigateToInvite() async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => InviteCalendarMembersScreen(
          calendarId: widget.calendarId,
          calendarName: widget.calendarName,
        ),
      ),
    );

    // Reload members if any were added
    if (result == true || mounted) {
      _loadMembers();
    }
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

    if (_members.isEmpty) {
      return EmptyState(
        icon: CupertinoIcons.person_2,
        message: context.l10n.noMembers,
        subtitle: 'No members in this calendar',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final user = member['user'] as Map<String, dynamic>?;
        final role = member['role'] as String? ?? 'member';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey4,
              width: 1,
            ),
          ),
          child: CupertinoListTile(
            title: Text(
              user?['display_name'] ?? 'Unknown',
              style: AppStyles.bodyText,
            ),
            subtitle: Text(
              _getRoleLabel(role),
              style: AppStyles.cardSubtitle.copyWith(
                color: _getRoleColor(role),
              ),
            ),
            trailing: const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.systemGrey,
            ),
            onTap: () => _showMemberOptions(member),
          ),
        );
      },
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      default:
        return 'Member';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return CupertinoColors.systemBlue;
      case 'admin':
        return CupertinoColors.systemGreen;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    final membershipId = member['id'] as int;
    final role = member['role'] as String? ?? 'member';
    final user = member['user'] as Map<String, dynamic>?;
    final userName = user?['display_name'] ?? 'Unknown';

    // Cannot manage owner
    if (role == 'owner') {
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(userName),
        actions: <CupertinoActionSheetAction>[
          if (role == 'member')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _promoteToAdmin(membershipId, userName);
              },
              child: const Text('Promote to Admin'),
            ),
          if (role == 'admin')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _demoteToMember(membershipId, userName);
              },
              child: const Text('Demote to Member'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _confirmRemoveMember(membershipId, userName);
            },
            isDestructiveAction: true,
            child: const Text('Remove from Calendar'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _promoteToAdmin(int membershipId, String userName) async {
    try {
      final repository = ref.read(calendarRepositoryProvider);
      await repository.updateMemberRole(membershipId, 'admin');

      if (!mounted) return;

      // Reload members
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      // Show error
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to promote $userName: ${e.toString()}'),
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

  Future<void> _demoteToMember(int membershipId, String userName) async {
    try {
      final repository = ref.read(calendarRepositoryProvider);
      await repository.updateMemberRole(membershipId, 'member');

      if (!mounted) return;

      // Reload members
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      // Show error
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to demote $userName: ${e.toString()}'),
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

  void _confirmRemoveMember(int membershipId, String userName) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $userName from this calendar?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _removeMember(membershipId, userName);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(int membershipId, String userName) async {
    try {
      final repository = ref.read(calendarRepositoryProvider);
      await repository.removeMember(membershipId);

      if (!mounted) return;

      // Reload members
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      // Show error
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to remove $userName: ${e.toString()}'),
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
}
