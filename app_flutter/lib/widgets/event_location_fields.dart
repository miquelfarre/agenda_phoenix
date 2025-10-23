import 'package:flutter/widgets.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../services/country_service.dart';
import 'country_timezone_selector.dart';

class EventLocationFields extends StatelessWidget {
  final String? city;
  final String? countryCode;
  final String? timezone;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onTimezoneChanged;
  final bool enabled;
  final bool isRequired;

  const EventLocationFields({
    super.key,
    this.city,
    this.countryCode,
    this.timezone,
    required this.onCityChanged,
    required this.onCountryChanged,
    required this.onTimezoneChanged,
    this.enabled = true,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.eventLocation,
          style: TextStyle(
            fontSize: AppConstants.bodyFontSize,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),

        const SizedBox(height: AppConstants.smallPadding),

        CountryTimezoneSelector(
          initialCountry: countryCode != null
              ? CountryService.getCountryByCode(countryCode!)
              : null,
          initialTimezone: timezone,
          initialCity: city,
          onChanged: (country, timezone, city) {
            onCountryChanged(country.code);
            onTimezoneChanged(timezone);
            if (city != null) onCityChanged(city);
          },
        ),
      ],
    );
  }
}

extension EventLocationFieldsExtension on EventLocationFields {
  bool validate() {
    if (!isRequired) return true;

    return countryCode != null && countryCode!.isNotEmpty;
  }

  bool get isEmpty {
    return (city == null || city!.isEmpty) &&
        (countryCode == null || countryCode!.isEmpty) &&
        (timezone == null || timezone!.isEmpty);
  }

  bool get isNotEmpty => !isEmpty;

  String getLocationSummary(BuildContext context) {
    final parts = <String>[];

    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }

    if (countryCode != null && countryCode!.isNotEmpty) {
      parts.add(countryCode!);
    }

    if (parts.isEmpty) {
      return context.l10n.noLocationSet;
    }

    return parts.join(', ');
  }
}
