# RecurrencePatternList Widget

## Overview
`RecurrencePatternList` is a StatefulWidget that manages and displays a list of recurrence patterns with add, edit, and delete operations. It features a header with pattern count badge, empty state when no patterns exist, PatternCard rendering for each pattern, confirmation dialogs for deletion, and proper mounted checks for async operations. The widget coordinates with PatternEditDialog and communicates changes back to parent via callback.

## File Location
`lib/widgets/recurrence_pattern_list.dart`

## Dependencies
```dart
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import '../models/recurrence_pattern.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'base_card.dart';
import 'pattern_card.dart';
import 'pattern_edit_dialog.dart';
```

**Key Dependencies:**
- `recurrence_pattern.dart`: RecurrencePattern model
- `pattern_card.dart`: Displays individual patterns with edit/delete buttons
- `pattern_edit_dialog.dart`: Modal for creating/editing patterns
- `base_card.dart`: Card wrapper for empty state
- `platform_navigation.dart`: presentModal for showing dialogs
- `dialog_helpers.dart`: Confirmation dialogs and snackbars
- `platform_detection.dart`: PlatformDetection.isIOS for styling
- `app_constants.dart`: Padding constants
- `app_styles.dart`: Colors and text styles
- `l10n_helpers.dart`: Localization for all text

## Class Declaration

```dart
class RecurrencePatternList extends StatefulWidget {
  final List<RecurrencePattern> patterns;
  final ValueChanged<List<RecurrencePattern>> onPatternsChanged;
  final bool enabled;
  final int eventId;

  const RecurrencePatternList({
    super.key,
    required this.patterns,
    required this.onPatternsChanged,
    this.enabled = true,
    required this.eventId
  });

  @override
  State<RecurrencePatternList> createState() => _RecurrencePatternListState();
}
```

**Widget Type:** StatefulWidget

**Rationale for Stateful:**
- **Async Operations:** Manages async add/edit/delete flows
- **Mounted Checks:** Needs to check mounted after dialogs
- **No Local State:** Actually doesn't manage local state, could potentially be StatelessWidget
- **Pattern:** Common to use StatefulWidget for async dialog coordination

### Properties Analysis

**patterns** (`List<RecurrencePattern>`):
- **Type:** Required list of RecurrencePattern objects
- **Purpose:** Current patterns to display
- **Usage:**
  - Rendered as PatternCard widgets
  - Counted in header badge
  - Determines empty state display
- **Pattern:** External state (parent manages list)
- **Mutability:** Not mutated directly (creates new lists)

**onPatternsChanged** (`ValueChanged<List<RecurrencePattern>>`):
- **Type:** Required callback `void Function(List<RecurrencePattern>)`
- **Purpose:** Notifies parent of pattern list changes
- **Called When:**
  - Pattern added
  - Pattern edited
  - Pattern deleted
- **Parameter:** Complete new list (not delta)
- **Pattern:** Immutable update pattern (new list each time)

**enabled** (`bool`):
- **Type:** Boolean flag
- **Default:** `true`
- **Purpose:** Controls whether patterns can be modified
- **UI Impact:**
  - Disables edit/delete buttons on PatternCards
  - Hides "Add Pattern" button when false
- **Use Cases:** Disable during save, or for read-only views

**eventId** (`int`):
- **Type:** Required integer
- **Purpose:** Parent event ID for patterns
- **Usage:** Passed to PatternEditDialog
- **Context:** Patterns belong to specific event

## State Class

```dart
class _RecurrencePatternListState extends State<RecurrencePatternList> {
```

**No State Variables:** This widget doesn't declare any internal state variables

**Pattern:** Uses widget.patterns from props, creates new lists for updates

## Build Method

```dart
@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader(context),

      const SizedBox(height: AppConstants.smallPadding),

      if (widget.patterns.isEmpty)
        _buildEmptyState(context)
      else
        ...widget.patterns.asMap().entries.map((entry) {
          final index = entry.key;
          final pattern = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
            child: PatternCard(
              pattern: pattern,
              enabled: widget.enabled,
              onEdit: widget.enabled ? () => _editPattern(index) : null,
              onDelete: widget.enabled ? () => _deletePattern(index) : null
            ),
          );
        }),

      if (widget.enabled) ...[
        const SizedBox(height: AppConstants.smallPadding),
        _buildAddPatternButton(context)
      ],
    ],
  );
}
```

### Detailed Analysis

**Lines 29-30: Column Container**
```dart
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
```
- Vertical layout
- Left-aligned children

**Line 32:** Header (icon, title, count badge)

**Line 34:** Spacing (smallPadding, typically 8-12px)

**Lines 36-46: Conditional Content**

### Empty State (Lines 36-37)
```dart
if (widget.patterns.isEmpty)
  _buildEmptyState(context)
```
- Shows when patterns list is empty
- Displays icon and "No patterns" message

### Pattern List (Lines 38-46)
```dart
else
  ...widget.patterns.asMap().entries.map((entry) {
    final index = entry.key;
    final pattern = entry.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: PatternCard(
        pattern: pattern,
        enabled: widget.enabled,
        onEdit: widget.enabled ? () => _editPattern(index) : null,
        onDelete: widget.enabled ? () => _deletePattern(index) : null
      ),
    );
  }),
```

**asMap().entries Pattern:**
- Converts list to map with indices as keys
- Allows access to both index and value
- **Usage:** Need index for edit/delete operations

**Spread Operator (`...`):**
- Flattens map result into Column children
- Avoids nested widget tree

**Padding:**
- Each PatternCard has bottom padding
- Creates spacing between cards

**PatternCard Props:**
- **pattern:** The pattern data
- **enabled:** Pass through from widget
- **onEdit:** If enabled, callback with index; else null (hides button)
- **onDelete:** If enabled, callback with index; else null (hides button)

**Conditional Callbacks:**
```dart
onEdit: widget.enabled ? () => _editPattern(index) : null,
```
- **Enabled:** Provides callback (button shown and functional)
- **Disabled:** null (button hidden)

**Lines 48: Add Button Section**
```dart
if (widget.enabled) ...[
  const SizedBox(height: AppConstants.smallPadding),
  _buildAddPatternButton(context)
],
```
- **Conditional:** Only if enabled
- **Spacing:** Before button
- **Pattern:** Add button at bottom of list

## Build Header

```dart
Widget _buildHeader(BuildContext context) {
  final l10n = context.l10n;

  final isIOS = PlatformDetection.isIOS;
  final primaryColor = isIOS
    ? CupertinoColors.activeBlue.resolveFrom(context)
    : AppStyles.primary600;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      PlatformWidgets.platformIcon(
        isIOS ? CupertinoIcons.repeat : CupertinoIcons.repeat,
        color: primaryColor,
        size: 20
      ),
      const SizedBox(width: 8),

      Expanded(
        child: Text(
          l10n.recurrencePatterns,
          style: AppStyles.cardTitle.copyWith(
            fontWeight: FontWeight.w600,
            color: primaryColor
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (widget.patterns.isNotEmpty) ...[
        const SizedBox(width: 8),

        Flexible(
          flex: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppStyles.colorWithOpacity(primaryColor, 0.1),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Text(
              l10n.patternsConfigured(widget.patterns.length),
              style: AppStyles.bodyTextSmall.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ],
  );
}
```

### Detailed Analysis

**Lines 56-57: Platform Color**
```dart
final isIOS = PlatformDetection.isIOS;
final primaryColor = isIOS
  ? CupertinoColors.activeBlue.resolveFrom(context)
  : AppStyles.primary600;
```
- **iOS:** Adaptive blue (light/dark mode support)
- **Android:** Static primary color
- **Usage:** Icon, title text, and badge

**Lines 59-91: Row Layout**
```
Row (center-aligned)
├── Icon (20px)
├── 8px gap
├── Expanded Title
├── [Conditional] 8px gap
└── [Conditional] Badge (flex: 0)
```

**Icon (Lines 62-64):**
```dart
PlatformWidgets.platformIcon(
  isIOS ? CupertinoIcons.repeat : CupertinoIcons.repeat,
  color: primaryColor,
  size: 20
),
```
- **Symbol:** Repeat icon (both platforms use same)
- **Color:** Primary color (matches title)
- **Size:** 20px

**Title (Lines 66-72):**
```dart
Expanded(
  child: Text(
    l10n.recurrencePatterns,
    style: AppStyles.cardTitle.copyWith(
      fontWeight: FontWeight.w600,
      color: primaryColor
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
),
```
- **Expanded:** Takes available space
- **Text:** "Recurrence Patterns" (localized)
- **Style:** Semi-bold, primary color
- **Overflow:** Ellipsis if too long

**Badge (Lines 73-89):**
```dart
if (widget.patterns.isNotEmpty) ...[
  const SizedBox(width: 8),

  Flexible(
    flex: 0,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(primaryColor, 0.1),
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        l10n.patternsConfigured(widget.patterns.length),
        style: AppStyles.bodyTextSmall.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w600
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
],
```

**Conditional:** Only shows if patterns exist

**Flexible with flex: 0:**
- Takes minimum width needed
- Doesn't compete with Expanded title
- **Pattern:** Badge shouldn't expand

**Container Styling:**
- **Padding:** 8px horizontal, 2px vertical (compact pill shape)
- **Background:** Primary color at 10% opacity (subtle)
- **Border Radius:** 12px (pill shape)

**Text:**
- Format: "X pattern(s) configured"
- **Localized:** Handles singular/plural via l10n method
- Small text, bold, primary color
- Ellipsis overflow handling

## Build Empty State

```dart
Widget _buildEmptyState(BuildContext context) {
  final l10n = context.l10n;
  final isIOS = PlatformDetection.isIOS;

  return BaseCard(
    child: Column(
      children: [
        PlatformWidgets.platformIcon(
          isIOS ? CupertinoIcons.calendar : CupertinoIcons.calendar,
          color: AppStyles.grey400,
          size: 48
        ),
        const SizedBox(height: 12),
        Text(
          l10n.noRecurrencePatterns,
          style: AppStyles.bodyText.copyWith(color: AppStyles.grey600),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
```

**BaseCard Wrapper:**
- Provides standard card styling
- Padding, rounded corners, elevation

**Column Content:**
1. Large calendar icon (48px, gray)
2. 12px spacing
3. "No recurrence patterns" text (gray, centered)

**Color Scheme:**
- Gray icon and text
- **Purpose:** Indicates empty/inactive state

**Pattern:** Standard empty state design

## Build Add Pattern Button

```dart
Widget _buildAddPatternButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: PlatformWidgets.platformButton(
      onPressed: _addPattern,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlatformWidgets.platformIcon(CupertinoIcons.add, size: 18),
          const SizedBox(width: 8),
          Text(context.l10n.addPattern, style: AppStyles.buttonText),
        ],
      ),
    ),
  );
}
```

**SizedBox:**
- Full width (`double.infinity`)
- Ensures button spans container

**PlatformWidgets.platformButton:**
- Platform-adaptive button (CupertinoButton on iOS, ElevatedButton on Android)
- **onPressed:** Calls _addPattern

**Row Content:**
- Centered alignment
- Plus icon (18px)
- 8px gap
- "Add Pattern" text

**Pattern:** Icon + text button (primary action)

## Add Pattern Method

```dart
void _addPattern() {
  Future<void> handleAddPattern() async {
    final pattern = await PlatformNavigation.presentModal<RecurrencePattern>(
      context,
      PatternEditDialog(eventId: widget.eventId)
    );
    if (!mounted) return;
    if (pattern != null) {
      final l10n = context.l10n;
      final updatedPatterns = List<RecurrencePattern>.from(widget.patterns)
        ..add(pattern);
      widget.onPatternsChanged(updatedPatterns);
      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: l10n.onePatternAdded
      );
    }
  }

  handleAddPattern();
}
```

### Detailed Analysis

**Inner Async Function Pattern:**
```dart
void _addPattern() {
  Future<void> handleAddPattern() async {
    // async logic
  }
  handleAddPattern();
}
```
- **Purpose:** Allows async/await in method called from onPressed
- **Pattern:** Wrapper function for async operations

**Lines 132:** Show PatternEditDialog
```dart
final pattern = await PlatformNavigation.presentModal<RecurrencePattern>(
  context,
  PatternEditDialog(eventId: widget.eventId)
);
```
- **Modal:** Pattern edit dialog
- **eventId:** Passed through from widget
- **No initial pattern:** Create mode
- **Returns:** RecurrencePattern? (null if cancelled)

**Line 133:** Mounted check
```dart
if (!mounted) return;
```
- **Critical:** Check after await
- **Prevents:** setState on disposed widget

**Lines 134-139: Save Pattern**
```dart
if (pattern != null) {
  final l10n = context.l10n;
  final updatedPatterns = List<RecurrencePattern>.from(widget.patterns)
    ..add(pattern);
  widget.onPatternsChanged(updatedPatterns);
  PlatformDialogHelpers.showSnackBar(
    context: context,
    message: l10n.onePatternAdded
  );
}
```

**Pattern Not Null Check:**
- User saved (not cancelled)

**Create New List (Line 136):**
```dart
final updatedPatterns = List<RecurrencePattern>.from(widget.patterns)
  ..add(pattern);
```
- **Creates copy** of existing list
- **Cascade operator** (`..`) adds new pattern
- **Immutable Pattern:** Don't mutate original list
- **Result:** New list with added pattern

**Notify Parent (Line 137):**
```dart
widget.onPatternsChanged(updatedPatterns);
```
- Passes complete new list to parent
- Parent updates its state with new list

**Success Feedback (Lines 138-141):**
```dart
PlatformDialogHelpers.showSnackBar(
  context: context,
  message: l10n.onePatternAdded
);
```
- Shows toast/snackbar
- Message: "1 pattern added" or similar
- **User feedback:** Confirms action completed

## Edit Pattern Method

```dart
void _editPattern(int index) {
  final pattern = widget.patterns[index];
  Future<void> handleEditPattern() async {
    final updatedPattern = await PlatformNavigation.presentModal<RecurrencePattern>(
      context,
      PatternEditDialog(pattern: pattern, eventId: widget.eventId)
    );
    if (!mounted) return;
    if (updatedPattern != null) {
      final l10n = context.l10n;
      final updatedPatterns = List<RecurrencePattern>.from(widget.patterns);
      updatedPatterns[index] = updatedPattern;
      widget.onPatternsChanged(updatedPatterns);
      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: l10n.patternsConfigured(1)
      );
    }
  }

  handleEditPattern();
}
```

### Detailed Analysis

**Line 146:** Get pattern to edit
```dart
final pattern = widget.patterns[index];
```
- **Index:** From PatternCard's onEdit callback
- **Pattern:** Existing pattern to edit

**Lines 148:** Show PatternEditDialog
```dart
final updatedPattern = await PlatformNavigation.presentModal<RecurrencePattern>(
  context,
  PatternEditDialog(pattern: pattern, eventId: widget.eventId)
);
```
- **Edit Mode:** Passes existing pattern
- **eventId:** Passed through
- **Returns:** Updated RecurrencePattern? (or null if cancelled)

**Line 149:** Mounted check after await

**Lines 150-156: Update Pattern**
```dart
if (updatedPattern != null) {
  final l10n = context.l10n;
  final updatedPatterns = List<RecurrencePattern>.from(widget.patterns);
  updatedPatterns[index] = updatedPattern;
  widget.onPatternsChanged(updatedPatterns);
  PlatformDialogHelpers.showSnackBar(
    context: context,
    message: l10n.patternsConfigured(1)
  );
}
```

**Create New List (Line 152):**
```dart
final updatedPatterns = List<RecurrencePattern>.from(widget.patterns);
```
- Copy entire list

**Replace At Index (Line 153):**
```dart
updatedPatterns[index] = updatedPattern;
```
- Replaces specific pattern
- **Immutable Pattern:** Copy first, then modify copy

**Notify Parent (Line 154):**
- Passes modified list

**Success Feedback (Lines 155-156):**
- Message: "1 pattern configured" or similar

## Delete Pattern Method

```dart
void _deletePattern(int index) {
  final l10n = context.l10n;
  final dialogContext = context;
  Future<void> handleDeletePattern() async {
    final confirmed = await PlatformDialogHelpers.showPlatformConfirmDialog(
      dialogContext,
      title: l10n.deletePattern,
      message: l10n.confirmDeletePattern,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
      isDestructive: true
    );
    if (!mounted) return;
    if (confirmed == true) {
      _performDelete(index);
    }
  }

  handleDeletePattern();
}
```

### Detailed Analysis

**Lines 163-164: Safe Context**
```dart
final l10n = context.l10n;
final dialogContext = context;
```
- **Cache:** Capture before async
- **Safe Pattern:** Context might become invalid during async

**Lines 166:** Confirmation Dialog
```dart
final confirmed = await PlatformDialogHelpers.showPlatformConfirmDialog(
  dialogContext,
  title: l10n.deletePattern,
  message: l10n.confirmDeletePattern,
  confirmText: l10n.delete,
  cancelText: l10n.cancel,
  isDestructive: true
);
```
- **Title:** "Delete Pattern"
- **Message:** "Are you sure you want to delete this pattern?"
- **Confirm:** "Delete"
- **Cancel:** "Cancel"
- **isDestructive:** Red/warning styling
- **Returns:** `bool?` (true = confirmed, false/null = cancelled)

**Line 167:** Mounted check after await

**Lines 168-170: Conditional Delete**
```dart
if (confirmed == true) {
  _performDelete(index);
}
```
- **Strict Check:** `== true` (not just truthy)
- **Delegate:** Separate _performDelete method
- **Pattern:** Confirmation in one method, action in another

## Perform Delete Method

```dart
void _performDelete(int index) {
  final updatedPatterns = List<RecurrencePattern>.from(widget.patterns);
  updatedPatterns.removeAt(index);
  widget.onPatternsChanged(updatedPatterns);
}
```

**Purpose:** Actual deletion logic (separated from confirmation)

**Line 177:** Create copy
```dart
final updatedPatterns = List<RecurrencePattern>.from(widget.patterns);
```

**Line 178:** Remove at index
```dart
updatedPatterns.removeAt(index);
```
- **removeAt:** Removes item at specific index
- **Mutates:** Modifies the copy (not original)

**Line 179:** Notify parent
```dart
widget.onPatternsChanged(updatedPatterns);
```
- Passes list with pattern removed

**No Snackbar:** Unlike add/edit, delete doesn't show success message
- **Pattern Choice:** Could be added for consistency

## Technical Characteristics

### State Management Pattern
- **External State:** Patterns list managed by parent
- **Callback Communication:** onPatternsChanged for all updates
- **Immutable Updates:** Always creates new lists, never mutates
- **Pattern:** Controlled component pattern

### List Mutation Strategy
- **Add:** `List.from(patterns)..add(pattern)`
- **Edit:** `List.from(patterns); list[index] = updated`
- **Delete:** `List.from(patterns); list.removeAt(index)`
- **Consistent:** Always copy, then modify, then callback

### Async Operation Handling
- **Wrapper Functions:** Inner async functions for each operation
- **Mounted Checks:** After every await
- **Safe Context:** Captured before async gaps
- **Pattern:** Standard async dialog coordination

### Platform Adaptation
- **Colors:** iOS uses adaptive CupertinoColors, Android uses static colors
- **Icon:** Same repeat icon on both platforms
- **Button:** Platform-specific via PlatformWidgets.platformButton

## Usage Examples

### Basic Usage
```dart
RecurrencePatternList(
  patterns: event.recurrencePatterns,
  eventId: event.id,
  onPatternsChanged: (newPatterns) {
    setState(() {
      event = event.copyWith(recurrencePatterns: newPatterns);
    });
  },
)
```

### With Repository Integration
```dart
RecurrencePatternList(
  patterns: patterns,
  eventId: eventId,
  onPatternsChanged: (updatedPatterns) async {
    await patternRepository.updatePatterns(eventId, updatedPatterns);
    setState(() {
      patterns = updatedPatterns;
    });
  },
)
```

### Read-Only Mode
```dart
RecurrencePatternList(
  patterns: event.recurrencePatterns,
  eventId: event.id,
  enabled: false, // Disables add/edit/delete
  onPatternsChanged: (_) {}, // No-op callback
)
```

### With Form Integration
```dart
class EventFormState {
  List<RecurrencePattern> patterns = [];

  Widget buildPatternsSection() {
    return RecurrencePatternList(
      patterns: patterns,
      eventId: eventId,
      enabled: !isSaving,
      onPatternsChanged: (newPatterns) {
        setState(() {
          patterns = newPatterns;
          _markFormDirty();
        });
      },
    );
  }
}
```

## Testing Recommendations

### Unit Tests

**1. List Copying:**
```dart
test('should not mutate original list when adding pattern', () {
  final originalPatterns = [pattern1, pattern2];
  final originalLength = originalPatterns.length;

  // Simulate add
  final updatedPatterns = List<RecurrencePattern>.from(originalPatterns)
    ..add(pattern3);

  expect(originalPatterns.length, originalLength);
  expect(updatedPatterns.length, originalLength + 1);
});
```

### Widget Tests

**1. Empty State:**
```dart
testWidgets('should show empty state when no patterns', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecurrencePatternList(
          patterns: [],
          eventId: 1,
          onPatternsChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.noRecurrencePatterns), findsOneWidget);
});
```

**2. Pattern Cards:**
```dart
testWidgets('should render PatternCard for each pattern', (tester) async {
  final patterns = [
    RecurrencePattern(dayOfWeek: 0, time: "10:00:00"),
    RecurrencePattern(dayOfWeek: 1, time: "14:00:00"),
  ];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecurrencePatternList(
          patterns: patterns,
          eventId: 1,
          onPatternsChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.byType(PatternCard), findsNWidgets(2));
});
```

**3. Header Badge:**
```dart
testWidgets('should show pattern count badge', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecurrencePatternList(
          patterns: [pattern1, pattern2, pattern3],
          eventId: 1,
          onPatternsChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.textContaining("3"), findsOneWidget);
});
```

**4. Add Pattern:**
```dart
testWidgets('should call onPatternsChanged when pattern added', (tester) async {
  List<RecurrencePattern>? newPatterns;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecurrencePatternList(
          patterns: [],
          eventId: 1,
          onPatternsChanged: (patterns) { newPatterns = patterns; },
        ),
      ),
    ),
  );

  // Mock dialog result
  await tester.tap(find.text(context.l10n.addPattern));
  await tester.pumpAndSettle();

  // Verify callback called with new pattern
  expect(newPatterns, isNotNull);
  expect(newPatterns!.length, 1);
});
```

**5. Disabled State:**
```dart
testWidgets('should hide add button when disabled', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecurrencePatternList(
          patterns: [pattern1],
          eventId: 1,
          enabled: false,
          onPatternsChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.addPattern), findsNothing);
});
```

## Comparison with Similar Widgets

### vs. Standard ListView
**RecurrencePatternList Advantages:**
- Integrated add/edit/delete logic
- Empty state handling
- Header with count badge
- Confirmation dialogs built-in

**Standard ListView:**
- More flexible
- No business logic
- Lighter weight

### vs. Reorderable List
**RecurrencePatternList:**
- Fixed order (patterns not reorderable)
- CRUD operations focus
- Simpler interaction

**ReorderableListView:**
- Drag-to-reorder
- Good for priority/sequence management

## Possible Improvements

### 1. Reordering
```dart
ReorderableListView(
  children: patterns.map((p) => PatternCard(key: Key(p.id), ...)).toList(),
  onReorder: (oldIndex, newIndex) {
    final reordered = List<RecurrencePattern>.from(patterns);
    final pattern = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, pattern);
    onPatternsChanged(reordered);
  },
)
```

### 2. Bulk Delete
```dart
final Set<int> selectedIndices = {};

// Show checkboxes, allow multi-select
// Delete selected button
```

### 3. Pattern Validation
```dart
String? _validatePatterns(List<RecurrencePattern> patterns) {
  // Check for duplicates
  // Check for conflicts
  return null; // or error message
}
```

### 4. Loading State
```dart
if (isLoading)
  CircularProgressIndicator()
else
  /* pattern list */
```

### 5. Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: _refreshPatterns,
  child: /* pattern list */,
)
```

### 6. Undo Delete
```dart
void _deletePattern(int index) {
  final deleted = patterns[index];
  _performDelete(index);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Pattern deleted"),
      action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          final restored = List.from(patterns)..insert(index, deleted);
          onPatternsChanged(restored);
        },
      ),
    ),
  );
}
```

### 7. Search/Filter
```dart
final String searchQuery;

final filteredPatterns = patterns.where((p) =>
  getDayName(p.dayOfWeek).contains(searchQuery) ||
  p.time.contains(searchQuery)
).toList();
```

### 8. Export/Import
```dart
void _exportPatterns() {
  final json = jsonEncode(patterns.map((p) => p.toJson()).toList());
  // Save to file or clipboard
}
```

### 9. Pattern Templates
```dart
final templates = [
  "Weekdays 9-5",
  "Weekends",
  "Mon-Wed-Fri",
];

// Quick apply template button
```

### 10. Conflict Detection
```dart
Widget build(BuildContext context) {
  final conflicts = _detectConflicts(patterns);

  if (conflicts.isNotEmpty) {
    return WarningBanner(
      message: "Some patterns overlap",
      onTap: _showConflictDetails,
    );
  }
  // ... rest of build
}
```

## Real-World Usage Context

This widget is typically used in:

1. **Event Series Management:** Managing weekly recurring patterns for events
2. **Schedule Builders:** Creating complex recurring schedules
3. **Habit Tracking:** Setting up recurring habit reminders
4. **Booking Systems:** Defining availability patterns
5. **Calendar Apps:** Managing event recurrence rules

The list-based interface with add/edit/delete is well-suited for managing multiple recurring patterns that together define a complex schedule.

## Performance Considerations

- **List Copying:** Creates new lists on every change (O(n) operation)
- **asMap().entries:** Efficient way to get index with value
- **PatternCard:** Reusable component (good separation)
- **Mounted Checks:** Prevents unnecessary operations on disposed widgets

**Recommendation:** Suitable for typical use cases (< 100 patterns). For very large lists, consider virtualization with ListView.builder.

## Security Considerations

- **Input Validation:** PatternEditDialog handles validation
- **Confirmation Dialogs:** Prevents accidental deletions
- **Immutable Updates:** Reduces risk of state corruption
- **eventId Validation:** Should be validated before passing to widget

**Recommendation:** Add pattern limit (e.g., max 50 patterns) to prevent abuse and performance issues.
