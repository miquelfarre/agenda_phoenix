import 'package:flutter/widgets.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import '../widgets/event_card/event_card_config.dart';

typedef EventTapCallback = void Function(Event event);
typedef EventActionCallback = Future<void> Function(Event event, {bool shouldNavigate});

class EventListItem extends StatelessWidget {
  final Event event;
  final EventTapCallback onTap;
  final EventActionCallback? onDelete;
  final bool navigateAfterDelete;
  final bool hideInvitationStatus;
  final bool showDate;
  final bool showNewBadge;

  const EventListItem({super.key, required this.event, required this.onTap, this.onDelete, this.navigateAfterDelete = false, this.hideInvitationStatus = false, this.showDate = false, this.showNewBadge = true});

  @override
  Widget build(BuildContext context) {
    return EventCard(
      key: Key('event_list_item_${event.id}'),
      event: event,
      onTap: () => onTap(event),
      config: EventCardConfig(onDelete: onDelete, navigateAfterDelete: navigateAfterDelete, showNewBadge: showNewBadge, showInvitationStatus: !hideInvitationStatus, showDate: showDate),
    );
  }
}
