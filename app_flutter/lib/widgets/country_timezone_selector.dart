import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:flutter/cupertino.dart';
import '../models/country.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import '../models/city.dart';
import '../services/country_service.dart';
import '../services/timezone_service.dart';
import 'package:eventypop/widgets/pickers/country_picker.dart';
import 'package:eventypop/widgets/pickers/city_search_picker.dart';

class CountryTimezoneSelector extends StatefulWidget {
  final Country? initialCountry;
  final String? initialTimezone;
  final String? initialCity;
  final Function(Country country, String timezone, String? city) onChanged;
  final bool showOffset;
  final String? label;

  const CountryTimezoneSelector({
    super.key,
    this.initialCountry,
    this.initialTimezone,
    this.initialCity,
    required this.onChanged,
    this.showOffset = true,
    this.label,
  });

  @override
  State<CountryTimezoneSelector> createState() =>
      _CountryTimezoneSelectorState();
}

class _CountryTimezoneSelectorState extends State<CountryTimezoneSelector> {
  Country? _selectedCountry;
  String? _selectedTimezone;
  String? _selectedCity;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _selectedTimezone =
        widget.initialTimezone ?? widget.initialCountry?.primaryTimezone;
    _selectedCity = widget.initialCity;
  }

  @override
  void didUpdateWidget(CountryTimezoneSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialCountry != oldWidget.initialCountry ||
        widget.initialTimezone != oldWidget.initialTimezone ||
        widget.initialCity != oldWidget.initialCity) {
      setState(() {
        _selectedCountry = widget.initialCountry;
        _selectedTimezone =
            widget.initialTimezone ?? widget.initialCountry?.primaryTimezone;
        _selectedCity = widget.initialCity;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCountry(Country country) {
    setState(() {
      _selectedCountry = country;
      _selectedTimezone = country.primaryTimezone;
      _selectedCity = null;
    });
    widget.onChanged(country, country.primaryTimezone, null);
  }

  void _selectTimezone(String timezone) {
    if (_selectedCountry != null) {
      setState(() {
        _selectedTimezone = timezone;
      });
      widget.onChanged(_selectedCountry!, timezone, _selectedCity);
    }
  }

  Future<void> _showCountryPicker() async {
    _searchController.clear();

    final isIOS = PlatformDetection.isIOS;

    if (isIOS) {
      await _showCupertinoCountryPicker();
    } else {
      await _showMaterialCountryPicker();
    }
  }

  Future<void> _showCupertinoCountryPicker() async {
    await PlatformNavigation.presentModal<void>(
      context,
      CountryPickerModal(
        initialCountry: _selectedCountry,
        showOffset: widget.showOffset,
        searchController: _searchController,
        onSelected: (country) => _selectCountry(country),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showMaterialCountryPicker() async {
    await PlatformNavigation.presentModal<void>(
      context,
      CountryPickerModal(
        initialCountry: _selectedCountry,
        showOffset: widget.showOffset,
        searchController: _searchController,
        onSelected: (country) => _selectCountry(country),
      ),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> _showTimezonePicker() async {
    if (_selectedCountry == null || _selectedCountry!.timezones.length <= 1) {
      return;
    }

    final isIOS = PlatformDetection.isIOS;

    if (isIOS) {
      await _showCupertinoTimezonePicker();
    } else {
      await _showMaterialTimezonePicker();
    }
  }

  Future<void> _showCupertinoTimezonePicker() async {
    if (_selectedCountry == null) return;

    final l10n = context.l10n;
    final safeContext = context;

    try {
      final choice =
          await PlatformDialogHelpers.showPlatformActionSheet<String>(
            safeContext,
            title: l10n.selectTimezoneForCountry(_selectedCountry!.name),
            actions: _selectedCountry!.timezones.map((timezone) {
              final offset = TimezoneService.getCurrentOffset(timezone);
              return PlatformAction(
                text: l10n.timezoneWithOffset(timezone, offset),
                value: timezone,
              );
            }).toList(),
            cancelText: l10n.cancel,
          );

      if (choice != null) {
        _selectTimezone(choice);
      }
    } catch (_) {}
  }

  Future<void> _showMaterialTimezonePicker() async {
    final l10n = context.l10n;
    final safeContext = context;

    try {
      final choice =
          await PlatformDialogHelpers.showPlatformActionSheet<String>(
            safeContext,
            title: l10n.selectTimezoneForCountry(_selectedCountry!.name),
            actions: _selectedCountry!.timezones.map((timezone) {
              final offset = TimezoneService.getCurrentOffset(timezone);
              return PlatformAction(
                text: l10n.timezoneWithOffset(timezone, offset),
                value: timezone,
              );
            }).toList(),
            cancelText: l10n.cancel,
          );

      if (choice != null) {
        _selectTimezone(choice);
      }
    } catch (_) {}
  }

  Future<void> _showCityPicker() async {
    final isIOS = PlatformDetection.isIOS;

    if (isIOS) {
      await _showCupertinoCitySearchPicker();
    } else {
      await _showMaterialCitySearchPicker();
    }
  }

  Future<void> _showCupertinoCitySearchPicker() async {
    await PlatformNavigation.presentModal<void>(
      context,
      CitySearchPickerModal(
        initialCountryCode: _selectedCountry?.code,
        onSelected: (city) => _selectCityWithTimezone(city),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showMaterialCitySearchPicker() async {
    await PlatformNavigation.presentModal<void>(
      context,
      CitySearchPickerModal(
        initialCountryCode: _selectedCountry?.code,
        onSelected: (city) => _selectCityWithTimezone(city),
      ),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _selectCityWithTimezone(City city) {
    Country? country = _selectedCountry;

    if (city.countryCode != _selectedCountry?.code) {
      country = CountryService.getCountryByCode(city.countryCode);
    }

    setState(() {
      _selectedCountry = country;
      _selectedCity = city.name;
      _selectedTimezone =
          city.timezone ?? country?.primaryTimezone ?? context.l10n.utc;
    });

    if (country != null) {
      widget.onChanged(country, _selectedTimezone!, city.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformDetection.isIOS;
    String offset = '';
    if (_selectedCountry != null &&
        widget.showOffset &&
        _selectedTimezone != null) {
      try {
        offset = TimezoneService.getCurrentOffset(_selectedTimezone!);
      } catch (e) {
        offset = '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppStyles.bodyText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppStyles.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],

        Container(
          decoration: BoxDecoration(
            color: AppStyles.grey50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppStyles.grey200, width: 1),
          ),
          child: isIOS
              ? CupertinoListTile(
                  leading: _selectedCountry != null
                      ? Text(
                          _selectedCountry!.flag,
                          style: AppStyles.headlineSmall.copyWith(fontSize: 24),
                        )
                      : PlatformWidgets.platformIcon(CupertinoIcons.globe),
                  title: Text(
                    _selectedCountry?.name ?? l10n.selectCountryTimezone,
                  ),
                  subtitle: widget.showOffset && _selectedCountry != null
                      ? Text(
                          l10n.timezoneWithOffset(
                            _selectedCountry!.primaryTimezone,
                            offset,
                          ),
                          style: AppStyles.cardSubtitle.copyWith(
                            color: AppStyles.grey600,
                            fontSize: 14,
                          ),
                        )
                      : null,
                  trailing: PlatformWidgets.platformIcon(
                    CupertinoIcons.forward,
                  ),
                  onTap: _showCountryPicker,
                )
              : _buildPlatformTile(
                  leading: _selectedCountry != null
                      ? Text(
                          _selectedCountry!.flag,
                          style: AppStyles.headlineSmall.copyWith(fontSize: 24),
                        )
                      : PlatformWidgets.platformIcon(CupertinoIcons.globe),
                  title: Text(
                    _selectedCountry?.name ?? l10n.selectCountryTimezone,
                  ),
                  subtitle: widget.showOffset && _selectedCountry != null
                      ? Text(
                          l10n.timezoneWithOffset(
                            _selectedCountry!.primaryTimezone,
                            offset,
                          ),
                          style: AppStyles.cardSubtitle.copyWith(
                            color: AppStyles.grey600,
                            fontSize: 14,
                          ),
                        )
                      : null,
                  trailing: PlatformWidgets.platformIcon(
                    CupertinoIcons.forward,
                  ),
                  onTap: _showCountryPicker,
                ),
        ),

        if (_selectedCountry != null) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppStyles.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppStyles.grey200, width: 1),
            ),
            child: isIOS
                ? CupertinoListTile(
                    leading: PlatformWidgets.platformIcon(
                      CupertinoIcons.location_solid,
                    ),
                    title: Text(l10n.city),
                    subtitle: Text(
                      _selectedCity ?? l10n.select,
                      style: AppStyles.cardSubtitle.copyWith(
                        color: _selectedCity != null
                            ? AppStyles.grey600
                            : AppStyles.grey400,
                        fontSize: 14,
                      ),
                    ),
                    trailing: PlatformWidgets.platformIcon(
                      CupertinoIcons.forward,
                    ),
                    onTap: _showCityPicker,
                  )
                : _buildPlatformTile(
                    leading: PlatformWidgets.platformIcon(
                      CupertinoIcons.location_solid,
                    ),
                    title: Text(l10n.city),
                    subtitle: Text(
                      _selectedCity ?? l10n.select,
                      style: AppStyles.cardSubtitle.copyWith(
                        color: _selectedCity != null
                            ? AppStyles.grey600
                            : AppStyles.grey400,
                        fontSize: 14,
                      ),
                    ),
                    trailing: PlatformWidgets.platformIcon(
                      CupertinoIcons.forward,
                    ),
                    onTap: _showCityPicker,
                  ),
          ),
        ],

        if (_selectedCountry != null &&
            _selectedCountry!.timezones.length > 1) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppStyles.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppStyles.grey200, width: 1),
            ),
            child: isIOS
                ? CupertinoListTile(
                    leading: PlatformWidgets.platformIcon(CupertinoIcons.time),
                    title: Text(l10n.specificTimezone),
                    subtitle: Text(
                      _selectedTimezone ?? l10n.select,
                      style: AppStyles.cardSubtitle.copyWith(
                        color: AppStyles.grey600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: PlatformWidgets.platformIcon(
                      CupertinoIcons.forward,
                    ),
                    onTap: _showTimezonePicker,
                  )
                : _buildPlatformTile(
                    leading: PlatformWidgets.platformIcon(CupertinoIcons.time),
                    title: Text(l10n.specificTimezone),
                    subtitle: Text(
                      _selectedTimezone ?? l10n.select,
                      style: AppStyles.cardSubtitle.copyWith(
                        color: AppStyles.grey600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: PlatformWidgets.platformIcon(
                      CupertinoIcons.forward,
                    ),
                    onTap: _showTimezonePicker,
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlatformTile({
    Widget? leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(width: 36, child: Center(child: leading)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(style: AppStyles.bodyText, child: title),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: AppStyles.cardSubtitle,
                        child: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
        ),
      ),
    );
  }
}
