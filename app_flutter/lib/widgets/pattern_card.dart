import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/recurrence_pattern.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'base_card.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class PatternCard extends StatelessWidget {
  final RecurrencePattern pattern;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool enabled;
  final bool showActions;

  const PatternCard({super.key, required this.pattern, this.onEdit, this.onDelete, this.enabled = true, this.showActions = true});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colon = l10n.colon;

    return BaseCard(
      child: Row(
        children: [
          _buildRecurrenceIcon(context),

          const SizedBox(width: AppConstants.defaultPadding),

          Expanded(child: _buildPatternInfo(context, colon)),

          if (showActions && enabled) ...[const SizedBox(width: AppConstants.smallPadding), _buildActions(context)],
        ],
      ),
    );
  }

  Widget _buildRecurrenceIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppStyles.colorWithOpacity(AppStyles.primary600, 0.1), borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)),
      child: PlatformWidgets.platformIcon(CupertinoIcons.repeat, color: AppStyles.primary600, size: 20),
    );
  }

  Widget _buildPatternInfo(BuildContext context, String colon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_getDayName(context, pattern), style: AppStyles.cardTitle.copyWith(fontWeight: FontWeight.w600)),

        const SizedBox(height: 4),

        Text(_formatTime(context, pattern.time, colon), style: AppStyles.bodyText.copyWith(color: AppStyles.grey600)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final l10n = context.l10n;

    final stableKey = pattern.id != null ? pattern.id.toString() : '${pattern.eventId}_${pattern.dayOfWeek}_${pattern.time}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          Tooltip(
            message: l10n.edit,
            child: AdaptiveButton(
              key: Key('pattern_edit_$stableKey'),
              config: const AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.small, fullWidth: false, iconPosition: IconPosition.only),
              icon: CupertinoIcons.pencil,
              onPressed: enabled ? onEdit : null,
            ),
          ),

        if (onDelete != null)
          Tooltip(
            message: l10n.delete,
            child: AdaptiveButton(
              key: Key('pattern_delete_$stableKey'),
              config: const AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.small, fullWidth: false, iconPosition: IconPosition.only),
              icon: CupertinoIcons.trash,
              onPressed: enabled ? onDelete : null,
            ),
          ),
      ],
    );
  }

  String _formatTime(BuildContext context, String time24, String colon) {
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return '${hour.toString().padLeft(2, '0')}$colon${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time24;
    }
  }

  String _getDayName(BuildContext context, RecurrencePattern pattern) {
    final l10n = context.l10n;
    final dayNames = [l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];

    if (!pattern.isValidDayOfWeek) {
      return l10n.unknownError;
    }
    return dayNames[pattern.dayOfWeek];
  }
}
