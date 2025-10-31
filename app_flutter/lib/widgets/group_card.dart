import 'package:flutter/material.dart';
import '../models/group.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final int? partiallyInvitedCount;
  final VoidCallback? onTap;
  final bool isSelected;

  const GroupCard({super.key, required this.group, this.partiallyInvitedCount, this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPartiallyInvited = partiallyInvitedCount != null && partiallyInvitedCount! > 0;

    Widget card = Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(Icons.group, color: theme.colorScheme.onSecondaryContainer, size: 28),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group.description.isNotEmpty)
                      Text(
                        group.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(group.memberCountText, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),

              if (isSelected) Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 28),
            ],
          ),
        ),
      ),
    );

    if (isPartiallyInvited) {
      final totalMembers = group.members.length;
      return Badge(
        label: Text(
          context.l10n.partiallyInvited(partiallyInvitedCount!, totalMembers),
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.secondaryContainer,
        textColor: theme.colorScheme.onSecondaryContainer,
        offset: const Offset(12, -12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: card,
      );
    }

    return card;
  }
}
