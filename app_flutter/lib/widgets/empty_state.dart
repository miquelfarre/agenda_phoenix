import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class EmptyState extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final String? imagePath;
  final IconData? icon;
  final double? imageSize;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    this.message,
    this.subtitle,
    this.imagePath,
    this.icon,
    this.imageSize = 120,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null) ...[
              Image.asset(
                imagePath!,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return PlatformWidgets.platformIcon(
                    icon ?? CupertinoIcons.square_stack,
                    size: 64,
                    color: AppStyles.grey400,
                  );
                },
              ),
              const SizedBox(height: 24),
            ] else if (icon != null) ...[
              PlatformWidgets.platformIcon(
                icon,
                size: 64,
                color: AppStyles.grey400,
              ),
              const SizedBox(height: 24),
            ],
            Text(
              message ?? context.l10n.noData,
              style: AppStyles.bodyText.copyWith(
                color: AppStyles.grey600,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppStyles.bodyText.copyWith(
                  color: AppStyles.grey500,
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
