import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:eventypop/services/supabase_auth_service.dart';
import 'package:eventypop/screens/login/phone_login_screen.dart';
import 'package:eventypop/widgets/user_type_checker.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/widgets/adaptive_scaffold.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final l10n = context.l10n;
          return AdaptivePageScaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlatformWidgets.platformLoadingIndicator(),
                  const SizedBox(height: 20),
                  Text(l10n.startingEventyPop),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data?.session != null) {
          return UserTypeChecker(env: 'production');
        }

        return PhoneLoginScreen();
      },
    );
  }
}
