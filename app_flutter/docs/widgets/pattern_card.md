# PatternCard Widget

## Overview
`PatternCard` is a StatelessWidget that displays a recurrence pattern (day of week and time) in a visually appealing card format with optional edit and delete actions. The widget is used to show individual patterns within a recurring event series, providing a consistent interface for viewing and managing weekly recurring events.

## File Location
`lib/widgets/pattern_card.dart`

## Dependencies
```dart
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/recurrence_pattern.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'base_card.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
```

**Key Dependencies:**
- `recurrence_pattern.dart`: Core model containing dayOfWeek, time, id, eventId properties
- `base_card.dart`: Wrapper providing standard card styling and elevation
- `adaptive_button.dart`: Platform-adaptive button for edit/delete actions
- `platform_widgets.dart`: Platform-adaptive icon rendering
- `l10n_helpers.dart`: Localization for day names, edit/delete labels, and colon separator
- `app_constants.dart`: Spacing constants (`defaultPadding`, `smallPadding`, `defaultBorderRadius`)
- `app_styles.dart`: Colors (`primary600`, `grey600`) and text styles (`cardTitle`, `bodyText`)

## Class Declaration

```dart
class PatternCard extends StatelessWidget {
```

**Type:** StatelessWidget

**Rationale:** This widget displays data from a RecurrencePattern model and triggers callbacks for user actions. It has no internal state to manage - all state (pattern data, enabled status) comes from parent widgets.

## Properties

```dart
final RecurrencePattern pattern;
final VoidCallback? onEdit;
final VoidCallback? onDelete;
final bool enabled;
final bool showActions;
```

### Property Analysis

**pattern** (`RecurrencePattern`):
- **Type:** Required, non-nullable
- **Purpose:** Core data model containing the recurrence pattern information
- **Expected Properties:**
  - `dayOfWeek`: Integer (0-6, where 0 = Monday, 6 = Sunday)
  - `time`: String in 24-hour format (e.g., "14:30")
  - `id`: Nullable integer for pattern identification
  - `eventId`: Integer linking pattern to parent event
  - `isValidDayOfWeek`: Boolean computed property for validation
- **Usage:** Determines what text to display and how to generate stable keys

**onEdit** (`VoidCallback?`):
- **Type:** Optional nullable callback
- **Purpose:** Called when user taps the edit button
- **Visibility Control:** If null, edit button is not displayed
- **Enabled Control:** Passes null to button's onPressed when widget is disabled
- **Typical Usage:** Opens a dialog or navigates to pattern editing screen

**onDelete** (`VoidCallback?`):
- **Type:** Optional nullable callback
- **Purpose:** Called when user taps the delete button
- **Visibility Control:** If null, delete button is not displayed
- **Enabled Control:** Passes null to button's onPressed when widget is disabled
- **Typical Usage:** Shows confirmation dialog then deletes the pattern

**enabled** (`bool`):
- **Type:** Boolean with default value
- **Default:** `true`
- **Purpose:** Controls whether action buttons are interactive
- **Effect:**
  - When true: edit/delete buttons respond to taps
  - When false: buttons are grayed out and non-interactive
- **Use Cases:** Disable during async operations (saving, deleting) or when user lacks permissions

**showActions** (`bool`):
- **Type:** Boolean with default value
- **Default:** `true`
- **Purpose:** Controls visibility of the entire actions section
- **Effect:**
  - When true: shows edit/delete buttons (if callbacks provided)
  - When false: hides actions completely, card is display-only
- **Use Cases:** Read-only views, summary screens, or when actions are contextually inappropriate

## Constructor

```dart
const PatternCard({
  super.key,
  required this.pattern,
  this.onEdit,
  this.onDelete,
  this.enabled = true,
  this.showActions = true
});
```

**Constructor Type:** Const constructor (performance optimized)

**Parameters:**
- `super.key`: Standard Flutter key for widget tree management
- `required this.pattern`: Mandatory - card cannot function without pattern data
- `this.onEdit`: Optional - allows display-only cards
- `this.onDelete`: Optional - allows cards without delete functionality
- `this.enabled = true`: Sensible default assumes interactive state
- `this.showActions = true`: Sensible default assumes actions are wanted

**Design Philosophy:** Required data (pattern) is mandatory, while behavioral aspects (callbacks, enabled, showActions) have defaults for common use cases.

## Build Method

```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  final colon = l10n.colon;

  return BaseCard(
    child: Row(
      children: [
        _buildRecurrenceIcon(context),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(child: _buildPatternInfo(context, colon)),
        if (showActions && enabled) ...[
          const SizedBox(width: AppConstants.smallPadding),
          _buildActions(context)
        ],
      ],
    ),
  );
}
```

### Line-by-Line Analysis

**Line 22:** `final l10n = context.l10n;`
- Extracts localization object from context via extension method
- Used for day names, labels, and formatting
- Caches reference for reuse across build methods

**Line 23:** `final colon = l10n.colon;`
- Retrieves localized colon separator for time formatting
- **Internationalization Detail:** Some languages use different separators (e.g., ":" vs ".")
- Passed to time formatting method for consistency

**Lines 25-37:** BaseCard wrapper with Row layout
```dart
return BaseCard(
  child: Row(
    children: [
      _buildRecurrenceIcon(context),
      const SizedBox(width: AppConstants.defaultPadding),
      Expanded(child: _buildPatternInfo(context, colon)),
      if (showActions && enabled) ...[
        const SizedBox(width: AppConstants.smallPadding),
        _buildActions(context)
      ],
    ],
  ),
);
```

**Layout Structure:**
```
BaseCard
└── Row
    ├── _buildRecurrenceIcon() [40x40 fixed]
    ├── SizedBox(width: defaultPadding) [16px]
    ├── Expanded(_buildPatternInfo()) [flexible]
    ├── [Conditional] SizedBox(width: smallPadding) [8px]
    └── [Conditional] _buildActions() [auto width]
```

**BaseCard Purpose:**
- Provides consistent card styling (elevation, rounded corners, padding)
- Centralizes card appearance across app
- Handles Material/Cupertino theming

**Row Children Breakdown:**

1. **Icon (fixed width):** 40x40 container with repeat icon
2. **Spacing:** 16px gap (defaultPadding)
3. **Pattern Info (flexible):** Expanded widget takes remaining space
4. **Conditional Actions:**
   - Only rendered if both `showActions == true` AND `enabled == true`
   - Uses spread operator `...[]` to conditionally include multiple widgets
   - Includes 8px spacing before actions

**Spread Operator Pattern (Line 34):**
```dart
if (showActions && enabled) ...[
  const SizedBox(width: AppConstants.smallPadding),
  _buildActions(context)
],
```
- `...[]`: Spreads list elements into parent children list
- Allows conditional inclusion of multiple widgets
- Alternative to nested Column/Row for conditional groups
- **Condition:** Both flags must be true to show actions

## Icon Section

```dart
Widget _buildRecurrenceIcon(BuildContext context) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppStyles.colorWithOpacity(AppStyles.primary600, 0.1),
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)
    ),
    child: PlatformWidgets.platformIcon(
      CupertinoIcons.repeat,
      color: AppStyles.primary600,
      size: 20
    ),
  );
}
```

### Detailed Analysis

**Container Dimensions (Lines 42-43):**
```dart
width: 40,
height: 40,
```
- **Fixed Size:** Ensures consistent icon area across all pattern cards
- **Square Shape:** Creates balanced visual weight
- **Alignment:** Vertically aligns with first line of text

**BoxDecoration (Lines 44):**
```dart
decoration: BoxDecoration(
  color: AppStyles.colorWithOpacity(AppStyles.primary600, 0.1),
  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)
),
```

**Background Color:**
- `AppStyles.colorWithOpacity(AppStyles.primary600, 0.1)`
- Base color: `primary600` (brand primary color)
- Opacity: 0.1 (10% opacity)
- **Effect:** Subtle tinted background that hints at primary color without overwhelming
- **Pattern:** Common in Material Design 3 for icon containers

**Border Radius:**
- `BorderRadius.circular(AppConstants.defaultBorderRadius)`
- Creates rounded corners matching app's standard border radius
- **Consistency:** Same radius used across cards, buttons, and containers
- **Typical Value:** 8-12px for modern, friendly appearance

**Platform Icon (Lines 45):**
```dart
child: PlatformWidgets.platformIcon(
  CupertinoIcons.repeat,
  color: AppStyles.primary600,
  size: 20
),
```

**Icon Choice:**
- `CupertinoIcons.repeat`: Circular arrow icon representing repetition/recurrence
- **Semantic Meaning:** Universally recognized symbol for recurring events
- **Platform Adaptation:** PlatformWidgets ensures appropriate rendering on iOS/Android

**Icon Color:**
- `AppStyles.primary600`: Full-opacity primary color
- **Contrast:** 100% opacity icon on 10% opacity background provides clear visibility
- **Visual Hierarchy:** Draws attention while maintaining subtlety

**Icon Size:**
- `20`: Pixels, smaller than container (40x40) to provide breathing room
- **Centering:** Container automatically centers child

## Pattern Info Section

```dart
Widget _buildPatternInfo(BuildContext context, String colon) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _getDayName(context, pattern),
        style: AppStyles.cardTitle.copyWith(fontWeight: FontWeight.w600)
      ),
      const SizedBox(height: 4),
      Text(
        _formatTime(context, pattern.time, colon),
        style: AppStyles.bodyText.copyWith(color: AppStyles.grey600)
      ),
    ],
  );
}
```

### Layout Analysis

**Column Configuration (Lines 50-52):**
```dart
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
```

**CrossAxisAlignment.start:**
- Left-aligns both text elements
- Creates clean, readable vertical stack
- Standard pattern for card content

**MainAxisSize.min:**
- Column height shrinks to fit content
- Prevents unnecessary vertical expansion
- Important for Row's vertical centering

### Day Name Text (Lines 54)

```dart
Text(
  _getDayName(context, pattern),
  style: AppStyles.cardTitle.copyWith(fontWeight: FontWeight.w600)
),
```

**Content:** Day name retrieved via `_getDayName()` method (e.g., "Monday", "Lunes")

**Style:**
- **Base:** `AppStyles.cardTitle` (project standard for card titles)
- **Override:** `fontWeight: FontWeight.w600` (semi-bold)
- **Purpose:** Primary information, visually prominent
- **Typography Pattern:** .copyWith() preserves font size and other properties while emphasizing weight

### Spacing (Line 56)

```dart
const SizedBox(height: 4),
```
- **Gap:** 4px between day name and time
- **Const:** Compile-time optimization
- **Visual Effect:** Minimal spacing maintains visual grouping while providing separation

### Time Text (Lines 58)

```dart
Text(
  _formatTime(context, pattern.time, colon),
  style: AppStyles.bodyText.copyWith(color: AppStyles.grey600)
),
```

**Content:** Formatted time via `_formatTime()` method (e.g., "14:30")

**Style:**
- **Base:** `AppStyles.bodyText` (standard body text)
- **Color Override:** `AppStyles.grey600` (subdued gray)
- **Purpose:** Secondary information, visually subordinate to day name
- **Hierarchy:** Color difference creates clear information hierarchy

## Actions Section

```dart
Widget _buildActions(BuildContext context) {
  final l10n = context.l10n;

  final stableKey = pattern.id != null
    ? pattern.id.toString()
    : '${pattern.eventId}_${pattern.dayOfWeek}_${pattern.time}';

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (onEdit != null)
        Tooltip(
          message: l10n.edit,
          child: AdaptiveButton(
            key: Key('pattern_edit_$stableKey'),
            config: const AdaptiveButtonConfig(
              variant: ButtonVariant.icon,
              size: ButtonSize.small,
              fullWidth: false,
              iconPosition: IconPosition.only
            ),
            icon: CupertinoIcons.pencil,
            onPressed: enabled ? onEdit : null,
          ),
        ),

      if (onDelete != null)
        Tooltip(
          message: l10n.delete,
          child: AdaptiveButton(
            key: Key('pattern_delete_$stableKey'),
            config: const AdaptiveButtonConfig(
              variant: ButtonVariant.icon,
              size: ButtonSize.small,
              fullWidth: false,
              iconPosition: IconPosition.only
            ),
            icon: CupertinoIcons.trash,
            onPressed: enabled ? onDelete : null,
          ),
        ),
    ],
  );
}
```

### Stable Key Generation (Lines 66)

```dart
final stableKey = pattern.id != null
  ? pattern.id.toString()
  : '${pattern.eventId}_${pattern.dayOfWeek}_${pattern.time}';
```

**Purpose:** Creates unique, stable identifier for widget keys

**Strategy:**
1. **Primary:** Use `pattern.id` if available (database-assigned ID)
2. **Fallback:** Composite key from `eventId_dayOfWeek_time`

**Why Stable Keys Matter:**
- **Widget Identification:** Flutter uses keys to track widgets across rebuilds
- **Testing:** Allows reliable widget finding in automated tests
- **State Preservation:** Ensures correct state handling in lists
- **Animation:** Enables proper animations when patterns are reordered

**Fallback Necessity:**
- New patterns (not yet saved) don't have IDs
- Composite key from event context + pattern details provides uniqueness
- Example: "42_3_14:30" (event 42, Thursday, 14:30)

### Row Configuration (Lines 67-68)

```dart
return Row(
  mainAxisSize: MainAxisSize.min,
```

**MainAxisSize.min:** Shrinks row width to fit button content, prevents unnecessary expansion

### Edit Button (Lines 70-79)

```dart
if (onEdit != null)
  Tooltip(
    message: l10n.edit,
    child: AdaptiveButton(
      key: Key('pattern_edit_$stableKey'),
      config: const AdaptiveButtonConfig(
        variant: ButtonVariant.icon,
        size: ButtonSize.small,
        fullWidth: false,
        iconPosition: IconPosition.only
      ),
      icon: CupertinoIcons.pencil,
      onPressed: enabled ? onEdit : null,
    ),
  ),
```

**Conditional Rendering (Line 70):**
- Only shows edit button if `onEdit` callback is provided
- Pattern: presence of callback determines UI presence

**Tooltip Wrapper:**
- **Message:** Localized "Edit" text (l10n.edit)
- **Purpose:** Provides accessibility and desktop hover feedback
- **Mobile:** Shows on long-press
- **Desktop:** Shows on hover

**Button Key:**
- `Key('pattern_edit_$stableKey')`
- Unique key per pattern: "pattern_edit_42" or "pattern_edit_42_3_14:30"
- **Testing Benefit:** `find.byKey(Key('pattern_edit_42'))` in tests

**AdaptiveButtonConfig:**
```dart
variant: ButtonVariant.icon,      // Icon-only button (no text)
size: ButtonSize.small,            // Compact size for card context
fullWidth: false,                  // Don't expand to fill space
iconPosition: IconPosition.only,   // Only icon, no text label
```

**Icon:** `CupertinoIcons.pencil` (standard edit icon)

**OnPressed Logic:**
```dart
onPressed: enabled ? onEdit : null,
```
- If enabled: passes onEdit callback (button is interactive)
- If disabled: passes null (button grays out and becomes non-interactive)
- **Pattern:** Standard Flutter pattern for disabling buttons

### Delete Button (Lines 81-90)

```dart
if (onDelete != null)
  Tooltip(
    message: l10n.delete,
    child: AdaptiveButton(
      key: Key('pattern_delete_$stableKey'),
      config: const AdaptiveButtonConfig(
        variant: ButtonVariant.icon,
        size: ButtonSize.small,
        fullWidth: false,
        iconPosition: IconPosition.only
      ),
      icon: CupertinoIcons.trash,
      onPressed: enabled ? onDelete : null,
    ),
  ),
```

**Structure:** Identical to edit button with different:
- **Key:** "pattern_delete_" prefix
- **Tooltip:** l10n.delete
- **Icon:** `CupertinoIcons.trash` (trash can icon)
- **Callback:** onDelete instead of onEdit

**Design Pattern:** Consistent structure for all action buttons simplifies maintenance and testing

## Time Formatting Method

```dart
String _formatTime(BuildContext context, String time24, String colon) {
  try {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return '${hour.toString().padLeft(2, '0')}$colon${minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return time24;
  }
}
```

### Detailed Analysis

**Method Signature (Line 95):**
- **Parameters:**
  - `context`: Required for potential future localization needs
  - `time24`: Input time string (expected format: "HH:MM")
  - `colon`: Localized separator character
- **Returns:** Formatted time string

**Try-Catch Block (Lines 96-106):**
- **Purpose:** Defensive programming against malformed time strings
- **Fallback:** Returns original string if any error occurs
- **Error Sources:**
  - Invalid format (not "HH:MM")
  - Non-numeric characters
  - Parsing failures

**String Splitting (Line 97):**
```dart
final parts = time24.split(':');
```
- Splits "14:30" into ["14", "30"]
- Assumes colon separator in input (standardized)

**Validation (Line 98):**
```dart
if (parts.length < 2) return time24;
```
- **Check:** Ensures at least hour and minute parts exist
- **Fallback:** Returns original string if malformed
- **Examples:**
  - "14" → returns "14" (malformed)
  - "14:30" → continues processing (valid)
  - "14:30:00" → continues processing (valid, ignores seconds)

**Parsing (Lines 100-101):**
```dart
final hour = int.parse(parts[0]);
final minute = int.parse(parts[1]);
```
- **Conversion:** String to integer
- **Can Throw:** FormatException if non-numeric
- **Protected By:** Try-catch block

**Formatting and Return (Line 103):**
```dart
return '${hour.toString().padLeft(2, '0')}$colon${minute.toString().padLeft(2, '0')}';
```

**Step-by-Step:**
1. `hour.toString()`: Converts integer back to string (e.g., 14 → "14", 5 → "5")
2. `.padLeft(2, '0')`: Ensures 2-digit format (e.g., "5" → "05", "14" → "14")
3. `$colon`: Inserts localized separator
4. `minute.toString().padLeft(2, '0')`: Same for minutes
5. **Result:** "14:30", "05:30", etc.

**Localization Benefit:**
- Input: "14:30" (standard format)
- Output with ":" colon: "14:30"
- Output with "." colon: "14.30" (some European locales)

**Example Flows:**
- Input: "9:5", Colon: ":" → Output: "09:05"
- Input: "14:30", Colon: "." → Output: "14.30"
- Input: "invalid", Colon: ":" → Output: "invalid" (fallback)

## Day Name Method

```dart
String _getDayName(BuildContext context, RecurrencePattern pattern) {
  final l10n = context.l10n;
  final dayNames = [
    l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday,
    l10n.friday, l10n.saturday, l10n.sunday
  ];

  if (!pattern.isValidDayOfWeek) {
    return l10n.unknownError;
  }
  return dayNames[pattern.dayOfWeek];
}
```

### Detailed Analysis

**Localization Setup (Lines 110-111):**
```dart
final l10n = context.l10n;
final dayNames = [
  l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday,
  l10n.friday, l10n.saturday, l10n.sunday
];
```

**Day Names Array:**
- **Index 0:** Monday (pattern.dayOfWeek = 0)
- **Index 1:** Tuesday (pattern.dayOfWeek = 1)
- **Index 2:** Wednesday (pattern.dayOfWeek = 2)
- **Index 3:** Thursday (pattern.dayOfWeek = 3)
- **Index 4:** Friday (pattern.dayOfWeek = 4)
- **Index 5:** Saturday (pattern.dayOfWeek = 5)
- **Index 6:** Sunday (pattern.dayOfWeek = 6)

**Convention:** Monday-first week (ISO 8601 standard)

**Localization:** Each day name comes from l10n, supporting all app languages

**Validation (Lines 113-115):**
```dart
if (!pattern.isValidDayOfWeek) {
  return l10n.unknownError;
}
```

**isValidDayOfWeek Property:**
- Likely checks: `dayOfWeek >= 0 && dayOfWeek <= 6`
- Prevents array out-of-bounds errors
- Returns error string instead of crashing

**Error Handling Strategy:**
- Graceful degradation: shows error message instead of exception
- User sees "Unknown Error" instead of blank or crashed screen
- Allows bug reporting while maintaining app stability

**Array Lookup (Line 116):**
```dart
return dayNames[pattern.dayOfWeek];
```
- Direct array access using dayOfWeek as index
- **Safe:** Protected by validation check above
- **Efficient:** O(1) lookup

**Example Outputs:**
- `pattern.dayOfWeek = 0` → "Monday" (English), "Lunes" (Spanish)
- `pattern.dayOfWeek = 6` → "Sunday" (English), "Domingo" (Spanish)
- `pattern.dayOfWeek = -1` → "Unknown Error" (any language)

## Technical Characteristics

### Layout Pattern
- **Structure:** Icon-Info-Actions three-section layout
- **Flexibility:** Expanded widget for info allows text wrapping
- **Spacing:** Consistent use of AppConstants for spacing
- **Adaptability:** Actions section conditionally rendered

### Error Handling
- **Time Formatting:** Try-catch with fallback to original string
- **Day Validation:** Checks isValidDayOfWeek before array access
- **Graceful Degradation:** Shows error strings instead of crashing

### Localization Integration
- **Day Names:** Fully localized via l10n system
- **Time Separator:** Respects locale-specific colon character
- **Button Labels:** Tooltips use localized edit/delete strings
- **Error Messages:** Localized unknownError string

### State Management
- **External Control:** All state (pattern, enabled) managed by parent
- **Callback Pattern:** onEdit and onDelete for user actions
- **Visibility Control:** showActions and callback presence determine UI
- **Disable Pattern:** enabled flag controls button interactivity

### Key Generation Strategy
- **Primary:** Database ID when available
- **Fallback:** Composite key from event context
- **Stability:** Same pattern always generates same key
- **Testing:** Predictable keys for automated tests

## Usage Examples

### Basic Read-Only Display
```dart
PatternCard(
  pattern: RecurrencePattern(
    dayOfWeek: 1, // Tuesday
    time: "14:30",
    eventId: 42,
  ),
  showActions: false,
)
```

### Editable Card with Both Actions
```dart
PatternCard(
  pattern: pattern,
  onEdit: () {
    showDialog(
      context: context,
      builder: (context) => PatternEditDialog(pattern: pattern),
    );
  },
  onDelete: () async {
    final confirmed = await showConfirmationDialog(context);
    if (confirmed) {
      await patternRepository.delete(pattern.id);
    }
  },
)
```

### Disabled During Async Operation
```dart
PatternCard(
  pattern: pattern,
  onEdit: () => editPattern(pattern),
  onDelete: () => deletePattern(pattern),
  enabled: !isLoading, // Disable while operation in progress
)
```

### Edit-Only Card (No Delete)
```dart
PatternCard(
  pattern: pattern,
  onEdit: () => editPattern(pattern),
  // onDelete not provided - delete button won't appear
)
```

### List of Patterns
```dart
ListView.builder(
  itemCount: patterns.length,
  itemBuilder: (context, index) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: PatternCard(
        pattern: patterns[index],
        onEdit: () => _handleEdit(patterns[index]),
        onDelete: () => _handleDelete(patterns[index]),
      ),
    );
  },
)
```

## Testing Recommendations

### Unit Tests

**1. Time Formatting:**
```dart
test('should format time with two-digit padding', () {
  final card = PatternCard(
    pattern: RecurrencePattern(dayOfWeek: 0, time: "9:5"),
  );
  final result = card._formatTime(context, "9:5", ":");
  expect(result, "09:05");
});

test('should use localized colon separator', () {
  final card = PatternCard(pattern: pattern);
  final result = card._formatTime(context, "14:30", ".");
  expect(result, "14.30");
});

test('should return original time on parsing error', () {
  final card = PatternCard(pattern: pattern);
  final result = card._formatTime(context, "invalid", ":");
  expect(result, "invalid");
});

test('should return original time for malformed input', () {
  final card = PatternCard(pattern: pattern);
  final result = card._formatTime(context, "14", ":");
  expect(result, "14");
});
```

**2. Day Name Retrieval:**
```dart
test('should return correct day name for valid dayOfWeek', () {
  final pattern = RecurrencePattern(dayOfWeek: 0, time: "10:00");
  final card = PatternCard(pattern: pattern);
  final result = card._getDayName(context, pattern);
  expect(result, context.l10n.monday);
});

test('should return error for invalid dayOfWeek', () {
  final pattern = RecurrencePattern(dayOfWeek: -1, time: "10:00");
  final card = PatternCard(pattern: pattern);
  final result = card._getDayName(context, pattern);
  expect(result, context.l10n.unknownError);
});
```

**3. Stable Key Generation:**
```dart
test('should use pattern.id for stable key when available', () {
  final pattern = RecurrencePattern(id: 42, dayOfWeek: 0, time: "10:00");
  final card = PatternCard(pattern: pattern);
  // Access stableKey via reflection or public getter
  expect(card.stableKey, "42");
});

test('should use composite key when pattern.id is null', () {
  final pattern = RecurrencePattern(
    eventId: 10,
    dayOfWeek: 3,
    time: "14:30"
  );
  final card = PatternCard(pattern: pattern);
  expect(card.stableKey, "10_3_14:30");
});
```

### Widget Tests

**1. Layout Structure:**
```dart
testWidgets('should display icon, day name, and time', (tester) async {
  final pattern = RecurrencePattern(
    dayOfWeek: 2, // Wednesday
    time: "15:30",
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(pattern: pattern),
      ),
    ),
  );

  // Verify icon presence
  expect(find.byIcon(CupertinoIcons.repeat), findsOneWidget);

  // Verify text content
  expect(find.text(context.l10n.wednesday), findsOneWidget);
  expect(find.text("15:30"), findsOneWidget);
});
```

**2. Actions Visibility:**
```dart
testWidgets('should show edit and delete buttons when callbacks provided', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    ),
  );

  expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
  expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
});

testWidgets('should hide actions when showActions is false', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onEdit: () {},
          onDelete: () {},
          showActions: false,
        ),
      ),
    ),
  );

  expect(find.byIcon(CupertinoIcons.pencil), findsNothing);
  expect(find.byIcon(CupertinoIcons.trash), findsNothing);
});

testWidgets('should hide edit button when onEdit is null', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onDelete: () {},
        ),
      ),
    ),
  );

  expect(find.byIcon(CupertinoIcons.pencil), findsNothing);
  expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
});
```

**3. Enabled State:**
```dart
testWidgets('should disable buttons when enabled is false', (tester) async {
  bool editTapped = false;
  bool deleteTapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onEdit: () { editTapped = true; },
          onDelete: () { deleteTapped = true; },
          enabled: false,
        ),
      ),
    ),
  );

  // Try to tap buttons
  await tester.tap(find.byIcon(CupertinoIcons.pencil));
  await tester.tap(find.byIcon(CupertinoIcons.trash));
  await tester.pump();

  // Verify callbacks weren't called
  expect(editTapped, false);
  expect(deleteTapped, false);
});
```

**4. Tooltip Presence:**
```dart
testWidgets('should show tooltips on long press', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    ),
  );

  // Long press edit button
  await tester.longPress(find.byIcon(CupertinoIcons.pencil));
  await tester.pumpAndSettle();
  expect(find.text(context.l10n.edit), findsOneWidget);

  // Long press delete button
  await tester.longPress(find.byIcon(CupertinoIcons.trash));
  await tester.pumpAndSettle();
  expect(find.text(context.l10n.delete), findsOneWidget);
});
```

**5. Key Generation for Testing:**
```dart
testWidgets('should have stable keys for edit/delete buttons', (tester) async {
  final pattern = RecurrencePattern(id: 42, dayOfWeek: 0, time: "10:00");

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    ),
  );

  expect(find.byKey(Key('pattern_edit_42')), findsOneWidget);
  expect(find.byKey(Key('pattern_delete_42')), findsOneWidget);
});
```

### Integration Tests

**1. Real User Interaction:**
```dart
testWidgets('should call onEdit when edit button tapped', (tester) async {
  bool editCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onEdit: () { editCalled = true; },
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(CupertinoIcons.pencil));
  await tester.pump();

  expect(editCalled, true);
});

testWidgets('should call onDelete when delete button tapped', (tester) async {
  bool deleteCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatternCard(
          pattern: pattern,
          onDelete: () { deleteCalled = true; },
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(CupertinoIcons.trash));
  await tester.pump();

  expect(deleteCalled, true);
});
```

**2. Localization:**
```dart
testWidgets('should display localized day names', (tester) async {
  // Test Spanish locale
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale('es'),
      home: Scaffold(
        body: PatternCard(
          pattern: RecurrencePattern(dayOfWeek: 0, time: "10:00"),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text("Lunes"), findsOneWidget); // Monday in Spanish

  // Test English locale
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale('en'),
      home: Scaffold(
        body: PatternCard(
          pattern: RecurrencePattern(dayOfWeek: 0, time: "10:00"),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text("Monday"), findsOneWidget);
});
```

## Comparison with Similar Widgets

### vs. EventCard
**Similarities:**
- Both use BaseCard wrapper
- Both have action buttons (edit/delete)
- Both display primary and secondary text

**PatternCard Specifics:**
- Fixed icon (repeat symbol)
- Day + Time display (recurring event context)
- Simpler data model (RecurrencePattern vs Event)
- No tap gesture for navigation

**EventCard Specifics:**
- Dynamic icons based on event type
- Event title + description
- Navigation on tap
- More complex layout with multiple sections

### vs. SubscriptionCard
**Similarities:**
- Three-section layout (icon-info-actions)
- Conditional action buttons
- Uses BaseCard

**PatternCard Specifics:**
- Simpler data (day + time)
- Always shows fixed repeat icon
- Actions are edit/delete (not follow/unfollow)

**SubscriptionCard Specifics:**
- User avatar instead of icon
- Statistics display
- Different action types

### vs. Standard ListTile
**PatternCard Advantages:**
- Custom styling with BaseCard
- Platform-adaptive buttons
- Tooltips for actions
- Stable key generation
- Conditional rendering logic

**ListTile Advantages:**
- Built-in Material styling
- Automatic touch feedback
- More layout options (leading, trailing, subtitle)
- Density configuration

## Possible Improvements

### 1. Loading State for Actions
```dart
final bool isDeleting;
final bool isEditing;

// In _buildActions:
if (isDeleting)
  SizedBox(
    width: 32, height: 32,
    child: CircularProgressIndicator(strokeWidth: 2),
  )
else if (onDelete != null)
  // existing delete button
```
**Benefit:** Visual feedback during async operations.

### 2. Confirmation Dialog Integration
```dart
onDelete: () async {
  final confirmed = await _showDeleteConfirmation(context);
  if (confirmed) {
    onDelete?.call();
  }
},
```
**Benefit:** Prevent accidental deletions.

### 3. Swipe-to-Delete Gesture
```dart
return Dismissible(
  key: Key('pattern_${stableKey}'),
  direction: DismissDirection.endToStart,
  onDismissed: onDelete != null ? (_) => onDelete!() : null,
  background: _buildDeleteBackground(),
  child: BaseCard(/* existing content */),
);
```
**Benefit:** Alternative, mobile-friendly deletion method.

### 4. Accessibility Improvements
```dart
Semantics(
  label: "${_getDayName(context, pattern)} at ${_formatTime(...)}",
  button: true,
  child: /* card content */,
)
```
**Benefit:** Better screen reader support.

### 5. Custom Color Theming
```dart
final Color? iconColor;
final Color? iconBackgroundColor;

// In _buildRecurrenceIcon:
color: iconBackgroundColor ?? AppStyles.colorWithOpacity(...),
```
**Benefit:** Allow pattern-specific or category-specific colors.

### 6. Expandable Details
```dart
bool _isExpanded = false;

// Show additional pattern details when expanded
if (_isExpanded)
  Padding(
    padding: EdgeInsets.only(top: 8),
    child: Text("Created: ${pattern.createdAt}"),
  )
```
**Benefit:** Show additional metadata without cluttering primary view.

### 7. Analytics/Tracking
```dart
onEdit: () {
  analytics.logEvent('pattern_edit_tapped', {
    'pattern_id': pattern.id,
    'day_of_week': pattern.dayOfWeek,
  });
  onEdit?.call();
},
```
**Benefit:** Understanding user interaction patterns.

### 8. Haptic Feedback
```dart
import 'package:flutter/services.dart';

onPressed: enabled ? () {
  HapticFeedback.lightImpact();
  onEdit?.call();
} : null,
```
**Benefit:** Tactile confirmation of button press.

### 9. Badge for Active/Inactive Patterns
```dart
final bool isActive;

// In icon container:
Stack(
  children: [
    /* existing icon container */,
    if (!isActive)
      Positioned(
        right: 0, top: 0,
        child: Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
  ],
)
```
**Benefit:** Visual indicator for suspended/inactive patterns.

### 10. Error State Display
```dart
final String? errorMessage;

// Below time text:
if (errorMessage != null)
  Text(
    errorMessage,
    style: TextStyle(color: Colors.red, fontSize: 12),
  )
```
**Benefit:** Show pattern-specific errors (e.g., conflicts, past dates).

## Real-World Usage Context

This widget is primarily used in:

1. **Event Series Management:** Display list of recurring patterns for a weekly event series
2. **Recurrence Pattern Editor:** Show existing patterns while allowing edits
3. **Event Detail Screen:** Display summary of recurring patterns
4. **Calendar Views:** Show which days/times have recurring events
5. **Pattern Conflict Resolution:** Display conflicting patterns for user review

The combination of display and action capabilities makes it versatile for both read-only and interactive contexts.

## Performance Considerations

- **Const Constructor:** Enables widget caching when possible
- **Stateless Design:** No setState() overhead, rebuilds only when parent changes
- **Minimal Computations:** Time formatting and day lookup are O(1) operations
- **Efficient Layout:** Row + Expanded avoids complex constraint calculations
- **Error Handling:** Try-catch ensures no runtime crashes from bad data

**Recommendation:** Suitable for use in scrollable lists with many pattern cards. Consider implementing list view optimizations (builders, lazy loading) for very large pattern lists (100+).
