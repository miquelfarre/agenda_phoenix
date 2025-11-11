import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

enum CreateOptionType {
  recurring,
  birthday,
  calendar,
}

class CreateOptionsSelector extends StatelessWidget {
  final Function(CreateOptionType) onOptionSelected;

  const CreateOptionsSelector({
    super.key,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOption(
          context: context,
          label: l10n.recurring,
          type: CreateOptionType.recurring,
        ),
        _buildOption(
          context: context,
          label: l10n.birthday,
          type: CreateOptionType.birthday,
        ),
        _buildOption(
          context: context,
          label: l10n.calendar,
          type: CreateOptionType.calendar,
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required CreateOptionType type,
  }) {
    final l10n = context.l10n;

    // Obtener icono y descripción según el tipo
    IconData icon;
    String description;

    switch (type) {
      case CreateOptionType.recurring:
        icon = CupertinoIcons.repeat;
        description = l10n.recurringEventDescription;
        break;
      case CreateOptionType.birthday:
        icon = CupertinoIcons.gift;
        description = l10n.birthdayEventDescription;
        break;
      case CreateOptionType.calendar:
        icon = CupertinoIcons.calendar_badge_plus;
        description = l10n.calendarDescription;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => onOptionSelected(type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppStyles.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
