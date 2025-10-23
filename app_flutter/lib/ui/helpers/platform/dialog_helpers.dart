import 'package:flutter/cupertino.dart';
import 'platform_detection.dart';
import '../../styles/app_styles.dart';
import '../l10n/l10n_helpers.dart';

class PlatformAction<T> {
  final String? text;
  final T? value;
  final bool? isDestructive;
  const PlatformAction({this.text, this.value, this.isDestructive});
}

class PlatformDialogHelpers {
  static Future<bool?> showPlatformConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    final l10n = _l10n(context);
    if (PlatformDetection.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText ?? l10n['cancel']!),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText ?? l10n['confirm']!),
            ),
          ],
        ),
      );
    }

    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: title.isNotEmpty ? Text(title) : null,
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText ?? l10n['cancel'] ?? 'Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText ?? l10n['confirm'] ?? 'OK'),
          ),
        ],
      ),
    );
  }

  static Future<T?> showPlatformActionSheet<T>(
    BuildContext context, {
    required String title,
    String? message,
    required List<dynamic> actions,
    bool showCancel = true,
    String? cancelText,
  }) {
    final l10n = _l10n(context);
    if (PlatformDetection.isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          message: message != null ? Text(message) : null,
          actions: actions
              .map(
                (action) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context).pop(action.value),
                  isDestructiveAction: action.isDestructive ?? false,
                  child: Text(action.text ?? ''),
                ),
              )
              .toList(),
          cancelButton: showCancel
              ? CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context).pop(),
                  isDefaultAction: true,
                  child: Text(cancelText ?? l10n['cancel']!),
                )
              : null,
        ),
      );
    }

    final route = PageRouteBuilder<T>(
      opaque: false,
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Container(
            color: const Color(0x80000000),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty || message != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (message != null) ...[
                              const SizedBox(height: 8),
                              Text(message, textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    ...actions.map(
                      (action) => CupertinoButton(
                        onPressed: () => Navigator.of(ctx).pop(action.value),
                        child: Text(action.text ?? ''),
                      ),
                    ),
                    if (showCancel)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: CupertinoButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(cancelText ?? l10n['cancel']!),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionsBuilder: (ctx, animation, secondary, child) {
        final offset = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    return Navigator.of(context).push<T>(route);
  }

  static void showPlatformLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 12),
            if (message != null) ...[const SizedBox(height: 16), Text(message)],
          ],
        ),
      ),
    );
  }

  static void showGlobalPlatformMessage({
    BuildContext? context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (context != null) {
      _showOverlayNotification(
        context,
        message,
        isError: isError,
        duration: duration,
      );
      return;
    }

    final idMatch = RegExp(r'\(ID:\s*(\d+)\)').firstMatch(message);
    idMatch != null ? ' [ID:${idMatch.group(1)}]' : '';
  }

  static void showSnackBar({
    BuildContext? context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showGlobalPlatformMessage(
      context: context,
      message: message,
      isError: isError,
      duration: duration,
    );
  }

  static String cleanApiError(String error, BuildContext context) {
    if (error.contains('Exception:')) {
      error = error.replaceAll('Exception:', '').trim();
    }
    if (error.contains('Error:')) {
      error = error.replaceAll('Error:', '').trim();
    }
    if (error.contains('SocketException:')) {
      return context.l10n.connectionErrorCheckInternet;
    }
    if (error.contains('TimeoutException')) {
      return context.l10n.operationTookTooLong;
    }
    if (error.contains('FormatException')) {
      return context.l10n.dataFormatError;
    }

    return error;
  }

  static void showError(BuildContext context, String message) {
    showGlobalPlatformMessage(
      context: context,
      message: message,
      isError: true,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showGlobalPlatformMessage(
      context: context,
      message: message,
      isError: false,
    );
  }

  static void showInfo(BuildContext context, String message) {
    showGlobalPlatformMessage(
      context: context,
      message: message,
      isError: false,
    );
  }

  static void showCleanError(BuildContext context, String error) {
    showError(context, cleanApiError(error, context));
  }

  static void showNetworkError(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final errorMessage = message ?? context.l10n.noInternetConnection;

    _showDismissibleBanner(
      context,
      message: errorMessage,
      isError: true,
      actionLabel: context.l10n.retry,
      onAction: onRetry,
      duration: const Duration(seconds: 5),
    );
  }

  static void _showDismissibleBanner(
    BuildContext context, {
    required String message,
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 8,
          left: 16,
          right: 16,
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 0),
            child: GestureDetector(
              onTap: () {
                try {
                  entry.remove();
                } catch (_) {}
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isError ? AppStyles.red600 : AppStyles.grey700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: const TextStyle(color: CupertinoColors.white),
                        child: Text(message),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        color: CupertinoColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          try {
                            entry.remove();
                          } catch (_) {}
                          onAction();
                        },
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      overlay.insert(entry);
      Future.delayed(duration, () {
        try {
          entry.remove();
        } catch (_) {}
      });
    } catch (_) {}
  }

  static void _showOverlayNotification(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 8,
          left: 16,
          right: 16,
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isError ? AppStyles.red600 : AppStyles.grey700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: CupertinoColors.white),
                child: Text(message),
              ),
            ),
          ),
        );
      },
    );

    try {
      overlay.insert(entry);
      Future.delayed(duration, () {
        try {
          entry.remove();
        } catch (_) {}
      });
    } catch (_) {}
  }

  static Map<String, String> _l10n(BuildContext ctx) {
    final l10n = ctx.l10n;
    return {'cancel': l10n.cancel, 'confirm': l10n.ok};
  }
}

class DialogHelpers {
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    return PlatformDialogHelpers.showPlatformConfirmDialog(
      context,
      title: title,
      message: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    );
  }

  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? buttonText,
  }) {
    return PlatformDialogHelpers.showPlatformConfirmDialog(
      context,
      title: title,
      message: content,
      confirmText: buttonText,
    ).then((_) => null);
  }

  static Future<T?> showSelectionDialog<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T) itemDisplayName,
    String? cancelText,
  }) {
    final actions = items
        .map((item) => PlatformAction(text: itemDisplayName(item), value: item))
        .toList();
    return PlatformDialogHelpers.showPlatformActionSheet<T>(
      context,
      title: title,
      actions: actions,
      cancelText: cancelText,
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? buttonText,
  }) {
    return showInfoDialog(
      context,
      title: title,
      content: content,
      buttonText: buttonText,
    );
  }
}

mixin DialogHelpersMixin<T extends StatefulWidget> on State<T> {
  Future<bool?> showConfirmation({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    return DialogHelpers.showConfirmationDialog(
      context,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    );
  }

  Future<void> showInfo({
    required String title,
    required String content,
    String? buttonText,
  }) {
    return DialogHelpers.showInfoDialog(
      context,
      title: title,
      content: content,
      buttonText: buttonText,
    );
  }

  Future<U?> showSelection<U>({
    required String title,
    required List<U> items,
    required String Function(U) itemDisplayName,
    String? cancelText,
  }) {
    return DialogHelpers.showSelectionDialog<U>(
      context,
      title: title,
      items: items,
      itemDisplayName: itemDisplayName,
      cancelText: cancelText,
    );
  }

  Future<void> showError({
    required String title,
    required String content,
    String? buttonText,
  }) {
    return DialogHelpers.showErrorDialog(
      context,
      title: title,
      content: content,
      buttonText: buttonText,
    );
  }
}
