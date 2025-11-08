import 'package:flutter/widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'styled_container.dart';

/// A card widget with optional tap handling and adaptive margins
///
/// Uses [StyledContainer] internally for consistent styling.
class BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformWidgets.isIOS;

    final cardMargin =
        margin ??
        EdgeInsets.symmetric(horizontal: isIOS ? 16.0 : 8.0, vertical: 4.0);

    Widget cardContent = StyledContainer(
      padding: (padding ?? AppStyles.cardPadding) as EdgeInsets,
      color: backgroundColor,
      child: child,
    );

    if (onTap != null) {
      cardContent = GestureDetector(
        key: key != null ? Key('${key.toString()}_gesture') : null,
        onTap: onTap,
        child: cardContent,
      );
    }

    return Container(
      margin: cardMargin,
      child: cardContent,
    );
  }
}

class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformWidgets.isIOS;

    return Container(
      padding: padding ?? AppStyles.cardPadding,
      margin: margin,
      decoration: isIOS
          ? AppStyles.iOSCardDecoration
          : AppStyles.cardDecoration,
      child: child,
    );
  }
}
