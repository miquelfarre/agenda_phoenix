import 'package:flutter/cupertino.dart';

class AppStyles {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color transparent = Color(0x00000000);

  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color primary50 = Color(0xFFE3F2FD);
  static const Color primary100 = Color(0xFFBBDEFB);
  static const Color primary200 = Color(0xFF90CAF9);
  static const Color primary300 = Color(0xFF64B5F6);
  static const Color primary400 = Color(0xFF42A5F5);
  static const Color primary500 = Color(0xFF2196F3);
  static const Color primary600 = Color(0xFF1E88E5);
  static const Color primary700 = Color(0xFF1976D2);
  static const Color primary800 = Color(0xFF1565C0);

  static const Color accentColor = Color(0xFFFF9800);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);

  static const Color blue = Color(0xFF2196F3);
  static const Color blue600 = Color(0xFF1E88E5);
  static const Color blueShade50 = Color(0xFFE3F2FD);
  static const Color blueShade100 = Color(0xFFBBDEFB);

  static const Color green = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color successColor = Color(0xFF43A047);

  static const Color orange = Color(0xFFFF9800);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color orange600 = Color(0xFFFB8C00);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color orangeShade50 = Color(0xFFFFF3E0);
  static const Color orangeShade100 = Color(0xFFFFE0B2);
  static const Color warningColor = Color(0xFFFB8C00);

  static const Color red = Color(0xFFF44336);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color errorColor = Color(0xFFE53935);

  static const Color purple = Color(0xFF9C27B0);
  static const Color purple600 = Color(0xFF8E24AA);
  static const Color teal600 = Color(0xFF00897B);
  static const Color indigo600 = Color(0xFF3949AB);
  static const Color pink600 = Color(0xFFD81B60);
  static const Color amber600 = Color(0xFFFFB300);
  static const Color cyan600 = Color(0xFF00ACC1);

  static const Color textColor = Color(0xDD000000);
  static const Color secondaryTextColor = Color(0xFF9E9E9E);

  static const Color cardBackgroundColor = Color(0xFFF2F2F7);

  static const LinearGradient splashGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)]);

  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets smallPadding = EdgeInsets.all(8);
  static const EdgeInsets largePadding = EdgeInsets.all(24);
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets dialogPadding = EdgeInsets.all(20);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));

  static const double cardElevation = 2.0;
  static const double dialogElevation = 8.0;

  static const TextStyle headlineSmall = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, decoration: TextDecoration.none);

  static const TextStyle cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor, decoration: TextDecoration.none);

  static const TextStyle cardSubtitle = TextStyle(fontSize: 14, color: secondaryTextColor, decoration: TextDecoration.none);

  static const TextStyle bodyText = TextStyle(fontSize: 16, color: textColor, decoration: TextDecoration.none);

  static const TextStyle bodyTextSmall = TextStyle(fontSize: 13, color: secondaryTextColor, decoration: TextDecoration.none);

  static const TextStyle buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.none);

  static Color colorWithOpacity(Color color, double opacity) {
    final int alpha = (opacity * 255).round().clamp(0, 255);
    return color.withAlpha(alpha);
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppStyles.white,
    borderRadius: cardRadius,
    boxShadow: [BoxShadow(color: AppStyles.colorWithOpacity(AppStyles.black, 0.098), blurRadius: 4, offset: const Offset(0, 2))],
  );

  static BoxDecoration get iOSCardDecoration => BoxDecoration(color: cardBackgroundColor, borderRadius: cardRadius);
}
