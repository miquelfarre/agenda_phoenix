import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/event.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'confirmation_action_widget.dart';
import '../l10n/app_localizations.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class EventActions extends StatelessWidget {
  final Event event;
  final Function(Event, {bool shouldNavigate})? onDelete;
  final Function(Event)? onEdit;
  final Function(Event)? onInvite;
  final Function(Event, {bool shouldNavigate})? onDeleteSeries;
  final Function(Event)? onEditSeries;
  final bool isCompact;
  final bool navigateAfterDelete;

  const EventActions({super.key, required this.event, this.onDelete, this.onEdit, this.onInvite, this.onDeleteSeries, this.onEditSeries, this.isCompact = false, this.navigateAfterDelete = false});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isCompact) {
      return _buildCompactActions(context, l10n);
    } else {
      return _buildFullActions(context, l10n);
    }
  }

  Widget _buildCompactActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onInvite != null) ...[_buildCompactActionButton(icon: CupertinoIcons.person_add, color: AppStyles.blue600, onTap: () => onInvite!(event), tooltip: l10n.invite), const SizedBox(width: 8)],
        if (onEdit != null) ...[event.isRecurringEvent ? _buildRecurringEditAction(context, l10n) : _buildRegularEditAction(context), const SizedBox(width: 8)],
        if (onDelete != null) event.isRecurringEvent ? _buildRecurringDeleteAction(context, l10n) : _buildRegularDeleteAction(context, l10n),
      ],
    );
  }

  Widget _buildFullActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onInvite != null) _buildActionButton(icon: CupertinoIcons.person_add, label: l10n.invite, color: AppStyles.blue600, onTap: () => onInvite!(event)),
        if (onEdit != null) event.isRecurringEvent ? _buildRecurringEditFullAction(context) : _buildRegularEditFullAction(context),
        if (onDelete != null) event.isRecurringEvent ? _buildRecurringDeleteFullAction(context, l10n) : _buildRegularDeleteFullAction(context, l10n),
      ],
    );
  }

  Widget _buildCompactActionButton({required IconData icon, required Color color, required VoidCallback onTap, required String tooltip}) {
    return GestureDetector(
      key: Key('compact_action_button_${icon.codePoint}'),
      onTap: onTap,
      child: Semantics(
        label: tooltip,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppStyles.colorWithOpacity(color, 0.1), shape: BoxShape.circle),
          child: PlatformWidgets.platformIcon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    final isIOS = PlatformDetection.isIOS;
    if (isIOS) {
      return GestureDetector(
        key: Key('action_button_${icon.codePoint}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformWidgets.platformIcon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: AppStyles.bodyTextSmall.copyWith(color: color)),
            ],
          ),
        ),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: label,
            child: AdaptiveButton(
              key: Key('event_action_${label.toLowerCase().replaceAll(' ', '_')}'),
              config: const AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only),
              icon: icon,
              onPressed: onTap,
            ),
          ),
          Text(
            label,
            style: AppStyles.bodyTextSmall.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }
  }

  Widget _buildRecurringDeleteAction(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showRecurringDeleteOptions(context, l10n),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppStyles.colorWithOpacity(AppStyles.red600, 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.colorWithOpacity(AppStyles.red600, 0.3), width: 1),
        ),
        child: PlatformWidgets.platformIcon(CupertinoIcons.delete, size: 16, color: AppStyles.red600),
      ),
    );
  }

  Widget _buildRegularDeleteAction(BuildContext context, AppLocalizations l10n) {
    return ConfirmationActionWidget(
      dialogTitle: l10n.confirmDelete,
      dialogMessage: l10n.confirmDeleteEvent(event.title),
      actionText: l10n.delete,
      isDestructive: true,
      onAction: () async {
        onDelete!(event, shouldNavigate: navigateAfterDelete);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppStyles.colorWithOpacity(AppStyles.red600, 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.colorWithOpacity(AppStyles.red600, 0.3), width: 1),
        ),
        child: PlatformWidgets.platformIcon(CupertinoIcons.delete, size: 16, color: AppStyles.red600),
      ),
    );
  }

  Widget _buildRecurringDeleteFullAction(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showRecurringDeleteOptions(context, l10n),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformWidgets.platformIcon(CupertinoIcons.delete, color: AppStyles.red600, size: 24),
            const SizedBox(height: 4),
            Text(
              l10n.delete,
              style: AppStyles.bodyTextSmall.copyWith(color: AppStyles.red600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularDeleteFullAction(BuildContext context, AppLocalizations l10n) {
    return ConfirmationActionWidget(
      dialogTitle: l10n.confirmDelete,
      dialogMessage: l10n.confirmDeleteEvent(event.title),
      actionText: l10n.delete,
      isDestructive: true,
      onAction: () async {
        onDelete!(event, shouldNavigate: navigateAfterDelete);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformWidgets.platformIcon(CupertinoIcons.delete, color: AppStyles.red600, size: 24),
          const SizedBox(height: 4),
          Text(
            l10n.delete,
            style: AppStyles.bodyTextSmall.copyWith(color: AppStyles.red600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showRecurringDeleteOptions(BuildContext context, AppLocalizations l10n) {
    final safeL10n = l10n;
    final safeTitle = safeL10n.deleteRecurringEvent;
    final safeMessage = safeL10n.deleteRecurringEventQuestion(event.title);
    final safeDeleteOnlyThisInstance = safeL10n.deleteOnlyThisInstance;
    final safeDeleteEntireSeries = safeL10n.deleteEntireSeries;
    final safeCancel = safeL10n.cancel;
    final safeUnexpectedError = safeL10n.unexpectedError;

    PlatformDialogHelpers.showPlatformActionSheet<String>(
          context,
          title: safeTitle,
          message: safeMessage,
          actions: [
            PlatformAction(text: safeDeleteOnlyThisInstance, value: AppConstants.actionChoiceThis),
            if (onDeleteSeries != null) PlatformAction(text: safeDeleteEntireSeries, value: AppConstants.actionChoiceSeries, isDestructive: true),
          ],
          cancelText: safeCancel,
        )
        .then((choice) {
          try {
            final appContext = context;
            if (appContext is Element && !appContext.mounted) return;

            if (choice == AppConstants.actionChoiceThis) {
              if (!appContext.mounted) return;
              PlatformDialogHelpers.showPlatformConfirmDialog(appContext, title: safeL10n.confirmDelete, message: safeL10n.confirmDeleteInstance(event.title), confirmText: safeL10n.deleteInstance, cancelText: safeL10n.cancel, isDestructive: true).then((confirmed) {
                if (confirmed == true && onDelete != null) {
                  try {
                    final res = onDelete!(event, shouldNavigate: navigateAfterDelete);
                    if (res is Future) {
                      res.catchError((e) {
                        if (appContext.mounted) {
                          PlatformDialogHelpers.showSnackBar(context: appContext, message: '$safeUnexpectedError $e', isError: true);
                        }
                      });
                    }
                  } catch (e) {
                    if (appContext.mounted) {
                      PlatformDialogHelpers.showSnackBar(context: appContext, message: '$safeUnexpectedError $e', isError: true);
                    }
                  }
                }
              });
            } else if (choice == AppConstants.actionChoiceSeries) {
              if (!appContext.mounted) return;
              PlatformDialogHelpers.showPlatformConfirmDialog(appContext, title: safeL10n.confirmDeleteSeries, message: safeL10n.confirmDeleteSeriesMessage(event.title), confirmText: safeL10n.deleteCompleteSeries, cancelText: safeL10n.cancel, isDestructive: true).then((confirmed) {
                if (confirmed == true && onDeleteSeries != null) {
                  try {
                    final res = onDeleteSeries!(event, shouldNavigate: navigateAfterDelete);
                    if (res is Future) {
                      res.catchError((e) {
                        if (appContext.mounted) {
                          PlatformDialogHelpers.showSnackBar(context: appContext, message: '$safeUnexpectedError $e', isError: true);
                        }
                      });
                    }
                  } catch (e) {
                    if (appContext.mounted) {
                      PlatformDialogHelpers.showSnackBar(context: appContext, message: '$safeUnexpectedError $e', isError: true);
                    }
                  }
                }
              });
            }
          } catch (e) {
            PlatformDialogHelpers.showSnackBar(message: '$safeUnexpectedError $e', isError: true);
          }
        })
        .catchError((e) {
          if (context.mounted) {
            PlatformDialogHelpers.showSnackBar(context: context, message: '$safeUnexpectedError $e', isError: true);
          }
        });
  }

  Widget _buildRecurringEditAction(BuildContext context, dynamic l10n) {
    return GestureDetector(
      onTap: () => _showRecurringEditOptions(context, l10n),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppStyles.colorWithOpacity(AppStyles.green600, 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.colorWithOpacity(AppStyles.green600, 0.3), width: 1),
        ),
        child: PlatformWidgets.platformIcon(CupertinoIcons.pencil, size: 16, color: AppStyles.green600),
      ),
    );
  }

  Widget _buildRegularEditAction(BuildContext context) {
    return GestureDetector(
      onTap: () => onEdit!(event),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppStyles.colorWithOpacity(AppStyles.green600, 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.colorWithOpacity(AppStyles.green600, 0.3), width: 1),
        ),
        child: PlatformWidgets.platformIcon(CupertinoIcons.pencil, size: 16, color: AppStyles.green600),
      ),
    );
  }

  Widget _buildRecurringEditFullAction(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => _showRecurringEditOptions(context, l10n),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformWidgets.platformIcon(CupertinoIcons.pencil, color: AppStyles.green600, size: 24),
            const SizedBox(height: 4),
            Text(
              l10n.edit,
              style: AppStyles.bodyTextSmall.copyWith(color: AppStyles.green600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularEditFullAction(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => onEdit!(event),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformWidgets.platformIcon(CupertinoIcons.pencil, color: AppStyles.green600, size: 24),
            const SizedBox(height: 4),
            Text(
              l10n.edit,
              style: AppStyles.bodyTextSmall.copyWith(color: AppStyles.green600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecurringEditOptions(BuildContext context, dynamic l10n) {
    final safeL10n = l10n;
    final safeTitle = safeL10n.editRecurringEvent;
    final safeMessage = safeL10n.editRecurringEventQuestion(event.title);
    final safeEditThis = safeL10n.editOnlyThisInstance;
    final safeEditSeries = safeL10n.editEntireSeries;
    final safeCancel = safeL10n.cancel;

    PlatformDialogHelpers.showPlatformActionSheet<String>(
          context,
          title: safeTitle,
          message: safeMessage,
          actions: [
            PlatformAction(text: safeEditThis, value: AppConstants.actionChoiceThis),
            if (onEditSeries != null) PlatformAction(text: safeEditSeries, value: AppConstants.actionChoiceSeries),
          ],
          cancelText: safeCancel,
        )
        .then((choice) {
          if (choice == AppConstants.actionChoiceThis) {
            try {
              onEdit?.call(event);
            } catch (e) {
              PlatformDialogHelpers.showSnackBar(message: '${safeL10n.unexpectedError} $e', isError: true);
            }
          } else if (choice == AppConstants.actionChoiceSeries) {
            try {
              onEditSeries?.call(event);
            } catch (e) {
              PlatformDialogHelpers.showSnackBar(message: '${safeL10n.unexpectedError} $e', isError: true);
            }
          }
        })
        .catchError((e) {
          if (context.mounted) {
            PlatformDialogHelpers.showSnackBar(context: context, message: '${l10n.unexpectedError} $e', isError: true);
          }
        });
  }
}
