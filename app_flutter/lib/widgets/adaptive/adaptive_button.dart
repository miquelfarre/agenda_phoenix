import 'package:flutter/material.dart';
import 'platform_theme.dart';

class AdaptiveButton extends StatelessWidget {
  final AdaptiveButtonConfig config;
  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  final bool isLoading;
  final void Function(bool loading)? onLoadingChanged;
  final bool enabled;

  const AdaptiveButton({
    super.key,
    required this.config,
    this.onPressed,
    this.text,
    this.icon,
    this.isLoading = false,
    this.onLoadingChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PlatformTheme.adaptive(context);

    if (isLoading) {
      return _buildLoadingButton(theme);
    }

    switch (config.variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton(theme);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(theme);
      case ButtonVariant.text:
        return _buildTextButton(theme);
      case ButtonVariant.icon:
        return _buildIconButton(theme);
      case ButtonVariant.fab:
        return _buildFAB(theme);
    }
  }

  Widget _buildPrimaryButton(PlatformTheme theme) {
    return SizedBox(
      width: config.fullWidth ? double.infinity : null,
      height: _getButtonHeight(theme),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: config.backgroundColor ?? theme.primaryColor,
          foregroundColor: config.textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              config.borderRadius ?? theme.defaultBorderRadius.topLeft.x,
            ),
          ),
          elevation: theme.isIOS ? 0 : 2,
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildSecondaryButton(PlatformTheme theme) {
    return SizedBox(
      width: config.fullWidth ? double.infinity : null,
      height: _getButtonHeight(theme),
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: config.textColor ?? theme.primaryColor,
          side: BorderSide(color: theme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              config.borderRadius ?? theme.defaultBorderRadius.topLeft.x,
            ),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildTextButton(PlatformTheme theme) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: config.textColor ?? theme.primaryColor,
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildIconButton(PlatformTheme theme) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon ?? Icons.star,
        color: config.textColor ?? theme.primaryColor,
      ),
      iconSize: _getIconSize(),
    );
  }

  Widget _buildFAB(PlatformTheme theme) {
    return FloatingActionButton(
      onPressed: enabled ? onPressed : null,
      backgroundColor: config.backgroundColor ?? theme.primaryColor,
      child: Icon(icon ?? Icons.add, color: config.textColor ?? Colors.white),
    );
  }

  Widget _buildLoadingButton(PlatformTheme theme) {
    return SizedBox(
      width: config.fullWidth ? double.infinity : null,
      height: _getButtonHeight(theme),
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: (config.backgroundColor ?? theme.primaryColor)
              .withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              config.borderRadius ?? theme.defaultBorderRadius.topLeft.x,
            ),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (icon != null && text != null) {
      return _buildIconTextContent();
    } else if (icon != null) {
      return Icon(icon, size: _getIconSize());
    } else {
      return Text(text ?? '');
    }
  }

  Widget _buildIconTextContent() {
    final iconWidget = Icon(icon, size: _getIconSize());
    final textWidget = Text(text ?? '');

    switch (config.iconPosition) {
      case IconPosition.leading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [iconWidget, const SizedBox(width: 8), textWidget],
        );
      case IconPosition.trailing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [textWidget, const SizedBox(width: 8), iconWidget],
        );
      case IconPosition.only:
        return iconWidget;
    }
  }

  double _getButtonHeight(PlatformTheme theme) {
    switch (config.size) {
      case ButtonSize.small:
        return theme.buttonHeight * 0.8;
      case ButtonSize.medium:
        return theme.buttonHeight;
      case ButtonSize.large:
        return theme.buttonHeight * 1.2;
    }
  }

  double _getIconSize() {
    switch (config.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

class AdaptiveButtonConfig {
  final ButtonVariant variant;
  final ButtonSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool fullWidth;
  final IconPosition iconPosition;
  final double? borderRadius;

  const AdaptiveButtonConfig({
    required this.variant,
    required this.size,
    this.backgroundColor,
    this.textColor,
    required this.fullWidth,
    required this.iconPosition,
    this.borderRadius,
  });

  factory AdaptiveButtonConfig.primary() => const AdaptiveButtonConfig(
    variant: ButtonVariant.primary,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.leading,
  );

  factory AdaptiveButtonConfig.secondary() => const AdaptiveButtonConfig(
    variant: ButtonVariant.secondary,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.leading,
  );

  factory AdaptiveButtonConfig.text() => const AdaptiveButtonConfig(
    variant: ButtonVariant.text,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.leading,
  );

  factory AdaptiveButtonConfig.icon() => const AdaptiveButtonConfig(
    variant: ButtonVariant.icon,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.only,
  );

  factory AdaptiveButtonConfig.fab() => const AdaptiveButtonConfig(
    variant: ButtonVariant.fab,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.only,
  );
}

enum ButtonVariant { primary, secondary, text, icon, fab }

enum ButtonSize { small, medium, large }

enum IconPosition { leading, trailing, only }
