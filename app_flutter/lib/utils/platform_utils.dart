import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlatformUtils {
  static Future<T?> push<T>(BuildContext context, Widget screen) {
    if (Platform.isIOS) {
      return Navigator.of(
        context,
      ).push<T>(CupertinoPageRoute(builder: (context) => screen));
    }
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (context) => screen));
  }

  static Future<T?> pushReplacement<T>(BuildContext context, Widget screen) {
    if (Platform.isIOS) {
      return Navigator.of(context).pushReplacement<T, void>(
        CupertinoPageRoute(builder: (context) => screen),
      );
    }
    return Navigator.of(
      context,
    ).pushReplacement<T, void>(MaterialPageRoute(builder: (context) => screen));
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static bool get isIOS => Platform.isIOS;

  static bool get isAndroid => Platform.isAndroid;
}
