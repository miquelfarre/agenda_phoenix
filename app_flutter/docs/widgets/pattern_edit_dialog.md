# PatternEditDialog Widget

## Overview
`PatternEditDialog` is a StatefulWidget that provides a modal dialog for creating or editing recurrence patterns with day-of-week and time selection. It features platform-adaptive UI with CupertinoPicker for iOS and custom dropdowns for Android, a custom time picker with 5-minute intervals, proper state initialization from existing patterns, and automatic rounding to 5-minute intervals on save. The widget returns a complete RecurrencePattern object when saved or null when cancelled.

## File Location
`lib/widgets/pattern_edit_dialog.dart`

## Dependencies
```dart
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import '../utils/time_of_day.dart';
import '../models/recurrence_pattern.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
```

**Key Dependencies:**
- `recurrence_pattern.dart`: RecurrencePattern model with dayOfWeek, time, eventId, and ensureFiveMinuteInterval() method
- `time_of_day.dart`: Custom TimeOfDay utilities and extensions
- `platform_navigation.dart`: presentModal for showing nested pickers
- `platform_detection.dart`: PlatformDetection.isIOS for UI branching
- `platform_widgets.dart`: Platform-adaptive icons
- `app_constants.dart`: Border radius constant
- `app_styles.dart`: Colors, text styles, and shadows
- `l10n_helpers.dart`: Localization for all text

## Class Declaration

```dart
class PatternEditDialog extends StatefulWidget {
  final RecurrencePattern? pattern;
  final int eventId;

  const PatternEditDialog({
    super.key,
    this.pattern,
    required this.eventId
  });

  @override
  State<PatternEditDialog> createState() => _PatternEditDialogState();
}
```

**Widget Type:** StatefulWidget

**Rationale for Stateful:**
- **Selection State:** Manages _selectedDayOfWeek and _selectedTime internally
- **User Interaction:** Updates state as user selects values
- **Initialization:** Needs to parse and set initial values from pattern
- **Not Form:** No TextEditingControllers, just local state for selections

### Properties Analysis

**pattern** (`RecurrencePattern?`):
- **Type:** Nullable RecurrencePattern
- **Purpose:** Existing pattern to edit (null for create mode)
- **Usage:**
  - **Edit Mode:** Initializes state with pattern's dayOfWeek and time
  - **Create Mode:** Uses defaults (Monday at 18:00)
- **Determines:** Dialog title ("Add Pattern" vs "Edit Pattern")
- **Preserved:** pattern.id, pattern.createdAt passed through to result

**eventId** (`int`):
- **Type:** Required integer
- **Purpose:** Parent event ID for the pattern
- **Usage:** Set in created/edited RecurrencePattern
- **Pattern:** Child entity needs parent reference
- **Context:** Pattern belongs to specific event

## State Class

```dart
class _PatternEditDialogState extends State<PatternEditDialog> {
  late int _selectedDayOfWeek;
  late TimeOfDay _selectedTime;
```

### State Variables Analysis

**_selectedDayOfWeek** (`late int`):
- **Type:** Integer (0-6)
- **Mapping:**
  - 0 = Monday
  - 1 = Tuesday
  - 2 = Wednesday
  - 3 = Thursday
  - 4 = Friday
  - 5 = Saturday
  - 6 = Sunday
- **Initialization:**
  - Edit mode: from widget.pattern.dayOfWeek
  - Create mode: 0 (Monday)
- **Updates:** setState when user selects different day
- **Usage:** Array index for day names, saved to RecurrencePattern

**_selectedTime** (`late TimeOfDay`):
- **Type:** TimeOfDay (Flutter's time representation)
- **Properties:** hour (0-23), minute (0-59)
- **Initialization:**
  - Edit mode: parsed from widget.pattern.time string
  - Create mode: TimeOfDay(hour: 18, minute: 0) (6:00 PM)
- **Updates:** setState when user selects time
- **Formatting:** Converted to HH:MM:SS string on save
- **Rounding:** Automatically rounded to 5-minute intervals via ensureFiveMinuteInterval()

## Lifecycle Methods

### initState

```dart
@override
void initState() {
  super.initState();

  if (widget.pattern != null) {
    _selectedDayOfWeek = widget.pattern!.dayOfWeek;

    final timeParts = widget.pattern!.time.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1])
    );
  } else {
    _selectedDayOfWeek = 0;
    _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  }
}
```

### Detailed Analysis

**Line 27:** `super.initState();`
- Required parent call

**Lines 29-34: Edit Mode Initialization**
```dart
if (widget.pattern != null) {
  _selectedDayOfWeek = widget.pattern!.dayOfWeek;

  final timeParts = widget.pattern!.time.split(':');
  _selectedTime = TimeOfDay(
    hour: int.parse(timeParts[0]),
    minute: int.parse(timeParts[1])
  );
}
```

**Line 30:** Day of week extraction
- Direct assignment from pattern
- **Example:** pattern.dayOfWeek = 3 → Thursday

**Lines 32-33:** Time parsing
```dart
final timeParts = widget.pattern!.time.split(':');
_selectedTime = TimeOfDay(
  hour: int.parse(timeParts[0]),
  minute: int.parse(timeParts[1])
);
```
- **Input Format:** "HH:MM:SS" (e.g., "14:30:00")
- **Split:** ["14", "30", "00"]
- **Parse:** Extract hours and minutes, ignore seconds
- **Create TimeOfDay:** hour=14, minute=30
- **Pattern:** Backend stores full time string, UI works with TimeOfDay

**Lines 35-37: Create Mode Defaults**
```dart
} else {
  _selectedDayOfWeek = 0;
  _selectedTime = const TimeOfDay(hour: 18, minute: 0);
}
```

**Defaults:**
- **Day:** Monday (0)
- **Time:** 18:00 (6:00 PM)
- **Rationale:** Common meeting/event time, start of week
- **Const:** TimeOfDay is const (compile-time optimization)

## Build Method

```dart
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
          PlatformDetection.isIOS ? 14 : 12
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.colorWithOpacity(AppStyles.black87, 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4)
          )
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
                  color: CupertinoColors.label.resolveFrom(context)
                )
              : AppStyles.cardTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.black87
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
```

### Detailed Analysis

**Lines 44-53: Container Styling**

**Width:** 320px fixed width

**Margin:** 24px on all sides (spacing from screen edges)

**Padding:** 24px internal padding

**Background Color:**
- **iOS:** `CupertinoColors.systemBackground.resolveFrom(context)`
  - Adapts to light/dark mode automatically
  - White in light, dark gray in dark mode
- **Android:** `AppStyles.cardBackgroundColor`
  - Static card background color

**Border Radius:**
- **iOS:** 14px (Apple's standard modal radius)
- **Android:** 12px (Material Design radius)

**Box Shadow:**
```dart
boxShadow: [
  BoxShadow(
    color: AppStyles.colorWithOpacity(AppStyles.black87, 0.2),
    blurRadius: 8,
    offset: const Offset(0, 4)
  )
]
```
- Black at 20% opacity
- 8px blur (soft shadow)
- Offset 4px down (elevation effect)

**Lines 54-69: Column Content**

**mainAxisSize: MainAxisSize.min**
- Dialog shrinks to fit content
- Prevents unnecessary vertical expansion

**crossAxisAlignment: CrossAxisAlignment.start**
- Left-aligned content

**Children:**
1. Title text (conditional)
2. Content section (selectors)
3. 24px spacing
4. Actions (buttons)

**Lines 58-61: Title Text**
```dart
Text(
  widget.pattern == null
    ? context.l10n.addPattern
    : context.l10n.editPattern,
  style: /* platform-specific */
),
```

**Content:**
- **Create Mode:** "Add Pattern"
- **Edit Mode:** "Edit Pattern"

**Style - iOS:**
- 17px font size (iOS modal title)
- Semi-bold (w600)
- Adaptive color (light/dark mode)

**Style - Android:**
- 20px font size (larger Material title)
- Semi-bold (w600)
- Static black color

**Line 63:** Content section (day and time selectors)

**Line 65:** 24px spacing before buttons

**Line 67:** Action buttons (cancel/save)

## Build Content

```dart
Widget _buildContent(dynamic l10n) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 16),
      _buildDayOfWeekSelector(l10n),
      const SizedBox(height: 24),
      _buildTimeSelector(l10n)
    ]
  );
}
```

**Simple Layout:**
1. 16px top spacing
2. Day of week selector
3. 24px spacing between selectors
4. Time selector

**Pattern:** Minimal size column with fixed spacing

## Build Day Of Week Selector

```dart
Widget _buildDayOfWeekSelector(dynamic l10n) {
  final List<String> days = [
    l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday,
    l10n.friday, l10n.saturday, l10n.sunday
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.dayOfWeek,
        style: AppStyles.cardSubtitle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppStyles.black87
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
                initialItem: _selectedDayOfWeek
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
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              color: AppStyles.cardBackgroundColor,
            ),
            child: Row(
              children: [
                PlatformWidgets.platformIcon(
                  CupertinoIcons.calendar,
                  color: AppStyles.primary600,
                  size: 20
                ),
                const SizedBox(width: 12),
                Text(days[_selectedDayOfWeek], style: AppStyles.bodyText),
                const Spacer(),
                PlatformWidgets.platformIcon(
                  CupertinoIcons.chevron_down,
                  color: AppStyles.grey600
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
```

### Detailed Analysis

**Lines 79:** Day Names Array
```dart
final List<String> days = [
  l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday,
  l10n.friday, l10n.saturday, l10n.sunday
];
```
- **Localized:** All day names from l10n
- **Order:** Monday-first (ISO 8601)
- **Usage:** Array indices match _selectedDayOfWeek values

**Lines 84-87:** Section Label**
- "Day of Week"
- 14px, semi-bold
- 8px spacing below

### iOS Implementation (Lines 90-106)

```dart
if (PlatformDetection.isIOS)
  SizedBox(
    height: 120,
    child: CupertinoPicker(
      itemExtent: 32,
      scrollController: FixedExtentScrollController(
        initialItem: _selectedDayOfWeek
      ),
      onSelectedItemChanged: (index) {
        setState(() {
          _selectedDayOfWeek = index;
        });
      },
      children: days.map((day) => Center(child: Text(day))).toList(),
    ),
  )
```

**CupertinoPicker:**
- iOS-style scrolling drum picker
- **Height:** 120px fixed
- **itemExtent:** 32px per item
- **ScrollController:** FixedExtentScrollController positions initial selection
- **Initial Item:** _selectedDayOfWeek (scrolls to selected day)
- **Callback:** onSelectedItemChanged updates state
- **Children:** Centered text for each day

**Pattern:** Inline iOS picker (no modal)

### Android Implementation (Lines 107-128)

```dart
else
  GestureDetector(
    onTap: () => _showDayPicker(days, l10n),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppStyles.grey300),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        color: AppStyles.cardBackgroundColor,
      ),
      child: Row(
        children: [
          PlatformWidgets.platformIcon(
            CupertinoIcons.calendar,
            color: AppStyles.primary600,
            size: 20
          ),
          const SizedBox(width: 12),
          Text(days[_selectedDayOfWeek], style: AppStyles.bodyText),
          const Spacer(),
          PlatformWidgets.platformIcon(
            CupertinoIcons.chevron_down,
            color: AppStyles.grey600
          ),
        ],
      ),
    ),
  ),
```

**Clickable Container:**
- Full width
- Border, rounded corners, padding
- Shows modal picker on tap (_showDayPicker)

**Row Content:**
- Calendar icon (primary color)
- 12px gap
- Selected day name
- Spacer (pushes chevron right)
- Chevron down icon (indicates dropdown)

**Pattern:** Looks like dropdown, opens modal picker

## Build Time Selector

```dart
Widget _buildTimeSelector(dynamic l10n) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.time,
        style: AppStyles.cardSubtitle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppStyles.black87
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
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            color: AppStyles.cardBackgroundColor,
          ),
          child: Row(
            children: [
              PlatformWidgets.platformIcon(
                CupertinoIcons.time,
                color: AppStyles.primary600,
                size: 20
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
```

**Structure:** Same as Android day selector

**Differences:**
- Label: "Time"
- Icon: Clock icon
- Display: `_selectedTime.format(context)` (e.g., "6:00 PM")
- Tap handler: `_selectTime` (platform-branching method)

**Pattern:** Both platforms use modal for time selection

## Select Time

```dart
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
                  2024, 1, 1,
                  _selectedTime.hour,
                  _selectedTime.minute
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
```

### Detailed Analysis

**Line 167:** Bottom inset capture
```dart
final bottomInset = MediaQuery.of(context).viewInsets.bottom;
```
- **Purpose:** Account for keyboard height
- **Usage:** Margin bottom for iOS picker
- **Prevents:** Picker hidden by keyboard

### iOS Path (Lines 169-199)

**Lines 170-199: CupertinoDatePicker Modal**

**Container Setup:**
- **Height:** 200px fixed
- **Top Padding:** 6px
- **Bottom Margin:** bottomInset (keyboard avoidance)
- **Color:** System background (adaptive)

**SafeArea:**
- `top: false` - Don't add top padding (already handled)
- Ensures picker doesn't go under safe area

**CupertinoDatePicker (Lines 181-193):**
```dart
CupertinoDatePicker(
  mode: CupertinoDatePickerMode.time,
  initialDateTime: DateTime(
    2024, 1, 1,
    _selectedTime.hour,
    _selectedTime.minute
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
)
```

**Mode:** `CupertinoDatePickerMode.time` (time-only picker)

**InitialDateTime:**
- Date is arbitrary (2024-01-01)
- Hour and minute from _selectedTime
- **Rationale:** CupertinoDatePicker requires DateTime, but only time matters

**onDateTimeChanged:**
- **Called:** Every scroll (real-time updates)
- **Mounted Check:** Critical before setState (picker is in modal)
- **Conversion:** DateTime → TimeOfDay
- **Pattern:** Immediate state update (no save button)

**minuteInterval:** 5 (allows 00, 05, 10, ..., 55)
- Aligns with ensureFiveMinuteInterval on save

### Android Path (Lines 200-210)

```dart
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
```

**Custom Picker:**
- Awaits `_showCustomTimePicker()` result
- Returns `TimeOfDay?` (null if cancelled)

**Mounted Check:**
- After await (modal might have closed widget)

**Update:**
- Only if picked is not null
- Sets _selectedTime to picked value

## Build Actions

```dart
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
                  fontWeight: FontWeight.w500
                )
              : AppStyles.bodyText.copyWith(
                  color: AppStyles.grey600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500
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
            borderRadius: BorderRadius.circular(8)
          ),
          child: Text(
            l10n.save,
            style: AppStyles.buttonText.copyWith(
              color: AppStyles.white,
              fontSize: 16,
              fontWeight: FontWeight.w600
            ),
          ),
        ),
      ),
    ],
  );
}
```

**Layout:** Right-aligned row

**Cancel Button (Lines 217-226):**
- **Action:** Pops dialog (returns null)
- **Styling:**
  - **iOS:** Blue text (standard iOS cancel)
  - **Android:** Gray text
- **Pattern:** Text-only button

**Save Button (Lines 230-240):**
- **Action:** Calls _savePattern
- **Styling:**
  - **Background:**
    - iOS: System blue
    - Android: Primary color
  - **Text:** White, bold
  - **Padding:** More padding than cancel (emphasis)
  - **Border Radius:** 8px rounded
- **Pattern:** Filled button (primary action)

## Show Day Picker (Android)

```dart
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
            PlatformDetection.isIOS ? 14 : 12
          ),
          boxShadow: [
            BoxShadow(
              color: AppStyles.colorWithOpacity(AppStyles.black87, 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4)
            )
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
                  : AppStyles.black87
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
                    horizontal: 16
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: _selectedDayOfWeek == index
                      ? AppStyles.colorWithOpacity(AppStyles.primary600, 0.1)
                      : AppStyles.transparent,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDayOfWeek == index
                        ? AppStyles.primary600
                        : AppStyles.black87
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
```

### Detailed Analysis

**Modal Container:**
- 280px width
- 24px margin, 16px padding
- Same styling as main dialog

**Title:** "Day of Week" (16px, semi-bold)

**Lines 266-283: Day List**
```dart
...List.generate(
  days.length,
  (index) => GestureDetector(
    onTap: () {
      setState(() {
        _selectedDayOfWeek = index;
      });
      Navigator.of(context).pop();
    },
    child: /* styled container */
  ),
),
```

**List.generate:**
- Creates 7 GestureDetector widgets (one per day)
- Spread operator inserts all into Column children

**OnTap Logic:**
1. **setState:** Update _selectedDayOfWeek
2. **Pop:** Close modal immediately
- **Pattern:** Select and close (no separate save button)

**Styling:**
- **Selected:** Light blue background (10% opacity), primary text color
- **Unselected:** Transparent background, black text
- **Padding:** 12px vertical, 16px horizontal
- **Margin:** 4px bottom (spacing between items)
- **Border Radius:** 8px rounded corners

**Pattern:** Radio-button-style list

## Show Custom Time Picker (Android)

```dart
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
            PlatformWidgets.isIOS ? 14 : 12
          ),
          boxShadow: [
            BoxShadow(
              color: AppStyles.colorWithOpacity(AppStyles.black87, 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4)
            )
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
                  : AppStyles.black87
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour picker
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
                          minute: selectedTime?.minute ?? 0
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
                              : AppStyles.grey500
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  l10n.colon,
                  style: AppStyles.headlineSmall.copyWith(fontSize: 24)
                ),

                // Minute picker
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
                            minute: minute
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
                                : AppStyles.grey600
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
            // Cancel and Save buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8
                    ),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(fontSize: 16, color: AppStyles.grey600)
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(selectedTime),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10
                    ),
                    decoration: BoxDecoration(
                      color: AppStyles.primary600,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(
                      l10n.save,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.white
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
```

### Detailed Analysis

**Line 293:** Local selectedTime variable
```dart
TimeOfDay? selectedTime = _selectedTime;
```
- **Purpose:** Temporary state for modal
- **Pattern:** Don't update widget state until save
- **Allows:** Cancel to discard changes

**Modal Structure:**
- 300px width container
- Title: "Time"
- Hour and minute pickers side by side
- Colon separator
- Cancel/Save buttons

### Hour Picker (Lines 319-339)

```dart
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
          minute: selectedTime?.minute ?? 0
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
              : AppStyles.grey500
          ),
        ),
      ),
    ),
  ),
),
```

**ListView.builder:**
- 24 items (0-23 hours)
- Scrollable (ClampingScrollPhysics)
- 80px width, 100px height

**OnTap:**
```dart
selectedTime = TimeOfDay(
  hour: hour,
  minute: selectedTime?.minute ?? 0
);
```
- Creates new TimeOfDay with selected hour
- Preserves existing minute (or 0 if null)
- **Pattern:** Immediate local state update (no setState needed)

**Styling:**
- Zero-padded: "00", "01", ..., "23"
- **Selected:** Primary color
- **Unselected:** Gray

### Minute Picker (Lines 342-366)

**Identical Structure:**
- 12 items (0, 5, 10, ..., 55)
- `final minute = index * 5` (5-minute intervals)
- OnTap creates new TimeOfDay with selected minute
- Preserves hour

**Pattern:** Coordinated hour-minute selection

### Action Buttons (Lines 370-393)

**Cancel Button:**
```dart
onTap: () => Navigator.of(context).pop(),
```
- Pops without value (returns null)

**Save Button:**
```dart
onTap: () => Navigator.of(context).pop(selectedTime),
```
- Pops with selectedTime value
- **Returns:** TimeOfDay? (the result)

**Line 401:** Return result
```dart
return result;
```
- Returns modal result (TimeOfDay? or null)

## Save Pattern

```dart
void _savePattern() {
  final timeString =
      '${_selectedTime.hour.toString().padLeft(2, '0')}:'
      '${_selectedTime.minute.toString().padLeft(2, '0')}:00';

  final pattern = RecurrencePattern(
    id: widget.pattern?.id,
    eventId: widget.eventId,
    dayOfWeek: _selectedDayOfWeek,
    time: timeString,
    createdAt: widget.pattern?.createdAt
  ).ensureFiveMinuteInterval();

  Navigator.of(context).pop(pattern);
}
```

### Detailed Analysis

**Lines 405-407: Time String Formatting**
```dart
final timeString =
    '${_selectedTime.hour.toString().padLeft(2, '0')}:'
    '${_selectedTime.minute.toString().padLeft(2, '0')}:00';
```

**Format:** "HH:MM:SS"
- Hour: Zero-padded (14 → "14", 5 → "05")
- Minute: Zero-padded (30 → "30", 5 → "05")
- Seconds: Always "00"

**Example:**
- Input: TimeOfDay(hour: 14, minute: 30)
- Output: "14:30:00"

**Lines 409-410: RecurrencePattern Creation**
```dart
final pattern = RecurrencePattern(
  id: widget.pattern?.id,
  eventId: widget.eventId,
  dayOfWeek: _selectedDayOfWeek,
  time: timeString,
  createdAt: widget.pattern?.createdAt
).ensureFiveMinuteInterval();
```

**Properties:**
- **id:** Preserves existing ID (edit) or null (create)
- **eventId:** From widget prop
- **dayOfWeek:** From state (0-6)
- **time:** Formatted string
- **createdAt:** Preserves existing timestamp or null

**ensureFiveMinuteInterval():**
- Method on RecurrencePattern
- Rounds time to nearest 5-minute interval
- **Rationale:** Backend constraint or business logic
- **Example:** "14:32:00" → "14:30:00"

**Line 412: Pop with Result**
```dart
Navigator.of(context).pop(pattern);
```
- Closes dialog
- Returns RecurrencePattern to caller
- **Usage:** `final pattern = await showDialog(...)`

## Technical Characteristics

### Platform Adaptation Strategy
- **iOS:** Inline CupertinoPicker for day, modal CupertinoDatePicker for time
- **Android:** Modal dropdown for day, custom scrollable picker for time
- **Styling:** Different colors, sizes, fonts per platform
- **Pattern:** Complete visual consistency with platform conventions

### State Management
- **Local State:** _selectedDayOfWeek and _selectedTime
- **Temporary State:** selectedTime in custom time picker
- **No External State:** Self-contained dialog
- **Result Pattern:** Returns value on save, null on cancel

### Time Handling
- **Storage:** "HH:MM:SS" string format
- **UI:** TimeOfDay object
- **Conversion:** Bidirectional (parse on init, format on save)
- **Rounding:** ensureFiveMinuteInterval() enforces granularity
- **Intervals:** 5-minute intervals in pickers

### Modal Coordination
- **Nested Modals:** Pattern edit dialog contains day/time picker modals
- **PresentModal:** All modals use PlatformNavigation.presentModal
- **Return Values:** TimeOfDay? from time picker, void from day picker
- **Mounted Checks:** After all async operations

## Usage Examples

### Create New Pattern
```dart
final pattern = await showDialog<RecurrencePattern>(
  context: context,
  builder: (context) => PatternEditDialog(
    eventId: event.id,
  ),
);

if (pattern != null) {
  await patternRepository.create(pattern);
}
```

### Edit Existing Pattern
```dart
final updatedPattern = await showDialog<RecurrencePattern>(
  context: context,
  builder: (context) => PatternEditDialog(
    pattern: existingPattern,
    eventId: event.id,
  ),
);

if (updatedPattern != null) {
  await patternRepository.update(updatedPattern);
}
```

### With Full Dialog Configuration
```dart
final pattern = await showDialog<RecurrencePattern>(
  context: context,
  barrierDismissible: false, // Prevent dismiss by tapping outside
  builder: (context) => PatternEditDialog(
    pattern: pattern,
    eventId: eventId,
  ),
);

if (pattern != null) {
  setState(() {
    patterns.add(pattern);
  });
}
```

## Testing Recommendations

### Unit Tests

**1. Time String Formatting:**
```dart
test('should format time with zero padding', () {
  final dialog = PatternEditDialog(eventId: 1);
  final state = dialog.createState();
  state._selectedTime = TimeOfDay(hour: 5, minute: 5);

  state._savePattern();

  // Verify timeString is "05:05:00"
});
```

**2. Pattern Initialization:**
```dart
test('should initialize with pattern values when editing', () {
  final pattern = RecurrencePattern(
    dayOfWeek: 3,
    time: "14:30:00",
  );

  final dialog = PatternEditDialog(
    pattern: pattern,
    eventId: 1,
  );

  final state = dialog.createState();
  state.initState();

  expect(state._selectedDayOfWeek, 3);
  expect(state._selectedTime.hour, 14);
  expect(state._selectedTime.minute, 30);
});

test('should use defaults when creating new pattern', () {
  final dialog = PatternEditDialog(eventId: 1);
  final state = dialog.createState();
  state.initState();

  expect(state._selectedDayOfWeek, 0); // Monday
  expect(state._selectedTime.hour, 18); // 6 PM
  expect(state._selectedTime.minute, 0);
});
```

### Widget Tests

**1. Dialog Rendering:**
```dart
testWidgets('should show "Add Pattern" title when creating', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternEditDialog(eventId: 1),
      ),
    ),
  );

  expect(find.text(context.l10n.addPattern), findsOneWidget);
});

testWidgets('should show "Edit Pattern" title when editing', (tester) async {
  final pattern = RecurrencePattern(
    dayOfWeek: 0,
    time: "10:00:00",
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternEditDialog(
          pattern: pattern,
          eventId: 1,
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.editPattern), findsOneWidget);
});
```

**2. Cancel Button:**
```dart
testWidgets('should pop dialog without value when cancel tapped', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => PatternEditDialog(eventId: 1),
              );
              expect(result, null);
            },
            child: Text('Show'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(context.l10n.cancel));
  await tester.pumpAndSettle();

  // Dialog dismissed, result is null
});
```

**3. Save Returns Pattern:**
```dart
testWidgets('should return pattern when save tapped', (tester) async {
  RecurrencePattern? result;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<RecurrencePattern>(
                context: context,
                builder: (context) => PatternEditDialog(eventId: 1),
              );
            },
            child: Text('Show'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(context.l10n.save));
  await tester.pumpAndSettle();

  expect(result, isNotNull);
  expect(result!.eventId, 1);
});
```

## Comparison with Similar Widgets

### vs. Standard DateTimePicker
**PatternEditDialog Advantages:**
- Day of week selection (not date)
- Recurrence-specific UI
- 5-minute intervals enforced
- Custom Android time picker

**Standard Picker:**
- Date selection (year, month, day)
- Platform-standard appearance
- More familiar to users

### vs. AlertDialog with Form Fields
**PatternEditDialog:**
- Custom pickers optimized for recurrence
- Platform-adaptive styling
- Integrated validation (5-minute rounding)

**AlertDialog with Fields:**
- More flexible
- Standard Material appearance
- Requires manual picker integration

## Possible Improvements

### 1. Validation
```dart
String? _validate() {
  if (_selectedDayOfWeek < 0 || _selectedDayOfWeek > 6) {
    return "Invalid day";
  }
  return null;
}

void _savePattern() {
  final error = _validate();
  if (error != null) {
    showSnackBar(error);
    return;
  }
  // ... existing save logic
}
```

### 2. Scroll to Selected Time
```dart
// In custom time picker:
final hourController = ScrollController(
  initialScrollOffset: _selectedTime.hour * 40.0,
);
```

### 3. Haptic Feedback
```dart
onSelectedItemChanged: (index) {
  HapticFeedback.selectionClick();
  setState(() {
    _selectedDayOfWeek = index;
  });
}
```

### 4. Keyboard Shortcuts
```dart
@override
Widget build(BuildContext context) {
  return Shortcuts(
    shortcuts: {
      LogicalKeySet(LogicalKeyboardKey.enter): SaveIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): CancelIntent(),
    },
    child: /* dialog */,
  );
}
```

### 5. Time Range Validation
```dart
final TimeOfDay? minTime;
final TimeOfDay? maxTime;

// In time picker, disable out-of-range times
```

### 6. Quick Time Buttons
```dart
Row(
  children: [
    QuickTimeButton(time: TimeOfDay(hour: 9, minute: 0), label: "Morning"),
    QuickTimeButton(time: TimeOfDay(hour: 14, minute: 0), label: "Afternoon"),
    QuickTimeButton(time: TimeOfDay(hour: 18, minute: 0), label: "Evening"),
  ],
)
```

### 7. Recently Used Times
```dart
final recentTimes = await StorageService.getRecentTimes();

// Show above time picker
if (recentTimes.isNotEmpty)
  RecentTimesSection(times: recentTimes, onSelect: _selectTime)
```

### 8. Duration Instead of Time
```dart
final bool useDuration;

if (useDuration)
  DurationPicker(...)
else
  TimePicker(...)
```

### 9. Multiple Day Selection
```dart
final Set<int> selectedDays = {};

// Allow selecting multiple days for same time
```

### 10. Copy from Template
```dart
if (templates.isNotEmpty)
  DropdownButton<RecurrencePattern>(
    hint: Text("Use template"),
    items: templates.map((t) =>
      DropdownMenuItem(value: t, child: Text(t.label))
    ).toList(),
    onChanged: _applyTemplate,
  )
```

## Real-World Usage Context

This dialog is typically used in:

1. **Event Series Management:** Adding weekly recurring patterns
2. **Schedule Templates:** Creating weekly schedules
3. **Habit Tracking:** Setting recurring habits
4. **Calendar Apps:** Defining recurrence rules
5. **Booking Systems:** Setting availability patterns

The day-of-week + time combination is specifically designed for weekly recurrence patterns common in scheduling applications.

## Performance Considerations

- **StatefulWidget:** Manages only local selection state
- **ListView.builder:** Efficient for time picker (12-24 items)
- **No Heavy Computations:** Simple state updates
- **Modal Management:** Proper cleanup via Navigator.pop
- **Mounted Checks:** Prevents setState on disposed widgets

**Recommendation:** Suitable for frequent use. The custom time picker is lightweight and performs well even on low-end devices.

## Security Considerations

- **Input Validation:** ensureFiveMinuteInterval() enforces constraints
- **Data Sanitization:** Time parsing with error handling (try-catch recommended)
- **No User Text Input:** All selections from pickers (prevents injection)
- **eventId Validation:** Should be validated before showing dialog

**Recommendation:** Add try-catch around time string parsing in initState to handle malformed data gracefully.
