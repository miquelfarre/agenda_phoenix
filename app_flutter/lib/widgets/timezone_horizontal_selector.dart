import 'package:flutter/material.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/ui/country.dart';
import '../models/ui/selector_option.dart';
import '../services/country_service.dart';
import '../services/timezone_service.dart';
import 'horizontal_selector_widget.dart';

class TimezoneHorizontalSelector extends StatefulWidget {
  final Country? initialCountry;

  final String? initialCity;

  final String? initialTimezone;

  final Function(Country country, String timezone, String? city) onChanged;

  const TimezoneHorizontalSelector({
    super.key,
    this.initialCountry,
    this.initialCity,
    this.initialTimezone,
    required this.onChanged,
  });

  @override
  State<TimezoneHorizontalSelector> createState() =>
      _TimezoneHorizontalSelectorState();
}

class _TimezoneHorizontalSelectorState
    extends State<TimezoneHorizontalSelector> {
  Country? _selectedCountry;
  String? _selectedTimezone;
  List<Country> _allCountries = [];

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _selectedTimezone = widget.initialTimezone;
    _loadCountries();
  }

  void _loadCountries() {
    _allCountries = CountryService.getAllCountries();
  }

  List<SelectorOption<Country>> _getCountryOptions() {
    return _allCountries.map((country) {
      return SelectorOption<Country>(
        value: country,
        displayText: '${country.flag} ${country.name}',
        isSelected: _selectedCountry?.code == country.code,
        isEnabled: true,
      );
    }).toList();
  }

  List<SelectorOption<String>> _getTimezoneOptions() {
    if (_selectedCountry == null) return [];

    return _selectedCountry!.timezones.map((timezone) {
      String gmtOffset = '';
      try {
        gmtOffset = TimezoneService.getCurrentOffset(timezone);
      } catch (e) {
        gmtOffset = '';
      }

      String cityName = timezone.split('/').last.replaceAll('_', ' ');

      return SelectorOption<String>(
        value: timezone,
        displayText: cityName,
        subtitle: gmtOffset,
        isSelected: _selectedTimezone == timezone,
        isEnabled: true,
      );
    }).toList();
  }

  void _onCountrySelected(Country country) {
    setState(() {
      _selectedCountry = country;
      _selectedTimezone = country.primaryTimezone;
    });
    widget.onChanged(country, country.primaryTimezone, null);
  }

  void _onTimezoneSelected(String timezone) {
    if (_selectedCountry != null) {
      String cityName = timezone.split('/').last.replaceAll('_', ' ');

      setState(() {
        _selectedTimezone = timezone;
      });
      widget.onChanged(_selectedCountry!, timezone, cityName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HorizontalSelectorWidget<Country>(
          options: _getCountryOptions(),
          onSelected: _onCountrySelected,
          label: context.l10n.country,
          icon: Icons.flag,
          emptyMessage: context.l10n.noCountriesAvailable,
        ),

        const SizedBox(height: 12),

        if (_selectedCountry != null) ...[
          HorizontalSelectorWidget<String>(
            options: _getTimezoneOptions(),
            onSelected: _onTimezoneSelected,
            label: context.l10n.cityOrTimezone,
            icon: Icons.location_city,
            emptyMessage: context.l10n.noTimezonesAvailable,
          ),
        ],
      ],
    );
  }
}
