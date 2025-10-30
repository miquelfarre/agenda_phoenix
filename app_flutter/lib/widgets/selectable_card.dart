import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import '../widgets/user_group_avatar.dart';

class SelectableCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onChanged;

  const SelectableCard({super.key, required this.title, this.subtitle, required this.icon, required this.color, required this.selected, required this.onTap, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformWidgets.isIOS;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isIOS ? 16.0 : 8.0, vertical: 4.0),
      decoration: AppStyles.cardDecoration,
      child: GestureDetector(
        key: key != null ? Key('${key.toString()}_card_tap') : null,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserGroupAvatar(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppStyles.cardSubtitle.copyWith(fontSize: 12, color: AppStyles.grey600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                key: key != null ? Key('${key.toString()}_checkbox_tap') : null,
                onTap: () => onChanged?.call(!selected),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: selected ? AppStyles.primary600 : AppStyles.grey600, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    color: selected ? AppStyles.primary600 : AppStyles.transparent,
                  ),
                  child: selected ? PlatformWidgets.platformIcon(CupertinoIcons.check_mark, size: 16, color: AppStyles.white) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
