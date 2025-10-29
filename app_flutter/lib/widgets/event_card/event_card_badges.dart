import 'package:flutter/cupertino.dart';
import '../../models/event.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../../l10n/app_localizations.dart';
import 'event_card_config.dart';

/// Widget for building event badges (NEW, Calendar, Birthday, Recurring)
class EventCardBadges extends StatelessWidget {
  final Event event;
  final EventCardConfig config;

  const EventCardBadges({
    super.key,
    required this.event,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> badges = [];

    // Show "NEW" badge if enabled and event is new
    if (config.showNewBadge && event.isNewInteraction) {
      badges.add(_buildNewBadge());
    }

    // Calendar badge
    if (event.calendarId != null && event.calendarName != null) {
      badges.add(_buildCalendarBadge());
    }

    // Birthday badge
    if (event.isBirthday) {
      badges.add(_buildBirthdayBadge(context));
    }

    // Recurring event badge
    if (event.isRecurring) {
      badges.add(_buildRecurringBadge(context));
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 4, runSpacing: 4, children: badges),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.red600, 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.red600, 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformWidgets.platformIcon(
            CupertinoIcons.sparkles,
            size: 11,
            color: AppStyles.red600,
          ),
          const SizedBox(width: 3),
          Text(
            'NEW',
            style: AppStyles.bodyText.copyWith(
              fontSize: 11,
              color: AppStyles.red600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBadge() {
    return Container(
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
    );
  }

  Widget _buildBirthdayBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
            l10n.isBirthday,
            style: AppStyles.bodyText.copyWith(
              fontSize: 11,
              color: AppStyles.orange600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
            l10n.recurringEvent,
            style: AppStyles.bodyText.copyWith(
              fontSize: 11,
              color: AppStyles.green600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
}
