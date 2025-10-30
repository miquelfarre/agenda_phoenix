import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../models/event_interaction.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../../core/state/app_state.dart';
import '../../services/config_service.dart';
import 'event_card_config.dart';

/// Widget for building trailing action buttons (accept/reject invitations, delete, chevron)
class EventCardActions extends ConsumerWidget {
  final Event event;
  final EventCardConfig config;
  final EventInteraction? interaction;
  final String? participationStatus;

  const EventCardActions({super.key, required this.event, required this.config, this.interaction, this.participationStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ConfigService.instance.currentUserId;
    final isOwner = event.ownerId == currentUserId;

    // If there's an invitation, show accept/reject buttons
    if (interaction != null && interaction!.inviterId != null) {
      return _buildInvitationActions(context, ref);
    }

    // If user is owner, show delete button
    if (isOwner) {
      return _buildOwnerActions(context);
    }

    // If subscribed to public event, show delete button
    final subsAsync = ref.watch(subscriptionsProvider);
    final subs = subsAsync.value ?? const [];

    final isOwnerPublic = event.owner?.isPublic == true;
    final isSubscribed = subs.any((s) => s.id == event.ownerId);

    if (isOwnerPublic && isSubscribed && event.id != null) {
      return _buildSubscriptionActions(context);
    }

    // Default: show chevron or nothing
    if (config.showChevron) {
      return PlatformWidgets.platformIcon(CupertinoIcons.chevron_right, color: AppStyles.grey400, size: 20);
    }

    return const SizedBox.shrink();
  }

  Widget _buildInvitationActions(BuildContext context, WidgetRef ref) {
    final currentStatus = participationStatus ?? 'pending';
    final isCurrentlyAccepted = currentStatus == 'accepted';
    final isCurrentlyRejected = currentStatus == 'rejected';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionCircle(
          context: context,
          icon: isCurrentlyAccepted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          color: AppStyles.green600,
          tooltip: context.l10n.accept,
          onTap: () async {
            if (event.id != null) {
              try {
                final newStatus = isCurrentlyAccepted ? 'pending' : 'accepted';
                await ref.read(eventInteractionRepositoryProvider).updateParticipationStatus(event.id!, newStatus, isAttending: false);
              } catch (e) {
                if (!context.mounted) return;
                PlatformWidgets.showSnackBar(message: context.l10n.errorAcceptingInvitation, isError: true);
              }
            }
          },
        ),
        const SizedBox(width: 8),
        _actionCircle(
          context: context,
          icon: isCurrentlyRejected ? CupertinoIcons.xmark_circle_fill : CupertinoIcons.xmark,
          color: AppStyles.red600,
          tooltip: context.l10n.decline,
          onTap: () async {
            if (event.id == null) return;
            try {
              final newStatus = isCurrentlyRejected ? 'pending' : 'rejected';
              await ref.read(eventInteractionRepositoryProvider).updateParticipationStatus(event.id!, newStatus, isAttending: false);
            } catch (e) {
              if (!context.mounted) return;
              PlatformWidgets.showSnackBar(message: context.l10n.errorRejectingInvitation, isError: true);
            }
          },
        ),
      ],
    );
  }

  Widget _buildOwnerActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionCircle(
          context: context,
          icon: CupertinoIcons.delete,
          color: AppStyles.red600,
          tooltip: context.l10n.delete,
          onTap: () async {
            if (config.onDelete != null) {
              try {
                await config.onDelete!(event, shouldNavigate: config.navigateAfterDelete);
              } catch (_) {}
            }
          },
        ),
      ],
    );
  }

  Widget _buildSubscriptionActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionCircle(
          context: context,
          icon: CupertinoIcons.delete,
          color: AppStyles.red600,
          tooltip: context.l10n.decline,
          onTap: () async {
            if (config.onDelete != null) {
              try {
                await config.onDelete!(event, shouldNavigate: config.navigateAfterDelete);
              } catch (_) {}
            }
          },
        ),
      ],
    );
  }

  Widget _actionCircle({required BuildContext context, required IconData icon, required Color color, required VoidCallback onTap, String? tooltip}) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: tooltip,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(color, 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppStyles.colorWithOpacity(color, 0.25), width: 1),
          ),
          child: Center(child: PlatformWidgets.platformIcon(icon, color: color, size: 16)),
        ),
      ),
    );
  }
}
