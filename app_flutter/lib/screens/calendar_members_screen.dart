import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/app_state.dart';
import '../widgets/empty_state.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

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
      ),
      child: SafeArea(
        child: _buildBody(),
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
    // TODO: Show action sheet with options
  }
}
