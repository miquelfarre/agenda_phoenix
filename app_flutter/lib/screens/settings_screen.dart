import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/settings_provider.dart';
import '../core/state/app_state.dart' show blockedUsersStreamProvider;
import '../models/app_settings.dart';
import '../services/country_service.dart';
import '../widgets/country_timezone_selector.dart';
import '../widgets/language_selector.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/common/configurable_styled_container.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../services/permission_service.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../widgets/adaptive/adaptive_button.dart';

import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

enum SettingsSection { general, profile, privacy, notifications }

class SettingsScreen extends ConsumerWidget {
  final SettingsSection initialSection;

  const SettingsScreen({
    super.key,
    this.initialSection = SettingsSection.general,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = PlatformDetection.isIOS;
    final l10n = context.l10n;

    return AdaptivePageScaffold(
      key: const Key('settings_screen_scaffold'),
      title: l10n.settings,
      body: _buildBody(context, ref, isIOS: isIOS, l10n: l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required bool isIOS,
    required dynamic l10n,
  }) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const LanguageSelector(),
            const SizedBox(height: 24),

            _buildSectionHeader(
              context: context,
              icon: CupertinoIcons.globe,
              title: l10n.countryAndTimezone,
              subtitle: l10n.defaultSettingsForNewEvents,
            ),

            const SizedBox(height: 24),

            _buildTimezoneSelector(context, settingsAsync, ref, l10n),
            const SizedBox(height: 24),

            _buildBlockedUsersSection(context, l10n),

            const SizedBox(height: 24),

            _buildPermissionsSection(context, l10n),

            const SizedBox(height: 24),

            _buildInfoCard(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ConfigurableStyledContainer.header(
      child: SectionHeader(icon: icon, title: title, subtitle: subtitle),
    );
  }

  Widget _buildPermissionsSection(BuildContext context, dynamic l10n) {
    return ConfigurableStyledContainer.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.lock,
                color: AppStyles.primary600,
              ),
              const SizedBox(width: 8),
              Text(l10n.contactsPermissionRequired, style: AppStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.contactsPermissionInstructions,
            style: AppStyles.bodyTextSmall.copyWith(color: AppStyles.grey700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AdaptiveButton(
                key: const Key('settings_reset_preferences_button'),
                config: AdaptiveButtonConfig.secondary(),
                text: l10n.resetContactsPermissions,
                onPressed: () async {
                  await PermissionService.resetContactsPermissionPreferences();
                  if (context.mounted) {
                    final l10n = context.l10n;
                    PlatformDialogHelpers.showSnackBar(
                      message: l10n.resetPreferences,
                    );
                  }
                },
              ),
              AdaptiveButton(
                key: const Key('settings_open_app_settings_button'),
                config: AdaptiveButtonConfig.secondary(),
                text: l10n.openAppSettings,
                onPressed: () async {
                  await openAppSettings();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, dynamic l10n) {
    return ConfigurableStyledContainer.info(
      child: Row(
        children: [
          PlatformWidgets.platformIcon(
            CupertinoIcons.info,
            color: AppStyles.primary600,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.info,
                  style: AppStyles.cardTitle.copyWith(
                    color: AppStyles.primary800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.syncInfoMessage,
                  style: AppStyles.bodyTextSmall.copyWith(
                    color: AppStyles.primary700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersSection(BuildContext context, dynamic l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final blockedUsersState = ref.watch(blockedUsersStreamProvider);
        final blockedCount = blockedUsersState.when(
          data: (users) => users.length,
          loading: () => 0,
          error: (error, stack) => 0,
        );

        return ConfigurableStyledContainer.card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlatformWidgets.platformIcon(
                    CupertinoIcons.person_badge_minus,
                    color: AppStyles.red600,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.blockedUsers, style: AppStyles.cardTitle),
                  if (blockedCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.grey100,
                        borderRadius: AppStyles.smallRadius,
                      ),
                      child: Text(
                        blockedCount.toString(),
                        style: AppStyles.bodyTextSmall.copyWith(
                          color: AppStyles.red600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.manageBlockedUsersDescription,
                style: AppStyles.bodyTextSmall.copyWith(
                  color: AppStyles.grey700,
                ),
              ),
              const SizedBox(height: 12),
              AdaptiveButton(
                key: const Key('settings_blocked_users_button'),
                config: AdaptiveButtonConfig.secondary(),
                text: l10n.blockedUsers,
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text(l10n.blockedUsers),
                      content: Text(l10n.seriesEditNotAvailable),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(l10n.ok),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimezoneSelector(
    BuildContext context,
    AsyncValue<AppSettings> settingsAsync,
    WidgetRef ref,
    dynamic l10n,
  ) {
    return settingsAsync.when(
      data: (settings) {
        final country = CountryService.getCountryByCode(
          settings.defaultCountryCode,
        );

        return CountryTimezoneSelector(
          initialCountry: country,
          initialTimezone: settings.defaultTimezone,
          initialCity: settings.defaultCity,
          onChanged: (selectedCountry, timezone, city) {
            final updatedSettings = settings.copyWith(
              defaultCountryCode: selectedCountry.code,
              defaultTimezone: timezone,
              defaultCity: city,
            );
            ref
                .read(settingsNotifierProvider.notifier)
                .updateSettings(updatedSettings);
          },
          showOffset: true,
          label: l10n.countryAndTimezone,
        );
      },
      loading: () => ConfigurableStyledContainer.card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
      error: (error, _) => ConfigurableStyledContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading settings: $error',
            style: AppStyles.bodyText.copyWith(color: AppStyles.errorColor),
          ),
        ),
      ),
    );
  }
}
