import 'package:flutter/cupertino.dart';
import 'platform_detection.dart';

class PlatformNavigation {
  static PageRoute<T> platformPageRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    if (PlatformDetection.isIOS) {
      return CupertinoPageRoute<T>(
        builder: builder,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Future<T?> presentModal<T>(
    BuildContext context,
    Widget screen, {
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    Object? shape,
  }) {
    if (PlatformDetection.isIOS) {
      final result = showCupertinoModalPopup<T>(
        context: context,
        builder: (ctx) => screen,
      );
      result.then((value) {});
      return result;
    }

    final route = PageRouteBuilder<T>(
      opaque: false,
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: isDismissible ? () => Navigator.of(ctx).pop() : null,
          child: Container(
            color: const Color(0x80000000),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(child: screen),
            ),
          ),
        );
      },
      transitionsBuilder: (ctx, animation, secondary, child) {
        final offset = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    return Navigator.of(context).push<T>(route);
  }
}
