import 'package:flutter/cupertino.dart';
import '../widgets/adaptive_scaffold.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/l10n/app_localizations.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdaptivePageScaffold(key: const Key('access_denied_screen_scaffold'), title: l10n.error, body: _buildContent(l10n));
  }

  Widget _buildContent(AppLocalizations l10n) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppStyles.grey400, AppStyles.grey600, AppStyles.grey700]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppStyles.colorWithOpacity(AppStyles.black87, 0.1), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: PlatformWidgets.platformIcon(CupertinoIcons.clear_thick, color: AppStyles.white, size: 60),
              ),

              const SizedBox(height: 32),

              Text(
                l10n.accessDeniedTitle,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppStyles.black87, letterSpacing: -0.5, decoration: TextDecoration.none),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                l10n.accessDeniedMessagePrimary,
                style: TextStyle(fontSize: 16, color: AppStyles.grey700, fontWeight: FontWeight.w500, decoration: TextDecoration.none, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                l10n.accessDeniedMessageSecondary,
                style: TextStyle(fontSize: 14, color: AppStyles.grey600, decoration: TextDecoration.none, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppStyles.blueShade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppStyles.blueShade100),
                ),
                child: Row(
                  children: [
                    PlatformWidgets.platformIcon(CupertinoIcons.info, color: AppStyles.blue600, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.contactAdminIfError,
                        style: TextStyle(fontSize: 14, color: AppStyles.blue600, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
