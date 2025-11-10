import 'package:eventypop/app.dart';
import 'package:eventypop/core/storage/hive_migration.dart';
import 'package:eventypop/models/persistence/calendar_hive.dart';
import 'package:eventypop/models/persistence/event_hive.dart';
import 'package:eventypop/models/persistence/group_hive.dart';
import 'package:eventypop/models/persistence/user_hive.dart';
import 'package:eventypop/services/api_client.dart';
import 'package:eventypop/services/config_service.dart';
import 'package:eventypop/services/timezone_service.dart';
import 'package:eventypop/services/supabase_service.dart';
import 'package:eventypop/services/app_config.dart';
import 'package:eventypop/services/permissions_service.dart';
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

    await Hive.openBox<UserHive>('users');

    await HiveMigration.initialize();

    await TimezoneService.initialize();

    await ConfigService.instance.initialize();

    await _validateTestModeConfiguration();

    // When running in test mode (debug), apply a generated JWT as Supabase auth
    // so Realtime (RLS) connections use a user token instead of the anon key.
    await SupabaseService.instance.applyTestAuthIfNeeded();

    // Request all critical permissions at startup
    if (kDebugMode) {
      print('🔐 Requesting critical permissions...');
    }
    final allPermissionsGranted =
        await PermissionsService.instance.requestAllCriticalPermissions();
    if (kDebugMode) {
      print('🔐 Permissions result: $allPermissionsGranted');
    }

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
