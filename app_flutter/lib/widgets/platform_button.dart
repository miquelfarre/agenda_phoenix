import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:eventypop/ui/styles/app_styles.dart';

class PlatformButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool filled;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool isDestructive;
  final bool fullWidth;
  final bool outlined;
  final double? minSize;

  const PlatformButton({super.key, required this.onPressed, required this.child, this.filled = true, this.color, this.padding, this.isDestructive = false, this.fullWidth = false, this.outlined = false, this.minSize});

  PlatformButton.icon({super.key, required this.onPressed, required Widget icon, required String label, this.filled = true, this.color, this.padding, this.isDestructive = false, this.fullWidth = false, this.outlined = false, this.minSize})
    : child = Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 8), Text(label)]);

  @override
  State<PlatformButton> createState() => _PlatformButtonState();
}

class _PlatformButtonState extends State<PlatformButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget built;

    if (widget.outlined) {
      final resolvedColor = widget.isDestructive ? AppStyles.red600 : (widget.color ?? AppStyles.primary600);
      final EdgeInsets effectivePadding = (widget.padding is EdgeInsets) ? widget.padding as EdgeInsets : const EdgeInsets.symmetric(vertical: 12, horizontal: 16);
      built = Semantics(
        button: true,
        enabled: widget.onPressed != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            HapticFeedback.selectionClick();
            setState(() => _pressed = true);
          },
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: effectivePadding,
            constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
            decoration: BoxDecoration(
              color: AppStyles.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: resolvedColor.withAlpha(70), width: 1),
            ),
            child: DefaultTextStyle(
              style: AppStyles.buttonText.copyWith(color: resolvedColor, fontWeight: FontWeight.w600),
              child: widget.child,
            ),
          ),
        ),
      );
      if (widget.fullWidth) {
        built = SizedBox(width: double.infinity, child: built);
      }
      return built;
    }

    if (Platform.isIOS) {
      final Color effectiveTextColor = widget.filled ? AppStyles.white : (widget.isDestructive ? CupertinoColors.destructiveRed.resolveFrom(context) : (widget.color ?? AppStyles.primary600));
      final textStyle = AppStyles.buttonText.copyWith(color: effectiveTextColor);
      final EdgeInsets defaultPadding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16);
      final EdgeInsets effectivePadding = (widget.padding is EdgeInsets) ? widget.padding as EdgeInsets : defaultPadding;

      if (widget.filled) {
        built = CupertinoButton.filled(
          onPressed: widget.onPressed,
          color: widget.isDestructive ? CupertinoColors.destructiveRed.resolveFrom(context) : (widget.color ?? AppStyles.primary600),
          padding: effectivePadding,
          child: DefaultTextStyle(style: textStyle, child: widget.child),
        );
      } else {
        built = CupertinoButton(
          onPressed: widget.onPressed,
          padding: effectivePadding,
          child: DefaultTextStyle(style: textStyle, child: widget.child),
        );
      }
      return widget.fullWidth ? SizedBox(width: double.infinity, child: built) : built;
    }

    final resolvedColor = widget.isDestructive ? AppStyles.red600 : (widget.color ?? AppStyles.primary600);
    final EdgeInsets effectivePadding = (widget.padding is EdgeInsets) ? widget.padding as EdgeInsets : const EdgeInsets.symmetric(vertical: 12, horizontal: 16);

    final decoration = widget.filled
        ? BoxDecoration(color: resolvedColor, borderRadius: BorderRadius.circular(8))
        : BoxDecoration(
            color: AppStyles.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: resolvedColor.withAlpha((0.12 * 255).round()), width: 1.0),
          );

    final textStyle = widget.filled ? AppStyles.buttonText.copyWith(color: AppStyles.white) : AppStyles.buttonText.copyWith(color: resolvedColor);

    built = Semantics(
      button: true,
      enabled: widget.onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: effectivePadding,
          constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
          decoration: decoration.copyWith(color: decoration.color?.withAlpha(((_pressed ? 0.85 : 1.0) * 255).round())),
          child: DefaultTextStyle(style: textStyle, child: widget.child),
        ),
      ),
    );
    if (widget.fullWidth) {
      built = SizedBox(width: double.infinity, child: built);
    }
    return built;
  }
}
