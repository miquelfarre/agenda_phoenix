import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class RecurrencePatternsHorizontalList extends StatelessWidget {
  final List<Map<String, dynamic>> patterns;
  final VoidCallback onAddPattern;
  final Function(int index) onRemovePattern;

  const RecurrencePatternsHorizontalList({
    super.key,
    required this.patterns,
    required this.onAddPattern,
    required this.onRemovePattern,
  });

  String _formatPatternDisplay(BuildContext context, Map<String, dynamic> pattern) {
    final l10n = context.l10n;
    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    final dayOfWeek = pattern['dayOfWeek'] as int? ?? 0;
    final time = pattern['time'] as String? ?? '00:00:00';
    final isValidDayOfWeek = dayOfWeek >= 0 && dayOfWeek < 7;

    final dayName = isValidDayOfWeek ? dayNames[dayOfWeek] : l10n.unknownError;

    // Format time as HH:MM (remove seconds)
    final timeParts = time.split(':');
    final timeFormatted = timeParts.length >= 2 ? '${timeParts[0]}:${timeParts[1]}' : time;

    return '$dayName\n$timeFormatted';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(CupertinoIcons.repeat, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.recurrencePatterns,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: patterns.length + 1, // +1 for the add button
            itemBuilder: (context, index) {
              // Add button at the end
              if (index == patterns.length) {
                return GestureDetector(
                  onTap: onAddPattern,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppStyles.colorWithOpacity(AppStyles.primaryColor, 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppStyles.primaryColor,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.add_circled,
                          color: AppStyles.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patterns.isEmpty ? l10n.addFirstPattern : l10n.add,
                          style: const TextStyle(
                            color: AppStyles.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Pattern cards
              final pattern = patterns[index];
              return Container(
                width: 110,
                margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey
                          .resolveFrom(context)
                          .withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        _formatPatternDisplay(context, pattern),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Delete button in top-right corner
                    Positioned(
                      top: -4,
                      right: -4,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () => onRemovePattern(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppStyles.colorWithOpacity(
                              AppStyles.errorColor,
                              0.9,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Empty state when no patterns
        if (patterns.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Text(
              l10n.noRecurrencePatterns,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}
