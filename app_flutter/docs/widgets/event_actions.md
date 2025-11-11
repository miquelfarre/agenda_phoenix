# EventActions Widget

## Overview
`EventActions` is a StatelessWidget that provides a comprehensive action bar for events with intelligent handling of recurring vs. regular events. It displays conditional buttons (invite, edit, delete) in either compact or full mode, automatically showing action sheets for recurring events to choose between modifying a single instance or the entire series. The widget includes confirmation dialogs, error handling, safe context management, and proper async callback handling.

## File Location
`lib/widgets/event_actions.dart`

## Dependencies
```dart
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/event.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'confirmation_action_widget.dart';
import '../l10n/app_localizations.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
```

**Key Dependencies:**
- `event.dart`: Event model with isRecurringEvent property and title
- `confirmation_action_widget.dart`: Wrapper for confirmation dialogs before destructive actions
- `dialog_helpers.dart`: Platform action sheets and confirmation dialogs
- `platform_widgets.dart`: Platform-adaptive icons
- `app_constants.dart`: Constants for action choices (actionChoiceThis, actionChoiceSeries)
- `l10n_helpers.dart`: Localization for all user-facing text
- `dart:async`: Future handling for async callbacks

## Class Declaration

```dart
class EventActions extends StatelessWidget {
  final Event event;
  final Function(Event, {bool shouldNavigate})? onDelete;
  final Function(Event)? onEdit;
  final Function(Event)? onInvite;
  final Function(Event, {bool shouldNavigate})? onDeleteSeries;
  final Function(Event)? onEditSeries;
  final bool isCompact;
  final bool navigateAfterDelete;

  const EventActions({
    super.key,
    required this.event,
    this.onDelete,
    this.onEdit,
    this.onInvite,
    this.onDeleteSeries,
    this.onEditSeries,
    this.isCompact = false,
    this.navigateAfterDelete = false
  });
}
```

**Widget Type:** StatelessWidget

**Rationale for Stateless:**
- No internal state management needed
- All actions delegated to parent via callbacks
- UI determined purely by props (isCompact, callback presence)
- Dialogs are ephemeral (don't require state tracking)

### Properties Analysis

**event** (`Event`):
- **Type:** Required Event model
- **Purpose:** The event for which actions are displayed
- **Used For:**
  - Determining if recurring (event.isRecurringEvent)
  - Display in confirmation messages (event.title)
  - Passed to all callbacks
- **Key Property:** `isRecurringEvent` determines action flow

**onDelete** (`Function(Event, {bool shouldNavigate})?`):
- **Type:** Optional callback with named parameter
- **Purpose:** Called when deleting a single event or instance
- **Parameters:**
  - `event`: Event to delete
  - `shouldNavigate`: Whether to navigate after deletion
- **Visibility:** If null, delete button not shown
- **For Recurring Events:** Deletes single instance after user chooses "This instance only"
- **Return Type:** Can return void or Future

**onEdit** (`Function(Event)?`):
- **Type:** Optional callback
- **Purpose:** Called when editing single event or instance
- **Parameter:** Event to edit
- **Visibility:** If null, edit button not shown
- **For Recurring Events:** Edits single instance after user chooses "This instance only"
- **Usage:** Typically navigates to edit screen

**onInvite** (`Function(Event)?`):
- **Type:** Optional callback
- **Purpose:** Called when inviting users to event
- **Parameter:** Event for invitations
- **Visibility:** If null, invite button not shown
- **Usage:** Opens invite/share interface

**onDeleteSeries** (`Function(Event, {bool shouldNavigate})?`):
- **Type:** Optional callback with named parameter
- **Purpose:** Called when deleting entire recurring series
- **Parameters:** Same as onDelete
- **Visibility in Action Sheet:** Only shows "Delete entire series" option if this callback provided
- **Pattern:** Separate callback for series-wide operations

**onEditSeries** (`Function(Event)?`):
- **Type:** Optional callback
- **Purpose:** Called when editing entire recurring series
- **Parameter:** Event (series master)
- **Visibility in Action Sheet:** Only shows "Edit entire series" option if provided
- **Usage:** Navigates to series edit screen with different logic

**isCompact** (`bool`):
- **Type:** Boolean flag
- **Default:** `false`
- **Purpose:** Switches between compact (icon-only) and full (icon + label) mode
- **UI Impact:**
  - **Compact:** Small circular buttons (32x32), minimal spacing
  - **Full:** Larger buttons with labels below, more spacing
- **Use Cases:**
  - Compact: Cards in lists, space-constrained contexts
  - Full: Detail screens, bottom sheets with room

**navigateAfterDelete** (`bool`):
- **Type:** Boolean flag
- **Default:** `false`
- **Purpose:** Controls whether to navigate after successful deletion
- **Passed To:** onDelete and onDeleteSeries callbacks
- **Use Cases:**
  - `true`: Delete from detail screen, pop back to list
  - `false`: Delete from list, stay on same screen

## Build Method

```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  if (isCompact) {
    return _buildCompactActions(context, l10n);
  } else {
    return _buildFullActions(context, l10n);
  }
}
```

**Simple Branching:**
- Caches localization
- Delegates to mode-specific builder
- Both builders receive context and l10n

## Build Compact Actions

```dart
Widget _buildCompactActions(BuildContext context, AppLocalizations l10n) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (onInvite != null) ...[
        _buildCompactActionButton(
          icon: CupertinoIcons.person_add,
          color: AppStyles.blue600,
          onTap: () => onInvite!(event),
          tooltip: l10n.invite
        ),
        const SizedBox(width: 8)
      ],
      if (onEdit != null) ...[
        event.isRecurringEvent
          ? _buildRecurringEditAction(context, l10n)
          : _buildRegularEditAction(context),
        const SizedBox(width: 8)
      ],
      if (onDelete != null)
        event.isRecurringEvent
          ? _buildRecurringDeleteAction(context, l10n)
          : _buildRegularDeleteAction(context, l10n),
    ],
  );
}
```

**Layout:** Horizontal Row with minimal size

**Button Order:** Invite → Edit → Delete (left to right)

**Conditional Rendering:**
1. **Invite Button:**
   - Only if `onInvite != null`
   - Blue color scheme
   - 8px spacing after

2. **Edit Button:**
   - Only if `onEdit != null`
   - Checks `event.isRecurringEvent`:
     - **Recurring:** Shows action sheet on tap
     - **Regular:** Direct edit callback
   - Green color scheme
   - 8px spacing after

3. **Delete Button:**
   - Only if `onDelete != null`
   - Checks `event.isRecurringEvent`:
     - **Recurring:** Shows action sheet with confirmation
     - **Regular:** Shows confirmation dialog directly
   - Red color scheme
   - No spacing after (last item)

**Spread Operator Pattern:**
```dart
if (onInvite != null) ...[
  _buildCompactActionButton(...),
  const SizedBox(width: 8)
],
```
- Conditionally includes button AND its spacing
- Cleaner than nested ternaries

## Build Full Actions

```dart
Widget _buildFullActions(BuildContext context, AppLocalizations l10n) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      if (onInvite != null)
        _buildActionButton(
          icon: CupertinoIcons.person_add,
          label: l10n.invite,
          color: AppStyles.blue600,
          onTap: () => onInvite!(event)
        ),
      if (onEdit != null)
        event.isRecurringEvent
          ? _buildRecurringEditFullAction(context)
          : _buildRegularEditFullAction(context),
      if (onDelete != null)
        event.isRecurringEvent
          ? _buildRecurringDeleteFullAction(context, l10n)
          : _buildRegularDeleteFullAction(context, l10n),
    ],
  );
}
```

**Layout:** Row with evenly spaced items

**Differences from Compact:**
- `mainAxisAlignment: MainAxisAlignment.spaceEvenly`
- Uses `_buildActionButton` (full version with labels)
- No manual spacing (spaceEvenly handles it)
- Same conditional logic for button types

## Build Compact Action Button

```dart
Widget _buildCompactActionButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  required String tooltip
}) {
  return GestureDetector(
    key: Key('compact_action_button_${icon.codePoint}'),
    onTap: onTap,
    child: Semantics(
      label: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppStyles.colorWithOpacity(color, 0.1),
          shape: BoxShape.circle
        ),
        child: PlatformWidgets.platformIcon(icon, size: 16, color: color),
      ),
    ),
  );
}
```

**Purpose:** Creates small circular icon button

**Key Generation:**
```dart
key: Key('compact_action_button_${icon.codePoint}')
```
- Unique key based on icon's Unicode codepoint
- Enables testing: `find.byKey(Key('compact_action_button_...'))`

**Semantics:**
- `label: tooltip` provides accessibility label
- Screen readers announce button purpose

**Container Styling:**
- **Size:** 32x32 pixels (compact)
- **Shape:** Circle (BoxShape.circle)
- **Background:** Color at 10% opacity (subtle)
- **Icon:** 16px, full color

**Color Scheme Examples:**
- Blue: Invite action
- Green: Edit action
- Red: Delete action

## Build Action Button (Full Mode)

```dart
Widget _buildActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap
}) {
  final isIOS = PlatformDetection.isIOS;
  if (isIOS) {
    return GestureDetector(
      key: Key('action_button_${icon.codePoint}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformWidgets.platformIcon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppStyles.bodyTextSmall.copyWith(color: color)
            ),
          ],
        ),
      ),
    );
  } else {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          child: AdaptiveButton(
            key: Key('event_action_${label.toLowerCase().replaceAll(' ', '_')}'),
            config: const AdaptiveButtonConfig(
              variant: ButtonVariant.icon,
              size: ButtonSize.medium,
              fullWidth: false,
              iconPosition: IconPosition.only
            ),
            icon: icon,
            onPressed: onTap,
          ),
        ),
        Text(
          label,
          style: AppStyles.bodyTextSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }
}
```

**Platform Branching:** Different implementations for iOS vs Android

### iOS Implementation (Lines 77-92)

**Layout:**
```
GestureDetector
└── Padding (8px all sides)
    └── Column (min size)
        ├── Icon (24px)
        ├── SizedBox (4px)
        └── Text (label)
```

**Icon:** 24px (larger than compact)
**Label:** Below icon, small text, colored
**Tappable:** Entire Column via GestureDetector

### Android Implementation (Lines 94-112)

**Layout:**
```
Column (min size)
├── Tooltip
│   └── AdaptiveButton (icon only)
└── Text (label)
```

**Differences:**
- Uses `AdaptiveButton` instead of custom container
- Tooltip on hover/long-press
- Label is separate from button (not wrapped in gesture detector)
- Button has Material ripple effect

**Key Generation (Line 100):**
```dart
key: Key('event_action_${label.toLowerCase().replaceAll(' ', '_')}')
```
- Example: "Delete Event" → "event_action_delete_event"
- Testable keys for UI automation

**AdaptiveButtonConfig:**
- Icon-only variant (no text in button)
- Medium size
- Not full width
- IconPosition.only

## Recurring Delete Action (Compact)

```dart
Widget _buildRecurringDeleteAction(BuildContext context, AppLocalizations l10n) {
  return GestureDetector(
    onTap: () => _showRecurringDeleteOptions(context, l10n),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.red600, 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.red600, 0.3),
          width: 1
        ),
      ),
      child: PlatformWidgets.platformIcon(
        CupertinoIcons.delete,
        size: 16,
        color: AppStyles.red600
      ),
    ),
  );
}
```

**Difference from Regular:**
- Taps calls `_showRecurringDeleteOptions` (action sheet)
- NOT wrapped in ConfirmationActionWidget
- Has border (emphasizes recurring event specificity)

**Border Styling:**
- Red at 30% opacity
- 1px width
- Provides visual distinction from regular delete

## Regular Delete Action (Compact)

```dart
Widget _buildRegularDeleteAction(BuildContext context, AppLocalizations l10n) {
  return ConfirmationActionWidget(
    dialogTitle: l10n.confirmDelete,
    dialogMessage: l10n.confirmDeleteEvent(event.title),
    actionText: l10n.delete,
    isDestructive: true,
    onAction: () async {
      onDelete!(event, shouldNavigate: navigateAfterDelete);
    },
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.red600, 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.red600, 0.3),
          width: 1
        ),
      ),
      child: PlatformWidgets.platformIcon(
        CupertinoIcons.delete,
        size: 16,
        color: AppStyles.red600
      ),
    ),
  );
}
```

**ConfirmationActionWidget Wrapper:**
- Shows confirmation dialog before executing action
- `isDestructive: true` → red/warning styling
- Handles dialog display and user confirmation
- Only calls `onAction` if user confirms

**Dialog Content:**
- **Title:** "Confirm Delete"
- **Message:** "Are you sure you want to delete [Event Title]?"
- **Action Button:** "Delete"

**onAction Callback:**
```dart
onAction: () async {
  onDelete!(event, shouldNavigate: navigateAfterDelete);
},
```
- Async callback (supports Future-returning callbacks)
- Passes event and shouldNavigate flag
- Force unwrap onDelete (safe, only shown if onDelete != null)

## Show Recurring Delete Options

```dart
void _showRecurringDeleteOptions(BuildContext context, AppLocalizations l10n) {
  final safeL10n = l10n;
  final safeTitle = safeL10n.deleteRecurringEvent;
  final safeMessage = safeL10n.deleteRecurringEventQuestion(event.title);
  final safeDeleteOnlyThisInstance = safeL10n.deleteOnlyThisInstance;
  final safeDeleteEntireSeries = safeL10n.deleteEntireSeries;
  final safeCancel = safeL10n.cancel;
  final safeUnexpectedError = safeL10n.unexpectedError;

  PlatformDialogHelpers.showPlatformActionSheet<String>(
    context,
    title: safeTitle,
    message: safeMessage,
    actions: [
      PlatformAction(
        text: safeDeleteOnlyThisInstance,
        value: AppConstants.actionChoiceThis
      ),
      if (onDeleteSeries != null)
        PlatformAction(
          text: safeDeleteEntireSeries,
          value: AppConstants.actionChoiceSeries,
          isDestructive: true
        ),
    ],
    cancelText: safeCancel,
  )
  .then((choice) {
    try {
      final appContext = context;
      if (appContext is Element && !appContext.mounted) return;

      if (choice == AppConstants.actionChoiceThis) {
        if (!appContext.mounted) return;
        PlatformDialogHelpers.showPlatformConfirmDialog(
          appContext,
          title: safeL10n.confirmDelete,
          message: safeL10n.confirmDeleteInstance(event.title),
          confirmText: safeL10n.deleteInstance,
          cancelText: safeL10n.cancel,
          isDestructive: true
        ).then((confirmed) {
          if (confirmed == true && onDelete != null) {
            try {
              final res = onDelete!(event, shouldNavigate: navigateAfterDelete);
              if (res is Future) {
                res.catchError((e) {
                  if (appContext.mounted) {
                    PlatformDialogHelpers.showSnackBar(
                      context: appContext,
                      message: '$safeUnexpectedError $e',
                      isError: true
                    );
                  }
                });
              }
            } catch (e) {
              if (appContext.mounted) {
                PlatformDialogHelpers.showSnackBar(
                  context: appContext,
                  message: '$safeUnexpectedError $e',
                  isError: true
                );
              }
            }
          }
        });
      } else if (choice == AppConstants.actionChoiceSeries) {
        if (!appContext.mounted) return;
        PlatformDialogHelpers.showPlatformConfirmDialog(
          appContext,
          title: safeL10n.confirmDeleteSeries,
          message: safeL10n.confirmDeleteSeriesMessage(event.title),
          confirmText: safeL10n.deleteCompleteSeries,
          cancelText: safeL10n.cancel,
          isDestructive: true
        ).then((confirmed) {
          if (confirmed == true && onDeleteSeries != null) {
            try {
              final res = onDeleteSeries!(event, shouldNavigate: navigateAfterDelete);
              if (res is Future) {
                res.catchError((e) {
                  if (appContext.mounted) {
                    PlatformDialogHelpers.showSnackBar(
                      context: appContext,
                      message: '$safeUnexpectedError $e',
                      isError: true
                    );
                  }
                });
              }
            } catch (e) {
              if (appContext.mounted) {
                PlatformDialogHelpers.showSnackBar(
                  context: appContext,
                  message: '$safeUnexpectedError $e',
                  isError: true
                );
              }
            }
          }
        });
      }
    } catch (e) {
      PlatformDialogHelpers.showSnackBar(
        message: '$safeUnexpectedError $e',
        isError: true
      );
    }
  })
  .catchError((e) {
    if (context.mounted) {
      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: '$safeUnexpectedError $e',
        isError: true
      );
    }
  });
}
```

### Detailed Analysis

**Lines 197-203: Safe String Capture**
```dart
final safeL10n = l10n;
final safeTitle = safeL10n.deleteRecurringEvent;
final safeMessage = safeL10n.deleteRecurringEventQuestion(event.title);
// ... more safe strings
```
- **Purpose:** Captures all localized strings before async gap
- **Rationale:** Context may become invalid during async operations
- **Pattern:** "Safe string" pattern for nested async flows

**Lines 205-214: Action Sheet**
```dart
PlatformDialogHelpers.showPlatformActionSheet<String>(
  context,
  title: safeTitle,
  message: safeMessage,
  actions: [
    PlatformAction(
      text: safeDeleteOnlyThisInstance,
      value: AppConstants.actionChoiceThis
    ),
    if (onDeleteSeries != null)
      PlatformAction(
        text: safeDeleteEntireSeries,
        value: AppConstants.actionChoiceSeries,
        isDestructive: true
      ),
  ],
  cancelText: safeCancel,
)
```

**Action 1: Delete This Instance**
- Always shown
- Value: "this" constant
- Non-destructive styling

**Action 2: Delete Entire Series**
- Conditional: only if `onDeleteSeries != null`
- Value: "series" constant
- `isDestructive: true` → red text

**Returns:** `Future<String?>` with selected action value or null if cancelled

**Lines 215-269: Choice Handling**

### This Instance Path (Lines 220-239)

**Lines 217-218: Safe Context Check**
```dart
final appContext = context;
if (appContext is Element && !appContext.mounted) return;
```
- Casts context to Element for mounted check
- Early return if already dismounted
- **Critical:** Prevents accessing dead context

**Lines 220-239: Confirmation Dialog**
```dart
if (choice == AppConstants.actionChoiceThis) {
  if (!appContext.mounted) return;
  PlatformDialogHelpers.showPlatformConfirmDialog(
    appContext,
    title: safeL10n.confirmDelete,
    message: safeL10n.confirmDeleteInstance(event.title),
    confirmText: safeL10n.deleteInstance,
    cancelText: safeL10n.cancel,
    isDestructive: true
  ).then((confirmed) {
    if (confirmed == true && onDelete != null) {
      try {
        final res = onDelete!(event, shouldNavigate: navigateAfterDelete);
        if (res is Future) {
          res.catchError((e) {
            if (appContext.mounted) {
              PlatformDialogHelpers.showSnackBar(
                context: appContext,
                message: '$safeUnexpectedError $e',
                isError: true
              );
            }
          });
        }
      } catch (e) {
        if (appContext.mounted) {
          PlatformDialogHelpers.showSnackBar(
            context: appContext,
            message: '$safeUnexpectedError $e',
            isError: true
          );
        }
      }
    }
  });
}
```

**Second Mounted Check (Line 221):** Before showing confirmation

**Confirmation Dialog:**
- **Title:** "Confirm Delete"
- **Message:** "Are you sure you want to delete this instance of [Event Title]?"
- **Confirm:** "Delete Instance"
- **Cancel:** "Cancel"

**On Confirmed (Lines 223-238):**
1. Check confirmed is true AND onDelete exists
2. Try to call onDelete callback
3. Capture return value
4. If return is Future:
   - Attach catchError handler
   - Show error snackbar if fails
5. If synchronous error:
   - Catch and show error snackbar

**Pattern:** Handles both void and Future-returning callbacks

### Series Path (Lines 240-259)

**Identical Structure:**
- Mounted check
- Confirmation dialog with series-specific text
- Try-catch with Future handling
- Error snackbars with mounted checks

**Key Differences:**
- Calls `onDeleteSeries` instead of `onDelete`
- Different confirmation messages
- "Delete Complete Series" button text

**Lines 261-263: Outer Try-Catch**
```dart
} catch (e) {
  PlatformDialogHelpers.showSnackBar(
    message: '$safeUnexpectedError $e',
    isError: true
  );
}
```
- Catches errors from action sheet selection logic
- No context check (uses global snackbar)

**Lines 265-269: Outer CatchError**
```dart
.catchError((e) {
  if (context.mounted) {
    PlatformDialogHelpers.showSnackBar(
      context: context,
      message: '$safeUnexpectedError $e',
      isError: true
    );
  }
});
```
- Catches errors from showPlatformActionSheet Future
- Context mounted check before showing snackbar

## Recurring Edit Actions

### Compact Version

```dart
Widget _buildRecurringEditAction(BuildContext context, dynamic l10n) {
  return GestureDetector(
    onTap: () => _showRecurringEditOptions(context, l10n),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.green600, 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.green600, 0.3),
          width: 1
        ),
      ),
      child: PlatformWidgets.platformIcon(
        CupertinoIcons.pencil,
        size: 16,
        color: AppStyles.green600
      ),
    ),
  );
}
```

**Pattern:** Same as recurring delete
- Shows action sheet on tap
- Green color scheme (edit action)
- Has border for visual distinction

### Regular Edit Action (Compact)

```dart
Widget _buildRegularEditAction(BuildContext context) {
  return GestureDetector(
    onTap: () => onEdit!(event),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.green600, 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.green600, 0.3),
          width: 1
        ),
      ),
      child: PlatformWidgets.platformIcon(
        CupertinoIcons.pencil,
        size: 16,
        color: AppStyles.green600
      ),
    ),
  );
}
```

**Difference:**
- Direct callback (no confirmation needed for edit)
- No ConfirmationActionWidget wrapper
- Same styling as recurring version

### Full Versions

```dart
Widget _buildRecurringEditFullAction(BuildContext context) {
  final l10n = context.l10n;

  return GestureDetector(
    onTap: () => _showRecurringEditOptions(context, l10n),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformWidgets.platformIcon(
            CupertinoIcons.pencil,
            color: AppStyles.green600,
            size: 24
          ),
          const SizedBox(height: 4),
          Text(
            l10n.edit,
            style: AppStyles.bodyTextSmall.copyWith(
              color: AppStyles.green600,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    ),
  );
}
```

**Pattern:** Icon + label column
- 24px icon (larger than compact)
- Label below
- Green color
- 8px padding

### Regular Edit Full Action

**Identical Structure:**
- Same layout as recurring version
- Direct callback instead of action sheet

## Show Recurring Edit Options

```dart
void _showRecurringEditOptions(BuildContext context, dynamic l10n) {
  final safeL10n = l10n;
  final safeTitle = safeL10n.editRecurringEvent;
  final safeMessage = safeL10n.editRecurringEventQuestion(event.title);
  final safeEditThis = safeL10n.editOnlyThisInstance;
  final safeEditSeries = safeL10n.editEntireSeries;
  final safeCancel = safeL10n.cancel;

  PlatformDialogHelpers.showPlatformActionSheet<String>(
    context,
    title: safeTitle,
    message: safeMessage,
    actions: [
      PlatformAction(text: safeEditThis, value: AppConstants.actionChoiceThis),
      if (onEditSeries != null)
        PlatformAction(text: safeEditSeries, value: AppConstants.actionChoiceSeries),
    ],
    cancelText: safeCancel,
  )
  .then((choice) {
    if (choice == AppConstants.actionChoiceThis) {
      try {
        onEdit?.call(event);
      } catch (e) {
        PlatformDialogHelpers.showSnackBar(
          message: '${safeL10n.unexpectedError} $e',
          isError: true
        );
      }
    } else if (choice == AppConstants.actionChoiceSeries) {
      try {
        onEditSeries?.call(event);
      } catch (e) {
        PlatformDialogHelpers.showSnackBar(
          message: '${safeL10n.unexpectedError} $e',
          isError: true
        );
      }
    }
  })
  .catchError((e) {
    if (context.mounted) {
      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: '${l10n.unexpectedError} $e',
        isError: true
      );
    }
  });
}
```

**Simpler than Delete:**
- No confirmation dialog (edit is non-destructive)
- Direct callback after choice
- Try-catch for error handling
- No Future handling (edit callbacks typically navigate, don't return Futures)

**Action Sheet:**
- "Edit This Instance Only"
- "Edit Entire Series" (if onEditSeries provided)
- "Cancel"

**Choice Handling:**
- This instance → calls onEdit(event)
- Series → calls onEditSeries(event)
- Error handling with snackbars

## Technical Characteristics

### Recurring Event Handling
- **Detection:** `event.isRecurringEvent` boolean
- **Action Sheet Flow:** User chooses instance vs series
- **Conditional Callbacks:** Series actions only shown if callbacks provided
- **Confirmation Dialogs:** Extra confirmation for destructive actions

### Error Handling Strategy
- **Triple Layer:**
  1. Try-catch around callback invocation
  2. Future.catchError for async callbacks
  3. .catchError on dialog Futures
- **Mounted Checks:** Before every snackbar
- **Safe Context:** Captured before async gaps

### Callback Flexibility
- **Named Parameters:** `shouldNavigate` passed through
- **Return Type Handling:** Supports void and Future
- **Null Safety:** Force unwrap only when existence checked

### Platform Adaptation
- **Full Mode:** Different button styles for iOS/Android
- **Compact Mode:** Consistent across platforms
- **Dialogs:** Platform-specific action sheets and confirmations

## Usage Examples

### Basic Event Actions
```dart
EventActions(
  event: event,
  onEdit: (event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventScreen(event: event),
      ),
    );
  },
  onDelete: (event, {required shouldNavigate}) async {
    await eventRepository.delete(event.id);
    if (shouldNavigate) {
      Navigator.pop(context);
    }
  },
)
```

### With Invite
```dart
EventActions(
  event: event,
  isCompact: false,
  onInvite: (event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => InviteUsersSheet(event: event),
    );
  },
  onEdit: _handleEdit,
  onDelete: _handleDelete,
)
```

### Recurring Event with Series Actions
```dart
EventActions(
  event: recurringEvent,
  isCompact: true,
  onEdit: (event) {
    // Edit single instance
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventInstanceScreen(event: event),
      ),
    );
  },
  onEditSeries: (event) {
    // Edit entire series
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSeriesScreen(event: event),
      ),
    );
  },
  onDelete: (event, {required shouldNavigate}) async {
    await eventRepository.deleteInstance(event.id);
    if (shouldNavigate) Navigator.pop(context);
  },
  onDeleteSeries: (event, {required shouldNavigate}) async {
    await eventRepository.deleteSeries(event.seriesId);
    if (shouldNavigate) Navigator.pop(context);
  },
)
```

### Detail Screen with Navigation
```dart
EventActions(
  event: event,
  isCompact: false,
  navigateAfterDelete: true, // Will pop after delete
  onEdit: _editEvent,
  onDelete: (event, {required shouldNavigate}) async {
    await _deleteEvent(event);
    // Widget handles navigation automatically
  },
)
```

## Testing Recommendations

### Unit Tests

**1. Callback Presence:**
```dart
test('should hide invite button when onInvite is null', () {
  final widget = EventActions(
    event: testEvent,
    onInvite: null,
  );

  // Verify invite button not rendered
});
```

**2. Recurring vs Regular:**
```dart
test('should use action sheet for recurring delete', () {
  final recurringEvent = Event(isRecurringEvent: true);
  final widget = EventActions(
    event: recurringEvent,
    onDelete: (_,{shouldNavigate}) {},
  );

  // Verify shows action sheet instead of direct confirmation
});
```

### Widget Tests

**1. Compact vs Full Mode:**
```dart
testWidgets('should render compact buttons in compact mode', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EventActions(
          event: testEvent,
          isCompact: true,
          onEdit: (_) {},
          onDelete: (_,{shouldNavigate}) {},
        ),
      ),
    ),
  );

  // Verify 32x32 circular buttons
  final container = tester.widget<Container>(find.byType(Container).first);
  expect(container.constraints?.maxWidth, 32);
});
```

**2. Action Sheet Display:**
```dart
testWidgets('should show action sheet for recurring event delete', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EventActions(
          event: Event(isRecurringEvent: true),
          onDelete: (_,{shouldNavigate}) {},
          onDeleteSeries: (_,{shouldNavigate}) {},
        ),
      ),
    ),
  );

  // Tap delete button
  await tester.tap(find.byIcon(CupertinoIcons.delete));
  await tester.pumpAndSettle();

  // Verify action sheet options
  expect(find.text(context.l10n.deleteOnlyThisInstance), findsOneWidget);
  expect(find.text(context.l10n.deleteEntireSeries), findsOneWidget);
});
```

**3. Confirmation Dialog:**
```dart
testWidgets('should show confirmation for regular delete', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EventActions(
          event: Event(isRecurringEvent: false, title: "Test Event"),
          onDelete: (_,{shouldNavigate}) {},
        ),
      ),
    ),
  );

  // Tap delete button
  await tester.tap(find.byIcon(CupertinoIcons.delete));
  await tester.pumpAndSettle();

  // Verify confirmation dialog
  expect(find.text(context.l10n.confirmDelete), findsOneWidget);
  expect(find.textContaining("Test Event"), findsOneWidget);
});
```

**4. Callback Invocation:**
```dart
testWidgets('should call onEdit when edit button tapped', (tester) async {
  bool editCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EventActions(
          event: testEvent,
          onEdit: (event) { editCalled = true; },
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(CupertinoIcons.pencil));
  await tester.pump();

  expect(editCalled, true);
});
```

## Comparison with Similar Widgets

### vs. Individual Action Buttons
**EventActions Advantages:**
- Consistent layout and spacing
- Unified recurring event logic
- Integrated confirmation dialogs
- Error handling built-in

**Individual Buttons:**
- More flexible positioning
- Custom styling per button
- Simpler for non-recurring events

### vs. PopupMenuButton
**EventActions:**
- Always visible actions
- Touch-friendly button sizes
- Platform-adaptive styling
- Two display modes

**PopupMenuButton:**
- Saves screen space
- Can accommodate many actions
- Standard Material pattern

## Possible Improvements

### 1. Loading States
```dart
final bool isDeleting;

if (isDeleting)
  CircularProgressIndicator(strokeWidth: 2)
else
  /* delete button */
```

### 2. Success Feedback
```dart
onDelete: (event, {shouldNavigate}) async {
  await deleteEvent(event);
  PlatformWidgets.showGlobalPlatformMessage(
    message: "Event deleted",
  );
}
```

### 3. Undo Functionality
```dart
onDelete: (event, {shouldNavigate}) async {
  await deleteEvent(event);
  showSnackBar(
    message: "Event deleted",
    action: SnackBarAction(
      label: "Undo",
      onPressed: () => restoreEvent(event),
    ),
  );
}
```

### 4. Custom Colors
```dart
final Color? editColor;
final Color? deleteColor;

// Use custom colors instead of fixed green/red
```

### 5. Haptic Feedback
```dart
onTap: () {
  HapticFeedback.mediumImpact();
  onDelete(event);
}
```

### 6. Analytics Integration
```dart
onDelete: (event, {shouldNavigate}) {
  analytics.logEvent('event_deleted', {
    'event_id': event.id,
    'is_recurring': event.isRecurringEvent,
  });
  // ... actual delete
}
```

### 7. Permission Checks
```dart
final bool canEdit;
final bool canDelete;

// Conditionally enable buttons based on permissions
```

### 8. Accessibility Improvements
```dart
Semantics(
  label: "Delete ${event.title}",
  hint: "Double tap to delete this event",
  child: /* delete button */,
)
```

## Real-World Usage Context

This widget is typically used in:

1. **Event Detail Screens:** Full mode with all actions
2. **Event Cards in Lists:** Compact mode, limited space
3. **Calendar Views:** Quick actions on event tiles
4. **Bottom Sheets:** Action bar for selected events
5. **Search Results:** Actions on found events

The recurring event handling is particularly important for calendar apps where users expect to choose between modifying a single occurrence or the entire series.

## Performance Considerations

- **Stateless Design:** No internal state overhead
- **Conditional Rendering:** Only renders provided actions
- **Dialog Caching:** Platform dialogs handle their own lifecycle
- **Error Boundary:** Try-catch prevents widget tree crashes

**Recommendation:** Suitable for any context. The action sheet and confirmation dialogs are ephemeral and don't impact performance.

## Security Considerations

- **Confirmation Dialogs:** Prevent accidental deletions
- **Recurring Event Clarity:** Clear messaging about scope of changes
- **Error Messages:** Don't expose sensitive information
- **Mounted Checks:** Prevent operations on disposed widgets

**Recommendation:** Consider additional permission checks before showing destructive actions for shared/public events.
