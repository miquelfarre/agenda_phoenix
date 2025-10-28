import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import '../l10n/app_localizations.dart';

class AdaptiveApp extends StatelessWidget {
  final Key? appKey;
  final String title;
  final List<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final List<Locale> supportedLocales;
  final Locale? locale;
  final Widget? home;
  final Map<String, WidgetBuilder>? routes;
  final GoRouter? routerConfig;
  final bool debugShowCheckedModeBanner;

  const AdaptiveApp({
    super.key,
    this.appKey,
    required this.title,
    required this.localizationsDelegates,
    required this.supportedLocales,
    this.locale,
    this.home,
    this.routes,
    this.debugShowCheckedModeBanner = false,
  }) : routerConfig = null;

  const AdaptiveApp.router({
    super.key,
    this.appKey,
    required this.title,
    required this.localizationsDelegates,
    required this.supportedLocales,
    this.locale,
    required this.routerConfig,
    this.debugShowCheckedModeBanner = false,
  }) : home = null,
       routes = null;

  @override
  Widget build(BuildContext context) {
    final delegates = <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    if (routerConfig != null) {
      if (PlatformDetection.isIOS) {
        return CupertinoApp.router(
          key: appKey,
          title: title,
          localizationsDelegates: delegates,
          supportedLocales: supportedLocales,
          locale: locale,
          routerConfig: routerConfig!,
          debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        );
      }

      return WidgetsApp.router(
        key: appKey,
        color: const Color(0xFFFFFFFF),
        title: title,
        localizationsDelegates: delegates,
        supportedLocales: supportedLocales,
        locale: locale,
        routerConfig: routerConfig!,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      );
    }

    if (PlatformDetection.isIOS) {
      return CupertinoApp(
        key: appKey,
        title: title,
        localizationsDelegates: delegates,
        supportedLocales: supportedLocales,
        locale: locale,
        home: home!,
        routes: routes ?? const {},
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      );
    }

    return WidgetsApp(
      key: appKey,
      color: const Color(0xFFFFFFFF),
      title: title,
      localizationsDelegates: delegates,
      supportedLocales: supportedLocales,
      locale: locale,
      routes: routes ?? {},
      onGenerateRoute: (settings) {
        if (settings.name == Navigator.defaultRouteName) {
          return CupertinoPageRoute(builder: (_) => home!, settings: settings);
        }
        final builder = routes?[settings.name];
        if (builder != null) {
          return CupertinoPageRoute(builder: builder, settings: settings);
        }
        return null;
      },
      builder: (context, child) => child ?? home!,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    );
  }
}
