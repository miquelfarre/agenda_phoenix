import 'package:flutter/widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';

class UserGroupAvatar extends StatelessWidget {
  final IconData icon;
  final Color color;
  const UserGroupAvatar({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(color, 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.colorWithOpacity(color, 0.30), width: 1.2),
      ),
      child: PlatformWidgets.platformIcon(icon, color: color, size: 28),
    );
  }
}
