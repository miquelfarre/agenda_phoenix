import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../l10n/app_localizations.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';

class SubscriptionCard extends ConsumerWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Widget? customAvatar;
  final String? customTitle;
  final String? customSubtitle;

  const SubscriptionCard({super.key, required this.user, required this.onTap, this.onDelete, this.customAvatar, this.customTitle, this.customSubtitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppStyles.colorWithOpacity(AppStyles.white, 1.0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppStyles.colorWithOpacity(AppStyles.black87, 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customTitle ?? user.displayName,
                    style: AppStyles.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customSubtitle ?? _buildDefaultSubtitle(l10n),
                    style: AppStyles.cardSubtitle.copyWith(fontSize: 13, color: AppStyles.grey600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Actions
            _buildTrailingActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (customAvatar != null) {
      return customAvatar!;
    }

    // Default avatar with initials
    String initials = '?';
    if (user.fullName?.isNotEmpty == true) {
      final nameParts = user.fullName!.trim().split(' ');
      if (nameParts.length >= 2) {
        initials = nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else {
        initials = nameParts[0][0].toUpperCase();
      }
    } else if (user.instagramName?.isNotEmpty == true) {
      initials = user.instagramName![0].toUpperCase();
    } else if (user.id > 0) {
      initials = user.id.toString()[0];
    }

    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.3), width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppStyles.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: AppStyles.blue600, letterSpacing: 0.5),
        ),
      ),
    );
  }

  String _buildDefaultSubtitle(AppLocalizations l10n) {
    if (user.newEventsCount != null && user.totalEventsCount != null && user.subscribersCount != null) {
      final newEvents = user.newEventsCount!;
      final totalEvents = user.totalEventsCount!;
      final subscribers = user.subscribersCount!;

      if (newEvents > 0) {
        return '$newEvents ${newEvents == 1 ? l10n.newEvent : l10n.newEvents} · $totalEvents total · $subscribers ${subscribers == 1 ? l10n.subscriber : l10n.subscribers}';
      } else {
        return '$totalEvents ${totalEvents == 1 ? l10n.event : l10n.events} · $subscribers ${subscribers == 1 ? l10n.subscriber : l10n.subscribers}';
      }
    }
    return l10n.publicUser;
  }

  Widget _buildTrailingActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onDelete != null)
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppStyles.colorWithOpacity(AppStyles.red600, 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppStyles.colorWithOpacity(AppStyles.red600, 0.25), width: 1),
              ),
              child: Center(child: PlatformWidgets.platformIcon(CupertinoIcons.delete, color: AppStyles.red600, size: 16)),
            ),
          ),
        if (onDelete == null) PlatformWidgets.platformIcon(CupertinoIcons.chevron_right, color: AppStyles.grey400, size: 20),
      ],
    );
  }
}
