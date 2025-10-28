import 'package:flutter/widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';

class ConfirmationActionWidget extends StatefulWidget {
  final String dialogTitle;

  final String dialogMessage;

  final String actionText;

  final Widget child;

  final Future<void> Function() onAction;

  final bool isDestructive;

  const ConfirmationActionWidget({super.key, required this.dialogTitle, required this.dialogMessage, required this.actionText, required this.child, required this.onAction, this.isDestructive = false});

  @override
  State<ConfirmationActionWidget> createState() => _ConfirmationActionWidgetState();
}

class _ConfirmationActionWidgetState extends State<ConfirmationActionWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _showConfirmationDialog, child: widget.child);
  }

  Future<void> _showConfirmationDialog() async {
    final callback = widget.onAction;
    final confirmed = await _showDialog();
    if (confirmed) {
      if (!mounted) return;
      await callback();
    }
  }

  Future<bool> _showDialog() async {
    return await PlatformDialogHelpers.showPlatformConfirmDialog(context, title: widget.dialogTitle, message: widget.dialogMessage, confirmText: widget.actionText, isDestructive: widget.isDestructive) ?? false;
  }
}
