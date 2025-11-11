import 'package:flutter/widgets.dart';
import '../models/domain/event.dart';
import '../ui/styles/app_styles.dart';
import '../utils/event_date_utils.dart';

/// A widget that displays a group of events for a specific date
///
/// Shows a formatted date header followed by a list of event widgets.
/// The date is formatted in a localized, human-readable format.
class EventDateSection extends StatelessWidget {
  /// The date group data containing 'date' (String) and 'events' (List of Event)
  final Map<String, dynamic> dateGroup;

  /// Builder function to create a widget for each event
  final Widget Function(Event event) eventBuilder;

  /// Optional padding around the section
  final EdgeInsetsGeometry? padding;

  /// Optional spacing after the section
  final double? bottomSpacing;

  const EventDateSection({
    super.key,
    required this.dateGroup,
    required this.eventBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0),
    this.bottomSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = dateGroup['date'] as String;
    final events = dateGroup['events'] as List<Event>;
    final date = EventDateUtils.parseDateString(dateStr);
    final formattedDate = EventDateUtils.formatEventDate(context, date);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              formattedDate,
              style: AppStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppStyles.grey700,
              ),
            ),
          ),
          ...events.map(eventBuilder),
          if (bottomSpacing != null) SizedBox(height: bottomSpacing!),
        ],
      ),
    );
  }
}
