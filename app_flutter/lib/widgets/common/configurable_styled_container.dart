import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import '../styled_container.dart';

class ConfigurableStyledContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ConfigurableContainerStyle style;
  final VoidCallback? onTap;

  const ConfigurableStyledContainer({super.key, required this.child, this.padding, this.style = ConfigurableContainerStyle.card, this.onTap});

  const ConfigurableStyledContainer.header({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap}) : style = ConfigurableContainerStyle.header;

  const ConfigurableStyledContainer.card({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap}) : style = ConfigurableContainerStyle.card;

  const ConfigurableStyledContainer.info({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap}) : style = ConfigurableContainerStyle.info;

  @override
  Widget build(BuildContext context) {
    Widget container;

    switch (style) {
      case ConfigurableContainerStyle.header:
        container = _buildHeaderContainer();
        break;
      case ConfigurableContainerStyle.card:
        container = _buildCardContainer();
        break;
      case ConfigurableContainerStyle.info:
        container = _buildInfoContainer();
        break;
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }

  Widget _buildHeaderContainer() {
    return StyledContainer(
      padding: (padding ?? const EdgeInsets.all(20)) as EdgeInsets,
      borderRadius: AppStyles.largeRadius,
      color: AppStyles.transparent,
      boxShadow: [BoxShadow(color: AppStyles.primary200, blurRadius: 12, offset: const Offset(0, 4))],
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppStyles.primary500, AppStyles.primary600], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: AppStyles.largeRadius,
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }

  Widget _buildCardContainer() {
    return StyledContainer(
      padding: (padding ?? const EdgeInsets.all(20)) as EdgeInsets,
      borderRadius: AppStyles.largeRadius,
      color: AppStyles.cardBackgroundColor,
      border: Border.all(color: AppStyles.grey300),
      child: child,
    );
  }

  Widget _buildInfoContainer() {
    return StyledContainer(
      padding: (padding ?? const EdgeInsets.all(20)) as EdgeInsets,
      borderRadius: AppStyles.largeRadius,
      color: AppStyles.primary50,
      border: Border.all(color: AppStyles.primary200),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final Color? textColor;

  const SectionHeader({super.key, required this.icon, required this.title, required this.subtitle, this.iconColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppStyles.white;
    final effectiveTextColor = textColor ?? AppStyles.white;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppStyles.colorWithOpacity(AppStyles.white, 0.2), borderRadius: AppStyles.cardRadius),
          child: PlatformWidgets.platformIcon(icon, color: effectiveIconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.headlineSmall.copyWith(color: effectiveTextColor)),
              const SizedBox(height: 4),
              Text(subtitle, style: AppStyles.bodyTextSmall.copyWith(color: AppStyles.colorWithOpacity(effectiveTextColor, 0.9))),
            ],
          ),
        ),
      ],
    );
  }
}

enum ConfigurableContainerStyle { header, card, info }
