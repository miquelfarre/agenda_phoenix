import 'package:flutter/widgets.dart';

import 'package:eventypop/ui/styles/app_styles.dart';

class StyledContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;

  const StyledContainer({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? AppStyles.cardPadding,
      decoration: BoxDecoration(
        color: color ?? AppStyles.cardBackgroundColor,
        borderRadius: borderRadius ?? AppStyles.cardRadius,
        boxShadow: boxShadow ?? AppStyles.cardDecoration.boxShadow,
        border: border,
      ),
      child: child,
    );
  }
}
