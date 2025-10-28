import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPermissionDialog extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const ContactsPermissionDialog({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<ContactsPermissionDialog> createState() =>
      _ContactsPermissionDialogState();
}

class _ContactsPermissionDialogState extends State<ContactsPermissionDialog> {
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final onGranted = widget.onPermissionGranted;

      final hasPermission = await Permission.contacts.request().isGranted;

      if (hasPermission) {
        onGranted?.call();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          _showSettingsDialog();
        }
      }
    } catch (e) {
      widget.onPermissionDenied?.call();
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  void _showSettingsDialog() {
    final l10n = context.l10n;

    final safeContext = context;
    final safeL10n = l10n;

    PlatformDialogHelpers.showPlatformConfirmDialog(
          safeContext,
          title: safeL10n.permissionsNeeded,
          message: safeL10n.contactsPermissionSettingsMessage,
          confirmText: safeL10n.goToSettings,
          cancelText: safeL10n.notNow,
        )
        .then((confirmed) async {
          if (confirmed == true) {
            try {
              await openAppSettings();
            } catch (e) {
              // Ignore errors
            }

            if (!mounted || !safeContext.mounted) return;
            Navigator.of(safeContext).pop(false);
            widget.onPermissionDenied?.call();
          } else {
            if (!mounted || !safeContext.mounted) return;
            Navigator.of(safeContext).pop();
            Navigator.of(safeContext).pop(false);
            widget.onPermissionDenied?.call();
          }
        })
        .catchError((e) {
          if (!mounted || !safeContext.mounted) return;
          Navigator.of(safeContext).pop();
          Navigator.of(safeContext).pop(false);
          widget.onPermissionDenied?.call();
        });
  }

  void _skipPermission() {
    widget.onPermissionDenied?.call();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return _buildCupertinoDialog();
  }

  Widget _buildCupertinoDialog() {
    final l10n = context.l10n;

    return CupertinoAlertDialog(
      title: Column(
        children: [
          PlatformWidgets.platformIcon(
            CupertinoIcons.person_2,
            color: PlatformDetection.isIOS
                ? CupertinoColors.activeBlue.resolveFrom(context)
                : AppStyles.primary600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(l10n.findYourFriends),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: 8),
          Text(l10n.contactsPermissionMessage),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppStyles.colorWithOpacity(
                PlatformDetection.isIOS
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : AppStyles.primary600,
                0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PlatformWidgets.platformIcon(
                      CupertinoIcons.check_mark_circled,
                      color: CupertinoColors.systemGreen.resolveFrom(context),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.yourContactsStayPrivate,
                        style: AppStyles.cardSubtitle.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    PlatformWidgets.platformIcon(
                      CupertinoIcons.check_mark_circled,
                      color: CupertinoColors.systemGreen.resolveFrom(context),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.onlyShowMutualFriends,
                        style: AppStyles.cardSubtitle.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          key: const Key('contacts_permission_not_now_button'),
          onPressed: _isRequesting ? null : _skipPermission,
          child: Text(l10n.notNow),
        ),
        CupertinoDialogAction(
          key: const Key('contacts_permission_allow_button'),
          onPressed: _isRequesting ? null : _requestPermission,
          isDefaultAction: true,
          child: _isRequesting
              ? PlatformWidgets.platformLoadingIndicator(radius: 8)
              : Text(l10n.allowAccess),
        ),
      ],
    );
  }
}
