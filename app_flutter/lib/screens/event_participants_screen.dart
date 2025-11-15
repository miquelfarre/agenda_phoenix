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
      return EmptyState(
        icon: CupertinoIcons.person_2,
        message: context.l10n.noParticipants,
        subtitle: context.l10n.noOneHasJoined,
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
              _getRoleLabel(role, context),
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

  String _getRoleLabel(String role, BuildContext context) {
    switch (role) {
      case 'owner':
        return context.l10n.owner;
      case 'admin':
        return context.l10n.admin;
      default:
        return context.l10n.attendee;
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
      builder: (BuildContext actionContext) => CupertinoActionSheet(
        title: Text(userName),
        actions: <CupertinoActionSheetAction>[
          if (role == 'attendee')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(actionContext);
                _promoteToAdmin(interactionId, userName);
              },
              child: Text(context.l10n.promoteToAdmin),
            ),
          if (role == 'admin')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(actionContext);
                _demoteToAttendee(interactionId, userName);
              },
              child: Text(context.l10n.demoteToAttendee),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(actionContext);
              _confirmRemoveParticipant(interactionId, userName);
            },
            isDestructiveAction: true,
            child: Text(context.l10n.removeFromEvent),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(actionContext);
          },
          child: Text(context.l10n.cancel),
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
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(context.l10n.error),
          content: Text(context.l10n.failedToPromote(userName, e.toString())),
          actions: [
            CupertinoDialogAction(
              child: Text(context.l10n.ok),
              onPressed: () => Navigator.pop(dialogContext),
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
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(context.l10n.error),
          content: Text(context.l10n.failedToDemote(userName, e.toString())),
          actions: [
            CupertinoDialogAction(
              child: Text(context.l10n.ok),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      );
    }
  }

  void _confirmRemoveParticipant(int interactionId, String userName) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.removeParticipant),
        content: Text(context.l10n.confirmRemoveParticipant(userName)),
        actions: [
          CupertinoDialogAction(
            child: Text(context.l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              _removeParticipant(interactionId, userName);
            },
            child: Text(context.l10n.remove),
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
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(context.l10n.error),
          content: Text(context.l10n.failedToRemove(userName, e.toString())),
          actions: [
            CupertinoDialogAction(
              child: Text(context.l10n.ok),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      );
    }
  }
}
