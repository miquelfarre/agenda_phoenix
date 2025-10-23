import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class PlatformDetection {
  static bool? _testIsIOS;

  static bool get isIOS => _testIsIOS ?? Platform.isIOS;

  @visibleForTesting
  static void overrideIsIOSForTests(bool? value) {
    _testIsIOS = value;
  }
}
