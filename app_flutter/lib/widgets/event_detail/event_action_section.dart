import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../core/state/app_state.dart';
import '../../services/config_service.dart';
import '../../screens/invite_users_screen.dart';
import '../../ui/helpers/platform/platform_widgets.dart';
import '../../ui/helpers/platform/dialog_helpers.dart';
import '../../ui/helpers/l10n/l10n_helpers.dart';
import '../../ui/styles/app_styles.dart';
import '../event_detail_actions.dart';
import '../../utils/event_permissions.dart';

class EventActionSection extends ConsumerStatefulWidget {
  final Event event;
  final VoidCallback? onEventUpdated;
  final VoidCallback? onEventDeleted;

  const EventActionSection({super.key, required this.event, this.onEventUpdated, this.onEventDeleted});

  @override
  ConsumerState<EventActionSection> createState() => _EventActionSectionState();
}

class _EventActionSectionState extends ConsumerState<EventActionSection> {
  bool _sendCancellationNotification = false;
  final TextEditingController _cancellationNotificationController = TextEditingController();

  int get currentUserId => ConfigService.instance.currentUserId;
  bool get isEventOwner => EventPermissions.isOwner(widget.event);
  bool get canInviteUsers => widget.event.canInviteUsers;

  @override
  void dispose() {
    _cancellationNotificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionButtons(),
        if (isEventOwner) ...[const SizedBox(height: 24), _buildCancellationNotificationSection()] else ...[const SizedBox(height: 24), _buildRemoveFromListButton()],
      ],
    );
  }

  Widget _buildActionButtons() {
    if (!canInviteUsers && !isEventOwner) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.eventActions, style: AppStyles.cardTitle),
          const SizedBox(height: 16),
          EventDetailActions(isEventOwner: isEventOwner, canInvite: canInviteUsers, onInvite: () => _navigateToInviteScreen(), onEdit: widget.onEventUpdated),
        ],
      ),
    );
  }

  void _navigateToInviteScreen() {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => InviteUsersScreen(event: widget.event)));
  }

  Widget _buildCancellationNotificationSection() {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.eventCancellation, style: AppStyles.cardTitle),
          const SizedBox(height: 16),
          Row(
            children: [
              PlatformWidgets.platformSwitch(
                value: _sendCancellationNotification,
                onChanged: (value) {
                  setState(() {
                    _sendCancellationNotification = value;
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(context.l10n.sendCancellationNotification, style: const TextStyle(fontSize: 16))),
            ],
          ),
          if (_sendCancellationNotification) ...[
            const SizedBox(height: 16),
            PlatformWidgets.platformTextField(controller: _cancellationNotificationController, placeholder: context.l10n.cancellationMessage, maxLines: 3, keyboardType: TextInputType.multiline),
            const SizedBox(height: 16),
            PlatformWidgets.platformButton(onPressed: () => _handleCancelEvent(), child: Text(context.l10n.cancelEventWithNotification), color: AppStyles.errorColor),
          ],
        ],
      ),
    );
  }

  Widget _buildRemoveFromListButton() {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.eventOptions, style: AppStyles.cardTitle),
          const SizedBox(height: 16),
          PlatformWidgets.platformButton(onPressed: () => _handleRemoveFromList(), child: Text(context.l10n.removeFromMyList), color: AppStyles.errorColor, filled: false),
        ],
      ),
    );
  }

  Future<void> _handleCancelEvent() async {
    final confirmed = await PlatformDialogHelpers.showPlatformConfirmDialog(context, title: context.l10n.cancelEvent, message: context.l10n.confirmCancelEvent, confirmText: context.l10n.cancel, cancelText: context.l10n.doNotCancel, isDestructive: true);

    if (confirmed != true) return;

    try {
      if (!mounted) return;

      await ref.read(eventServiceProvider).deleteEvent(widget.event.id!);

      // Realtime handles refresh automatically via EventRepository

      if (mounted) {
        PlatformDialogHelpers.showGlobalPlatformMessage(context: context, message: context.l10n.eventCancelledSuccessfully);

        widget.onEventDeleted?.call();
      }
    } catch (error) {
      if (mounted) {
        PlatformDialogHelpers.showGlobalPlatformMessage(context: context, message: context.l10n.failedToCancelEvent, isError: true);
      }
    }
  }

  Future<void> _handleRemoveFromList() async {
    final confirmed = await PlatformDialogHelpers.showPlatformConfirmDialog(context, title: context.l10n.removeFromList, message: context.l10n.confirmRemoveFromList, confirmText: context.l10n.remove, cancelText: context.l10n.cancel, isDestructive: true);

    if (confirmed != true) return;

    try {
      if (!mounted) return;

      await ref.read(eventServiceProvider).deleteEvent(widget.event.id!);

      // Realtime handles refresh automatically via EventRepository

      if (mounted) {
        PlatformDialogHelpers.showGlobalPlatformMessage(context: context, message: context.l10n.eventRemovedFromList);

        widget.onEventDeleted?.call();
      }
    } catch (error) {
      if (mounted) {
        PlatformDialogHelpers.showGlobalPlatformMessage(context: context, message: context.l10n.failedToRemoveFromList, isError: true);
      }
    }
  }
}
