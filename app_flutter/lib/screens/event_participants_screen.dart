import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/app_state.dart';
import '../widgets/empty_state.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class EventParticipantsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventName;

  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState
    extends ConsumerState<EventParticipantsScreen> {
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      final interactions = await repository.fetchEventInteractions(
        widget.eventId,
      );

      if (!mounted) return;

      // Filter only joined participants
      final participants = interactions
          .where((i) => i['interaction_type'] == 'joined')
          .toList();

      setState(() {
        _participants = participants;
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
        middle: Text(widget.eventName),
        previousPageTitle: context.l10n.events,
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

    if (_participants.isEmpty) {
      return const EmptyState(
        icon: CupertinoIcons.person_2,
        message: 'No participants',
        subtitle: 'No one has joined this event yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        final user = participant['user'] as Map<String, dynamic>?;
        final role = participant['role'] as String? ?? 'attendee';

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
            onTap: () => _showParticipantOptions(participant),
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
        return 'Attendee';
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

  void _showParticipantOptions(Map<String, dynamic> participant) {
    final interactionId = participant['id'] as int;
    final role = participant['role'] as String? ?? 'attendee';
    final user = participant['user'] as Map<String, dynamic>?;
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
          if (role == 'attendee')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _promoteToAdmin(interactionId, userName);
              },
              child: const Text('Promote to Admin'),
            ),
          if (role == 'admin')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _demoteToAttendee(interactionId, userName);
              },
              child: const Text('Demote to Attendee'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _confirmRemoveParticipant(interactionId, userName);
            },
            isDestructiveAction: true,
            child: const Text('Remove from Event'),
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

  Future<void> _promoteToAdmin(int interactionId, String userName) async {
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.updateParticipantRole(interactionId, 'admin');

      if (!mounted) return;

      // Reload participants
      await _loadParticipants();
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _demoteToAttendee(int interactionId, String userName) async {
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.updateParticipantRole(interactionId, 'attendee');

      if (!mounted) return;

      // Reload participants
      await _loadParticipants();
    } catch (e) {
      if (!mounted) return;
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

  void _confirmRemoveParticipant(int interactionId, String userName) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Participant'),
        content:
            Text('Are you sure you want to remove $userName from this event?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _removeParticipant(interactionId, userName);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeParticipant(int interactionId, String userName) async {
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.deleteInteraction(interactionId);

      if (!mounted) return;

      // Reload participants
      await _loadParticipants();
    } catch (e) {
      if (!mounted) return;
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
