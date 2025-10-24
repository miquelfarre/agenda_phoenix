import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../l10n/app_localizations.dart';
import '../config/app_constants.dart';
import 'event_card/event_card_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/app_state.dart';
import '../services/config_service.dart';
import '../models/user.dart';

class EventCard extends ConsumerWidget {
  final Event event;
  final VoidCallback onTap;
  final EventCardConfig config;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.config = const EventCardConfig(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // Use interaction data from event (from backend) instead of Hive
    final participationStatus = event.interactionStatus;

    final effectiveConfig = participationStatus != null
        ? config.copyWith(
            showInvitationStatus: true,
            invitationStatus: participationStatus,
          )
        : config;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppStyles.colorWithOpacity(AppStyles.white, 1.0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppStyles.colorWithOpacity(AppStyles.black87, 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, l10n, effectiveConfig, ref),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLeading(context),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEventContent(
                    context,
                    l10n,
                    effectiveConfig,
                    ref,
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrailingActions(context, ref, effectiveConfig),
              ],
            ),

            buildAttendeesRow(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    EventCardConfig config,
    WidgetRef ref,
  ) {
    final List<Widget> widgets = [];

    if (config.showInvitationStatus &&
        config.invitationStatus != null &&
        config.invitationStatus!.toLowerCase() == AppConstants.statusPending) {
      // Get inviter name from backend data if available
      String inviterText = '';
      if (event.invitedByUserId != null) {
        // Find inviter name in attendees list
        final inviterName = event.attendees.firstWhere(
          (a) => a is Map && a['id'] == event.invitedByUserId,
          orElse: () => null,
        )?['name'];
        if (inviterName != null) {
          inviterText = ' • $inviterName';
        }
      }

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.35),
              width: 1,
            ),
          ),
          child: Text(
            '${l10n.pendingInvitationBanner}$inviterText',
            style: AppStyles.bodyText.copyWith(
              fontSize: 12,
              color: AppStyles.orange600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final hasOwner =
        config.showOwner &&
        event.owner?.isPublic == true &&
        event.owner?.fullName != null;
    final hasInviter = false;
    if (hasOwner || hasInviter) {
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.white, 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (hasOwner) ...[
                _buildSmallOwnerAvatar(ref),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.owner!.fullName!,
                    style: AppStyles.cardSubtitle.copyWith(
                      color: AppStyles.blue600,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 6));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget buildAttendeesRow(BuildContext context, WidgetRef ref) {
    final currentUserId = ConfigService.instance.currentUserId;

    // Parse attendees from both User objects and Maps
    final List<Map<String, dynamic>> attendeeData = [];
    for (final a in event.attendees) {
      if (a is User) {
        attendeeData.add({
          'id': a.id,
          'name': a.fullName,
          'profile_picture': a.profilePicture,
        });
      } else if (a is Map<String, dynamic>) {
        attendeeData.add(a);
      }
    }

    // Filter out current user
    final otherAttendees = attendeeData
        .where((a) => a['id'] != currentUserId)
        .toList();

    if (otherAttendees.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.l10n.attendees,
            style: AppStyles.cardSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppStyles.grey700,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: otherAttendees.take(6).map((a) {
                final name = (a['name'] as String?) ?? '';
                final initials = name.trim().isNotEmpty
                    ? name.trim().split(RegExp(r"\s+")).first[0].toUpperCase()
                    : '?';
                return Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppStyles.blue600,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppStyles.bodyText.copyWith(
                        color: AppStyles.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingActions(
    BuildContext context,
    WidgetRef ref,
    EventCardConfig config,
  ) {
    final currentUserId = ConfigService.instance.currentUserId;
    final isOwner = event.ownerId == currentUserId;

    Widget actionCircle({
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      String? tooltip,
    }) {
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
              border: Border.all(
                color: AppStyles.colorWithOpacity(color, 0.25),
                width: 1,
              ),
            ),
            child: Center(
              child: PlatformWidgets.platformIcon(icon, color: color, size: 16),
            ),
          ),
        ),
      );
    }

    // Show accept/reject buttons for pending invitations
    if (event.wasInvited && event.interactionStatus == 'pending') {
      final isCurrentlyAccepted = event.interactionStatus == 'accepted';
      final isCurrentlyDeclined = event.interactionStatus == 'rejected';
      final isDeclinedNotAttending = isCurrentlyDeclined;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          actionCircle(
            icon: isCurrentlyAccepted
                ? CupertinoIcons.heart_fill
                : CupertinoIcons.heart,
            color: AppStyles.green600,
            tooltip: context.l10n.accept,
            onTap: () async {
              if (event.id != null) {
                try {
                  final newStatus = isCurrentlyAccepted
                      ? 'pending'
                      : 'accepted';
                  await ref
                      .read(eventInteractionsProvider.notifier)
                      .updateParticipationStatus(
                        event.id!,
                        newStatus,
                        isAttending: false,
                      );
                  ref.read(eventStateProvider.notifier).refresh();
                } catch (e) {
                  if (!context.mounted) return;
                  PlatformWidgets.showSnackBar(
                    message: context.l10n.errorAcceptingInvitation,
                    isError: true,
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),

          actionCircle(
            icon: isDeclinedNotAttending
                ? CupertinoIcons.xmark_circle_fill
                : CupertinoIcons.xmark,
            color: AppStyles.red600,
            tooltip: context.l10n.decline,
            onTap: () async {
              if (event.id == null) return;
              try {
                await ref
                    .read(eventInteractionsProvider.notifier)
                    .updateParticipationStatus(
                      event.id!,
                      'declined',
                      isAttending: false,
                    );
                ref.read(eventStateProvider.notifier).refresh();
              } catch (e) {
                if (!context.mounted) return;
                PlatformWidgets.showSnackBar(
                  message: context.l10n.errorRejectingInvitation,
                  isError: true,
                );
              }
            },
          ),
        ],
      );
    }

    if (isOwner) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          actionCircle(
            icon: CupertinoIcons.delete,
            color: AppStyles.red600,
            tooltip: context.l10n.delete,
            onTap: () async {
              if (config.onDelete != null) {
                try {
                  await config.onDelete!(
                    event,
                    shouldNavigate: config.navigateAfterDelete,
                  );
                } catch (_) {}
              } else {}
            },
          ),
        ],
      );
    }

    final subsAsync = ref.watch(subscriptionsProvider);
    final subs = subsAsync.value ?? const [];

    final isOwnerPublic = event.owner?.isPublic == true;
    final isSubscribed = subs.any(
      (s) => s.subscribedToId == event.ownerId && s.userId == currentUserId,
    );
    if (isOwnerPublic && isSubscribed && event.id != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          actionCircle(
            icon: CupertinoIcons.delete,
            color: AppStyles.red600,
            tooltip: context.l10n.decline,
            onTap: () async {
              if (config.onDelete != null) {
                try {
                  await config.onDelete!(
                    event,
                    shouldNavigate: config.navigateAfterDelete,
                  );
                } catch (_) {}
              }
            },
          ),
        ],
      );
    }

    if (config.showChevron) {
      return PlatformWidgets.platformIcon(
        CupertinoIcons.chevron_right,
        color: AppStyles.grey400,
        size: 20,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLeading(BuildContext context) {
    if (config.customAvatar != null) {
      return config.customAvatar!;
    }

    if (event.isBirthday) {
      return _buildBirthdayAvatar(context);
    }

    return _buildTimeContainer(context);
  }

  Widget _buildBirthdayAvatar(BuildContext context) {
    final owner = event.owner;
    final profilePicture = owner?.profilePicture;

    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.3),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: profilePicture != null && profilePicture.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: profilePicture,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildBirthdayIcon(),
              )
            : _buildBirthdayIcon(),
      ),
    );
  }

  Widget _buildBirthdayIcon() {
    return Center(
      child: PlatformWidgets.platformIcon(
        CupertinoIcons.gift,
        color: AppStyles.orange600,
        size: 32,
      ),
    );
  }

  Widget _buildTimeContainer(BuildContext context) {
    final eventTime = event.date;

    final colon = context.l10n.colon;
    final timeStr =
        '${eventTime.hour.toString().padLeft(2, '0')}$colon${eventTime.minute.toString().padLeft(2, '0')}';

    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeStr,
            style: AppStyles.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppStyles.blue600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(
    BuildContext context,
    AppLocalizations l10n,
    EventCardConfig config,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.customTitle ?? event.title,
          style: AppStyles.cardTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if ((config.customSubtitle ?? event.description ?? '').isNotEmpty)
          Text(
            config.customSubtitle ?? event.description ?? '',
            style: AppStyles.cardSubtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

        _buildEventBadges(context),

        if (config.customStatus != null) ...[
          const SizedBox(height: 4),
          Text(
            config.customStatus!,
            style: AppStyles.cardSubtitle.copyWith(
              color: AppStyles.blue600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        if (config.showInvitationStatus &&
            config.invitationStatus != null &&
            config.invitationStatus!.toLowerCase() !=
                AppConstants.statusPending) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(context, config.invitationStatus!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(l10n, config.invitationStatus!),
              style: AppStyles.bodyText.copyWith(
                fontSize: 12,
                color: AppStyles.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventBadges(BuildContext context) {
    final List<Widget> badges = [];

    if (event.calendarId != null && event.calendarName != null) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.calendarColor != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _parseColor(event.calendarColor!),
                    shape: BoxShape.circle,
                  ),
                ),
              if (event.calendarColor != null) const SizedBox(width: 4),
              Text(
                event.calendarName!,
                style: AppStyles.bodyText.copyWith(
                  fontSize: 11,
                  color: AppStyles.blue600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (event.isBirthday) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppStyles.colorWithOpacity(AppStyles.orange600, 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.gift,
                size: 11,
                color: AppStyles.orange600,
              ),
              const SizedBox(width: 3),
              Text(
                context.l10n.isBirthday,
                style: AppStyles.bodyText.copyWith(
                  fontSize: 11,
                  color: AppStyles.orange600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (event.isRecurring) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(AppStyles.green600, 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppStyles.colorWithOpacity(AppStyles.green600, 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.repeat,
                size: 11,
                color: AppStyles.green600,
              ),
              const SizedBox(width: 3),
              Text(
                context.l10n.recurringEvent,
                style: AppStyles.bodyText.copyWith(
                  fontSize: 11,
                  color: AppStyles.green600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 4, runSpacing: 4, children: badges),
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppStyles.blue600;
    }
  }

  Widget _buildSmallOwnerAvatar(WidgetRef ref) {
    final owner = event.owner;

    if (owner?.isPublic != true) {
      return const SizedBox.shrink();
    }

    final logoPath = ref.watch(logoPathProvider(owner!.id)).value;
    if (logoPath != null) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.25),
            width: 1,
          ),
          image: DecorationImage(
            image: FileImage(File(logoPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    String? url = owner.profilePicture;
    if (url != null && url.isNotEmpty) {
      if (url.contains('placehold.co') && !url.contains('.png')) {
        final uri = Uri.parse(url);
        final path = uri.path.endsWith('.png') ? uri.path : '${uri.path}.png';
        url = uri.replace(path: path).toString();
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (context, failedUrl, error) {
              final name = owner.fullName;
              if (name != null && name.isNotEmpty) {
                return _buildSmallInitials(name);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    final name = owner.fullName;
    if (name != null && name.isNotEmpty) {
      return _buildSmallInitials(name);
    }

    return const SizedBox.shrink();
  }

  Widget _buildSmallInitials(String name) {
    String initials = name
        .trim()
        .split(RegExp(r"\s+"))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    if (initials.isEmpty) initials = '?';

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.25),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppStyles.bodyText.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppStyles.blue600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return AppStyles.orange600;
      case AppConstants.statusAccepted:
        return AppStyles.green600;
      case AppConstants.statusRejected:
        return AppStyles.red600;
      default:
        return AppStyles.grey500;
    }
  }

  String _getStatusText(AppLocalizations l10n, String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return l10n.pendingStatus;
      case AppConstants.statusAccepted:
        return l10n.acceptedStatus;
      case AppConstants.statusRejected:
        return l10n.rejectedStatus;
      default:
        return status;
    }
  }
}
