# RecurringEventToggle Widget

## Overview
`RecurringEventToggle` is a platform-adaptive StatelessWidget that provides a consistent toggle interface for enabling/disabling recurring events across iOS and Android platforms. The widget automatically switches between Cupertino (iOS) and Material Design (Android) implementations based on the current platform, maintaining native look and feel while providing a unified API.

## File Location
`lib/widgets/recurring_event_toggle.dart`

## Dependencies
```dart
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
```

**Key Dependencies:**
- `platform_detection.dart`: Provides `PlatformDetection.isIOS` for platform detection
- `platform_widgets.dart`: Used in Material variant for `PlatformWidgets.platformSwitch()`
- `app_constants.dart`: Font size constants (`bodyFontSize`, `captionFontSize`)
- `l10n_helpers.dart`: Localization extensions for `context.l10n.recurringEvent` and `context.l10n.recurringEventHelperText`
- `app_styles.dart`: Predefined text styles and colors (`bodyText`, `bodyTextSmall`, `grey600`)

## Class Declaration

```dart
class RecurringEventToggle extends StatelessWidget {
```

**Type:** StatelessWidget

**Rationale for Stateless:** This widget is stateless because it doesn't manage any internal state. The toggle value and enabled state are controlled by the parent widget through the `value` and `enabled` properties, following the controlled component pattern.

## Properties

```dart
final String? labelText;
final String? helperText;
final bool value;
final ValueChanged<bool> onChanged;
final bool enabled;
```

### Property Analysis

**labelText** (`String?`):
- **Type:** Nullable String
- **Purpose:** Main label displayed above the toggle switch
- **Default Behavior:** If null, falls back to `context.l10n.recurringEvent` localized string
- **Usage:** Allows customization of the label text while providing a sensible default for recurring event contexts
- **Example:** "Evento recurrente" (Spanish), "Recurring Event" (English)

**helperText** (`String?`):
- **Type:** Nullable String
- **Purpose:** Explanatory text displayed below the label to provide additional context
- **Default Behavior:** If null, falls back to `context.l10n.recurringEventHelperText` localized string
- **Usage:** Helps users understand what enabling the toggle will do
- **Example:** "Este evento se repetirá según el patrón especificado"

**value** (`bool`):
- **Type:** Required boolean
- **Purpose:** Current state of the toggle (true = enabled, false = disabled)
- **Pattern:** Controlled component - parent manages state
- **Usage:** Reflects whether recurring event functionality is currently enabled

**onChanged** (`ValueChanged<bool>`):
- **Type:** Required callback function `void Function(bool)`
- **Purpose:** Called when user taps the toggle to change its state
- **Parameter:** New boolean value after the change
- **Pattern:** Standard Flutter callback pattern for interactive widgets
- **Critical Detail:** Can be set to `null` indirectly through the `enabled` property

**enabled** (`bool`):
- **Type:** Boolean with default value
- **Default:** `true`
- **Purpose:** Controls whether the toggle is interactive or disabled
- **Implementation:** When false, passes `null` to the switch's onChanged callback, disabling interaction
- **Visual Effect:** Disabled toggles appear grayed out automatically by the platform switch widgets

## Constructor

```dart
const RecurringEventToggle({
  super.key,
  this.labelText,
  this.helperText,
  required this.value,
  required this.onChanged,
  this.enabled = true
});
```

**Constructor Type:** Const constructor (optimized for performance)

**Parameters:**
- `super.key`: Standard Flutter key for widget identification
- `this.labelText`: Optional, allows null for default localized text
- `this.helperText`: Optional, allows null for default localized text
- `required this.value`: Mandatory current toggle state
- `required this.onChanged`: Mandatory callback for state changes
- `this.enabled = true`: Optional with default value, makes most use cases simpler

**Design Pattern:** Builder pattern with sensible defaults for localized text while requiring core interactive properties.

## Build Method

```dart
@override
Widget build(BuildContext context) {
  final isIOS = PlatformDetection.isIOS;

  if (isIOS) {
    return _buildCupertinoToggle(context);
  } else {
    return _buildMaterialToggle(context);
  }
}
```

### Line-by-Line Analysis

**Line 19:** `final isIOS = PlatformDetection.isIOS;`
- Detects current platform using the `PlatformDetection` utility
- Stores result in local variable for clarity and potential future optimization
- Returns boolean: true for iOS, false for Android/other platforms

**Lines 21-25:** Platform selection logic
- Simple conditional: iOS → Cupertino, otherwise → Material
- Clean separation of concerns: platform detection in build(), UI construction in private methods
- Return type is Widget in both branches, ensuring type safety

**Pattern Benefits:**
- Single source of truth for platform detection
- Easy to test (mock `PlatformDetection.isIOS`)
- Clear separation between decision logic and UI construction
- Could be extended to support other platforms (web, desktop) in the future

## Material Toggle Implementation

```dart
Widget _buildMaterialToggle(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelText ?? context.l10n.recurringEvent,
                  style: AppStyles.bodyText.copyWith(
                    fontSize: AppConstants.bodyFontSize,
                    fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  helperText ?? context.l10n.recurringEventHelperText,
                  style: AppStyles.bodyTextSmall.copyWith(
                    fontSize: AppConstants.captionFontSize,
                    color: AppStyles.grey600
                  ),
                ),
              ],
            ),
          ),
          PlatformWidgets.platformSwitch(
            value: value,
            onChanged: enabled ? onChanged : null
          ),
        ],
      ),
    ],
  );
}
```

### Structural Analysis

**Layout Hierarchy:**
```
Column (crossAxisAlignment: start)
└── Row
    ├── Expanded
    │   └── Column (crossAxisAlignment: start)
    │       ├── Text (label)
    │       ├── SizedBox(height: 4)
    │       └── Text (helper)
    └── PlatformSwitch
```

### Component Breakdown

**Outer Column (Lines 29-30):**
- **Purpose:** Wrapper container for potential future expansion (e.g., adding bottom margin)
- **CrossAxisAlignment:** `.start` ensures left alignment
- **Current State:** Contains only one child (Row), but maintains consistent structure with Cupertino variant

**Row (Lines 32-52):**
- **Purpose:** Horizontal layout placing text labels on left, switch on right
- **Children:** Expanded text column + switch widget
- **Flex Behavior:** Expanded takes all available space except switch width

**Expanded Widget (Lines 34-49):**
- **Critical Role:** Ensures text labels take all available horizontal space, preventing overflow
- **Contains:** Nested column with two text widgets
- **Flex:** Default flex=1, pushes against the fixed-width switch

**Inner Text Column (Lines 35-48):**
- **Purpose:** Vertical stacking of label and helper text
- **CrossAxisAlignment:** `.start` for left alignment
- **Spacing:** 4px SizedBox between texts

**Label Text (Lines 38-41):**
```dart
Text(
  labelText ?? context.l10n.recurringEvent,
  style: AppStyles.bodyText.copyWith(
    fontSize: AppConstants.bodyFontSize,
    fontWeight: FontWeight.w500
  ),
),
```
- **Content:** Custom label or fallback to localized "Recurring Event"
- **Null Coalescing:** `labelText ?? context.l10n.recurringEvent` provides type-safe default
- **Style Base:** `AppStyles.bodyText` (project standard for body content)
- **Font Size:** Override with `AppConstants.bodyFontSize` (ensures consistency across app)
- **Font Weight:** `w500` (medium weight) for visual hierarchy emphasis
- **Pattern:** `.copyWith()` preserves base style while overriding specific properties

**Spacing SizedBox (Line 42):**
```dart
const SizedBox(height: 4),
```
- **Purpose:** Fixed 4-pixel vertical gap between label and helper text
- **Const:** Compile-time constant optimization
- **Size:** Small gap maintains visual grouping while providing breathing room

**Helper Text (Lines 43-46):**
```dart
Text(
  helperText ?? context.l10n.recurringEventHelperText,
  style: AppStyles.bodyTextSmall.copyWith(
    fontSize: AppConstants.captionFontSize,
    color: AppStyles.grey600
  ),
),
```
- **Content:** Custom helper or fallback to localized explanation
- **Null Coalescing:** Same pattern as label text
- **Style Base:** `AppStyles.bodyTextSmall` (smaller variant for secondary text)
- **Font Size:** `AppConstants.captionFontSize` (smaller than label)
- **Color:** `AppStyles.grey600` (subdued color for secondary text, provides visual hierarchy)
- **Pattern:** Consistent .copyWith() approach

**Platform Switch (Lines 50):**
```dart
PlatformWidgets.platformSwitch(
  value: value,
  onChanged: enabled ? onChanged : null
),
```
- **Widget Type:** `PlatformWidgets.platformSwitch()` factory method
- **Behavior:** Creates Material Switch on Android, CupertinoSwitch on iOS
- **Value:** Current toggle state from widget property
- **OnChanged Logic:**
  - If `enabled == true`: passes `onChanged` callback (switch is interactive)
  - If `enabled == false`: passes `null` (switch becomes disabled/grayed out)
- **Disabled Pattern:** Passing `null` to onChanged is Flutter's standard for disabling interactive widgets

## Cupertino Toggle Implementation

```dart
Widget _buildCupertinoToggle(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelText ?? context.l10n.recurringEvent,
                  style: TextStyle(
                    fontSize: AppConstants.bodyFontSize,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.label.resolveFrom(context),
                    decoration: TextDecoration.none
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  helperText ?? context.l10n.recurringEventHelperText,
                  style: TextStyle(
                    fontSize: AppConstants.captionFontSize,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    decoration: TextDecoration.none
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: enabled ? onChanged : null
          ),
        ],
      ),
    ],
  );
}
```

### Structural Analysis

**Layout Structure:** Identical to Material variant
```
Column (crossAxisAlignment: start)
└── Row
    ├── Expanded
    │   └── Column (crossAxisAlignment: start)
    │       ├── Text (label)
    │       ├── SizedBox(height: 4)
    │       └── Text (helper)
    └── CupertinoSwitch
```

### Key Differences from Material Variant

**1. Direct TextStyle Construction:**
- Material uses `AppStyles.bodyText.copyWith()`
- Cupertino uses `TextStyle()` constructor directly
- **Rationale:** Cupertino styles need platform-specific color resolution

**2. Cupertino-Specific Colors:**

**Label Text (Lines 68-70):**
```dart
style: TextStyle(
  fontSize: AppConstants.bodyFontSize,
  fontWeight: FontWeight.w500,
  color: CupertinoColors.label.resolveFrom(context),
  decoration: TextDecoration.none
),
```
- **Color:** `CupertinoColors.label.resolveFrom(context)`
  - `.resolveFrom(context)`: Critical method that adapts color to light/dark mode
  - Returns appropriate color based on current `Brightness` theme
  - Light mode: near-black text
  - Dark mode: near-white text
  - **Pattern:** iOS standard for primary text content

**Helper Text (Lines 73-75):**
```dart
style: TextStyle(
  fontSize: AppConstants.captionFontSize,
  color: CupertinoColors.secondaryLabel.resolveFrom(context),
  decoration: TextDecoration.none
),
```
- **Color:** `CupertinoColors.secondaryLabel.resolveFrom(context)`
  - Secondary label is more subdued than primary label
  - Light mode: medium gray
  - Dark mode: lighter gray (but darker than label)
  - **Pattern:** iOS standard for secondary/explanatory text

**3. TextDecoration.none:**
- **Purpose:** Explicitly removes any text decoration (underlines, etc.)
- **Necessity:** Required in Cupertino widgets to avoid default decorations
- **Absent in Material:** Material Text widgets don't have default decorations

**4. Switch Widget:**
```dart
CupertinoSwitch(
  value: value,
  onChanged: enabled ? onChanged : null
),
```
- **Type:** Direct `CupertinoSwitch` (not using PlatformWidgets factory)
- **Behavior:** iOS-style toggle with green/gray states
- **OnChanged Logic:** Identical to Material (null when disabled)
- **Visual Appearance:**
  - Active (on): iOS green color
  - Inactive (off): light gray
  - Disabled: same colors but with reduced opacity

## Technical Characteristics

### Platform Adaptation Strategy
- **Detection Method:** Runtime platform check using `PlatformDetection.isIOS`
- **Implementation:** Complete separation of Material and Cupertino code paths
- **Consistency:** Identical layout structure in both variants ensures predictable behavior

### Color Adaptation
- **Material:** Static colors from `AppStyles.grey600`
- **Cupertino:** Dynamic colors via `.resolveFrom(context)` for automatic dark mode support
- **Trade-off:** Material variant may need manual dark mode theming

### Text Styling Approach
- **Material:** Based on AppStyles with .copyWith() modifications
- **Cupertino:** Direct TextStyle construction for platform color integration
- **Consistency:** Both use AppConstants for font sizes

### State Management Pattern
- **External State Control:** Widget receives `value` and `onChanged` from parent
- **No Internal State:** Completely stateless, makes testing and predictability easier
- **Disabled State:** Implemented via conditional callback (not separate boolean property in switch)

### Localization Integration
- **Fallback Pattern:** `labelText ?? context.l10n.recurringEvent`
- **Benefits:**
  - Allows custom text when needed
  - Provides sensible defaults without requiring every caller to pass text
  - Leverages l10n system for multi-language support

## Usage Examples

### Basic Usage (Default Labels)
```dart
RecurringEventToggle(
  value: isRecurring,
  onChanged: (bool newValue) {
    setState(() {
      isRecurring = newValue;
    });
  },
)
```

### Custom Labels
```dart
RecurringEventToggle(
  labelText: "Repeat this booking",
  helperText: "Automatically create future bookings",
  value: repeatBooking,
  onChanged: (newValue) => setState(() => repeatBooking = newValue),
)
```

### Disabled State
```dart
RecurringEventToggle(
  value: isRecurring,
  onChanged: (newValue) => setState(() => isRecurring = newValue),
  enabled: false, // Toggle is grayed out and non-interactive
)
```

### Form Integration with Validation
```dart
RecurringEventToggle(
  value: formData.isRecurring,
  onChanged: (newValue) {
    setState(() {
      formData.isRecurring = newValue;
      if (!newValue) {
        // Clear recurrence pattern when disabling
        formData.recurrencePattern = null;
      }
    });
  },
  enabled: formData.canEditRecurrence,
)
```

## Testing Recommendations

### Unit Tests

**1. Constructor and Properties:**
```dart
test('should initialize with default enabled = true', () {
  final widget = RecurringEventToggle(
    value: false,
    onChanged: (_) {},
  );
  expect(widget.enabled, true);
});

test('should accept custom label and helper text', () {
  final widget = RecurringEventToggle(
    labelText: "Custom Label",
    helperText: "Custom Helper",
    value: true,
    onChanged: (_) {},
  );
  expect(widget.labelText, "Custom Label");
  expect(widget.helperText, "Custom Helper");
});
```

**2. Platform Switching:**
```dart
testWidgets('should build Material toggle on Android', (tester) async {
  // Mock PlatformDetection.isIOS to return false
  await tester.pumpWidget(
    MaterialApp(
      home: RecurringEventToggle(
        value: false,
        onChanged: (_) {},
      ),
    ),
  );

  // Verify Material switch is used
  expect(find.byType(Switch), findsOneWidget);
});

testWidgets('should build Cupertino toggle on iOS', (tester) async {
  // Mock PlatformDetection.isIOS to return true
  await tester.pumpWidget(
    CupertinoApp(
      home: RecurringEventToggle(
        value: false,
        onChanged: (_) {},
      ),
    ),
  );

  expect(find.byType(CupertinoSwitch), findsOneWidget);
});
```

**3. Localization Fallbacks:**
```dart
testWidgets('should use localized text when labelText is null', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale('es'),
      home: RecurringEventToggle(
        value: false,
        onChanged: (_) {},
      ),
    ),
  );

  // Verify localized text appears
  expect(find.text(context.l10n.recurringEvent), findsOneWidget);
  expect(find.text(context.l10n.recurringEventHelperText), findsOneWidget);
});
```

**4. Enabled/Disabled Behavior:**
```dart
testWidgets('should disable switch when enabled = false', (tester) async {
  bool switchTapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: RecurringEventToggle(
        value: false,
        onChanged: (_) { switchTapped = true; },
        enabled: false,
      ),
    ),
  );

  // Try to tap the switch
  await tester.tap(find.byType(Switch));
  await tester.pump();

  // Verify callback wasn't called
  expect(switchTapped, false);
});

testWidgets('should enable switch when enabled = true', (tester) async {
  bool switchTapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: RecurringEventToggle(
        value: false,
        onChanged: (_) { switchTapped = true; },
        enabled: true,
      ),
    ),
  );

  await tester.tap(find.byType(Switch));
  await tester.pump();

  expect(switchTapped, true);
});
```

**5. State Changes:**
```dart
testWidgets('should call onChanged with new value', (tester) async {
  bool? receivedValue;

  await tester.pumpWidget(
    MaterialApp(
      home: RecurringEventToggle(
        value: false,
        onChanged: (newValue) { receivedValue = newValue; },
      ),
    ),
  );

  await tester.tap(find.byType(Switch));
  await tester.pump();

  expect(receivedValue, true);
});
```

### Widget Tests

**1. Layout Structure:**
```dart
testWidgets('should have correct layout structure', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RecurringEventToggle(
        value: false,
        onChanged: (_) {},
      ),
    ),
  );

  // Verify Column > Row > Expanded structure
  final column = tester.widget<Column>(find.byType(Column).first);
  expect(column.crossAxisAlignment, CrossAxisAlignment.start);

  expect(find.byType(Row), findsOneWidget);
  expect(find.byType(Expanded), findsOneWidget);
});
```

**2. Text Styling:**
```dart
testWidgets('should apply correct text styles on Material', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RecurringEventToggle(
        labelText: "Test Label",
        helperText: "Test Helper",
        value: false,
        onChanged: (_) {},
      ),
    ),
  );

  final labelText = tester.widget<Text>(find.text("Test Label"));
  expect(labelText.style?.fontWeight, FontWeight.w500);

  final helperText = tester.widget<Text>(find.text("Test Helper"));
  expect(helperText.style?.color, AppStyles.grey600);
});
```

**3. Dark Mode Adaptation (Cupertino):**
```dart
testWidgets('should adapt colors to dark mode on iOS', (tester) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.dark),
      home: RecurringEventToggle(
        labelText: "Test",
        value: false,
        onChanged: (_) {},
      ),
    ),
  );

  // Build widget and verify color resolves correctly for dark mode
  await tester.pump();

  final text = tester.widget<Text>(find.text("Test"));
  // Color should be appropriate for dark mode (near-white)
  final resolvedColor = CupertinoColors.label.resolveFrom(
    tester.element(find.text("Test"))
  );
  expect(resolvedColor.computeLuminance(), greaterThan(0.5));
});
```

### Integration Tests

**1. Real User Interaction Flow:**
```dart
testWidgets('should toggle value through user interaction', (tester) async {
  bool currentValue = false;

  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          return RecurringEventToggle(
            value: currentValue,
            onChanged: (newValue) {
              setState(() => currentValue = newValue);
            },
          );
        },
      ),
    ),
  );

  // Initial state: off
  expect(currentValue, false);

  // Tap to turn on
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
  expect(currentValue, true);

  // Tap to turn off
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
  expect(currentValue, false);
});
```

## Comparison with Similar Widgets

### vs. Standard Switch Widget
**Advantages of RecurringEventToggle:**
- Integrated label and helper text (no need for separate Text widgets)
- Automatic platform adaptation (iOS/Android)
- Built-in localization fallbacks
- Consistent layout structure
- Enabled/disabled state management

**When to Use Standard Switch:**
- Simple on/off without explanatory text
- Custom layout requirements
- Non-platform-specific design

### vs. SwitchListTile
**Similarities:**
- Both combine Switch with text labels
- Both support title and subtitle

**RecurringEventToggle Advantages:**
- Platform-adaptive (Cupertino on iOS)
- Smaller, more compact layout
- Customizable text with localized fallbacks
- No Material ListTile decoration overhead

**SwitchListTile Advantages:**
- Built-in Material list item styling
- Support for leading/trailing widgets
- Built-in tap feedback and ripple effects
- Better for list contexts

### vs. Custom Platform-Adaptive Widgets
**RecurringEventToggle Benefits:**
- Domain-specific (optimized for recurring event use case)
- Integrated localization
- Consistent styling across the app
- Less boilerplate for common use case

## Possible Improvements

### 1. Semantic Labels for Accessibility
```dart
Semantics(
  label: "${labelText ?? context.l10n.recurringEvent}, ${value ? 'enabled' : 'disabled'}",
  child: PlatformWidgets.platformSwitch(
    value: value,
    onChanged: enabled ? onChanged : null,
  ),
)
```
**Benefit:** Better screen reader support for visually impaired users.

### 2. Custom Active Color
```dart
final Color? activeColor;

// In switch widget:
PlatformWidgets.platformSwitch(
  value: value,
  onChanged: enabled ? onChanged : null,
  activeColor: activeColor,
)
```
**Benefit:** Allow brand-specific colors while maintaining platform adaptation.

### 3. Animation Controller for Value Changes
```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: Text(
    value ? context.l10n.enabled : context.l10n.disabled,
    key: ValueKey(value),
  ),
)
```
**Benefit:** Visual feedback when toggle state changes.

### 4. Tooltip Support
```dart
final String? tooltip;

Tooltip(
  message: tooltip ?? helperText ?? context.l10n.recurringEventHelperText,
  child: /* existing switch */,
)
```
**Benefit:** Additional context on long press/hover for desktop/web platforms.

### 5. Error State
```dart
final String? errorText;
final bool hasError;

// Add error text below helper text:
if (hasError && errorText != null)
  Padding(
    padding: EdgeInsets.only(top: 4),
    child: Text(
      errorText,
      style: TextStyle(color: Colors.red, fontSize: AppConstants.captionFontSize),
    ),
  )
```
**Benefit:** Form validation feedback without separate error widgets.

### 6. Analytics/Tracking Integration
```dart
onChanged: enabled ? (value) {
  // Track toggle event
  analytics.logEvent('recurring_toggle_changed', {
    'new_value': value,
    'screen': currentScreen,
  });
  onChanged(value);
} : null,
```
**Benefit:** Understanding user behavior with recurring events.

### 7. Haptic Feedback
```dart
import 'package:flutter/services.dart';

onChanged: enabled ? (value) async {
  await HapticFeedback.lightImpact();
  onChanged(value);
} : null,
```
**Benefit:** Tactile confirmation of toggle action, especially useful on mobile devices.

### 8. Custom Switch Size
```dart
final double? switchScale;

// In Material variant:
Transform.scale(
  scale: switchScale ?? 1.0,
  child: PlatformWidgets.platformSwitch(...),
)
```
**Benefit:** Adapt to different form densities (compact vs. comfortable).

### 9. Loading State
```dart
final bool isLoading;

// Replace switch with loading indicator when saving:
isLoading
  ? SizedBox(
      width: 51, // Standard switch width
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    )
  : PlatformWidgets.platformSwitch(...)
```
**Benefit:** Visual feedback during async operations (e.g., saving recurring pattern to backend).

### 10. Theme Integration Enhancement
```dart
// Use Material 3 color scheme:
color: Theme.of(context).colorScheme.primary,

// Or for Cupertino, respect CupertinoTheme:
activeColor: CupertinoTheme.of(context).primaryColor,
```
**Benefit:** Better integration with app-wide theming systems.

## Real-World Usage Context

Based on the widget name and implementation, this widget is likely used in:

1. **Event Creation Forms:** Toggle to enable/disable recurring event functionality
2. **Event Editing Screens:** Allow users to convert one-time events to recurring
3. **Settings Screens:** Global preferences for default recurring behavior
4. **Quick Actions:** Enable/disable recurrence without entering full edit mode

The platform-adaptive design ensures iOS users see familiar Cupertino switches while Android users see Material switches, maintaining platform conventions and user expectations.

## Performance Considerations

- **Const Constructor:** Allows Flutter to cache widget instances when properties don't change
- **Stateless Design:** No setState() calls, reducing rebuild overhead
- **Platform Check:** Single boolean check per build, negligible performance impact
- **No Expensive Operations:** All styling is declarative, no runtime computations
- **Const SizedBox:** Spacing widget is compile-time constant

**Recommendation:** This widget is lightweight and suitable for use in lists or forms with many instances.
