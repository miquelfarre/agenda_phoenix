import 'package:flutter/widgets.dart';
import 'package:eventypop/l10n/app_localizations.dart';
import 'package:eventypop/l10n/app_localizations_en.dart';

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEn();
}

extension AppLocalizationsHelpers on AppLocalizations {
  String timezoneWithOffset(String timezone, String offset) {
    if (offset.isEmpty) return timezone;
    return '$timezone ($offset)';
  }
}
