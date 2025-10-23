import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import '../utils/time_of_day.dart';
import '../models/recurrence_pattern.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class PatternEditDialog extends StatefulWidget {
  final RecurrencePattern? pattern;
  final int eventId;

  const PatternEditDialog({super.key, this.pattern, required this.eventId});

  @override
  State<PatternEditDialog> createState() => _PatternEditDialogState();
}

class _PatternEditDialogState extends State<PatternEditDialog> {
  late int _selectedDayOfWeek;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();

    if (widget.pattern != null) {
      _selectedDayOfWeek = widget.pattern!.dayOfWeek;

      final timeParts = widget.pattern!.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } else {
      _selectedDayOfWeek = 0;
      _selectedTime = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PlatformDetection.isIOS
              ? CupertinoColors.systemBackground.resolveFrom(context)
              : AppStyles.cardBackgroundColor,
          borderRadius: BorderRadius.circular(
            PlatformDetection.isIOS ? 14 : 12,
          ),
          boxShadow: [
            BoxShadow(
              color: AppStyles.colorWithOpacity(AppStyles.black87, 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pattern == null
                  ? context.l10n.addPattern
                  : context.l10n.editPattern,
              style: PlatformDetection.isIOS
                  ? AppStyles.cardTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    )
                  : AppStyles.cardTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppStyles.black87,
                    ),
            ),

            _buildContent(context.l10n),

            const SizedBox(height: 24),

            _buildActions(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(dynamic l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),

        _buildDayOfWeekSelector(l10n),

        const SizedBox(height: 24),

        _buildTimeSelector(l10n),
      ],
    );
  }

  Widget _buildDayOfWeekSelector(dynamic l10n) {
    final List<String> days = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.dayOfWeek,
          style: AppStyles.cardSubtitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppStyles.black87,
          ),
        ),
        const SizedBox(height: 8),

        if (PlatformDetection.isIOS)
          SizedBox(
            height: 120,
            child: SizedBox(
              height: 120,
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedDayOfWeek,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedDayOfWeek = index;
                  });
                },
                children: days.map((day) => Center(child: Text(day))).toList(),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => _showDayPicker(days, l10n),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppStyles.grey300),
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
                color: AppStyles.cardBackgroundColor,
              ),
              child: Row(
                children: [
                  PlatformWidgets.platformIcon(
                    CupertinoIcons.calendar,
                    color: AppStyles.primary600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(days[_selectedDayOfWeek], style: AppStyles.bodyText),
                  const Spacer(),
                  PlatformWidgets.platformIcon(
                    CupertinoIcons.chevron_down,
                    color: AppStyles.grey600,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSelector(dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.time,
          style: AppStyles.cardSubtitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppStyles.black87,
          ),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _selectTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppStyles.grey300),
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
              color: AppStyles.cardBackgroundColor,
            ),
            child: Row(
              children: [
                PlatformWidgets.platformIcon(
                  CupertinoIcons.time,
                  color: AppStyles.primary600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(_selectedTime.format(context), style: AppStyles.bodyText),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (PlatformDetection.isIOS) {
      await PlatformNavigation.presentModal<void>(
        context,
        Builder(
          builder: (context) {
            return Container(
              height: 200,
              padding: const EdgeInsets.only(top: 6),
              margin: EdgeInsets.only(bottom: bottomInset),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _selectedTime = TimeOfDay.fromDateTime(newDateTime);
                    });
                  },
                  minuteInterval: 5,
                ),
              ),
            );
          },
        ),
        isScrollControlled: true,
      );
    } else {
      final TimeOfDay? picked = await _showCustomTimePicker();
      if (!mounted) {
        return;
      }
      if (picked != null) {
        setState(() {
          _selectedTime = picked;
        });
      }
    }
  }

  Widget _buildActions(BuildContext context, dynamic l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.cancel,
              style: PlatformDetection.isIOS
                  ? AppStyles.buttonText.copyWith(
                      color: CupertinoColors.systemBlue.resolveFrom(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )
                  : AppStyles.bodyText.copyWith(
                      color: AppStyles.grey600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        GestureDetector(
          onTap: _savePattern,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: PlatformDetection.isIOS
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : AppStyles.primary600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.save,
              style: AppStyles.buttonText.copyWith(
                color: AppStyles.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDayPicker(List<String> days, dynamic l10n) async {
    await PlatformNavigation.presentModal<void>(
      context,
      Center(
        child: Container(
          width: 280,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PlatformDetection.isIOS
                ? CupertinoColors.systemBackground.resolveFrom(context)
                : AppStyles.cardBackgroundColor,
            borderRadius: BorderRadius.circular(
              PlatformDetection.isIOS ? 14 : 12,
            ),
            boxShadow: [
              BoxShadow(
                color: AppStyles.colorWithOpacity(AppStyles.black87, 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.dayOfWeek,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: PlatformDetection.isIOS
                      ? CupertinoColors.label.resolveFrom(context)
                      : AppStyles.black87,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                days.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayOfWeek = index;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: _selectedDayOfWeek == index
                          ? AppStyles.colorWithOpacity(
                              AppStyles.primary600,
                              0.1,
                            )
                          : AppStyles.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDayOfWeek == index
                            ? AppStyles.primary600
                            : AppStyles.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<TimeOfDay?> _showCustomTimePicker() async {
    TimeOfDay? selectedTime = _selectedTime;
    final l10n = context.l10n;

    final result = await PlatformNavigation.presentModal<TimeOfDay>(
      context,
      Center(
        child: Container(
          width: 300,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PlatformWidgets.isIOS
                ? CupertinoColors.systemBackground.resolveFrom(context)
                : AppStyles.white,
            borderRadius: BorderRadius.circular(
              PlatformWidgets.isIOS ? 14 : 12,
            ),
            boxShadow: [
              BoxShadow(
                color: AppStyles.colorWithOpacity(AppStyles.black87, 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.time,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: PlatformDetection.isIOS
                      ? CupertinoColors.label.resolveFrom(context)
                      : AppStyles.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 100,
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: 24,
                      itemBuilder: (context, hour) => GestureDetector(
                        onTap: () {
                          selectedTime = TimeOfDay(
                            hour: hour,
                            minute: selectedTime?.minute ?? 0,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: selectedTime?.hour == hour
                                  ? AppStyles.primary600
                                  : AppStyles.grey500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    l10n.colon,
                    style: AppStyles.headlineSmall.copyWith(fontSize: 24),
                  ),

                  SizedBox(
                    width: 80,
                    height: 100,
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),

                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final minute = index * 5;
                        return GestureDetector(
                          onTap: () {
                            selectedTime = TimeOfDay(
                              hour: selectedTime?.hour ?? 0,
                              minute: minute,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              minute.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: selectedTime?.minute == minute
                                    ? AppStyles.primary600
                                    : AppStyles.grey600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppStyles.grey600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(selectedTime),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.primary600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.save,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );

    return result;
  }

  void _savePattern() {
    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:'
        '${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    final pattern = RecurrencePattern(
      id: widget.pattern?.id,
      eventId: widget.eventId,
      dayOfWeek: _selectedDayOfWeek,
      time: timeString,
      createdAt: widget.pattern?.createdAt,
    ).ensureFiveMinuteInterval();

    Navigator.of(context).pop(pattern);
  }
}
