import 'package:flutter/widgets.dart';
import 'package:eventypop/screens/access_denied_screen.dart';
import 'package:eventypop/screens/home_screen.dart';
import 'package:eventypop/screens/splash_screen.dart';
import 'package:eventypop/services/unified_user_service.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/widgets/adaptive_scaffold.dart';

class UserTypeChecker extends StatefulWidget {
  final String env;

  const UserTypeChecker({super.key, required this.env});

  @override
  State<UserTypeChecker> createState() => _UserTypeCheckerState();
}

class _UserTypeCheckerState extends State<UserTypeChecker> {
  bool _isLoading = true;
  bool _isPublicUser = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    try {
      final isPublic = await UnifiedUserService.isCurrentUserPublic();
      if (mounted) {
        setState(() {
          _isPublicUser = isPublic;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublicUser = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final l10n = context.l10n;
      return AdaptivePageScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlatformWidgets.platformLoadingIndicator(),
              const SizedBox(height: 20),
              Text(l10n.verifyingAccess),
            ],
          ),
        ),
      );
    }

    if (_isPublicUser) {
      return AccessDeniedScreen();
    }

    return SplashScreen(nextScreen: HomeScreen(env: widget.env));
  }
}
