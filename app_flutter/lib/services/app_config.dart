import 'dart:io' show Platform;

class AppConfig {
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static String get baseUrl {
    final defined = const String.fromEnvironment('BASE_URL');
    if (defined.isNotEmpty) return defined;

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    if (Platform.isIOS) {
      return 'http://localhost:8000';
    }

    return 'http://localhost:8000';
  }
}
