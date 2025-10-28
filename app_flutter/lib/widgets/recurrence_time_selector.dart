import 'package:flutter/material.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/selector_option.dart';
import 'horizontal_selector_widget.dart';

class RecurrenceTimeSelector extends StatelessWidget {
  final TimeOfDay? initialTime;

  final Function(TimeOfDay time) onSelected;

  final int minuteInterval;

  final int startHour;

  final int endHour;

  final String? label;

  final IconData? icon;

  const RecurrenceTimeSelector({
    super.key,
    this.initialTime,
    required this.onSelected,
    this.minuteInterval = 5,
    this.startHour = 0,
    this.endHour = 23,
    this.label,
    this.icon,
  }) : assert(minuteInterval > 0 && minuteInterval <= 60),
       assert(startHour >= 0 && startHour <= 23),
       assert(endHour >= 0 && endHour <= 23),
       assert(startHour <= endHour);

  List<SelectorOption<TimeOfDay>> _generateTimeOptions() {
    final options = <SelectorOption<TimeOfDay>>[];

    for (int hour = startHour; hour <= endHour; hour++) {
      for (int minute = 0; minute < 60; minute += minuteInterval) {
        final time = TimeOfDay(hour: hour, minute: minute);
        final isSelected =
            initialTime != null &&
            time.hour == initialTime!.hour &&
            time.minute == initialTime!.minute;

        options.add(
          SelectorOption<TimeOfDay>(
            value: time,
            displayText: _formatTime24Hour(time),
            isSelected: isSelected,
            isEnabled: true,
          ),
        );
      }
    }

    return options;
  }

  String _formatTime24Hour(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return HorizontalSelectorWidget<TimeOfDay>(
      options: _generateTimeOptions(),
      onSelected: onSelected,
      label: label ?? 'Hora',
      icon: icon ?? Icons.access_time,
      autoScrollToSelected: true,
      emptyMessage: context.l10n.noTimeOptionsAvailable,
    );
  }
}
