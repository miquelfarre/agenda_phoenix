import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/widgets/platform_button.dart';

class PlatformFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? heroTag;
  final String? tooltip;
  final Color? backgroundColor;
  final bool mini;

  const PlatformFab({super.key, required this.onPressed, required this.child, this.heroTag, this.tooltip, this.backgroundColor, this.mini = false});

  @override
  State<PlatformFab> createState() => _PlatformFabState();
}

class _PlatformFabState extends State<PlatformFab> {
  @override
  Widget build(BuildContext context) {
    final size = widget.mini ? 40.0 : 56.0;
    final fab = Semantics(
      button: true,
      label: widget.tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppStyles.colorWithOpacity(AppStyles.black87, 0.24), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: PlatformButton(
            padding: const EdgeInsets.all(0),
            filled: true,
            color: widget.backgroundColor ?? AppStyles.primary600,
            onPressed: widget.onPressed,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: fab);
    }

    return fab;
  }
}
