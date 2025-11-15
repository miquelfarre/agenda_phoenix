import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../l10n/app_localizations.dart';
import '../models/domain/calendar.dart';
import '../utils/calendar_permissions.dart';

typedef CalendarTapCallback = void Function(Calendar calendar);
typedef CalendarActionCallback = Future<void> Function(Calendar calendar);

class CalendarCard extends StatelessWidget {
  final Calendar calendar;
  final CalendarTapCallback onTap;
  final CalendarActionCallback? onDelete;
  final bool showActions;

  const CalendarCard({
    super.key,
    required this.calendar,
    required this.onTap,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOwner = CalendarPermissions.isOwner(calendar);
    final isSubscribed = calendar.shareHash != null;

    return GestureDetector(
      onTap: () => onTap(calendar),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: calendar.isPublic
                    ? AppStyles.green600.withValues(alpha: 0.1)
                    : AppStyles.blue600.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                calendar.isPublic ? CupertinoIcons.globe : CupertinoIcons.lock,
                color: calendar.isPublic ? AppStyles.green600 : AppStyles.blue600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar name
                  Text(
                    calendar.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppStyles.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description (if exists)
                  if (calendar.description != null && calendar.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      calendar.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppStyles.grey600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getRoleBadgeColor(isOwner, isSubscribed),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getRoleText(l10n, isOwner, isSubscribed),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getRoleTextColor(isOwner, isSubscribed),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            if (showActions && onDelete != null) ...[
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                onPressed: () => onDelete!(calendar),
                child: Icon(
                  CupertinoIcons.trash,
                  color: AppStyles.red600,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleBadgeColor(bool isOwner, bool isSubscribed) {
    if (isOwner) {
      return AppStyles.primary600.withValues(alpha: 0.1);
    } else if (isSubscribed) {
      return AppStyles.purple600.withValues(alpha: 0.1);
    } else {
      return AppStyles.grey600.withValues(alpha: 0.1);
    }
  }

  Color _getRoleTextColor(bool isOwner, bool isSubscribed) {
    if (isOwner) {
      return AppStyles.primary600;
    } else if (isSubscribed) {
      return AppStyles.purple600;
    } else {
      return AppStyles.grey700;
    }
  }

  String _getRoleText(AppLocalizations l10n, bool isOwner, bool isSubscribed) {
    if (isOwner) {
      return l10n.owner;
    } else if (isSubscribed) {
      return l10n.subscriber;
    } else {
      return l10n.member;
    }
  }
}
