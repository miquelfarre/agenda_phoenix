import 'package:flutter/cupertino.dart';
import 'package:eventypop/models/ui/city.dart';
import 'package:eventypop/services/city_service.dart';
import 'package:eventypop/services/country_service.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';

typedef CitySelected = void Function(City city);

class CitySearchPickerModal extends StatefulWidget {
  final String? initialCountryCode;
  final CitySelected onSelected;

  const CitySearchPickerModal({
    super.key,
    this.initialCountryCode,
    required this.onSelected,
  });

  @override
  State<CitySearchPickerModal> createState() => _CitySearchPickerModalState();
}

class _CitySearchPickerModalState extends State<CitySearchPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  List<City> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.length < 3) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await CityService.searchCities(q);
      final filtered = widget.initialCountryCode != null
          ? res
                .where((c) => c.countryCode == widget.initialCountryCode)
                .toList()
          : res;
      setState(() {
        _results = filtered;
      });
    } catch (_) {
      setState(() {
        _results = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _flagFor(String code) {
    final country = CountryService.getCountryByCode(code);
    return country?.flag ?? context.l10n.worldFlag;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (PlatformDetection.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.searchCity),
          leading: AdaptiveButton(
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
                  controller: _searchController,
                  placeholder: l10n.citySearchPlaceholder,
                  onChanged: (v) => _search(v),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: PlatformWidgets.platformIcon(CupertinoIcons.search),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: PlatformWidgets.platformLoadingIndicator())
                    : (_results.isEmpty
                          ? const SizedBox.shrink()
                          : ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final city = _results[index];
                                return PlatformWidgets.platformListTile(
                                  leading: Text(
                                    _flagFor(city.countryCode),
                                    style: AppStyles.headlineSmall.copyWith(
                                      fontSize: 24,
                                    ),
                                  ),
                                  title: Text(city.name),
                                  subtitle: Text(
                                    l10n.countryCodeDotTimezone(
                                      city.countryCode,
                                      city.timezone ?? '',
                                    ),
                                    style: AppStyles.cardSubtitle.copyWith(
                                      color: AppStyles.grey600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onTap: () {
                                    widget.onSelected(city);
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            )),
              ),
            ],
          ),
        ),
      );
    }

    final modalHeight = MediaQuery.of(context).size.height * 0.8;
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
                        l10n.searchCity,
                        style: AppStyles.cardTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AdaptiveButton(
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
                  controller: _searchController,
                  hintText: l10n.citySearchPlaceholder,
                  prefixIcon: PlatformWidgets.platformIcon(
                    CupertinoIcons.search,
                    size: 20,
                  ),
                  onChanged: (v) => _search(v),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: PlatformWidgets.platformLoadingIndicator())
                : (_results.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final city = _results[index];
                            return PlatformWidgets.platformListTile(
                              leading: Text(
                                _flagFor(city.countryCode),
                                style: AppStyles.headlineSmall.copyWith(
                                  fontSize: 24,
                                ),
                              ),
                              title: Text(city.name),
                              subtitle: Text(
                                l10n.countryCodeDotTimezone(
                                  city.countryCode,
                                  city.timezone ?? '',
                                ),
                                style: AppStyles.cardSubtitle.copyWith(
                                  color: AppStyles.grey600,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                widget.onSelected(city);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        )),
          ),
        ],
      ),
    );
  }
}
