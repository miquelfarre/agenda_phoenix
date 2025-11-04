import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'adaptive/adaptive_button.dart';

class EventDetailActions extends StatelessWidget {
  final bool isEventOwner;
  final bool? canInvite;
  final VoidCallback? onEdit;
  final VoidCallback? onInvite;

  const EventDetailActions({super.key, required this.isEventOwner, this.canInvite, this.onEdit, this.onInvite});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool shouldShowInvite = canInvite ?? isEventOwner;

    return Column(
      children: [
        if (shouldShowInvite) ...[
          SizedBox(
            width: double.infinity,
            child: AdaptiveButton(
              config: AdaptiveButtonConfig.primary(),
              text: l10n.inviteUsers,
              icon: CupertinoIcons.person_add,
              onPressed: () {
                onInvite?.call();
              },
            ),
          ),
        ],
        if (shouldShowInvite && isEventOwner) const SizedBox(height: 12),
        if (isEventOwner) ...[
          SizedBox(
            width: double.infinity,
            child: AdaptiveButton(key: const Key('event_detail_edit_button'), config: AdaptiveButtonConfig.primary(), text: l10n.editEvent, icon: CupertinoIcons.pencil, onPressed: onEdit),
          ),
        ],
      ],
    );
  }
}
