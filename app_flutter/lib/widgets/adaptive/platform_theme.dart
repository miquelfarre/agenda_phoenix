import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PlatformTheme {
  final bool isIOS;
  final bool isDark;
  final Color primaryColor;
  final Color backgroundColor;
  final TextStyle textStyle;
  final EdgeInsets defaultPadding;

  const PlatformTheme({
    required this.isIOS,
    required this.isDark,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textStyle,
    required this.defaultPadding,
  });

  factory PlatformTheme.adaptive(BuildContext? context) {
    final isIOS = _isIOSPlatform();
    final brightness = context != null
        ? Theme.of(context).brightness
        : WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;

    if (context != null) {
      final theme = Theme.of(context);
      return PlatformTheme(
        isIOS: isIOS,
        isDark: isDark,
        primaryColor: theme.primaryColor,
        backgroundColor: theme.cardColor,
        textStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
        defaultPadding: _getDefaultPadding(isIOS),
      );
    }

    return PlatformTheme(
      isIOS: isIOS,
      isDark: isDark,
      primaryColor: isIOS ? const Color(0xFF007AFF) : const Color(0xFF2196F3),
      backgroundColor: isDark
          ? (isIOS ? const Color(0xFF1C1C1E) : const Color(0xFF121212))
          : (isIOS ? const Color(0xFFF2F2F7) : const Color(0xFFFFFFFF)),
      textStyle: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black,
        fontFamily: isIOS ? '.SF Pro Text' : 'Roboto',
      ),
      defaultPadding: _getDefaultPadding(isIOS),
    );
  }

  static bool _isIOSPlatform() {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  static EdgeInsets _getDefaultPadding(bool isIOS) {
    return isIOS ? const EdgeInsets.all(16.0) : const EdgeInsets.all(12.0);
  }

  double get cardElevation => isIOS ? 0.0 : 2.0;

  BorderRadius get defaultBorderRadius =>
      BorderRadius.circular(isIOS ? 10.0 : 8.0);

  double get buttonHeight => isIOS ? 50.0 : 48.0;

  double get textFieldHeight => isIOS ? 44.0 : 56.0;

  Color get secondaryColor => isIOS
      ? (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70))
      : (isDark ? const Color(0xFFBB86FC) : const Color(0xFF03DAC6));

  Color get errorColor =>
      isIOS ? const Color(0xFFFF3B30) : const Color(0xFFB00020);

  Color get surfaceColor => isDark
      ? (isIOS ? const Color(0xFF2C2C2E) : const Color(0xFF1E1E1E))
      : (isIOS ? const Color(0xFFFFFFFF) : const Color(0xFFFAFAFA));

  Color get dividerColor => isDark
      ? Colors.white.withValues(alpha: 0.1)
      : Colors.black.withValues(alpha: 0.1);

  PlatformTheme copyWith({
    bool? isIOS,
    bool? isDark,
    Color? primaryColor,
    Color? backgroundColor,
    TextStyle? textStyle,
    EdgeInsets? defaultPadding,
  }) {
    return PlatformTheme(
      isIOS: isIOS ?? this.isIOS,
      isDark: isDark ?? this.isDark,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      defaultPadding: defaultPadding ?? this.defaultPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatformTheme &&
        other.isIOS == isIOS &&
        other.isDark == isDark &&
        other.primaryColor == primaryColor &&
        other.backgroundColor == backgroundColor &&
        other.textStyle == textStyle &&
        other.defaultPadding == defaultPadding;
  }

  @override
  int get hashCode {
    return Object.hash(
      isIOS,
      isDark,
      primaryColor,
      backgroundColor,
      textStyle,
      defaultPadding,
    );
  }

  @override
  String toString() {
    return 'PlatformTheme('
        'isIOS: $isIOS, '
        'isDark: $isDark, '
        'primaryColor: $primaryColor, '
        'backgroundColor: $backgroundColor'
        ')';
  }
}
