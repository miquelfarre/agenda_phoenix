import 'package:flutter/cupertino.dart';
import '../core/mixins/singleton_mixin.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';

class NavigationService with SingletonMixin {
  NavigationService._internal();

  factory NavigationService() => SingletonMixin.getInstance(() => NavigationService._internal());

  static NavigationService get instance => NavigationService();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get navigator => navigatorKey.currentState;
  BuildContext? get context => navigatorKey.currentContext;

  Future<T?> push<T extends Object?>(Route<T> route) async {

    if (navigator == null) {
      return null;
    }

    final result = await navigator?.push(route);
    return result;
  }

  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) async {
    return navigator?.pushNamed(routeName, arguments: arguments);
  }

  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(Route<T> newRoute, {TO? result}) async {
    return navigator?.pushReplacement(newRoute, result: result);
  }

  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(String routeName, {TO? result, Object? arguments}) async {
    return navigator?.pushReplacementNamed(routeName, result: result, arguments: arguments);
  }

  Future<T?> pushAndRemoveUntil<T extends Object?>(Route<T> newRoute, RoutePredicate predicate) async {
    return navigator?.pushAndRemoveUntil(newRoute, predicate);
  }

  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(String newRouteName, RoutePredicate predicate, {Object? arguments}) async {
    return navigator?.pushNamedAndRemoveUntil(newRouteName, predicate, arguments: arguments);
  }

  void pop<T extends Object?>([T? result]) {
    navigator?.pop(result);
  }

  void popUntil(RoutePredicate predicate) {
    navigator?.popUntil(predicate);
  }

  bool canPop() {
    return navigator?.canPop() ?? false;
  }

  Future<bool> maybePop<T extends Object?>([T? result]) async {
    return await navigator?.maybePop(result) ?? false;
  }

  Future<T?> showAppDialog<T>({required Widget dialog, bool barrierDismissible = true, String? barrierLabel, Color? barrierColor}) async {
    final context = this.context;
    if (context == null) {
      return null;
    }

    return showCupertinoDialog<T>(context: context, barrierDismissible: barrierDismissible, builder: (context) => dialog);
  }

  Future<T?> showAppBottomSheet<T>({required Widget bottomSheet, bool isScrollControlled = false, bool isDismissible = true, bool enableDrag = true}) async {
    final context = this.context;
    if (context == null) {
      return null;
    }

    return showCupertinoModalPopup<T>(context: context, builder: (context) => bottomSheet);
  }

  void showAlert(String message, {String? title}) {
    final context = this.context;
    if (context == null) {
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [CupertinoDialogAction(key: const Key('navigation_service_alert_ok_button'), child: Text(context.l10n.ok), onPressed: () => Navigator.of(context).pop())],
      ),
    );
  }

  String? get currentRouteName {
    return ModalRoute.of(context!)?.settings.name;
  }

  Future<T?> clearStackAndNavigate<T extends Object?>(String routeName, {Object? arguments}) {
    return pushNamedAndRemoveUntil<T>(routeName, (route) => false, arguments: arguments);
  }
}
