# CustomDateTimeWidget

## Overview
`CustomDateTimeWidget` is a StatefulWidget that provides a custom date and time picker with horizontal scrolling lists for month, day, and time selection. It features intelligent time filtering (prevents past times for today), automatic scroll positioning, 15-minute interval rounding, and a "Today" quick-selection button. The widget coordinates three interdependent selectors with proper synchronization and validates time options based on current datetime.

## File Location
`lib/widgets/custom_datetime_widget.dart`

## Dependencies
```dart
import 'package:flutter/material.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/month_option.dart';
import '../models/day_option.dart';
import '../models/time_option.dart';
import '../models/datetime_selection.dart';
import '../services/date_range_calculator.dart';
```

**Key Dependencies:**
- `month_option.dart`: Model for month selection (month, year, displayName)
- `day_option.dart`: Model for day selection (day, displayName)
- `time_option.dart`: Model for time selection (hour, minute, displayName)
- `datetime_selection.dart`: Combined selection result with timezone
- `date_range_calculator.dart`: Service for generating options, rounding times, calculating ranges

**Model Structure:**
- `MonthOption`: `{int month, int year, String displayName}`
- `DayOption`: `{int day, String displayName}`
- `TimeOption`: `{int hour, int minute, String displayName}`
- `DateTimeSelection`: `{DateTime dateTime, String timezone}`

## Class Declaration

```dart
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
    this.showTodayButton = true
  });
}
```

**Widget Type:** StatefulWidget

**Rationale for Stateful:**
- **Option Lists:** Manages monthOptions, dayOptions, timeOptions arrays
- **Selection State:** Tracks selected indices for each selector
- **ScrollControllers:** Three controllers for programmatic scrolling
- **Dynamic Options:** Time options change based on selected date
- **Complex Interactions:** Month change regenerates days, day change filters times

### Properties Analysis

**initialDateTime** (`DateTime?`):
- **Type:** Nullable DateTime
- **Purpose:** Pre-selects date/time when widget loads
- **Rounding:** Rounded to next 15-minute interval
- **Default:** If null, uses current DateTime
- **Usage:** Editing existing events, setting default meeting time

**timezone** (`String`):
- **Type:** Required IANA timezone string (e.g., "America/New_York")
- **Purpose:** Included in DateTimeSelection result
- **Not Used Internally:** Widget works with local times, timezone passed through to result
- **Usage:** Parent needs timezone context for datetime interpretation

**onDateTimeChanged** (`Function(DateTimeSelection)`):
- **Type:** Required callback function
- **Parameter:** DateTimeSelection object with dateTime and timezone
- **Called When:**
  - Initial setup (post-frame callback)
  - Month changed
  - Day changed
  - Time changed
  - "Today" button pressed
- **Pattern:** Immediate callback on every selection change

**locale** (`String`):
- **Type:** String locale code
- **Default:** `'es'` (Spanish)
- **Purpose:** Determines display format for month and day names
- **Passed To:** DateRangeCalculator for localized strings
- **Usage:** Match app's current locale

**showTimePicker** (`bool`):
- **Type:** Boolean flag
- **Default:** `true`
- **Purpose:** Controls visibility of time selector
- **Use Case:** Date-only selection (e.g., birthdays, all-day events)
- **UI Impact:** Hides time scroll list when false

**showTodayButton** (`bool`):
- **Type:** Boolean flag
- **Default:** `true`
- **Purpose:** Shows/hides "Today" quick-select button
- **Use Case:** Hide when default is already today or in specific contexts
- **UI Impact:** Shows button with "Today" label and calendar icon

## State Class

```dart
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
```

### State Variables Analysis

**monthOptions** (`List<MonthOption>`):
- **Type:** List of month selection options
- **Initialization:** Generated in _initializeOptions from today to maxDate (30 days)
- **Content:** Current month through next month(s)
- **Immutable:** Doesn't change after initialization
- **Example:** `[MonthOption(month: 1, year: 2025, displayName: "January"), ...]`

**dayOptions** (`List<DayOption>`):
- **Type:** List of day selection options for currently selected month
- **Initialization:** Generated for initialDateTime's month
- **Regenerates:** When month selection changes
- **Content:** All days in selected month
- **Example:** `[DayOption(day: 1, displayName: "Mon 1"), ...]`

**timeOptions** (`List<TimeOption>`):
- **Type:** List of time selection options in 15-minute intervals
- **Initialization:** Generated with 15-min intervals (00:00, 00:15, 00:30, ...)
- **Dynamic Filtering:** For "today", filters out past times
- **Content:** 24 hours * 4 intervals = 96 options normally
- **Example:** `[TimeOption(hour: 14, minute: 30, displayName: "14:30"), ...]`

**monthController, dayController, timeController** (`ScrollController`):
- **Purpose:** Programmatic scroll control for each horizontal list
- **Creation:** In _initializeOptions
- **Usage:**
  - Initial scroll to selected items (post-frame callback)
  - Animated scroll for "Today" button
  - Jump scroll for initial positioning
- **Disposal:** All three disposed in dispose()

**selectedMonthIndex, selectedDayIndex, selectedTimeIndex** (`int`):
- **Purpose:** Track currently selected item in each list
- **Initialization:** Calculated from initialDateTime or current time
- **Updates:** On user tap or programmatic selection
- **Usage:** Highlighting selected items, calculating final datetime

## Lifecycle Methods

### initState

```dart
@override
void initState() {
  super.initState();
  _initializeOptions();
}
```

**Delegates** to _initializeOptions for all setup logic

### Initialize Options

```dart
void _initializeOptions() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final maxDate = DateRangeCalculator.calculateMaxDate(today, 30);

  monthOptions = DateRangeCalculator.generateMonthOptions(
    today,
    maxDate,
    widget.locale
  );

  timeOptions = DateRangeCalculator.generateTimeOptions();

  final initialDate = widget.initialDateTime ?? now;
  final roundedDate = DateRangeCalculator.roundToNext15Min(initialDate);

  selectedMonthIndex = monthOptions.indexWhere(
    (m) => m.month == roundedDate.month && m.year == roundedDate.year
  );
  if (selectedMonthIndex == -1) selectedMonthIndex = 0;

  final selectedMonth = monthOptions[selectedMonthIndex];
  dayOptions = DateRangeCalculator.generateDayOptions(
    selectedMonth.month,
    selectedMonth.year,
    widget.locale
  );

  selectedDayIndex = dayOptions.indexWhere((d) => d.day == roundedDate.day);
  if (selectedDayIndex == -1) selectedDayIndex = 0;

  final isToday = selectedMonth.month == now.month &&
                   selectedMonth.year == now.year &&
                   roundedDate.day == now.day;

  if (isToday) {
    final allTimeOptions = DateRangeCalculator.generateTimeOptions();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    timeOptions = allTimeOptions.where((timeOption) {
      if (timeOption.hour > currentHour) return true;
      if (timeOption.hour == currentHour && timeOption.minute > currentMinute) {
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
      timeOptions
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
```

### Detailed Analysis

**Lines 43-46:** Date range calculation
```dart
final now = DateTime.now();
final today = DateTime(now.year, now.month, now.day);
final maxDate = DateRangeCalculator.calculateMaxDate(today, 30);
```
- **now:** Current datetime with time
- **today:** Midnight of current day (removes time component)
- **maxDate:** 30 days from today
- **Range:** Widget allows selection from today through next 30 days

**Line 48:** Generate month options
```dart
monthOptions = DateRangeCalculator.generateMonthOptions(today, maxDate, widget.locale);
```
- Creates list of months within range
- Typically current month + next month (if 30 days span includes it)
- Localized month names

**Line 50:** Generate all time options
```dart
timeOptions = DateRangeCalculator.generateTimeOptions();
```
- Full 24-hour day in 15-minute intervals
- Will be filtered later if today is selected

**Lines 52-53:** Initial date with rounding
```dart
final initialDate = widget.initialDateTime ?? now;
final roundedDate = DateRangeCalculator.roundToNext15Min(initialDate);
```
- Use provided initialDateTime or current time
- Round to next 15-minute boundary
- **Example:** 14:07 → 14:15, 14:00 → 14:00

**Lines 55-56:** Find month index
```dart
selectedMonthIndex = monthOptions.indexWhere(
  (m) => m.month == roundedDate.month && m.year == roundedDate.year
);
if (selectedMonthIndex == -1) selectedMonthIndex = 0;
```
- Search for month matching roundedDate
- **Fallback:** If not found (edge case), use first month
- **Index:** 0-based position in monthOptions array

**Lines 58-62:** Generate days for selected month
```dart
final selectedMonth = monthOptions[selectedMonthIndex];
dayOptions = DateRangeCalculator.generateDayOptions(
  selectedMonth.month,
  selectedMonth.year,
  widget.locale
);

selectedDayIndex = dayOptions.indexWhere((d) => d.day == roundedDate.day);
if (selectedDayIndex == -1) selectedDayIndex = 0;
```
- Generate days for the selected month
- Find day matching roundedDate
- Fallback to first day if not found

**Line 64:** Check if selected date is today
```dart
final isToday = selectedMonth.month == now.month &&
                 selectedMonth.year == now.year &&
                 roundedDate.day == now.day;
```
- Compares year, month, and day
- Determines if time filtering is needed

**Lines 66-84:** Time options filtering for today
```dart
if (isToday) {
  final allTimeOptions = DateRangeCalculator.generateTimeOptions();
  final currentHour = now.hour;
  final currentMinute = now.minute;

  timeOptions = allTimeOptions.where((timeOption) {
    if (timeOption.hour > currentHour) return true;
    if (timeOption.hour == currentHour && timeOption.minute > currentMinute) {
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
}
```

**Filtering Logic (Lines 71-77):**
- Keep times where `hour > currentHour`
- OR `hour == currentHour AND minute > currentMinute`
- **Effect:** Only future times available
- **Example:** If now is 14:30:
  - 14:00 → filtered out
  - 14:30 → filtered out
  - 14:45 → kept
  - 15:00 → kept

**Empty Check (Lines 79-81):**
```dart
if (timeOptions.isEmpty) {
  timeOptions = allTimeOptions;
  selectedTimeIndex = allTimeOptions.length - 1;
}
```
- **Scenario:** It's 23:50, no future times in current day
- **Fallback:** Show all times, select last one (23:45)
- **Rationale:** Allow user to select evening time, understanding it's for today

**Non-Empty Case (Lines 82-84):**
```dart
else {
  selectedTimeIndex = 0;
}
```
- Select first available future time
- **Example:** Now is 14:30, first available is 14:45, select index 0 (of filtered list)

**Lines 85-87:** Time selection for non-today dates
```dart
} else {
  selectedTimeIndex = DateRangeCalculator.getTimeOptionIndex(
    roundedDate,
    timeOptions
  );
}
```
- Find index matching roundedDate's time
- No filtering needed for future dates

**Lines 89-91:** Create scroll controllers

**Lines 93-96:** Post-frame callback
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _notifyDateTimeChanged();
  _scrollToSelected();
});
```
- **Timing:** After first frame is rendered
- **Why:** ScrollControllers need attached scroll positions (hasClients)
- **Actions:**
  1. Notify parent of initial selection
  2. Scroll lists to show selected items

## Scroll to Selected

```dart
void _scrollToSelected() {
  const monthItemWidth = 120.0;
  const dayItemWidth = 90.0;
  const timeItemWidth = 80.0;

  if (monthController.hasClients) {
    final offset = selectedMonthIndex * monthItemWidth;
    monthController.jumpTo(
      offset.clamp(0.0, monthController.position.maxScrollExtent)
    );
  }
  if (dayController.hasClients) {
    final offset = selectedDayIndex * dayItemWidth;
    dayController.jumpTo(
      offset.clamp(0.0, dayController.position.maxScrollExtent)
    );
  }
  if (timeController.hasClients && widget.showTimePicker) {
    final offset = selectedTimeIndex * timeItemWidth;
    timeController.jumpTo(
      offset.clamp(0.0, timeController.position.maxScrollExtent)
    );
  }
}
```

**Purpose:** Scrolls each list to show the selected item

**Item Widths:**
- Month: 120px (wider for month names)
- Day: 90px (day names + numbers)
- Time: 80px (time format "HH:MM")

**For Each Controller:**
1. **hasClients Check:** Ensures scroll view is attached
2. **Calculate Offset:** `index * itemWidth`
3. **Clamp:** Ensures offset doesn't exceed scroll limits
4. **jumpTo:** Instant scroll (no animation)

**Time Controller Special Case:**
```dart
if (timeController.hasClients && widget.showTimePicker)
```
- Only scroll if time picker is shown

## Selection Change Methods

### On Month Changed

```dart
void _onMonthChanged(int index) {
  setState(() {
    selectedMonthIndex = index;
    final selectedMonth = monthOptions[index];

    dayOptions = DateRangeCalculator.generateDayOptions(
      selectedMonth.month,
      selectedMonth.year,
      widget.locale
    );

    if (selectedDayIndex >= dayOptions.length) {
      selectedDayIndex = dayOptions.length - 1;
    }

    _updateTimeOptions();
  });
  _notifyDateTimeChanged();
}
```

**Purpose:** Handles month selection

**State Updates (Lines 119-130):**
1. Update selected month index
2. Regenerate days for new month
3. Validate day index (in case new month has fewer days)
4. Update time options (might need filtering if switched to current month)

**Day Index Validation (Lines 125-127):**
```dart
if (selectedDayIndex >= dayOptions.length) {
  selectedDayIndex = dayOptions.length - 1;
}
```
- **Scenario:** Selected day 31, switched to month with only 30 days
- **Fix:** Select last day of new month
- **Example:** January 31 → February, select February 28

**Line 129:** Update time options
- Calls _updateTimeOptions to check if filtering needed

**Line 131:** Notify parent
- Calls after setState completes

### On Day Changed

```dart
void _onDayChanged(int index) {
  setState(() {
    selectedDayIndex = index;
    _updateTimeOptions();
  });
  _notifyDateTimeChanged();
}
```

**Simpler than month change:**
- Update day index
- Update time options (might need filtering if switched to/from today)
- Notify parent

### Update Time Options

```dart
void _updateTimeOptions() {
  final now = DateTime.now();
  final selectedMonth = monthOptions[selectedMonthIndex];
  final selectedDay = dayOptions[selectedDayIndex];

  final isToday = selectedMonth.month == now.month &&
                   selectedMonth.year == now.year &&
                   selectedDay.day == now.day;

  if (isToday) {
    final allTimeOptions = DateRangeCalculator.generateTimeOptions();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    timeOptions = allTimeOptions.where((timeOption) {
      if (timeOption.hour > currentHour) return true;
      if (timeOption.hour == currentHour && timeOption.minute > currentMinute) {
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
```

**Purpose:** Regenerates time options based on selected date

**Logic:** Identical to initialization logic (lines 64-87)
- Check if selected date is today
- If yes: filter past times, select first future time
- If no: all times available, validate selected index

**Key Difference (Lines 170-173):**
```dart
} else {
  timeOptions = DateRangeCalculator.generateTimeOptions();
  if (selectedTimeIndex >= timeOptions.length) {
    selectedTimeIndex = 0;
  }
}
```
- For non-today: regenerate full list
- Validate selected index (in case it was out of bounds from previous filtered list)

### On Time Changed

```dart
void _onTimeChanged(int index) {
  setState(() {
    selectedTimeIndex = index;
  });
  _notifyDateTimeChanged();
}
```

**Simplest handler:**
- Update time index
- Notify parent
- No cascading updates needed

### Notify DateTime Changed

```dart
void _notifyDateTimeChanged() {
  final selection = DateTimeSelection.fromOptions(
    monthOptions[selectedMonthIndex],
    dayOptions[selectedDayIndex],
    timeOptions[selectedTimeIndex],
    widget.timezone
  );
  widget.onDateTimeChanged(selection);
}
```

**Purpose:** Constructs DateTimeSelection and calls parent callback

**DateTimeSelection.fromOptions:**
- Factory constructor that combines month, day, time, and timezone
- Returns DateTimeSelection with complete DateTime and timezone string

**Pattern:** Single source of truth for notification logic

## Scroll to Today

```dart
void scrollToToday() {
  final now = DateTime.now();
  final roundedNow = DateRangeCalculator.roundToNext15Min(now);

  final monthIndex = monthOptions.indexWhere(
    (m) => m.month == roundedNow.month && m.year == roundedNow.year
  );

  if (monthIndex != -1) {
    setState(() {
      selectedMonthIndex = monthIndex;
      final selectedMonth = monthOptions[monthIndex];

      dayOptions = DateRangeCalculator.generateDayOptions(
        selectedMonth.month,
        selectedMonth.year,
        widget.locale
      );
    });

    final dayIndex = dayOptions.indexWhere((d) => d.day == roundedNow.day);
    final timeIndex = DateRangeCalculator.getTimeOptionIndex(
      roundedNow,
      timeOptions
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
        curve: Curves.easeInOut
      );
    }
    if (dayController.hasClients && dayIndex != -1) {
      final offset = dayIndex * dayItemWidth;
      dayController.animateTo(
        offset.clamp(0.0, dayController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut
      );
    }
    if (timeController.hasClients && widget.showTimePicker) {
      final offset = timeIndex * timeItemWidth;
      timeController.animateTo(
        offset.clamp(0.0, timeController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut
      );
    }

    _notifyDateTimeChanged();
  }
}
```

**Purpose:** "Today" button handler - resets to current date/time

**Differs from _scrollToSelected:**
- Uses `animateTo` instead of `jumpTo` (animated scroll)
- 400ms duration with easeInOut curve
- Recalculates indices for current datetime

**Two setState Calls:**
1. **First (Lines 196-201):** Update month, regenerate days
2. **Second (Lines 206-211):** Update day and time indices

**Why Split:** dayOptions must be regenerated before finding dayIndex

## Build Horizontal Scroll List

```dart
Widget _buildHorizontalScrollList<T>({
  required String label,
  required IconData icon,
  required List<T> items,
  required int selectedIndex,
  required ScrollController controller,
  required String Function(T) displayText,
  required Function(int) onSelectedItemChanged
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : null,
                  border: Border.all(
                    color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                    width: isSelected ? 2 : 1
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    displayText(items[index]),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null
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
```

**Purpose:** Generic builder for month/day/time selectors

**Generic Type `<T>`:**
- Works with MonthOption, DayOption, or TimeOption
- Type-safe without duplication

**Parameters:**
- `label`: Section label ("Month", "Day", "Hour")
- `icon`: Icon next to label
- `items`: List of options
- `selectedIndex`: Currently selected item index
- `controller`: ScrollController for programmatic scrolling
- `displayText`: Function to extract display string from item
- `onSelectedItemChanged`: Callback with selected index

**Header (Lines 238-247):**
```
Icon + 8px + Label
```
- Icon at 20px size
- Label in medium weight

**ListView.builder (Lines 249-279):**
- **Height:** Fixed 55px
- **Physics:** ClampingScrollPhysics (stops at edges, no bounce)
- **Direction:** Horizontal
- **Padding:** 16px left/right margins

**Item Builder (Lines 257-277):**

**GestureDetector:**
- Full container tappable
- Calls onSelectedItemChanged with index

**Container Styling:**
- **Margin:** 8px right (gap between items)
- **Padding:** 14px horizontal, 10px vertical
- **Background:**
  - **Selected:** Primary color at 10% opacity
  - **Unselected:** Transparent
- **Border:**
  - **Selected:** Primary color, 2px width
  - **Unselected:** Gray, 1px width
- **BorderRadius:** 8px rounded corners

**Text Styling:**
- **Font Size:** 15px
- **Font Weight:**
  - **Selected:** Bold
  - **Unselected:** Normal
- **Color:**
  - **Selected:** Primary color
  - **Unselected:** Default text color

## Dispose

```dart
@override
void dispose() {
  monthController.dispose();
  dayController.dispose();
  timeController.dispose();
  super.dispose();
}
```

**Critical:** Dispose all three scroll controllers to prevent memory leaks

## Build Method

```dart
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
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
        onSelectedItemChanged: _onMonthChanged
      ),
      const SizedBox(height: 16),

      _buildHorizontalScrollList<DayOption>(
        label: context.l10n.day,
        icon: Icons.today,
        items: dayOptions,
        selectedIndex: selectedDayIndex,
        controller: dayController,
        displayText: (day) => day.displayName,
        onSelectedItemChanged: _onDayChanged
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
          onSelectedItemChanged: _onTimeChanged
        ),
      ],
    ],
  );
}
```

**Structure:**
1. **Today Button** (conditional)
2. Month selector
3. Day selector
4. Time selector (conditional)

**Today Button (Lines 296-308):**
- Shows if `showTodayButton == true`
- Centered TextButton with icon
- Icon: `Icons.today`
- Label: Localized "Today"
- Extra padding for comfort
- If hidden: 8px spacing instead

**Month Selector (Lines 310):**
- Label: "Month"
- Icon: calendar_month
- displayText extracts month.displayName

**Day Selector (Lines 313):**
- Label: "Day"
- Icon: today
- displayText extracts day.displayName

**Time Selector (Lines 315-318):**
- Conditional on `showTimePicker`
- Label: "Hour"
- Icon: access_time
- displayText extracts time.displayName

## Technical Characteristics

### Time Filtering Algorithm
- **Today:** Only future times available
- **Edge Case:** If no future times, show all times and select last
- **Recalculation:** Every time day or month changes
- **Granularity:** 15-minute intervals

### State Synchronization
- **Month → Day:** Regenerates day options, validates day index
- **Day → Time:** Updates time filtering based on is-today check
- **Cascading Updates:** Proper order prevents invalid states

### Scroll Management
- **Initial:** jumpTo (instant) in post-frame callback
- **User Interaction:** Handled by ListView
- **Today Button:** animateTo (smooth) with 400ms duration
- **Clamping:** Prevents scroll beyond content bounds

### Selection Flow
1. User taps item
2. Callback fires with index
3. setState updates selected index (and possibly options)
4. _notifyDateTimeChanged constructs DateTimeSelection
5. Parent receives update via onDateTimeChanged

## Usage Examples

### Basic Usage
```dart
CustomDateTimeWidget(
  timezone: 'America/New_York',
  onDateTimeChanged: (selection) {
    print('Selected: ${selection.dateTime}');
  },
)
```

### Pre-Selected DateTime
```dart
CustomDateTimeWidget(
  initialDateTime: eventDateTime,
  timezone: eventTimezone,
  onDateTimeChanged: (selection) {
    setState(() {
      eventDateTime = selection.dateTime;
    });
  },
)
```

### Date-Only Selection
```dart
CustomDateTimeWidget(
  timezone: 'UTC',
  showTimePicker: false,
  showTodayButton: true,
  onDateTimeChanged: (selection) {
    final dateOnly = DateTime(
      selection.dateTime.year,
      selection.dateTime.month,
      selection.dateTime.day,
    );
    _saveBirthday(dateOnly);
  },
)
```

### With Different Locale
```dart
CustomDateTimeWidget(
  timezone: userTimezone,
  locale: 'en', // English
  onDateTimeChanged: (selection) {
    _saveSelection(selection);
  },
)
```

## Testing Recommendations

### Unit Tests

**1. Time Rounding:**
```dart
test('should round initial time to next 15 minutes', () {
  final widget = createTestWidget(
    initialDateTime: DateTime(2025, 1, 15, 14, 07),
  );

  // Verify selection is rounded to 14:15
});
```

**2. Today Time Filtering:**
```dart
test('should filter past times when today is selected', () {
  final now = DateTime.now();
  final state = createTestState();

  // Select today
  state._onDayChanged(/* today's index */);

  // Verify timeOptions doesn't include past times
});
```

**3. Month Change Day Validation:**
```dart
test('should adjust day when switching to month with fewer days', () {
  final state = createTestState();

  // Select January 31
  state.selectedDayIndex = 30; // Index for day 31

  // Switch to February
  state._onMonthChanged(1);

  // Verify selectedDayIndex is last day of February
  expect(state.selectedDayIndex, lessThan(30));
});
```

### Widget Tests

**1. Initial Rendering:**
```dart
testWidgets('should render month, day, and time selectors', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomDateTimeWidget(
          timezone: 'UTC',
          onDateTimeChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.month), findsOneWidget);
  expect(find.text(context.l10n.day), findsOneWidget);
  expect(find.text(context.l10n.hour), findsOneWidget);
});
```

**2. Today Button:**
```dart
testWidgets('should scroll to today when button tapped', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomDateTimeWidget(
          timezone: 'UTC',
          initialDateTime: DateTime.now().add(Duration(days: 10)),
          onDateTimeChanged: (_) {},
        ),
      ),
    ),
  );

  // Verify not showing today initially
  // Tap today button
  await tester.tap(find.text(context.l10n.today));
  await tester.pumpAndSettle();

  // Verify scrolled to today
});
```

**3. Selection:**
```dart
testWidgets('should call onDateTimeChanged when item selected', (tester) async {
  DateTimeSelection? selection;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomDateTimeWidget(
          timezone: 'America/New_York',
          onDateTimeChanged: (s) { selection = s; },
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Verify initial callback
  expect(selection, isNotNull);
  expect(selection!.timezone, 'America/New_York');
});
```

**4. Hide Time Picker:**
```dart
testWidgets('should hide time picker when showTimePicker is false', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomDateTimeWidget(
          timezone: 'UTC',
          showTimePicker: false,
          onDateTimeChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.hour), findsNothing);
});
```

## Comparison with Similar Widgets

### vs. Standard DateTimePicker
**CustomDateTimeWidget Advantages:**
- Custom horizontal scroll design
- Prevents past time selection for today
- Integrated "Today" button
- 15-minute intervals
- More control over styling

**Standard Picker:**
- Native platform appearance
- More familiar to users
- Less code to maintain

### vs. Cupertino/Material Pickers
**CustomDateTimeWidget:**
- Horizontal layout
- Three separate selectors
- Custom time filtering
- More screen real estate

**Platform Pickers:**
- Compact modals
- Platform-native UX
- Less intrusive

## Possible Improvements

### 1. Custom Time Intervals
```dart
final int timeIntervalMinutes;

// Generate options with custom interval
timeOptions = DateRangeCalculator.generateTimeOptions(
  intervalMinutes: timeIntervalMinutes
);
```

### 2. Date Range Limits
```dart
final DateTime? minDate;
final DateTime? maxDate;

// Filter month options to range
```

### 3. Week Start Day
```dart
final int weekStartDay; // 0 = Sunday, 1 = Monday

// Adjust day display based on week start
```

### 4. Keyboard Navigation
```dart
@override
Widget build(BuildContext context) {
  return Focus(
    onKey: (node, event) {
      // Arrow keys to navigate selections
    },
    child: /* existing widget */,
  );
}
```

### 5. Haptic Feedback
```dart
onTap: () {
  HapticFeedback.selectionClick();
  onSelectedItemChanged(index);
}
```

### 6. Loading State
```dart
if (isLoadingOptions)
  Center(child: CircularProgressIndicator())
else
  /* existing selectors */
```

### 7. Error State
```dart
if (errorMessage != null)
  Text(errorMessage, style: TextStyle(color: Colors.red))
```

### 8. Accessibility Labels
```dart
Semantics(
  label: "Month selector, currently ${monthOptions[selectedMonthIndex].displayName}",
  child: /* month selector */,
)
```

## Real-World Usage Context

This widget is typically used in:

1. **Event Creation:** Selecting event date and time
2. **Appointment Booking:** Choosing meeting slots
3. **Task Management:** Setting due dates
4. **Calendar Apps:** Creating reminders
5. **Scheduling Forms:** Any datetime input

The horizontal scroll design and time filtering make it particularly suitable for mobile-first applications where users frequently select near-future datetimes.

## Performance Considerations

- **Three ScrollControllers:** Proper disposal prevents leaks
- **Dynamic Filtering:** Time options recalculated on day/month change
- **Post-Frame Callback:** Ensures scroll positions available before scrolling
- **ListView.builder:** Efficient for rendering large lists
- **Clamping:** Prevents unnecessary scroll calculations

**Recommendation:** Suitable for most forms. Consider caching DateRangeCalculator results if widget is created/disposed frequently.
