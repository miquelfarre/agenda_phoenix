import 'package:eventypop/app.dart';
import 'package:eventypop/core/storage/hive_migration.dart';
import 'package:eventypop/firebase_options.dart';
import 'package:eventypop/models/birthday_event_hive.dart';
import 'package:eventypop/models/calendar_hive.dart';
import 'package:eventypop/models/calendar_share_hive.dart';
import 'package:eventypop/models/event_collection_hive.dart';
import 'package:eventypop/models/event_hive.dart';
import 'package:eventypop/models/event_interaction_hive.dart';
import 'package:eventypop/models/event_note_hive.dart';
import 'package:eventypop/models/group_hive.dart';
import 'package:eventypop/models/subscription_hive.dart';
import 'package:eventypop/models/user_event_note_hive.dart';
import 'package:eventypop/models/user_hive.dart';
import 'package:eventypop/services/api_client.dart';
import 'package:eventypop/services/birthday_service.dart';
import 'package:eventypop/services/calendar_service.dart';
import 'package:eventypop/services/collection_service.dart';
import 'package:eventypop/services/composite_sync_service.dart';
import 'package:eventypop/services/config_service.dart';
import 'package:eventypop/services/group_service.dart';
import 'package:eventypop/services/sync_service.dart';
import 'package:eventypop/services/timezone_service.dart';
import 'package:firebase_core/firebase_core.dart';
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

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _initializeApiClient();

    await Hive.initFlutter();

    Hive.registerAdapter(EventHiveAdapter());
    Hive.registerAdapter(SubscriptionHiveAdapter());
    Hive.registerAdapter(GroupHiveAdapter());
    Hive.registerAdapter(EventNoteHiveAdapter());
    Hive.registerAdapter(UserEventNoteHiveAdapter());
    Hive.registerAdapter(UserHiveAdapter());

    Hive.registerAdapter(CalendarHiveAdapter());
    Hive.registerAdapter(CalendarShareHiveAdapter());
    Hive.registerAdapter(BirthdayEventHiveAdapter());
    Hive.registerAdapter(EventCollectionHiveAdapter());
    Hive.registerAdapter(EventInteractionHiveAdapter());

    try {
      await Hive.openBox<EventHive>('events');
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk('events');
        await Hive.openBox<EventHive>('events');
      } catch (recoveryError) {
        rethrow;
      }
    }

    if (!Hive.isBoxOpen('subscriptions')) {
      await Hive.openBox<SubscriptionHive>('subscriptions');
    }

    await Hive.openBox<GroupHive>('groups');
    await Hive.openBox<EventNoteHive>('event_notes');
    await Hive.openBox<UserEventNoteHive>('user_event_note');
    await Hive.openBox<UserHive>('users');

    await Hive.openBox<CalendarHive>('calendars');
    await Hive.openBox<CalendarShareHive>('calendar_shares');
    await Hive.openBox<BirthdayEventHive>('birthday_events');
    await Hive.openBox<EventCollectionHive>('event_collections');
    await Hive.openBox<EventInteractionHive>('event_interactions');

    await HiveMigration.initialize();

    await TimezoneService.initialize();

    await SyncService.init();

    await ConfigService.instance.initialize();

    await _validateTestModeConfiguration();

    await GroupService().initialize();

    await BirthdayService().initialize();

    await CalendarService().initialize();

    await CollectionService().initialize();

    await CompositeSyncService.instance.initialize();

    const env = String.fromEnvironment(
      'FLUTTER_ENV',
      defaultValue: 'development',
    );

    runApp(ProviderScope(child: MyApp(env: env)));
  } catch (e, _) {
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
