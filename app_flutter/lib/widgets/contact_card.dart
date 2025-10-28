import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../models/user.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'user_avatar.dart';

class ContactCard extends StatelessWidget {
  final User contact;
  final VoidCallback onTap;

  const ContactCard({super.key, required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformDetection.isIOS;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isIOS ? 16.0 : 8.0, vertical: 4.0),
      decoration: AppStyles.cardDecoration,
      child: GestureDetector(
        key: Key('contact_card_tap_${contact.id}'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatar(user: contact, radius: 32.5, showOnlineIndicator: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName.isNotEmpty ? contact.displayName : context.l10n.unknownUser,
                      style: AppStyles.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (contact.displaySubtitle?.isNotEmpty == true)
                      Text(
                        contact.displaySubtitle ?? '',
                        style: AppStyles.cardSubtitle.copyWith(color: AppStyles.grey600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PlatformWidgets.platformIcon(CupertinoIcons.chevron_right, color: AppStyles.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
