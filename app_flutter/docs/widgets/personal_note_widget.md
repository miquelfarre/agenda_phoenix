# PersonalNoteWidget

## Overview
`PersonalNoteWidget` is a ConsumerStatefulWidget that provides a complete interface for managing personal notes on events. It handles three distinct states: empty (add note), viewing (show note with edit/delete), and editing (text field with save/cancel). The widget manages complex async operations including API calls, state synchronization, race condition prevention, and proper error handling with mounted checks.

## File Location
`lib/widgets/personal_note_widget.dart`

## Dependencies
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../models/event.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../services/api_client.dart';
import '../utils/app_exceptions.dart';
import 'adaptive/adaptive_button.dart';
import 'adaptive/configs/button_config.dart';
```

**Key Dependencies:**
- `flutter_riverpod`: Provides ConsumerStatefulWidget and ref for state management
- `api_client.dart`: `ApiClientFactory.instance` for PATCH requests to save/delete notes
- `event.dart`: Event model with personalNote property and copyWith method
- `app_exceptions.dart`: `ApiException` for handling API errors with status codes
- `adaptive_button.dart`: Platform-adaptive buttons for all actions
- `platform_widgets.dart`: Platform detection, icons, dialogs, and messages
- `l10n_helpers.dart`: Localization for labels, hints, and messages
- `app_styles.dart`: Colors and decoration for container styling

## Class Declaration

```dart
class PersonalNoteWidget extends ConsumerStatefulWidget {
  final Event event;
  final ValueChanged<Event> onEventUpdated;

  const PersonalNoteWidget({
    super.key,
    required this.event,
    required this.onEventUpdated
  });

  @override
  ConsumerState<PersonalNoteWidget> createState() => _PersonalNoteWidgetState();
}
```

**Widget Type:** ConsumerStatefulWidget (Riverpod)

**Rationale for ConsumerStatefulWidget:**
- **Stateful:** Manages internal state (_isEditing, _isSaving, TextEditingController, cached _currentNote)
- **Consumer:** Has access to `ref` for potential Riverpod providers (though not currently used in this widget)
- **Complex Lifecycle:** Needs initState, didUpdateWidget, and dispose lifecycle methods
- **Async Operations:** Handles async API calls with loading states

### Properties

**event** (`Event`):
- **Type:** Required, non-nullable
- **Purpose:** The event for which the personal note is being managed
- **Expected Properties:**
  - `id`: Integer event ID for API endpoints
  - `personalNote`: Nullable String containing the current note
- **Usage:** Displayed and edited, used for API endpoint construction

**onEventUpdated** (`ValueChanged<Event>`):
- **Type:** Required callback function `void Function(Event)`
- **Purpose:** Notifies parent widget when event note changes
- **Called After:** Successful save or delete operations
- **Parameter:** Updated Event with new personalNote value
- **Pattern:** Allows parent to update its state/cache with modified event

## State Class

```dart
class _PersonalNoteWidgetState extends ConsumerState<PersonalNoteWidget> {
  late Event _event;
  bool _isEditing = false;
  bool _isSaving = false;
  final TextEditingController _controller = TextEditingController();
  String? _currentNote;
  bool _preventOverwrite = false;
```

### State Variables Analysis

**_event** (`late Event`):
- **Type:** Late-initialized Event
- **Purpose:** Internal cached copy of widget.event
- **Initialization:** In initState() with `_event = widget.event`
- **Updates:** On successful save/delete via `_event = updatedEvent`
- **Rationale:** Allows local updates before parent is notified

**_isEditing** (`bool`):
- **Type:** Boolean flag
- **Default:** `false`
- **Purpose:** Controls which UI to show (view vs edit)
- **Transitions:**
  - false → true: User taps "Add" or "Edit" button
  - true → false: Save succeeds, cancel pressed, or empty note saved
- **UI Impact:** Determines whether to show view card or edit form

**_isSaving** (`bool`):
- **Type:** Boolean flag
- **Default:** `false`
- **Purpose:** Prevents concurrent save/delete operations
- **Set to true:** Start of _saveNote() or _deleteNote()
- **Set to false:** In finally block after operation completes
- **UI Impact:**
  - Disables edit/delete buttons in view mode
  - Disables text field in edit mode
  - Shows loading indicator instead of action buttons
- **Race Condition Prevention:** Early return if already saving

**_controller** (`TextEditingController`):
- **Type:** Final TextEditingController
- **Purpose:** Manages text input for note editing
- **Initialization:** Created in state declaration
- **Disposal:** Cleaned up in dispose() method
- **Updates:**
  - In initState: Set to current note if exists
  - In didUpdateWidget: Reset on external changes (when not saving)
  - In _deleteNote: Cleared after successful deletion
  - In cancel action: Reset to _currentNote
- **Pattern:** Standard Flutter controller for text input

**_currentNote** (`String?`):
- **Type:** Nullable String
- **Purpose:** Cached version of the saved note (not user input)
- **Represents:** Last known saved state from server
- **Updates:**
  - In initState: From widget.event.personalNote
  - In didUpdateWidget: From updated widget.event (if not saving)
  - After _saveNote: Set to newly saved note
  - After _deleteNote: Set to null
- **Usage:** Determines hasNote condition, provides fallback for cancel action
- **Rationale:** Separates saved state (_currentNote) from user input (_controller.text)

**_preventOverwrite** (`bool`):
- **Type:** Boolean flag
- **Default:** `false`
- **Purpose:** Prevents external updates from overwriting UI during delete operation
- **Set to true:** Start of _deleteNote() (line 110)
- **Set to false:** 500ms after delete completes (lines 162-164)
- **Rationale:** During delete, realtime updates might arrive with old data; this flag prevents UI reset
- **Pattern:** Temporary flag with delayed reset for async coordination

## Lifecycle Methods

### initState

```dart
@override
void initState() {
  super.initState();
  _event = widget.event;
  _currentNote = _event.personalNote;
  if (_currentNote != null && _currentNote!.isNotEmpty) {
    _controller.text = _currentNote!;
  }
}
```

**Line-by-Line Analysis:**

**Line 32:** `super.initState();`
- Required call to parent class initialization

**Line 33:** `_event = widget.event;`
- Initializes late variable with widget prop
- Creates internal copy for local state management

**Line 34:** `_currentNote = _event.personalNote;`
- Caches the initial note value
- May be null if no note exists yet

**Lines 35-37:** Conditional controller initialization
```dart
if (_currentNote != null && _currentNote!.isNotEmpty) {
  _controller.text = _currentNote!;
}
```
- **Condition:** Only sets controller text if note exists and is non-empty
- **Null Check:** `_currentNote != null`
- **Empty Check:** `_currentNote!.isNotEmpty`
- **Action:** Pre-fills text field with existing note
- **Edge Case:** If note is null or empty, controller starts with empty string (default)

### didUpdateWidget

```dart
@override
void didUpdateWidget(covariant PersonalNoteWidget oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (oldWidget.event.id != widget.event.id ||
      oldWidget.event.personalNote != widget.event.personalNote) {
    _event = widget.event;

    if (!_isSaving && !_preventOverwrite) {
      _currentNote = _event.personalNote;
      _controller.text = _currentNote ?? '';
      _isEditing = false;
    } else {}
  } else {}
}
```

**Purpose:** Handles external prop changes (e.g., from realtime updates, parent refreshes)

**Line-by-Line Analysis:**

**Line 42:** `super.didUpdateWidget(oldWidget);`
- Required parent call

**Lines 44-45:** Change detection
```dart
if (oldWidget.event.id != widget.event.id ||
    oldWidget.event.personalNote != widget.event.personalNote)
```
- **First Condition:** Event ID changed (completely different event)
- **Second Condition:** Personal note changed (same event, note updated)
- **Logical OR:** Updates if either condition is true

**Line 46:** `_event = widget.event;`
- Updates internal event cache regardless of other flags
- Ensures _event.id is current for API calls

**Lines 47-51:** Conditional state synchronization
```dart
if (!_isSaving && !_preventOverwrite) {
  _currentNote = _event.personalNote;
  _controller.text = _currentNote ?? '';
  _isEditing = false;
} else {}
```

**Protection Conditions:**
- `!_isSaving`: Don't update if we're currently saving (our changes in flight)
- `!_preventOverwrite`: Don't update if delete is in progress (temporary flag)

**Actions When Safe:**
1. Update cached note: `_currentNote = _event.personalNote`
2. Reset controller: `_controller.text = _currentNote ?? ''`
3. Exit editing mode: `_isEditing = false`

**Rationale:**
- Prevents overwriting user's unsaved edits with external updates
- Prevents race conditions during save/delete operations
- Resets UI to view mode when external changes arrive

**Empty Else Blocks (Lines 51-52):**
- Intentionally empty
- Documents that we considered the case but chose no action
- Prevents accidental handling mistakes

### dispose

```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

**Line 57:** `_controller.dispose();`
- **Critical:** Releases TextEditingController resources
- **Prevents:** Memory leaks from undisposed controllers
- **Pattern:** Always dispose controllers before widget disposal

**Line 58:** `super.dispose();`
- Required parent call
- Must be after controller disposal

## Save Note Method

```dart
Future<void> _saveNote(String note) async {
  final l10n = context.l10n;
  if (_isSaving) return;

  setState(() => _isSaving = true);

  try {
    if (note.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isEditing = false;
          _controller.text = _currentNote ?? '';
        });
      }
      return;
    }

    await ApiClientFactory.instance.patch(
      '/api/v1/events/${_event.id}/interaction',
      body: {'note': note}
    );

    if (mounted) {
      setState(() {
        _currentNote = note;
        _isEditing = false;
      });

      final updatedEvent = _event.copyWith(personalNote: note);
      _event = updatedEvent;
      widget.onEventUpdated(updatedEvent);

      // Realtime handles refresh automatically via EventRepository

      PlatformWidgets.showGlobalPlatformMessage(
        message: l10n.personalNoteUpdated
      );
    }
  } catch (e) {
    if (mounted) {
      PlatformWidgets.showGlobalPlatformMessage(
        message: l10n.errorSavingNote,
        isError: true
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

### Detailed Analysis

**Method Signature (Line 61):**
- **Returns:** `Future<void>` (async operation)
- **Parameter:** `note` - String to save (from _controller.text.trim())

**Lines 62-63:** Setup and guard
```dart
final l10n = context.l10n;
if (_isSaving) return;
```
- Caches localization object
- **Guard Clause:** Prevents concurrent save operations
- Returns early if already saving

**Line 65:** Set saving state
```dart
setState(() => _isSaving = true);
```
- Marks operation as in-progress
- Disables UI controls
- Shows loading indicator

**Lines 68-76:** Empty note handling
```dart
if (note.trim().isEmpty) {
  if (mounted) {
    setState(() {
      _isEditing = false;
      _controller.text = _currentNote ?? '';
    });
  }
  return;
}
```
**Edge Case:** User cleared the text entirely
- **Action:** Exit editing mode without API call
- **Reset Controller:** Restore to last saved note (_currentNote)
- **Mounted Check:** Ensures widget still exists before setState
- **No API Call:** Empty notes aren't saved, just cancel editing
- **Return Early:** Skips rest of method, goes to finally block

**Lines 78-79:** API request
```dart
await ApiClientFactory.instance.patch(
  '/api/v1/events/${_event.id}/interaction',
  body: {'note': note}
);
```
- **Method:** PATCH (update existing resource)
- **Endpoint:** `/api/v1/events/{eventId}/interaction`
- **Body:** JSON with 'note' field
- **Await:** Blocks until API responds or throws
- **Can Throw:** Network errors, API errors, timeouts

**Lines 80-93:** Success handling
```dart
if (mounted) {
  setState(() {
    _currentNote = note;
    _isEditing = false;
  });

  final updatedEvent = _event.copyWith(personalNote: note);
  _event = updatedEvent;
  widget.onEventUpdated(updatedEvent);

  // Realtime handles refresh automatically via EventRepository

  PlatformWidgets.showGlobalPlatformMessage(
    message: l10n.personalNoteUpdated
  );
}
```

**Mounted Check (Line 80):**
- **Critical:** Ensures widget hasn't been disposed during async operation
- **Pattern:** Always check mounted after await in StatefulWidget

**setState Block (Lines 81-84):**
1. Update cache: `_currentNote = note` (marks this as saved state)
2. Exit edit mode: `_isEditing = false` (returns to view mode)

**Event Update (Lines 86-88):**
```dart
final updatedEvent = _event.copyWith(personalNote: note);
_event = updatedEvent;
widget.onEventUpdated(updatedEvent);
```
1. Create new event with updated note using copyWith
2. Update internal cache
3. Notify parent via callback
- **Pattern:** Immutable data updates with copyWith

**Realtime Comment (Line 90):**
- Documents that realtime system will propagate changes
- Explains why we don't manually refresh repositories

**Success Message (Lines 92):**
```dart
PlatformWidgets.showGlobalPlatformMessage(
  message: l10n.personalNoteUpdated
);
```
- Shows toast/snackbar with success message
- Provides user feedback for async operation

**Lines 94-98:** Error handling
```dart
} catch (e) {
  if (mounted) {
    PlatformWidgets.showGlobalPlatformMessage(
      message: l10n.errorSavingNote,
      isError: true
    );
  }
}
```
- **Catches:** All exceptions (network, API, parsing, etc.)
- **Mounted Check:** Only show message if widget still exists
- **User Feedback:** Error message with isError flag (likely red color)
- **No Rethrow:** Silently handles error after showing message
- **State Preservation:** Keeps edit mode open so user can retry

**Lines 98-102:** Cleanup
```dart
} finally {
  if (mounted) {
    setState(() => _isSaving = false);
  }
}
```
- **Always Runs:** Even after return, exception, or success
- **Mounted Check:** Safety before setState
- **Reset Flag:** Re-enables UI controls
- **Pattern:** finally block for cleanup ensures flag is always reset

## Delete Note Method

```dart
Future<void> _deleteNote() async {
  final l10n = context.l10n;
  if (_isSaving) return;

  setState(() => _isSaving = true);
  _preventOverwrite = true;

  try {
    await ApiClientFactory.instance.patch(
      '/api/v1/events/${_event.id}/interaction',
      body: {'note': null}
    );

    // Realtime handles refresh automatically via EventRepository

    _currentNote = null;
    _controller.clear();

    final updatedEvent = _event.copyWith(personalNote: null);
    _event = updatedEvent;
    widget.onEventUpdated(updatedEvent);

    if (mounted) {
      setState(() {
        _isEditing = false;
      });

      PlatformWidgets.showGlobalPlatformMessage(
        message: l10n.personalNoteDeleted
      );
    }
  } on ApiException catch (apiErr) {
    if (apiErr.statusCode == 404) {
      // Realtime handles refresh automatically via EventRepository

      _currentNote = null;
      _controller.clear();

      final updatedEvent = _event.copyWith(personalNote: null);
      _event = updatedEvent;
      widget.onEventUpdated(updatedEvent);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        PlatformWidgets.showGlobalPlatformMessage(
          message: l10n.personalNoteDeleted
        );
      }
    } else {
      if (mounted) {
        PlatformWidgets.showGlobalPlatformMessage(
          message: l10n.errorSavingNote,
          isError: true
        );
      }
    }
  } catch (e) {
    if (mounted) {
      PlatformWidgets.showGlobalPlatformMessage(
        message: l10n.errorSavingNote,
        isError: true
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);

      Future.delayed(Duration(milliseconds: 500), () {
        _preventOverwrite = false;
      });
    }
  }
}
```

### Detailed Analysis

**Lines 106-110:** Setup and guards
```dart
final l10n = context.l10n;
if (_isSaving) return;

setState(() => _isSaving = true);
_preventOverwrite = true;
```
- Same guard pattern as _saveNote
- **Additional Flag:** `_preventOverwrite = true` (line 110)
  - Prevents didUpdateWidget from resetting state during delete
  - Critical for race condition prevention with realtime updates

**Lines 112-114:** API request
```dart
await ApiClientFactory.instance.patch(
  '/api/v1/events/${_event.id}/interaction',
  body: {'note': null}
);
```
- **Same Endpoint:** Uses interaction endpoint with null note
- **Pattern:** Null value deletes the note (rather than DELETE verb)
- **Rationale:** Interaction endpoint handles multiple fields, PATCH with null is idiomatic

**Lines 116-130:** Success path
```dart
// Realtime handles refresh automatically via EventRepository

_currentNote = null;
_controller.clear();

final updatedEvent = _event.copyWith(personalNote: null);
_event = updatedEvent;
widget.onEventUpdated(updatedEvent);

if (mounted) {
  setState(() {
    _isEditing = false;
  });

  PlatformWidgets.showGlobalPlatformMessage(
    message: l10n.personalNoteDeleted
  );
}
```

**Lines 117-118:** Clear cached data
- `_currentNote = null`: Marks no saved note
- `_controller.clear()`: Clears text field

**Lines 120-122:** Event update
- Same pattern as save: copyWith, cache update, parent notification

**Lines 124-130:** UI update
- **Mounted Check:** Before setState
- Exit editing mode
- Show success message with "deleted" text

**Lines 131-154:** ApiException handling
```dart
} on ApiException catch (apiErr) {
  if (apiErr.statusCode == 404) {
    // [Same cleanup as success path]
  } else {
    // [Error message]
  }
}
```

**404 Handling (Lines 132-148):**
- **Scenario:** Note was already deleted (by another client, realtime, etc.)
- **Strategy:** Treat as success - perform same cleanup
- **Rationale:** Idempotent delete - end result is correct (no note)
- **User Experience:** Still shows "deleted" message, user's intent succeeded
- **Code Duplication:** Intentional - maintains clarity of both paths

**Other API Errors (Lines 149-153):**
- All non-404 errors show error message
- Preserves editing state for retry

**Lines 154-158:** Generic error handling
```dart
} catch (e) {
  if (mounted) {
    PlatformWidgets.showGlobalPlatformMessage(
      message: l10n.errorSavingNote,
      isError: true
    );
  }
}
```
- Catches non-API exceptions (network, parsing, etc.)
- Same error message as other errors

**Lines 158-167:** Cleanup with delayed flag reset
```dart
} finally {
  if (mounted) {
    setState(() => _isSaving = false);

    Future.delayed(Duration(milliseconds: 500), () {
      _preventOverwrite = false;
    });
  }
}
```

**Line 160:** Reset saving flag (immediate)

**Lines 162-164:** Delayed preventOverwrite reset
```dart
Future.delayed(Duration(milliseconds: 500), () {
  _preventOverwrite = false;
});
```
- **Delay:** 500 milliseconds
- **Rationale:** Gives realtime system time to process delete and send updates
- **Without Delay:** Realtime update might arrive immediately and overwrite clean state with stale data
- **Trade-off:** 500ms window where external updates are ignored
- **Pattern:** Time-based coordination for distributed state

## Confirm and Delete Method

```dart
Future<void> _confirmAndDelete() async {
  final l10n = context.l10n;
  final shouldDelete = await PlatformWidgets.showPlatformConfirmDialog(
    context,
    title: l10n.deleteNote,
    message: l10n.deleteNoteConfirmation,
    confirmText: l10n.delete,
    cancelText: l10n.cancel,
    isDestructive: true
  );

  if (shouldDelete == true) {
    await _deleteNote();
  }
}
```

**Purpose:** Wrapper for _deleteNote that shows confirmation dialog

**Lines 171:** Dialog display
```dart
final shouldDelete = await PlatformWidgets.showPlatformConfirmDialog(
  context,
  title: l10n.deleteNote,
  message: l10n.deleteNoteConfirmation,
  confirmText: l10n.delete,
  cancelText: l10n.cancel,
  isDestructive: true
);
```
- **Platform Adaptive:** Shows UIAlertController (iOS) or AlertDialog (Android)
- **Await:** Blocks until user responds
- **Returns:** `bool?` (true = confirm, false/null = cancel)
- **isDestructive:** Red/warning styling for confirm button
- **Localized:** All text from l10n

**Lines 173-175:** Conditional deletion
```dart
if (shouldDelete == true) {
  await _deleteNote();
}
```
- **Strict Check:** `== true` (not just truthy) handles null from dismissing dialog
- **Await:** Waits for deletion to complete
- **No Else:** If cancelled, does nothing (stays in current state)

## Build Method

```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  final isIOS = PlatformWidgets.isIOS;
  final hasNote = _currentNote != null && _currentNote!.isNotEmpty;

  return Container(
    margin: EdgeInsets.zero,
    decoration: AppStyles.cardDecoration,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppStyles.blueShade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: PlatformWidgets.platformIcon(
                  isIOS ? CupertinoIcons.doc_text : CupertinoIcons.doc,
                  color: AppStyles.blue600,
                  size: 20
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.personalNote,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.black87
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (!hasNote && !_isEditing)
            _buildAddButton(l10n)
          else if (hasNote && !_isEditing)
            _buildViewCard(l10n)
          else if (_isEditing)
            _buildEditForm(l10n, isIOS),
        ],
      ),
    ),
  );
}
```

### Analysis

**Lines 180-182:** Setup
```dart
final l10n = context.l10n;
final isIOS = PlatformWidgets.isIOS;
final hasNote = _currentNote != null && _currentNote!.isNotEmpty;
```
- Cache localization
- Platform detection for icon selection
- **hasNote:** Computed property determining if note exists
  - Used for conditional UI rendering

**Lines 184-186:** Container wrapper
```dart
return Container(
  margin: EdgeInsets.zero,
  decoration: AppStyles.cardDecoration,
```
- **Margin:** Explicitly zero (parent handles spacing)
- **Decoration:** Standard card styling (elevation, rounded corners, background)

**Lines 187-213:** Padding and column
```dart
child: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
```
- 16px padding on all sides
- Column for vertical stacking
- Left-aligned content

**Lines 192-205:** Header row
```dart
Row(
  children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppStyles.blueShade100,
        borderRadius: BorderRadius.circular(8)
      ),
      child: PlatformWidgets.platformIcon(
        isIOS ? CupertinoIcons.doc_text : CupertinoIcons.doc,
        color: AppStyles.blue600,
        size: 20
      ),
    ),
    const SizedBox(width: 12),
    Text(
      l10n.personalNote,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppStyles.black87
      ),
    ),
  ],
),
```

**Icon Container:**
- 8px padding creates space around icon
- Light blue background (blueShade100)
- 8px border radius for rounded corners
- **Platform-Specific Icons:**
  - iOS: `CupertinoIcons.doc_text` (document with text lines)
  - Android: `CupertinoIcons.doc` (simple document icon)
- Blue icon color (blue600)
- 20px size

**Title Text:**
- "Personal Note" (localized)
- 16px font size
- Semi-bold weight (w600)
- Near-black color (black87)

**Lines 209:** Conditional content rendering
```dart
if (!hasNote && !_isEditing)
  _buildAddButton(l10n)
else if (hasNote && !_isEditing)
  _buildViewCard(l10n)
else if (_isEditing)
  _buildEditForm(l10n, isIOS),
```

**State Machine:**
1. **No note, not editing:** Show add button
2. **Has note, not editing:** Show view card with edit/delete
3. **Editing:** Show text field with save/cancel
- **Mutually Exclusive:** Only one state shown at a time
- **Complete Coverage:** All combinations handled

## Build Add Button

```dart
Widget _buildAddButton(dynamic l10n) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.privateNoteHint,
        style: TextStyle(fontSize: 14, color: AppStyles.grey600)
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: AdaptiveButton(
          config: AdaptiveButtonConfigExtended.submit(),
          text: l10n.addPersonalNote,
          icon: CupertinoIcons.add,
          onPressed: () => setState(() => _isEditing = true)
        ),
      ),
    ],
  );
}
```

**Structure:**
- Hint text (gray, 14px)
- 16px spacing
- Full-width button

**Hint Text (Lines 220):**
- Explains privacy/purpose of personal notes
- Gray color for secondary information
- Small font size (14px)

**Button (Lines 222-225):**
- **Full Width:** `width: double.infinity`
- **Config:** `AdaptiveButtonConfigExtended.submit()` (primary styling)
- **Icon:** Plus sign (add)
- **Action:** Sets `_isEditing = true` via setState
- **Effect:** Switches UI to edit form

## Build View Card

```dart
Widget _buildViewCard(dynamic l10n) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppStyles.blueShade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppStyles.blueShade100),
        ),
        child: Text(
          _currentNote!,
          style: TextStyle(fontSize: 14, color: AppStyles.black87)
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: AdaptiveButton(
              config: AdaptiveButtonConfig.primary(),
              text: l10n.editPersonalNote,
              icon: CupertinoIcons.pencil,
              onPressed: _isSaving
                  ? null
                  : () => setState(() {
                      _isEditing = true;
                      _controller.text = _currentNote ?? '';
                    }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AdaptiveButton(
              config: AdaptiveButtonConfigExtended.destructive(),
              text: l10n.delete,
              icon: CupertinoIcons.trash,
              onPressed: _isSaving ? null : _confirmAndDelete
            ),
          ),
        ],
      ),
    ],
  );
}
```

**Note Display Container (Lines 234-243):**
```dart
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppStyles.blueShade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppStyles.blueShade100),
  ),
  child: Text(
    _currentNote!,
    style: TextStyle(fontSize: 14, color: AppStyles.black87)
  ),
),
```
- **Full Width:** Ensures consistent card appearance
- **Padding:** 12px on all sides
- **Background:** Very light blue (blueShade50)
- **Border:** Light blue border (blueShade100)
- **Border Radius:** 8px rounded corners
- **Text:** Displays _currentNote with force unwrap (safe due to hasNote check in build())

**Action Buttons Row (Lines 245-267):**
- Two equal-width buttons (Expanded widgets)
- 12px gap between them

**Edit Button (Lines 247-258):**
```dart
AdaptiveButton(
  config: AdaptiveButtonConfig.primary(),
  text: l10n.editPersonalNote,
  icon: CupertinoIcons.pencil,
  onPressed: _isSaving
      ? null
      : () => setState(() {
          _isEditing = true;
          _controller.text = _currentNote ?? '';
        }),
),
```
- **Primary Styling:** Blue background
- **Icon:** Pencil
- **Disabled When:** `_isSaving == true` (passes null as onPressed)
- **Action:**
  1. Enter edit mode: `_isEditing = true`
  2. Pre-fill controller: `_controller.text = _currentNote ?? ''`
- **Pattern:** Restore current note to text field for editing

**Delete Button (Lines 261-263):**
```dart
AdaptiveButton(
  config: AdaptiveButtonConfigExtended.destructive(),
  text: l10n.delete,
  icon: CupertinoIcons.trash,
  onPressed: _isSaving ? null : _confirmAndDelete
),
```
- **Destructive Styling:** Red/warning colors
- **Icon:** Trash can
- **Disabled When:** `_isSaving == true`
- **Action:** Calls _confirmAndDelete (shows dialog then deletes)

## Build Edit Form

```dart
Widget _buildEditForm(dynamic l10n, bool isIOS) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CupertinoTextField(
        controller: _controller,
        placeholder: l10n.addPersonalNoteHint,
        maxLines: 4,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppStyles.grey300),
          borderRadius: BorderRadius.circular(8),
        ),
        enabled: !_isSaving,
      ),

      const SizedBox(height: 16),

      if (_isSaving)
        Center(child: PlatformWidgets.platformLoadingIndicator())
      else
        Row(
          children: [
            Expanded(
              child: AdaptiveButton(
                config: AdaptiveButtonConfigExtended.cancel(),
                text: l10n.cancel,
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _controller.text = _currentNote ?? '';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdaptiveButton(
                config: AdaptiveButtonConfigExtended.submit(),
                text: l10n.save,
                onPressed: () async {
                  final note = _controller.text.trim();
                  await _saveNote(note);
                },
              ),
            ),
          ],
        ),
    ],
  );
}
```

**Text Field (Lines 274-284):**
```dart
CupertinoTextField(
  controller: _controller,
  placeholder: l10n.addPersonalNoteHint,
  maxLines: 4,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    border: Border.all(color: AppStyles.grey300),
    borderRadius: BorderRadius.circular(8),
  ),
  enabled: !_isSaving,
),
```
- **Type:** CupertinoTextField (used on both platforms for consistent styling)
- **Controller:** Bound to _controller for text access
- **Placeholder:** Hint text for empty field
- **MaxLines:** 4 lines tall (multiline input)
- **Padding:** 12px internal padding
- **Border:** Gray border with rounded corners
- **Enabled:** Disabled during save operation (`!_isSaving`)

**Conditional Action Section (Lines 288-318):**
- **If saving:** Show centered loading indicator
- **Else:** Show cancel and save buttons

**Loading Indicator (Line 289):**
```dart
if (_isSaving)
  Center(child: PlatformWidgets.platformLoadingIndicator())
```
- Platform-adaptive spinner
- Centered alignment
- Replaces buttons during save operation

**Action Buttons (Lines 291-317):**
- Two equal-width buttons (Expanded)
- 12px gap

**Cancel Button (Lines 293-303):**
```dart
AdaptiveButton(
  config: AdaptiveButtonConfigExtended.cancel(),
  text: l10n.cancel,
  onPressed: () {
    setState(() {
      _isEditing = false;
      _controller.text = _currentNote ?? '';
    });
  },
),
```
- **Cancel Styling:** Gray/secondary appearance
- **Action:**
  1. Exit edit mode
  2. Reset controller to saved note (discards unsaved changes)
- **Always Enabled:** Not disabled during save (save disables via conditional rendering)

**Save Button (Lines 306-315):**
```dart
AdaptiveButton(
  config: AdaptiveButtonConfigExtended.submit(),
  text: l10n.save,
  onPressed: () async {
    final note = _controller.text.trim();
    await _saveNote(note);
  },
),
```
- **Submit Styling:** Primary/blue colors
- **Action:**
  1. Extract text and trim whitespace
  2. Call async _saveNote method
  3. Await completion
- **Error Handling:** Handled within _saveNote

## Technical Characteristics

### State Management Pattern
- **ConsumerStatefulWidget:** Riverpod integration (though ref not actively used)
- **Internal State:** Complex boolean flags (_isEditing, _isSaving, _preventOverwrite)
- **Controlled Input:** TextEditingController for text field
- **Cached State:** Separate _currentNote from _controller.text
- **Parent Communication:** Callback pattern (onEventUpdated)

### Async Operation Handling
- **Guard Clauses:** Early return if already saving
- **Loading States:** _isSaving flag disables UI and shows spinner
- **Mounted Checks:** After every await before setState
- **Try-Catch-Finally:** Proper exception handling with cleanup
- **Race Condition Prevention:** _preventOverwrite flag with delayed reset

### API Integration
- **Endpoint:** `/api/v1/events/{id}/interaction`
- **Method:** PATCH (update)
- **Save:** `{'note': 'text'}`
- **Delete:** `{'note': null}`
- **Error Handling:** ApiException for typed errors, generic catch for others
- **Idempotent Delete:** 404 treated as success

### State Synchronization
- **didUpdateWidget:** Responds to external prop changes
- **Conditional Updates:** Only sync when safe (!_isSaving && !_preventOverwrite)
- **Realtime Integration:** Comments indicate automatic refresh via EventRepository
- **Delayed Flag Reset:** 500ms delay for distributed state coordination

### UI State Machine
1. **Empty:** Add button with hint
2. **Viewing:** Note display with edit/delete buttons
3. **Editing:** Text field with cancel/save buttons
- **Mutually Exclusive:** Only one state visible at a time
- **Loading Overlay:** Indicator replaces buttons during save

## Usage Examples

### Basic Usage
```dart
PersonalNoteWidget(
  event: currentEvent,
  onEventUpdated: (updatedEvent) {
    setState(() {
      currentEvent = updatedEvent;
    });
  },
)
```

### In Event Detail Screen
```dart
class EventDetailScreen extends ConsumerWidget {
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // ... other event details ...
          PersonalNoteWidget(
            event: event,
            onEventUpdated: (updated) {
              // Update local cache
              ref.read(eventCacheProvider.notifier).update(updated);
              // Or update parent state
              Navigator.pop(context, updated);
            },
          ),
        ],
      ),
    );
  }
}
```

### With Repository Integration
```dart
PersonalNoteWidget(
  event: event,
  onEventUpdated: (updatedEvent) async {
    // Update repository
    await ref.read(eventRepositoryProvider).updateLocal(updatedEvent);
    // Update cached list
    ref.read(eventsListProvider.notifier).replaceEvent(updatedEvent);
  },
)
```

## Testing Recommendations

### Unit Tests

**1. Lifecycle Methods:**
```dart
test('initState should initialize controller with existing note', () {
  final event = Event(id: 1, personalNote: "Test note");
  final widget = PersonalNoteWidget(event: event, onEventUpdated: (_) {});
  final state = widget.createState();

  state.initState();

  expect(state._controller.text, "Test note");
  expect(state._currentNote, "Test note");
});

test('initState should leave controller empty for null note', () {
  final event = Event(id: 1, personalNote: null);
  final widget = PersonalNoteWidget(event: event, onEventUpdated: (_) {});
  final state = widget.createState();

  state.initState();

  expect(state._controller.text, "");
  expect(state._currentNote, null);
});
```

**2. State Flags:**
```dart
test('_isSaving should prevent concurrent save operations', () async {
  // Create widget and state
  final state = createTestState();
  state._isSaving = true;

  // Attempt to save
  await state._saveNote("test");

  // Verify no API call was made (mock ApiClient)
  verifyNever(mockApiClient.patch(any, body: any));
});
```

**3. Empty Note Handling:**
```dart
test('_saveNote should exit edit mode for empty note without API call', () async {
  final state = createTestState();
  state._isEditing = true;
  state._currentNote = "existing";

  await state._saveNote("   "); // Whitespace only

  expect(state._isEditing, false);
  expect(state._controller.text, "existing");
  verifyNever(mockApiClient.patch(any, body: any));
});
```

### Widget Tests

**1. Initial State Rendering:**
```dart
testWidgets('should show add button when no note exists', (tester) async {
  final event = Event(id: 1, personalNote: null);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.addPersonalNote), findsOneWidget);
  expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
});

testWidgets('should show view card when note exists', (tester) async {
  final event = Event(id: 1, personalNote: "My note");

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  expect(find.text("My note"), findsOneWidget);
  expect(find.text(context.l10n.editPersonalNote), findsOneWidget);
  expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
});
```

**2. State Transitions:**
```dart
testWidgets('should transition to edit mode when add button tapped', (tester) async {
  final event = Event(id: 1, personalNote: null);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  // Tap add button
  await tester.tap(find.text(context.l10n.addPersonalNote));
  await tester.pump();

  // Verify edit form is shown
  expect(find.byType(CupertinoTextField), findsOneWidget);
  expect(find.text(context.l10n.save), findsOneWidget);
  expect(find.text(context.l10n.cancel), findsOneWidget);
});

testWidgets('should return to view mode when cancel tapped', (tester) async {
  final event = Event(id: 1, personalNote: "Original");

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  // Enter edit mode
  await tester.tap(find.text(context.l10n.editPersonalNote));
  await tester.pump();

  // Modify text
  await tester.enterText(find.byType(CupertinoTextField), "Modified");

  // Tap cancel
  await tester.tap(find.text(context.l10n.cancel));
  await tester.pump();

  // Verify returned to view with original text
  expect(find.text("Original"), findsOneWidget);
  expect(find.byType(CupertinoTextField), findsNothing);
});
```

**3. Saving Flow:**
```dart
testWidgets('should show loading indicator while saving', (tester) async {
  final event = Event(id: 1, personalNote: null);

  // Setup mock API with delay
  when(mockApiClient.patch(any, body: any))
    .thenAnswer((_) => Future.delayed(Duration(seconds: 1)));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  // Enter edit mode and type
  await tester.tap(find.text(context.l10n.addPersonalNote));
  await tester.pump();
  await tester.enterText(find.byType(CupertinoTextField), "New note");

  // Tap save
  await tester.tap(find.text(context.l10n.save));
  await tester.pump();

  // Verify loading indicator appears
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text(context.l10n.save), findsNothing);
});

testWidgets('should call onEventUpdated after successful save', (tester) async {
  Event? updatedEvent;
  final event = Event(id: 1, personalNote: null);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (e) { updatedEvent = e; },
        ),
      ),
    ),
  );

  // Add note and save
  await tester.tap(find.text(context.l10n.addPersonalNote));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(CupertinoTextField), "New note");
  await tester.tap(find.text(context.l10n.save));
  await tester.pumpAndSettle();

  // Verify callback was called with updated event
  expect(updatedEvent, isNotNull);
  expect(updatedEvent!.personalNote, "New note");
});
```

**4. Delete Confirmation:**
```dart
testWidgets('should show confirmation dialog before delete', (tester) async {
  final event = Event(id: 1, personalNote: "To delete");

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  // Tap delete
  await tester.tap(find.byIcon(CupertinoIcons.trash));
  await tester.pumpAndSettle();

  // Verify confirmation dialog appears
  expect(find.text(context.l10n.deleteNote), findsOneWidget);
  expect(find.text(context.l10n.deleteNoteConfirmation), findsOneWidget);
});

testWidgets('should not delete if confirmation cancelled', (tester) async {
  final event = Event(id: 1, personalNote: "Keep me");

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  // Tap delete
  await tester.tap(find.byIcon(CupertinoIcons.trash));
  await tester.pumpAndSettle();

  // Cancel dialog
  await tester.tap(find.text(context.l10n.cancel));
  await tester.pumpAndSettle();

  // Verify note still exists
  expect(find.text("Keep me"), findsOneWidget);
  verifyNever(mockApiClient.patch(any, body: {'note': null}));
});
```

**5. Error Handling:**
```dart
testWidgets('should show error message on save failure', (tester) async {
  // Setup API to throw error
  when(mockApiClient.patch(any, body: any))
    .thenThrow(Exception("Network error"));

  final event = Event(id: 1, personalNote: null);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalNoteWidget(
          event: event,
          onEventUpdated: (_) {},
        ),
      ),
    ),
  );

  // Attempt to save
  await tester.tap(find.text(context.l10n.addPersonalNote));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(CupertinoTextField), "New note");
  await tester.tap(find.text(context.l10n.save));
  await tester.pumpAndSettle();

  // Verify error message appeared
  expect(find.text(context.l10n.errorSavingNote), findsOneWidget);
  // Verify still in edit mode (for retry)
  expect(find.byType(CupertinoTextField), findsOneWidget);
});
```

### Integration Tests

**1. Full Flow Test:**
```dart
testWidgets('should complete full add-edit-delete flow', (tester) async {
  Event currentEvent = Event(id: 1, personalNote: null);

  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            body: PersonalNoteWidget(
              event: currentEvent,
              onEventUpdated: (e) {
                setState(() => currentEvent = e);
              },
            ),
          );
        },
      ),
    ),
  );

  // Add note
  await tester.tap(find.text(context.l10n.addPersonalNote));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(CupertinoTextField), "First note");
  await tester.tap(find.text(context.l10n.save));
  await tester.pumpAndSettle();
  expect(find.text("First note"), findsOneWidget);

  // Edit note
  await tester.tap(find.text(context.l10n.editPersonalNote));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(CupertinoTextField), "Updated note");
  await tester.tap(find.text(context.l10n.save));
  await tester.pumpAndSettle();
  expect(find.text("Updated note"), findsOneWidget);

  // Delete note
  await tester.tap(find.byIcon(CupertinoIcons.trash));
  await tester.pumpAndSettle();
  await tester.tap(find.text(context.l10n.delete));
  await tester.pumpAndSettle();
  expect(find.text(context.l10n.addPersonalNote), findsOneWidget);
});
```

## Comparison with Similar Widgets

### vs. Standard TextField with Buttons
**PersonalNoteWidget Advantages:**
- Complete state management (add/view/edit)
- Integrated API calls
- Error handling and loading states
- Confirmation dialogs
- Success/error messages
- Platform-adaptive UI

**When to Use Standard:**
- Simple input without backend
- Custom state management needed
- Different API patterns

### vs. Form-Based Note Input
**PersonalNoteWidget Advantages:**
- Inline editing (no navigation)
- Immediate feedback
- Optimized for single field
- Visual note display with styling

**Form-Based Advantages:**
- Multiple related fields
- Complex validation
- Structured data entry

## Possible Improvements

### 1. Debounced Auto-Save
```dart
Timer? _autoSaveTimer;

void _onTextChanged(String text) {
  _autoSaveTimer?.cancel();
  _autoSaveTimer = Timer(Duration(seconds: 2), () {
    _saveNote(text);
  });
}

// In CupertinoTextField:
onChanged: _onTextChanged,
```
**Benefit:** Automatic saving without explicit save button.

### 2. Character Count
```dart
Text(
  "${_controller.text.length} / 500",
  style: TextStyle(fontSize: 12, color: AppStyles.grey600),
)
```
**Benefit:** User awareness of length limits.

### 3. Rich Text Support
```dart
import 'package:flutter_markdown/flutter_markdown.dart';

// In view card:
MarkdownBody(data: _currentNote!)
```
**Benefit:** Allow formatted notes (bold, lists, links).

### 4. Undo/Redo
```dart
final _history = <String>[];
int _historyIndex = -1;

void _undo() {
  if (_historyIndex > 0) {
    _historyIndex--;
    _controller.text = _history[_historyIndex];
  }
}
```
**Benefit:** Recover accidentally deleted or modified text.

### 5. Optimistic UI Updates
```dart
// Update UI immediately, rollback on error
setState(() {
  _currentNote = note;
  _isEditing = false;
});

try {
  await api.patch(...);
} catch (e) {
  // Rollback
  setState(() {
    _currentNote = oldNote;
    _isEditing = true;
  });
}
```
**Benefit:** Faster perceived performance.

### 6. Voice Input Support
```dart
import 'package:speech_to_text/speech_to_text.dart';

IconButton(
  icon: Icon(CupertinoIcons.mic),
  onPressed: _startVoiceInput,
)
```
**Benefit:** Accessibility and convenience for mobile users.

### 7. Template/Quick Replies
```dart
final quickReplies = ["Interested", "Maybe later", "Need more info"];

Wrap(
  children: quickReplies.map((reply) =>
    Chip(
      label: Text(reply),
      onPressed: () => _controller.text = reply,
    )
  ).toList(),
)
```
**Benefit:** Faster input for common responses.

### 8. Note History/Versions
```dart
final List<NoteVersion> _versions;

IconButton(
  icon: Icon(CupertinoIcons.time),
  onPressed: () => showNoteHistory(context, _versions),
)
```
**Benefit:** See previous versions, undo changes.

### 9. Offline Support
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

if (await isOnline()) {
  await api.patch(...);
} else {
  await queueForSync(note);
  showOfflineMessage();
}
```
**Benefit:** Continue working without network.

### 10. Analytics Integration
```dart
analytics.logEvent('personal_note_added', {
  'note_length': note.length,
  'event_id': _event.id,
});
```
**Benefit:** Understand feature usage patterns.

## Real-World Usage Context

This widget is used in:

1. **Event Detail Screens:** Allow users to add private notes to events
2. **Calendar Views:** Quick note access from event cards
3. **Shared Events:** Private annotations on public/shared events
4. **Meeting Preparation:** Personal notes separate from event description
5. **Follow-up Tracking:** Remember action items or outcomes

The separation of personal notes from event descriptions allows users to maintain private information on shared/public events without affecting other participants.

## Performance Considerations

- **TextEditingController Management:** Properly disposed in lifecycle method
- **Mounted Checks:** Prevents setState on disposed widgets
- **Conditional Rendering:** Only one UI state rendered at a time (no hidden widgets)
- **API Efficiency:** Single endpoint for save/delete via PATCH with null
- **State Caching:** _currentNote prevents unnecessary API calls on cancel
- **Loading States:** Prevents concurrent operations with guard clauses

**Recommendation:** Suitable for event detail screens. Consider implementing optimistic updates and offline support for high-latency networks.

## Security Considerations

- **Input Validation:** Text is trimmed, empty notes handled gracefully
- **API Security:** Uses authenticated ApiClient (factory pattern)
- **Personal Data:** Notes are private to user, not shared with event participants
- **Error Handling:** API errors don't expose sensitive information
- **Race Conditions:** Proper flag management prevents data corruption

**Recommendation:** Consider adding input sanitization for XSS prevention if notes are ever displayed in web views or shared contexts.
