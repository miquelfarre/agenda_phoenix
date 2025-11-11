import 'package:flutter/material.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/domain/calendar.dart';
import '../models/ui/selector_option.dart';
import 'horizontal_selector_widget.dart';

class CalendarHorizontalSelector extends StatelessWidget {
  final List<Calendar> calendars;

  final int? selectedCalendarId;

  final Function(int calendarId) onSelected;

  final bool isDisabled;

  final String? label;

  const CalendarHorizontalSelector({
    super.key,
    required this.calendars,
    this.selectedCalendarId,
    required this.onSelected,
    this.isDisabled = false,
    this.label,
  });

  List<SelectorOption<Calendar>> _transformCalendars() {
    return calendars.map((calendar) {
      return SelectorOption<Calendar>(
        value: calendar,
        displayText: calendar.name,
        highlightColor: Colors.blue,
        isSelected: calendar.id == selectedCalendarId,
        isEnabled: !isDisabled,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final options = _transformCalendars();

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: HorizontalSelectorWidget<Calendar>(
        options: options,
        onSelected: (calendar) {
          if (!isDisabled) {
            onSelected(calendar.id);
          }
        },
        label: label,
        icon: Icons.calendar_today,
        emptyMessage: context.l10n.noCalendarsAvailable,
      ),
    );
  }
}
