import 'package:eventypop/app.dart';
import 'package:eventypop/core/storage/hive_migration.dart';
import 'package:eventypop/models/calendar_hive.dart';
import 'package:eventypop/models/calendar_share_hive.dart';
import 'package:eventypop/models/event_hive.dart';
import 'package:eventypop/models/group_hive.dart';
import 'package:eventypop/models/user_event_note_hive.dart';
import 'package:eventypop/models/user_hive.dart';
import 'package:eventypop/services/api_client.dart';
import 'package:eventypop/services/config_service.dart';
import 'package:eventypop/services/timezone_service.dart';
import 'package:eventypop/services/supabase_service.dart';
import 'package:eventypop/services/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {};

    PlatformDispatcher.instance.onError = (error, stack) {
      return true;
    };

    await _initializeSupabase();

    await _initializeApiClient();

    await Hive.initFlutter();

    Hive.registerAdapter(EventHiveAdapter());
    Hive.registerAdapter(GroupHiveAdapter());
    Hive.registerAdapter(UserHiveAdapter());
    Hive.registerAdapter(CalendarHiveAdapter());
    Hive.registerAdapter(CalendarShareHiveAdapter());
    Hive.registerAdapter(UserEventNoteHiveAdapter());

    await Hive.openBox<UserEventNoteHive>('user_event_note');
    await Hive.openBox<UserHive>('users');
    await Hive.openBox<CalendarShareHive>('calendar_shares');

    await HiveMigration.initialize();

    await TimezoneService.initialize();

    await ConfigService.instance.initialize();

    await _validateTestModeConfiguration();

    // When running in test mode (debug), apply a generated JWT as Supabase auth
    // so Realtime (RLS) connections use a user token instead of the anon key.
    await SupabaseService.instance.applyTestAuthIfNeeded();

    const env = String.fromEnvironment(
      'FLUTTER_ENV',
      defaultValue: 'development',
    );

    runApp(ProviderScope(child: MyApp(env: env)));
  } catch (e, _) {
    rethrow;
  }
}

Future<void> _initializeSupabase() async {
  try {
    await SupabaseService.initialize(
      supabaseUrl: AppConfig.supabaseUrl,
      supabaseAnonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    rethrow;
  }
}

Future<void> _initializeApiClient() async {
  try {
    ApiClientFactory.initialize(ApiClient());
  } catch (e) {
    rethrow;
  }
}

Future<void> _validateTestModeConfiguration() async {
  try {
    final configService = ConfigService.instance;

    const isReleaseMode = bool.fromEnvironment('dart.vm.product');

    if (isReleaseMode && configService.isTestMode) {
      configService.disableTestMode();

      throw Exception(
        'Test mode was enabled in a release build and has been forcibly disabled. '
        'This is a security violation. Please review your build configuration.',
      );
    }

    if (kDebugMode && !isReleaseMode && !configService.isTestMode) {
      configService.enableTestMode();
    }

    if (configService.isTestMode) {
      if (kDebugMode) {
        final testUserInfo = configService.testUserInfo;
        if (testUserInfo != null) {
        } else {}
      }
    } else {}
  } catch (e) {
    rethrow;
  }
}