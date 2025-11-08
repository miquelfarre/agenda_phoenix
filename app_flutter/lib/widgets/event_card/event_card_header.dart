import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/event.dart';
import '../../models/user.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_constants.dart';
import '../../core/state/app_state.dart';
import '../../services/config_service.dart';
import 'event_card_config.dart';

/// Widget for building the event card header (invitation banner, owner avatar)
class EventCardHeader extends ConsumerWidget {
  final Event event;
  final EventCardConfig config;

  const EventCardHeader({super.key, required this.event, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final List<Widget> widgets = [];

    // Show pending invitation banner if applicable
    if (config.showInvitationStatus &&
        config.invitationStatus != null &&
        config.invitationStatus!.toLowerCase() == AppConstants.statusPending) {
      widgets.add(_buildInvitationBanner(l10n));
    }

    // Show owner information if applicable
    final hasOwner =
        config.showOwner &&
        event.owner?.isPublic == true &&
        event.owner?.fullName != null;

    if (hasOwner) {
      widgets.add(_buildOwnerInfo(ref));
      widgets.add(const SizedBox(height: 6));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInvitationBanner(AppLocalizations l10n) {
    // Get inviter name from backend data if available
    String inviterText = '';
    if (event.invitedByUserId != null) {
      // Find inviter name in attendees list
      final inviter = event.attendees.firstWhere(
        (a) => a is Map && a['id'] == event.invitedByUserId,
        orElse: () => null,
      );
      final inviterName = inviter != null
          ? (inviter['full_name'] ?? inviter['name'])
          : null;
      if (inviterName != null) {
        inviterText = ' • $inviterName';
      }
    }

    return Container(
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
    );
  }

  Widget _buildOwnerInfo(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.white, 0.0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
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
      ),
    );
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
}

/// Widget for building the attendees row
class EventCardAttendeesRow extends ConsumerWidget {
  final Event event;

  const EventCardAttendeesRow({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ConfigService.instance.currentUserId;

    // Parse attendees from both User objects and Maps
    final List<Map<String, dynamic>> attendeeData = [];
    for (final a in event.attendees) {
      if (a is User) {
        attendeeData.add({
          'id': a.id,
          'full_name': a.fullName,
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
                final name =
                    (a['full_name'] as String?) ?? (a['name'] as String?) ?? '';
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
}
