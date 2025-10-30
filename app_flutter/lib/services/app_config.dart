import 'dart:io' show Platform;

class AppConfig {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'development');

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

  static String get supabaseUrl {
    final defined = const String.fromEnvironment('SUPABASE_URL');
    if (defined.isNotEmpty) return defined;

    // Local Supabase instance through Kong gateway
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String get supabaseAnonKey {
    return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJvbGUiOiJhbm9uIiwiYXVkIjoiYXV0aGVudGljYXRlZCIsImV4cCI6MTk4MzgxMjk5Nn0.VZkz5UpquChN3tfC9v5FyuE7_k6cqyrOXpIpajpGVsw');
  }
}
