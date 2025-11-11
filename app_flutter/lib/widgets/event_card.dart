import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/domain/event.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../l10n/app_localizations.dart';
import '../config/app_constants.dart';
import 'event_card/event_card_config.dart';
import 'event_card/event_card_badges.dart';
import 'event_card/event_card_actions.dart';
import 'event_card/event_card_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/app_state.dart';

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

    // Get interaction from provider (source of truth for interaction state)
    final interactions = ref.watch(eventInteractionsProvider).value ?? [];
    final interaction = interactions
        .where((i) => i.eventId == event.id)
        .firstOrNull;

    final participationStatus = interaction?.status;

    // Only show invitation status if config allows it AND there's a participation status
    final effectiveConfig =
        participationStatus != null && config.showInvitationStatus
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
            EventCardHeader(event: event, config: effectiveConfig),

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
                EventCardActions(
                  event: event,
                  config: effectiveConfig,
                  interaction: interaction,
                  participationStatus: participationStatus,
                ),
              ],
            ),

            EventCardAttendeesRow(event: event),
          ],
        ),
      ),
    );
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
    final profilePicture = owner?.profilePictureUrl;

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
    final l10n = context.l10n;

    final colon = l10n.colon;
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
          if (config.showDate) ...[
            const SizedBox(height: 2),
            Text(
              _formatDateShort(eventTime, l10n),
              style: AppStyles.bodyText.copyWith(
                fontSize: 10,
                color: AppStyles.blue600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateShort(DateTime date, AppLocalizations l10n) {
    final months = [
      l10n.january.substring(0, 3),
      l10n.february.substring(0, 3),
      l10n.march.substring(0, 3),
      l10n.april.substring(0, 3),
      l10n.may.substring(0, 3),
      l10n.june.substring(0, 3),
      l10n.july.substring(0, 3),
      l10n.august.substring(0, 3),
      l10n.september.substring(0, 3),
      l10n.october.substring(0, 3),
      l10n.november.substring(0, 3),
      l10n.december.substring(0, 3),
    ];

    return '${date.day} ${months[date.month - 1]}';
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

        EventCardBadges(event: event, config: config),

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
