import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../core/state/app_state.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = PlatformDetection.isIOS;
    final localeNotifier = ref.read(localeProvider.notifier);
    final l10n = context.l10n;

    final availableLanguages = localeNotifier.getAvailableLanguages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            l10n.language,
            style: AppStyles.cardTitle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppStyles.grey700,
            ),
          ),
        ),
        ...availableLanguages.map((lang) {
          final locale = lang['locale'] as Locale;
          final name = lang['name'] as String;
          final flag = lang['flag'] as String;
          final isSelected = ref.watch(localeProvider) == locale;

          return PlatformWidgets.platformListTile(
            leading: Text(
              flag,
              style: AppStyles.headlineSmall.copyWith(fontSize: 24),
            ),
            title: Text(
              name,
              style: AppStyles.cardTitle.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: AppStyles.black87,
              ),
            ),
            trailing: isSelected
                ? PlatformWidgets.platformIcon(
                    CupertinoIcons.check_mark,
                    color: isIOS
                        ? CupertinoColors.activeBlue.resolveFrom(context)
                        : AppStyles.blue600,
                    size: 20,
                  )
                : null,
            onTap: () => _changeLanguage(context, ref, locale),
          );
        }),
        PlatformWidgets.platformDivider(),
      ],
    );
  }

  void _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
  ) async {
    final localeNotifier = ref.read(localeProvider.notifier);
    final l10n = context.l10n;

    try {
      PlatformDialogHelpers.showPlatformLoadingDialog(
        context,
        message: l10n.updating,
      );
    } catch (e) {
      return;
    }

    try {
      await localeNotifier.setLocale(locale);

      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              final newL10n = context.l10n;
              PlatformDialogHelpers.showSnackBar(
                context: context,
                message: newL10n.settingsUpdated,
              );
            } else {}
          });
        } catch (_) {}
      } else {}
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();

          final errL10n = context.l10n;
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: errL10n.errorUpdatingSettings,
            isError: true,
          );
        } catch (_) {}
      } else {}
    }
  }
}
