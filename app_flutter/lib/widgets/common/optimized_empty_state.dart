import 'package:flutter/cupertino.dart';
import '../../ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class OptimizedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final double iconSize;
  final Color? iconColor;

  const OptimizedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.iconSize = 64.0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppStyles.largePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: iconColor ?? AppStyles.grey400),
            const SizedBox(height: AppStyles.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppStyles.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: AppStyles.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppStyles.spacingXL),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class OptimizedLoadingState extends StatelessWidget {
  final String? message;

  const OptimizedLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppStyles.spacingM),
            Text(
              message!,
              style: const TextStyle(color: AppStyles.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class OptimizedErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const OptimizedErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedEmptyState(
      icon: CupertinoIcons.exclamationmark_circle,
      title: title,
      subtitle: message,
      iconColor: AppStyles.errorColor,
      action: onRetry != null
          ? CupertinoButton.filled(
              key: const Key('empty_state_retry_button'),
              onPressed: onRetry,
              padding: AppStyles.buttonPadding,
              borderRadius: AppStyles.smallRadius,
              child: Text(context.l10n.retry),
            )
          : null,
    );
  }
}
