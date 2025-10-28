class AppConstants {
  static const int maxEventTitleLength = 100;
  static const int maxEventDescriptionLength = 500;
  static const int minEventTitleLength = 3;

  static const int maxGroupNameLength = 50;
  static const int maxGroupDescriptionLength = 200;
  static const int minGroupNameLength = 2;

  static const int maxFullNameLength = 100;
  static const int maxInstagramNameLength = 30;
  static const int maxUserBioLength = 150;
  static const int minFullNameLength = 2;

  static const int maxNotificationMessageLength = 300;
  static const int maxCommentLength = 280;
  static const int maxEventChangeNotificationLength = 200;

  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  static const int maxInvitationMessageLength = 150;

  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double circularBorderRadius = 50.0;

  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 12.0;
  static const double smallFontSize = 10.0;

  static const double defaultButtonHeight = 48.0;
  static const double smallButtonHeight = 36.0;
  static const double largeButtonHeight = 56.0;

  static const double defaultTextFieldHeight = 48.0;
  static const double multilineTextFieldMinHeight = 80.0;

  static const Duration userCacheExpiry = Duration(hours: 1);
  static const Duration eventCacheExpiry = Duration(minutes: 30);
  static const Duration contactsCacheExpiry = Duration(hours: 6);
  static const Duration groupCacheExpiry = Duration(hours: 2);
  static const Duration notificationCacheExpiry = Duration(minutes: 15);

  static const int maxCachedUsers = 1000;
  static const int maxCachedEvents = 500;
  static const int maxCachedGroups = 100;
  static const int maxPendingOperations = 100;

  static const Duration syncRetryDelay = Duration(seconds: 5);
  static const int maxSyncRetries = 3;
  static const Duration backgroundSyncInterval = Duration(minutes: 15);
  static const Duration offlineSyncTimeout = Duration(seconds: 30);

  static const Duration defaultApiTimeout = Duration(seconds: 15);
  static const Duration longApiTimeout = Duration(seconds: 30);
  static const Duration shortApiTimeout = Duration(seconds: 10);

  static const int maxApiRetries = 3;
  static const Duration apiRetryDelay = Duration(seconds: 2);

  static const double profileImageSize = 80.0;
  static const double smallProfileImageSize = 40.0;
  static const double largeProfileImageSize = 120.0;

  static const double eventImageMaxWidth = 800.0;
  static const double eventImageMaxHeight = 600.0;

  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String instagramUsernameRegex = r'^[a-zA-Z0-9._]{1,30}$';

  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;
  static const bool enableCacheLogs = false;

  static const String defaultLanguage = 'es';
  static const String defaultCountryCode = 'ES';
  static const String defaultTimezone = 'Europe/Madrid';

  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';

  static const String actionChoiceThis = 'this';
  static const String actionChoiceSeries = 'series';
}

enum Environment { development, staging, production }

class AppConfig {
  static Environment get currentEnvironment {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    switch (env) {
      case 'staging':
        return Environment.staging;
      case 'production':
        return Environment.production;
      default:
        return Environment.development;
    }
  }

  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://localhost:8001';
      case Environment.staging:
        return 'https://staging-api.eventypop.com';
      case Environment.production:
        return 'https://api.eventypop.com';
    }
  }

  static bool get enableDebugLogs => currentEnvironment != Environment.production;
  static bool get enableCrashReporting => currentEnvironment == Environment.production;
  static bool get enableAnalytics => currentEnvironment == Environment.production;

  static Duration get apiTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return const Duration(seconds: 60);
      case Environment.staging:
        return const Duration(seconds: 30);
      case Environment.production:
        return AppConstants.defaultApiTimeout;
    }
  }

  static Duration get cacheExpiry {
    switch (currentEnvironment) {
      case Environment.development:
        return const Duration(minutes: 5);
      case Environment.staging:
        return const Duration(minutes: 15);
      case Environment.production:
        return AppConstants.userCacheExpiry;
    }
  }
}
