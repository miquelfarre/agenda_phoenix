import 'package:flutter/cupertino.dart';

import '../../models/country.dart';
import '../../services/country_service.dart';
import '../../services/timezone_service.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../adaptive/adaptive_button.dart';

typedef CountrySelected = void Function(Country country);

class CountryPickerModal extends StatefulWidget {
  final Country? initialCountry;
  final bool showOffset;
  final TextEditingController? searchController;
  final CountrySelected onSelected;

  const CountryPickerModal({
    super.key,
    this.initialCountry,
    this.showOffset = true,
    this.searchController,
    required this.onSelected,
  });

  @override
  State<CountryPickerModal> createState() => _CountryPickerModalState();
}

class _CountryPickerModalState extends State<CountryPickerModal> {
  late TextEditingController _controller;
  List<Country> _filtered = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.searchController ?? TextEditingController();
    _filtered = CountryService.getAllCountries();
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _filtered = CountryService.searchCountries(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final modalHeight = MediaQuery.of(context).size.height * 0.8;

    if (PlatformDetection.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.selectCountryTimezone),
          leading: AdaptiveButton(
            key: const Key('country_picker_cancel_button'),
            config: AdaptiveButtonConfig.secondary(),
            text: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoTextField(
                  controller: _controller,
                  placeholder: l10n.search,
                  onChanged: _onSearch,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: PlatformWidgets.platformIcon(CupertinoIcons.search),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final country = _filtered[index];
                    final offset = widget.showOffset
                        ? TimezoneService.getCurrentOffset(
                            country.primaryTimezone,
                          )
                        : '';

                    return PlatformWidgets.platformListTile(
                      leading: Text(
                        country.flag,
                        style: AppStyles.headlineSmall.copyWith(fontSize: 24),
                      ),
                      title: Text(country.name),
                      subtitle: widget.showOffset
                          ? Text(
                              l10n.timezoneWithOffset(
                                country.primaryTimezone,
                                offset,
                              ),
                              style: AppStyles.cardSubtitle.copyWith(
                                color: AppStyles.grey600,
                                fontSize: 14,
                              ),
                            )
                          : Text(
                              country.primaryTimezone,
                              style: AppStyles.cardSubtitle.copyWith(
                                color: AppStyles.grey600,
                                fontSize: 14,
                              ),
                            ),
                      onTap: () {
                        widget.onSelected(country);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: modalHeight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.selectCountryTimezone,
                        style: AppStyles.cardTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AdaptiveButton(
                      key: const Key('country_picker_close_button'),
                      config: const AdaptiveButtonConfig(
                        variant: ButtonVariant.icon,
                        size: ButtonSize.medium,
                        fullWidth: false,
                        iconPosition: IconPosition.only,
                      ),
                      icon: CupertinoIcons.clear,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                PlatformWidgets.platformTextField(
                  controller: _controller,
                  hintText: l10n.search,
                  prefixIcon: PlatformWidgets.platformIcon(
                    CupertinoIcons.search,
                  ),
                  onChanged: _onSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final country = _filtered[index];
                final offset = widget.showOffset
                    ? TimezoneService.getCurrentOffset(country.primaryTimezone)
                    : '';

                return PlatformWidgets.platformListTile(
                  leading: Text(
                    country.flag,
                    style: AppStyles.headlineSmall.copyWith(fontSize: 24),
                  ),
                  title: Text(country.name),
                  subtitle: widget.showOffset
                      ? Text(
                          l10n.timezoneWithOffset(
                            country.primaryTimezone,
                            offset,
                          ),
                          style: AppStyles.cardSubtitle.copyWith(
                            color: AppStyles.grey600,
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          country.primaryTimezone,
                          style: AppStyles.cardSubtitle.copyWith(
                            color: AppStyles.grey600,
                            fontSize: 14,
                          ),
                        ),
                  onTap: () {
                    widget.onSelected(country);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
