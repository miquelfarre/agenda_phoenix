import 'package:flutter/cupertino.dart';
import 'package:eventypop/widgets/platform_button.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class PlatformIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const PlatformIconButton({super.key, required this.icon, this.onPressed, this.tooltip, this.color});

  @override
  Widget build(BuildContext context) {
    return PlatformButton(
      padding: const EdgeInsets.all(8.0),
      filled: false,
      onPressed: onPressed,
      child: Semantics(
        label: tooltip,
        button: true,
        child: IconTheme(
          data: IconThemeData(color: color ?? AppStyles.blue600),
          child: icon,
        ),
      ),
    );
  }
}
