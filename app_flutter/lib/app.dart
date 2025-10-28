import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/core/navigation/app_router.dart';
import 'package:eventypop/core/state/app_state.dart';
import 'package:eventypop/l10n/app_localizations.dart';
import 'package:eventypop/widgets/adaptive_app.dart';
import 'package:eventypop/widgets/app_initializer.dart';

class MyApp extends StatelessWidget {
  final String env;
  const MyApp({super.key, required this.env});

  @override
  Widget build(BuildContext context) {
    return AppInitializer(
      child: Consumer(
        builder: (context, ref, child) {
          final locale = ref.watch(localeProvider);

          return AdaptiveApp.router(
            appKey: ValueKey(locale.toString()),
            title: 'EventyPop',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
