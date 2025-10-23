import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../utils/time_of_day.dart';

class EventDateTimeFields extends StatelessWidget {
  final DateTime startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final bool isRecurring;
  final bool enabled;
  final String? startDateLabel;
  final String? endDateLabel;

  const EventDateTimeFields({
    super.key,
    required this.startDate,
    this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.isRecurring = false,
    this.enabled = true,
    this.startDateLabel,
    this.endDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimeSelector(
          label: startDateLabel ?? context.l10n.startDateTime,
          selectedDate: startDate,
          onDateChanged: onStartDateChanged,
          enabled: enabled,
        ),

        if (isRecurring) ...[
          const SizedBox(height: AppConstants.defaultPadding),
          _DateTimeSelector(
            label: endDateLabel ?? context.l10n.endDateTime,
            selectedDate: endDate ?? startDate.add(const Duration(hours: 1)),
            onDateChanged: (date) => onEndDateChanged(date),
            enabled: enabled,
            isEndDate: true,
            minimumDate: startDate,
          ),
        ],
      ],
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool enabled;
  final bool isEndDate;
  final DateTime? minimumDate;

  const _DateTimeSelector({
    required this.label,
    required this.selectedDate,
    required this.onDateChanged,
    this.enabled = true,
    this.isEndDate = false,
    this.minimumDate,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformDetection.isIOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isIOS
              ? AppStyles.bodyText.copyWith(
                  fontSize: AppConstants.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label.resolveFrom(context),
                )
              : AppStyles.bodyText.copyWith(
                  fontSize: AppConstants.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppStyles.black87,
                ),
        ),
        const SizedBox(height: AppConstants.smallPadding / 2),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: _DateButton(
                selectedDate: selectedDate,
                onDateChanged: (date) {
                  final newDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    selectedDate.hour,
                    selectedDate.minute,
                  );
                  onDateChanged(newDateTime);
                },
                enabled: enabled,
                minimumDate: minimumDate,
              ),
            ),

            const SizedBox(width: AppConstants.smallPadding),

            Expanded(
              flex: 1,
              child: _TimeButton(
                selectedTime: TimeOfDay.fromDateTime(selectedDate),
                onTimeChanged: (time) {
                  final newDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    time.hour,
                    time.minute,
                  );
                  onDateChanged(newDateTime);
                },
                enabled: enabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool enabled;
  final DateTime? minimumDate;

  const _DateButton({
    required this.selectedDate,
    required this.onDateChanged,
    this.enabled = true,
    this.minimumDate,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformWidgets.isIOS;
    final dateText = _formatDate(selectedDate, context);

    return Container(
      decoration: BoxDecoration(
        color: AppStyles.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.grey300, width: 1),
      ),
      child: Builder(
        builder: (ctx) => CupertinoButton(
          key: const Key('date_picker_button'),
          onPressed: enabled
              ? () {
                  if (isIOS) {
                    _showCupertinoDatePicker(ctx);
                  } else {
                    _showMaterialDatePicker(ctx);
                  }
                }
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 18,
                color: enabled ? AppStyles.primaryColor : AppStyles.grey500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: enabled ? AppStyles.textColor : AppStyles.grey500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return context.l10n.today;
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return context.l10n.tomorrow;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showCupertinoDatePicker(BuildContext context) {
    PlatformNavigation.presentModal(
      context,
      Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlatformWidgets.platformButton(
                    padding: EdgeInsets.zero,
                    filled: false,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n.done,
                      style: AppStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                minimumDate: minimumDate,
                onDateTimeChanged: onDateChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaterialDatePicker(BuildContext context) async {
    DateTime tempSelected = selectedDate;
    await PlatformNavigation.presentModal(
      context,
      Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlatformWidgets.platformButton(
                    padding: EdgeInsets.zero,
                    filled: false,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDateChanged(tempSelected);
                    },
                    child: Text(
                      context.l10n.done,
                      style: AppStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                minimumDate: minimumDate,
                onDateTimeChanged: (dt) => tempSelected = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool enabled;

  const _TimeButton({
    required this.selectedTime,
    required this.onTimeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformWidgets.isIOS;
    final timeText = selectedTime.format(context);

    return Container(
      decoration: BoxDecoration(
        color: AppStyles.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.grey300, width: 1),
      ),
      child: CupertinoButton(
        key: const Key('time_picker_button'),
        onPressed: isIOS
            ? (enabled ? () => _showCupertinoTimePicker(context) : null)
            : (enabled ? () => _showMaterialTimePicker(context) : null),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.clock,
              size: 18,
              color: enabled ? AppStyles.primaryColor : AppStyles.grey500,
            ),
            const SizedBox(width: 8),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? AppStyles.textColor : AppStyles.grey500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCupertinoTimePicker(BuildContext context) {
    final formContext = context;

    showCupertinoModalPopup(
      context: formContext,
      builder: (BuildContext modalContext) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(modalContext),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(
                        modalContext,
                      ),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.of(modalContext).pop();
                      },
                      child: Text(
                        'Done',
                        style: AppStyles.cardTitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime.now().copyWith(
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                  ),
                  onDateTimeChanged: (dateTime) {
                    onTimeChanged(TimeOfDay.fromDateTime(dateTime));
                  },

                  minuteInterval: 5,
                  use24hFormat: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMaterialTimePicker(BuildContext context) async {
    TimeOfDay tempTime = selectedTime;
    await PlatformNavigation.presentModal(
      context,
      Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlatformWidgets.platformButton(
                    padding: EdgeInsets.zero,
                    filled: false,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onTimeChanged(tempTime);
                    },
                    child: Text(
                      context.l10n.done,
                      style: AppStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime.now().copyWith(
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                ),
                onDateTimeChanged: (dateTime) {
                  tempTime = TimeOfDay.fromDateTime(dateTime);
                },
                minuteInterval: 5,
                use24hFormat: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
