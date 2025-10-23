import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import '../models/recurrence_pattern.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'base_card.dart';
import 'pattern_card.dart';
import 'pattern_edit_dialog.dart';

class RecurrencePatternList extends StatefulWidget {
  final List<RecurrencePattern> patterns;
  final ValueChanged<List<RecurrencePattern>> onPatternsChanged;
  final bool enabled;
  final int eventId;

  const RecurrencePatternList({
    super.key,
    required this.patterns,
    required this.onPatternsChanged,
    this.enabled = true,
    required this.eventId,
  });

  @override
  State<RecurrencePatternList> createState() => _RecurrencePatternListState();
}

class _RecurrencePatternListState extends State<RecurrencePatternList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),

        const SizedBox(height: AppConstants.smallPadding),

        if (widget.patterns.isEmpty)
          _buildEmptyState(context)
        else
          ...widget.patterns.asMap().entries.map((entry) {
            final index = entry.key;
            final pattern = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
              child: PatternCard(
                pattern: pattern,
                enabled: widget.enabled,
                onEdit: widget.enabled ? () => _editPattern(index) : null,
                onDelete: widget.enabled ? () => _deletePattern(index) : null,
              ),
            );
          }),

        if (widget.enabled) ...[
          const SizedBox(height: AppConstants.smallPadding),
          _buildAddPatternButton(context),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = context.l10n;

    final isIOS = PlatformDetection.isIOS;
    final primaryColor = isIOS
        ? CupertinoColors.activeBlue.resolveFrom(context)
        : AppStyles.primary600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PlatformWidgets.platformIcon(
          isIOS ? CupertinoIcons.repeat : CupertinoIcons.repeat,
          color: primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),

        Expanded(
          child: Text(
            l10n.recurrencePatterns,
            style: AppStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.patterns.isNotEmpty) ...[
          const SizedBox(width: 8),

          Flexible(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppStyles.colorWithOpacity(primaryColor, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.patternsConfigured(widget.patterns.length),
                style: AppStyles.bodyTextSmall.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformDetection.isIOS;

    return BaseCard(
      child: Column(
        children: [
          PlatformWidgets.platformIcon(
            isIOS ? CupertinoIcons.calendar : CupertinoIcons.calendar,
            color: AppStyles.grey400,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noRecurrencePatterns,
            style: AppStyles.bodyText.copyWith(color: AppStyles.grey600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddPatternButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PlatformWidgets.platformButton(
        onPressed: _addPattern,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlatformWidgets.platformIcon(CupertinoIcons.add, size: 18),
            const SizedBox(width: 8),
            Text(context.l10n.addPattern, style: AppStyles.buttonText),
          ],
        ),
      ),
    );
  }

  void _addPattern() {
    Future<void> handleAddPattern() async {
      final pattern = await PlatformNavigation.presentModal<RecurrencePattern>(
        context,
        PatternEditDialog(eventId: widget.eventId),
      );
      if (!mounted) return;
      if (pattern != null) {
        final l10n = context.l10n;
        final updatedPatterns = List<RecurrencePattern>.from(widget.patterns)
          ..add(pattern);
        widget.onPatternsChanged(updatedPatterns);
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: l10n.onePatternAdded,
        );
      }
    }

    handleAddPattern();
  }

  void _editPattern(int index) {
    final pattern = widget.patterns[index];
    Future<void> handleEditPattern() async {
      final updatedPattern =
          await PlatformNavigation.presentModal<RecurrencePattern>(
            context,
            PatternEditDialog(pattern: pattern, eventId: widget.eventId),
          );
      if (!mounted) return;
      if (updatedPattern != null) {
        final l10n = context.l10n;
        final updatedPatterns = List<RecurrencePattern>.from(widget.patterns);
        updatedPatterns[index] = updatedPattern;
        widget.onPatternsChanged(updatedPatterns);
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: l10n.patternsConfigured(1),
        );
      }
    }

    handleEditPattern();
  }

  void _deletePattern(int index) {
    final l10n = context.l10n;
    final dialogContext = context;
    Future<void> handleDeletePattern() async {
      final confirmed = await PlatformDialogHelpers.showPlatformConfirmDialog(
        dialogContext,
        title: l10n.deletePattern,
        message: l10n.confirmDeletePattern,
        confirmText: l10n.delete,
        cancelText: l10n.cancel,
        isDestructive: true,
      );
      if (!mounted) return;
      if (confirmed == true) {
        _performDelete(index);
      }
    }

    handleDeletePattern();
  }

  void _performDelete(int index) {
    final updatedPatterns = List<RecurrencePattern>.from(widget.patterns);
    updatedPatterns.removeAt(index);
    widget.onPatternsChanged(updatedPatterns);
  }
}
