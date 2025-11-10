import 'package:flutter/material.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/ui/month_option.dart';
import '../models/ui/day_option.dart';
import '../models/ui/time_option.dart';
import '../models/ui/datetime_selection.dart';
import '../services/date_range_calculator.dart';

class CustomDateTimeWidget extends StatefulWidget {
  final DateTime? initialDateTime;
  final String timezone;
  final Function(DateTimeSelection) onDateTimeChanged;
  final String locale;
  final bool showTimePicker;
  final bool showTodayButton;

  const CustomDateTimeWidget({
    super.key,
    this.initialDateTime,
    required this.timezone,
    required this.onDateTimeChanged,
    this.locale = 'es',
    this.showTimePicker = true,
    this.showTodayButton = true,
  });

  @override
  State<CustomDateTimeWidget> createState() => _CustomDateTimeWidgetState();
}

class _CustomDateTimeWidgetState extends State<CustomDateTimeWidget> {
  late List<MonthOption> monthOptions;
  late List<DayOption> dayOptions;
  late List<TimeOption> timeOptions;

  late ScrollController monthController;
  late ScrollController dayController;
  late ScrollController timeController;

  late int selectedMonthIndex;
  late int selectedDayIndex;
  late int selectedTimeIndex;

  @override
  void initState() {
    super.initState();
    _initializeOptions();
  }

  void _initializeOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final maxDate = DateRangeCalculator.calculateMaxDate(today, 30);

    monthOptions = DateRangeCalculator.generateMonthOptions(
      today,
      maxDate,
      widget.locale,
    );

    timeOptions = DateRangeCalculator.generateTimeOptions();

    final initialDate = widget.initialDateTime ?? now;
    final roundedDate = DateRangeCalculator.roundToNext15Min(initialDate);

    selectedMonthIndex = monthOptions.indexWhere(
      (m) => m.month == roundedDate.month && m.year == roundedDate.year,
    );
    if (selectedMonthIndex == -1) selectedMonthIndex = 0;

    final selectedMonth = monthOptions[selectedMonthIndex];
    dayOptions = DateRangeCalculator.generateDayOptions(
      selectedMonth.month,
      selectedMonth.year,
      widget.locale,
    );

    selectedDayIndex = dayOptions.indexWhere((d) => d.day == roundedDate.day);
    if (selectedDayIndex == -1) selectedDayIndex = 0;

    final isToday =
        selectedMonth.month == now.month &&
        selectedMonth.year == now.year &&
        roundedDate.day == now.day;

    if (isToday) {
      final allTimeOptions = DateRangeCalculator.generateTimeOptions();
      final currentHour = now.hour;
      final currentMinute = now.minute;

      timeOptions = allTimeOptions.where((timeOption) {
        if (timeOption.hour > currentHour) return true;
        if (timeOption.hour == currentHour &&
            timeOption.minute > currentMinute) {
          return true;
        }
        return false;
      }).toList();

      if (timeOptions.isEmpty) {
        timeOptions = allTimeOptions;
        selectedTimeIndex = allTimeOptions.length - 1;
      } else {
        selectedTimeIndex = 0;
      }
    } else {
      selectedTimeIndex = DateRangeCalculator.getTimeOptionIndex(
        roundedDate,
        timeOptions,
      );
    }

    monthController = ScrollController();
    dayController = ScrollController();
    timeController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyDateTimeChanged();
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    const monthItemWidth = 120.0;
    const dayItemWidth = 90.0;
    const timeItemWidth = 80.0;

    if (monthController.hasClients) {
      final offset = selectedMonthIndex * monthItemWidth;
      monthController.jumpTo(
        offset.clamp(0.0, monthController.position.maxScrollExtent),
      );
    }
    if (dayController.hasClients) {
      final offset = selectedDayIndex * dayItemWidth;
      dayController.jumpTo(
        offset.clamp(0.0, dayController.position.maxScrollExtent),
      );
    }
    if (timeController.hasClients && widget.showTimePicker) {
      final offset = selectedTimeIndex * timeItemWidth;
      timeController.jumpTo(
        offset.clamp(0.0, timeController.position.maxScrollExtent),
      );
    }
  }

  void _onMonthChanged(int index) {
    setState(() {
      selectedMonthIndex = index;
      final selectedMonth = monthOptions[index];

      dayOptions = DateRangeCalculator.generateDayOptions(
        selectedMonth.month,
        selectedMonth.year,
        widget.locale,
      );

      if (selectedDayIndex >= dayOptions.length) {
        selectedDayIndex = dayOptions.length - 1;
      }

      _updateTimeOptions();
    });
    _notifyDateTimeChanged();
  }

  void _onDayChanged(int index) {
    setState(() {
      selectedDayIndex = index;

      _updateTimeOptions();
    });
    _notifyDateTimeChanged();
  }

  void _updateTimeOptions() {
    final now = DateTime.now();
    final selectedMonth = monthOptions[selectedMonthIndex];
    final selectedDay = dayOptions[selectedDayIndex];

    final isToday =
        selectedMonth.month == now.month &&
        selectedMonth.year == now.year &&
        selectedDay.day == now.day;

    if (isToday) {
      final allTimeOptions = DateRangeCalculator.generateTimeOptions();
      final currentHour = now.hour;
      final currentMinute = now.minute;

      timeOptions = allTimeOptions.where((timeOption) {
        if (timeOption.hour > currentHour) return true;
        if (timeOption.hour == currentHour &&
            timeOption.minute > currentMinute) {
          return true;
        }
        return false;
      }).toList();

      if (timeOptions.isEmpty) {
        timeOptions = allTimeOptions;
        selectedTimeIndex = allTimeOptions.length - 1;
      } else {
        selectedTimeIndex = 0;
      }
    } else {
      timeOptions = DateRangeCalculator.generateTimeOptions();
      if (selectedTimeIndex >= timeOptions.length) {
        selectedTimeIndex = 0;
      }
    }
  }

  void _onTimeChanged(int index) {
    setState(() {
      selectedTimeIndex = index;
    });
    _notifyDateTimeChanged();
  }

  void _notifyDateTimeChanged() {
    final selection = DateTimeSelection.fromOptions(
      monthOptions[selectedMonthIndex],
      dayOptions[selectedDayIndex],
      timeOptions[selectedTimeIndex],
      widget.timezone,
    );
    widget.onDateTimeChanged(selection);
  }

  void scrollToToday() {
    final now = DateTime.now();
    final roundedNow = DateRangeCalculator.roundToNext15Min(now);

    final monthIndex = monthOptions.indexWhere(
      (m) => m.month == roundedNow.month && m.year == roundedNow.year,
    );

    if (monthIndex != -1) {
      setState(() {
        selectedMonthIndex = monthIndex;
        final selectedMonth = monthOptions[monthIndex];

        dayOptions = DateRangeCalculator.generateDayOptions(
          selectedMonth.month,
          selectedMonth.year,
          widget.locale,
        );
      });

      final dayIndex = dayOptions.indexWhere((d) => d.day == roundedNow.day);
      final timeIndex = DateRangeCalculator.getTimeOptionIndex(
        roundedNow,
        timeOptions,
      );

      setState(() {
        if (dayIndex != -1) {
          selectedDayIndex = dayIndex;
        }
        selectedTimeIndex = timeIndex;
      });

      const monthItemWidth = 120.0;
      const dayItemWidth = 90.0;
      const timeItemWidth = 80.0;

      if (monthController.hasClients) {
        final offset = monthIndex * monthItemWidth;
        monthController.animateTo(
          offset.clamp(0.0, monthController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      if (dayController.hasClients && dayIndex != -1) {
        final offset = dayIndex * dayItemWidth;
        dayController.animateTo(
          offset.clamp(0.0, dayController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      if (timeController.hasClients && widget.showTimePicker) {
        final offset = timeIndex * timeItemWidth;
        timeController.animateTo(
          offset.clamp(0.0, timeController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }

      _notifyDateTimeChanged();
    }
  }

  Widget _buildHorizontalScrollList<T>({
    required String label,
    required IconData icon,
    required List<T> items,
    required int selectedIndex,
    required ScrollController controller,
    required String Function(T) displayText,
    required Function(int) onSelectedItemChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemBuilder: (context, index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelectedItemChanged(index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : null,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      displayText(items[index]),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    monthController.dispose();
    dayController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showTodayButton) ...[
          Center(
            child: TextButton.icon(
              onPressed: scrollToToday,
              icon: const Icon(Icons.today),
              label: Text(context.l10n.today),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          const SizedBox(height: 8),
        ],

        _buildHorizontalScrollList<MonthOption>(
          label: context.l10n.month,
          icon: Icons.calendar_month,
          items: monthOptions,
          selectedIndex: selectedMonthIndex,
          controller: monthController,
          displayText: (month) => month.displayName,
          onSelectedItemChanged: _onMonthChanged,
        ),
        const SizedBox(height: 16),

        _buildHorizontalScrollList<DayOption>(
          label: context.l10n.day,
          icon: Icons.today,
          items: dayOptions,
          selectedIndex: selectedDayIndex,
          controller: dayController,
          displayText: (day) => day.displayName,
          onSelectedItemChanged: _onDayChanged,
        ),

        if (widget.showTimePicker) ...[
          const SizedBox(height: 16),
          _buildHorizontalScrollList<TimeOption>(
            label: context.l10n.hour,
            icon: Icons.access_time,
            items: timeOptions,
            selectedIndex: selectedTimeIndex,
            controller: timeController,
            displayText: (time) => time.displayName,
            onSelectedItemChanged: _onTimeChanged,
          ),
        ],
      ],
    );
  }
}
