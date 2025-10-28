import 'package:flutter/cupertino.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'platform_detection.dart';
import 'dialog_helpers.dart';
import 'platform_navigation.dart';
import '../../styles/app_styles.dart';

class PlatformWidgets {
  static bool get isIOS => PlatformDetection.isIOS;
  static Widget platformTextField({
    required TextEditingController controller,
    String? placeholder,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextStyle? style,
    int? maxLines = 1,
    bool enabled = true,
  }) {
    if (PlatformDetection.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? hintText,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        focusNode: focusNode,
        prefix: prefixIcon,
        suffix: suffixIcon,
        style: style,
        maxLines: maxLines,
        enabled: enabled,
        decoration: BoxDecoration(
          color: AppStyles.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppStyles.grey300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    }

    return _NeutralTextField(
      controller: controller,
      hintText: hintText ?? placeholder,
      prefix: prefixIcon,
      suffix: suffixIcon,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      style: style,
      maxLines: maxLines,
      enabled: enabled,
    );
  }

  static Widget platformLoadingIndicator({double? radius, Color? color}) {
    if (PlatformDetection.isIOS) {
      return CupertinoActivityIndicator(radius: radius ?? 10.0, color: color);
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(child: _NeutralCircularProgress(color: color)),
    );
  }

  static Widget platformButton({required VoidCallback? onPressed, required Widget child, bool filled = true, Color? color, double? minSize, EdgeInsetsGeometry? padding, bool isLoading = false, bool isDisabled = false, double borderRadius = 8, double? width, double? height}) {
    if (isLoading || isDisabled) {
      final effectiveColor = color ?? AppStyles.primary600;
      final disabledColor = isLoading || isDisabled ? AppStyles.grey300 : effectiveColor;

      return SizedBox(
        width: width,
        height: height,
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: disabledColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: PlatformDetection.isIOS ? Border.all(color: AppStyles.grey200, width: 1) : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(width: 20, height: 20, child: platformLoadingIndicator(radius: 10, color: AppStyles.white))
                : DefaultTextStyle(
                    style: AppStyles.buttonText.copyWith(color: AppStyles.grey600),
                    child: child,
                  ),
          ),
        ),
      );
    }

    final config = AdaptiveButtonConfig(variant: filled ? ButtonVariant.primary : ButtonVariant.secondary, size: ButtonSize.medium, backgroundColor: color, fullWidth: width != null, iconPosition: IconPosition.leading, borderRadius: borderRadius);

    return SizedBox(
      width: width,
      height: height,
      child: AdaptiveButton(config: config, onPressed: onPressed, text: child is Text ? child.data : null),
    );
  }

  static Widget platformSwitch({required bool value, required ValueChanged<bool>? onChanged, Color? activeColor, Color? trackColor}) {
    if (PlatformDetection.isIOS) {
      return CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: activeColor ?? AppStyles.primary600);
    }

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Container(
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: value ? (activeColor ?? AppStyles.primary600) : AppStyles.grey300, borderRadius: BorderRadius.circular(16)),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: AppStyles.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  static Widget platformSlider({required double value, required ValueChanged<double>? onChanged, double min = 0.0, double max = 1.0, int? divisions, Color? activeColor, Color? inactiveColor}) {
    if (PlatformDetection.isIOS) {
      return CupertinoSlider(value: value, onChanged: onChanged, min: min, max: max, divisions: divisions, activeColor: activeColor ?? AppStyles.primary600);
    }

    return _NeutralSlider(value: value, onChanged: onChanged, min: min, max: max, divisions: divisions, activeColor: activeColor, inactiveColor: inactiveColor);
  }

  static Widget platformListTile({Widget? leading, required Widget title, Widget? subtitle, Widget? trailing, VoidCallback? onTap, EdgeInsetsGeometry? contentPadding, Color? backgroundColor}) {
    if (PlatformDetection.isIOS) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 12)],
              Expanded(child: title),
              if (trailing != null) ...[const SizedBox(width: 8), trailing] else if (onTap != null) ...[const SizedBox(width: 8), const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.tertiaryLabel)],
            ],
          ),
        ),
      );
    }

    return InkWellLike(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            if (leading != null) leading,
            Expanded(child: title),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  static Widget platformIcon(IconData? icon, {Color? color, double? size}) {
    if (icon == null) return const SizedBox.shrink();
    return Icon(icon, color: color ?? CupertinoColors.label, size: size);
  }

  static Widget platformDivider({double? height, double? thickness, Color? color}) {
    return Container(height: height ?? 0.5, color: color ?? CupertinoColors.separator);
  }

  static Widget platformActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    bool isDestructive = false,
    bool showChevron = true,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double borderRadius = 12,
    bool isLoading = false,
  }) {
    final isIOS = PlatformDetection.isIOS;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isIOS ? AppStyles.cardBackgroundColor : AppStyles.grey50),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppStyles.grey200, width: 1),
      ),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              platformIcon(icon, color: isDestructive ? AppStyles.red600 : AppStyles.primary600, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: isDestructive ? AppStyles.red700 : AppStyles.black87),
                    ),
                    if (subtitle?.isNotEmpty == true) ...[const SizedBox(height: 4), Text(subtitle!, style: AppStyles.cardSubtitle.copyWith(fontSize: 14, color: AppStyles.grey600))],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ] else if (isLoading) ...[
                const SizedBox(width: 8),
                SizedBox(width: 16, height: 16, child: platformLoadingIndicator(radius: 8)),
              ] else if (showChevron) ...[
                platformIcon(CupertinoIcons.chevron_right, color: AppStyles.grey400, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget platformCardContainer({required Widget child, EdgeInsetsGeometry? padding, EdgeInsetsGeometry? margin, Color? backgroundColor, double borderRadius = 12, bool showBorder = true, Color? borderColor, double borderWidth = 1, List<BoxShadow>? boxShadow}) {
    final isIOS = PlatformDetection.isIOS;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isIOS ? AppStyles.cardBackgroundColor : AppStyles.grey50),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: borderColor ?? AppStyles.grey200, width: borderWidth) : null,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }

  static Widget platformUserHeader({required String displayName, String? subtitle, Widget? avatar, List<Widget>? badges, double avatarRadius = 30, EdgeInsetsGeometry? padding, EdgeInsetsGeometry? margin, Color? backgroundColor, double borderRadius = 12}) {
    final isIOS = PlatformDetection.isIOS;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(color: backgroundColor ?? (isIOS ? AppStyles.cardBackgroundColor : AppStyles.grey50), borderRadius: BorderRadius.circular(borderRadius)),
      child: Row(
        children: [
          avatar ??
              Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(color: AppStyles.blueShade100, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: AppStyles.headlineSmall.copyWith(fontSize: avatarRadius * 0.6, fontWeight: FontWeight.bold, color: AppStyles.blue600),
                  ),
                ),
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppStyles.cardTitle.copyWith(fontSize: 18, color: AppStyles.black87)),
                if (subtitle?.isNotEmpty == true) ...[const SizedBox(height: 4), Text(subtitle!, style: AppStyles.cardSubtitle)],
                if (badges?.isNotEmpty == true) ...[const SizedBox(height: 6), Wrap(spacing: 8, children: badges ?? const [])],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget platformBadge({required String text, Color? backgroundColor, Color? textColor, Color? borderColor, double borderRadius = 12, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppStyles.blueShade50,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppStyles.blueShade100, width: 1),
      ),
      child: Text(
        text,
        style: AppStyles.bodyTextSmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: textColor ?? AppStyles.blue600),
      ),
    );
  }

  static Widget platformSeparator({double height = 1, Color? color, EdgeInsetsGeometry? margin}) {
    return Container(height: height, margin: margin ?? const EdgeInsets.symmetric(horizontal: 16), color: color ?? AppStyles.grey200);
  }

  static Future<bool?> showPlatformConfirmDialog(BuildContext context, {required String title, required String message, String? confirmText, String? cancelText, bool isDestructive = false}) {
    return PlatformDialogHelpers.showPlatformConfirmDialog(context, title: title, message: message, confirmText: confirmText, cancelText: cancelText, isDestructive: isDestructive);
  }

  static void showSnackBar({BuildContext? context, required String message, bool isError = false, Duration duration = const Duration(seconds: 3), String? actionLabel, VoidCallback? onAction}) {
    PlatformDialogHelpers.showSnackBar(context: context, message: message, isError: isError, duration: duration, actionLabel: actionLabel, onAction: onAction);
  }

  static void showGlobalPlatformMessage({BuildContext? context, required String message, bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    PlatformDialogHelpers.showGlobalPlatformMessage(context: context, message: message, isError: isError, duration: duration);
  }

  static Widget platformScaffold({
    required Widget body,
    PreferredSizeWidget? appBar,
    CupertinoNavigationBar? navigationBar,
    String? title,
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
    bool? resizeToAvoidBottomInset,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    bool extendBodyBehindAppBar = false,
  }) {
    final isIOS = PlatformDetection.isIOS;

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar:
            navigationBar ??
            (title != null
                ? CupertinoNavigationBar(
                    middle: Text(title, style: AppStyles.cardTitle),
                    backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
                    trailing: actions?.isNotEmpty == true ? Row(mainAxisSize: MainAxisSize.min, children: actions ?? const []) : null,
                    leading: leading,
                  )
                : null),
        backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
        child: SafeArea(child: body),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: backgroundColor ?? AppStyles.primary600,
              child: Row(
                children: [
                  if (leading != null) leading,
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(color: AppStyles.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (actions != null && actions.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: actions.take(2).toList()),
                ],
              ),
            ),
          Expanded(child: body),
          if (bottomNavigationBar != null) bottomNavigationBar,
          if (floatingActionButton != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: floatingActionButton),
        ],
      ),
    );
  }

  static Widget platformRefreshIndicator({required Widget child, required Future<void> Function() onRefresh}) {
    if (PlatformDetection.isIOS) {
      return CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          SliverToBoxAdapter(child: child),
        ],
      );
    }

    return GestureDetector(onTap: () => onRefresh(), child: child);
  }
}

extension NavigatorStateExtensions on NavigatorState {
  Future<T?> pushScreen<T extends Object?>(BuildContext context, Widget screen, {bool fullscreenDialog = false}) {
    return push<T>(PlatformNavigation.platformPageRoute<T>(builder: (_) => screen, fullscreenDialog: fullscreenDialog));
  }
}

class _NeutralTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final TextStyle? style;
  final int? maxLines;
  final bool enabled;

  const _NeutralTextField({required this.controller, this.hintText, this.prefix, this.suffix, this.keyboardType, this.obscureText = false, this.onChanged, this.onEditingComplete, this.focusNode, this.style, this.maxLines = 1, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.grey300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (prefix != null) Padding(padding: const EdgeInsets.only(right: 8), child: prefix),
          Expanded(
            child: CupertinoTextField(controller: controller, keyboardType: keyboardType, obscureText: obscureText, onChanged: onChanged, onEditingComplete: onEditingComplete, focusNode: focusNode, style: style, maxLines: maxLines, enabled: enabled, placeholder: hintText, decoration: null),
          ),
          if (suffix != null) Padding(padding: const EdgeInsets.only(left: 8), child: suffix),
        ],
      ),
    );
  }
}

class _NeutralCircularProgress extends StatelessWidget {
  final Color? color;
  const _NeutralCircularProgress({this.color});
  @override
  Widget build(BuildContext context) {
    return const CupertinoActivityIndicator();
  }
}

class _NeutralSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;
  final Color? inactiveColor;

  const _NeutralSlider({required this.value, required this.onChanged, required this.min, required this.max, this.divisions, this.activeColor, this.inactiveColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: onChanged == null
          ? null
          : (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              final t = (local.dx / box.size.width).clamp(0.0, 1.0);
              final newValue = min + (max - min) * t;
              onChanged!(newValue);
            },
      child: Container(
        height: 36,
        color: const Color(0x00000000),
        child: CustomPaint(
          painter: _SliderPainter(value: (value - min) / (max - min), activeColor: activeColor ?? AppStyles.primary600),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  final double value;
  final Color activeColor;
  _SliderPainter({required this.value, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = AppStyles.grey300;
    final paintActive = Paint()..color = activeColor;
    final trackHeight = 6.0;
    final r = RRect.fromLTRBR(0, (size.height - trackHeight) / 2, size.width, (size.height + trackHeight) / 2, Radius.circular(6));
    canvas.drawRRect(r, paintBg);
    final activeR = RRect.fromLTRBR(0, (size.height - trackHeight) / 2, size.width * value, (size.height + trackHeight) / 2, Radius.circular(6));
    canvas.drawRRect(activeR, paintActive);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AdaptiveTimeOfDay {
  final int hour;
  final int minute;

  const AdaptiveTimeOfDay({required this.hour, required this.minute});

  factory AdaptiveTimeOfDay.now() {
    final now = DateTime.now();
    return AdaptiveTimeOfDay(hour: now.hour, minute: now.minute);
  }

  factory AdaptiveTimeOfDay.fromDateTime(DateTime dateTime) {
    return AdaptiveTimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  DateTime toDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String format12Hour() {
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  String toString() => format24Hour();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveTimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

class InkWellLike extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const InkWellLike({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: child);
  }
}
