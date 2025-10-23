import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

class AppDefaults {
  AppDefaults._();

  static const String defaultCountryCode = 'ES';

  static const String defaultTimezone = 'Europe/Madrid';

  static const String defaultCity = 'Madrid';

  static const int invalidUserId = 0;

  static const int defaultEventDurationHours = 1;

  static const int timeRoundingMinutes = 5;

  static const Duration defaultCacheTtl = Duration(minutes: 15);

  static const int defaultMaxCacheSize = 100;

  static const Duration cacheCleanupInterval = Duration(minutes: 10);

  static const Duration defaultNetworkTimeout = Duration(seconds: 30);

  static const int maxRetryAttempts = 3;

  static const Duration retryBaseDelay = Duration(seconds: 2);

  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  static const int maxFileUploadSize = 10 * 1024 * 1024;

  static const int minPasswordLength = 8;

  static const int maxUsernameLength = 50;

  static const int maxEventTitleLength = 200;

  static const int maxEventDescriptionLength = 1000;

  static const String defaultDateFormat = 'dd/MM/yyyy';

  static const String defaultTimeFormat = 'HH:mm';

  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss.SSSZ';

  static const int maxEventsPerPage = 50;

  static const int maxContactsDisplay = 200;

  static const int maxSearchResults = 100;

  static const bool enableDebugLogging = true;

  static const bool enableAnalytics = false;

  static bool isValidUserId(int userId) {
    return userId > invalidUserId;
  }

  static String getSafeUserDisplayName(String? userName, BuildContext context) {
    if (userName == null || userName.trim().isEmpty) {
      return AppLocalizations.of(context)!.guestUser;
    }
    return userName.trim();
  }

  static String getSafeEventTitle(String? title, BuildContext context) {
    if (title == null || title.trim().isEmpty) {
      return AppLocalizations.of(context)!.untitled;
    }
    return title.trim();
  }

  static String getGenericErrorMessage(BuildContext context) {
    return AppLocalizations.of(context)!.unexpectedError;
  }

  static String getNetworkErrorMessage(BuildContext context) {
    return AppLocalizations.of(context)!.connectionError;
  }

  static String getValidationErrorMessage(BuildContext context) {
    return AppLocalizations.of(context)!.validationFailed;
  }

  static Duration getRetryDelay(int attemptNumber) {
    return retryBaseDelay * (attemptNumber * attemptNumber);
  }
}
