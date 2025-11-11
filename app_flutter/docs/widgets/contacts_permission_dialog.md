# ContactsPermissionDialog Widget

## Overview
`ContactsPermissionDialog` is a StatefulWidget that presents a user-friendly dialog for requesting contacts permission. It handles the complete permission flow including initial request, settings redirection when denied, loading states, and proper async/mounted checks. The dialog uses platform-adaptive styling with Cupertino design and integrates with the `permission_handler` package for iOS and Android permission management.

## File Location
`lib/widgets/contacts_permission_dialog.dart`

## Dependencies
```dart
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:permission_handler/permission_handler.dart';
```

**Key Dependencies:**
- `permission_handler`: Third-party package for runtime permission requests on iOS/Android
- `dialog_helpers.dart`: Platform confirmation dialog utilities
- `platform_widgets.dart`: Platform icons and loading indicators
- `platform_detection.dart`: `PlatformDetection.isIOS` for platform-specific styling
- `l10n_helpers.dart`: Localization for all text content
- `app_styles.dart`: Colors and text styles

## Class Declaration

```dart
class ContactsPermissionDialog extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const ContactsPermissionDialog({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied
  });

  @override
  State<ContactsPermissionDialog> createState() => _ContactsPermissionDialogState();
}
```

**Widget Type:** StatefulWidget

**Rationale for Stateful:**
- **Loading State:** Manages `_isRequesting` flag during async permission request
- **User Feedback:** Shows loading indicator while permission dialog is displayed
- **Async Operations:** Handles permission requests, settings navigation, and callbacks
- **Button State:** Disables buttons during request to prevent duplicate actions

### Properties

**onPermissionGranted** (`VoidCallback?`):
- **Type:** Optional nullable callback
- **Purpose:** Called when user grants contacts permission
- **Timing:** Invoked before dialog is dismissed with `true` result
- **Usage:** Parent can trigger next action (e.g., fetch contacts, show contacts picker)
- **Pattern:** Success callback for permission flow

**onPermissionDenied** (`VoidCallback?`):
- **Type:** Optional nullable callback
- **Purpose:** Called when user denies permission or cancels
- **Scenarios:**
  - User taps "Not Now" button
  - Permission request throws exception
  - User denies in settings dialog
  - User cancels settings dialog
- **Usage:** Parent can handle denial (e.g., show alternative UI, track analytics)
- **Pattern:** Failure/cancellation callback for permission flow

## State Class

```dart
class _ContactsPermissionDialogState extends State<ContactsPermissionDialog> {
  bool _isRequesting = false;
```

### State Variables

**_isRequesting** (`bool`):
- **Type:** Boolean flag
- **Default:** `false`
- **Purpose:** Prevents concurrent permission requests and provides loading state
- **Set to true:** Start of _requestPermission() method
- **Set to false:** In finally block after request completes (success or error)
- **UI Impact:**
  - Disables both action buttons when true
  - Shows loading indicator instead of "Allow Access" text
- **Pattern:** Standard loading flag with guard clause

## Request Permission Method

```dart
Future<void> _requestPermission() async {
  if (_isRequesting) return;

  setState(() {
    _isRequesting = true;
  });

  try {
    final onGranted = widget.onPermissionGranted;

    final hasPermission = await Permission.contacts.request().isGranted;

    if (hasPermission) {
      onGranted?.call();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        _showSettingsDialog();
      }
    }
  } catch (e) {
    widget.onPermissionDenied?.call();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  } finally {
    if (mounted) {
      setState(() {
        _isRequesting = false;
      });
    }
  }
}
```

### Detailed Analysis

**Line 23:** Guard clause
```dart
if (_isRequesting) return;
```
- **Purpose:** Prevents concurrent permission requests
- **Scenario:** User rapidly taps "Allow Access" button
- **Effect:** Second tap is ignored while first request is processing
- **Pattern:** Early return for state flag check

**Lines 25-27:** Set loading state
```dart
setState(() {
  _isRequesting = true;
});
```
- Marks request as in-progress
- Triggers button disable and loading indicator display
- No mounted check needed (not async yet)

**Line 30:** Cache callback reference
```dart
final onGranted = widget.onPermissionGranted;
```
- **Purpose:** Captures callback before async operation
- **Rationale:** Widget might be disposed during await, callback reference could become stale
- **Best Practice:** Cache widget properties before async gaps

**Line 32:** Permission request
```dart
final hasPermission = await Permission.contacts.request().isGranted;
```
- **Method:** `Permission.contacts.request()`
  - Shows OS permission dialog (first time)
  - Returns current status (if already decided)
- **Chaining:** `.isGranted` returns boolean
  - `true`: User granted permission
  - `false`: User denied or restricted
- **Await:** Blocks until user responds to OS dialog
- **Platform Behavior:**
  - **iOS:** Shows system alert with app name
  - **Android:** Shows system permission dialog
  - **Second Request:** On iOS, if previously denied, request() returns false immediately (requires settings)

**Lines 34-38:** Success path
```dart
if (hasPermission) {
  onGranted?.call();
  if (mounted) {
    Navigator.of(context).pop(true);
  }
}
```

**Line 35:** Notify parent
- Calls cached callback (null-safe with `?.call()`)
- Callback executes before dialog dismissal
- Parent can prepare UI for next step

**Lines 36-38:** Dismiss dialog with success
- **Mounted Check:** Critical after callback execution (callback might navigate elsewhere)
- **Pop with true:** Indicates permission was granted
- **Result Type:** `bool?` returned to caller via `showDialog().then()`

**Lines 39-43:** Denial path
```dart
} else {
  if (mounted) {
    _showSettingsDialog();
  }
}
```
- **Scenario:** User denied permission or it's permanently denied
- **Mounted Check:** After await
- **Action:** Show secondary dialog offering to open settings
- **Pattern:** Progressive permission request (offer alternative when denied)

**Lines 44-49:** Error handling
```dart
} catch (e) {
  widget.onPermissionDenied?.call();
  if (mounted) {
    Navigator.of(context).pop(false);
  }
}
```
- **Catches:** All exceptions from permission_handler
- **Common Errors:**
  - Platform exceptions
  - Missing permissions in manifest (Android)
  - Entitlements issues (iOS)
- **Callback:** Notifies parent of failure
- **Dialog Result:** Returns false
- **No Error Message:** Silent failure (permission_handler errors are typically platform issues, not user-facing)

**Lines 50-55:** Cleanup
```dart
} finally {
  if (mounted) {
    setState(() {
      _isRequesting = false;
    });
  }
}
```
- **Always Runs:** Success, denial, or error
- **Mounted Check:** Before setState
- **Reset Flag:** Re-enables buttons
- **Pattern:** finally block ensures cleanup

## Show Settings Dialog Method

```dart
void _showSettingsDialog() {
  final l10n = context.l10n;

  final safeContext = context;
  final safeL10n = l10n;

  PlatformDialogHelpers.showPlatformConfirmDialog(
    safeContext,
    title: safeL10n.permissionsNeeded,
    message: safeL10n.contactsPermissionSettingsMessage,
    confirmText: safeL10n.goToSettings,
    cancelText: safeL10n.notNow
  )
    .then((confirmed) async {
      if (confirmed == true) {
        try {
          await openAppSettings();
        } catch (e) {
          // Ignore errors
        }

        if (!mounted || !safeContext.mounted) return;
        Navigator.of(safeContext).pop(false);
        widget.onPermissionDenied?.call();
      } else {
        if (!mounted || !safeContext.mounted) return;
        Navigator.of(safeContext).pop();
        Navigator.of(safeContext).pop(false);
        widget.onPermissionDenied?.call();
      }
    })
    .catchError((e) {
      if (!mounted || !safeContext.mounted) return;
      Navigator.of(safeContext).pop();
      Navigator.of(safeContext).pop(false);
      widget.onPermissionDenied?.call();
    });
}
```

### Detailed Analysis

**Lines 61-62:** Safe context capture
```dart
final safeContext = context;
final safeL10n = l10n;
```
- **Purpose:** Captures context and l10n before async gap
- **Rationale:** Context might become invalid during async operations
- **Pattern:** "Safe context" pattern for async callbacks
- **Critical:** Used in .then() and .catchError() callbacks

**Lines 64-68:** Settings confirmation dialog
```dart
PlatformDialogHelpers.showPlatformConfirmDialog(
  safeContext,
  title: safeL10n.permissionsNeeded,
  message: safeL10n.contactsPermissionSettingsMessage,
  confirmText: safeL10n.goToSettings,
  cancelText: safeL10n.notNow
)
```
- **Platform Adaptive:** UIAlertController (iOS) or AlertDialog (Android)
- **Title:** "Permissions Needed" (localized)
- **Message:** Explains user must enable permission in settings
- **Confirm:** "Go to Settings"
- **Cancel:** "Not Now"
- **Returns:** `Future<bool?>` (true = confirmed, false/null = cancelled)

**Lines 65-75:** Confirmed path (open settings)
```dart
if (confirmed == true) {
  try {
    await openAppSettings();
  } catch (e) {
    // Ignore errors
  }

  if (!mounted || !safeContext.mounted) return;
  Navigator.of(safeContext).pop(false);
  widget.onPermissionDenied?.call();
}
```

**Lines 67-70:** Open settings
```dart
try {
  await openAppSettings();
} catch (e) {
  // Ignore errors
}
```
- **Function:** `openAppSettings()` from permission_handler
- **Behavior:**
  - **iOS:** Opens app-specific settings in Settings app
  - **Android:** Opens app info/permissions screen
- **Await:** Waits until user returns to app
- **Error Handling:** Silently ignores errors (platform-specific failures)
- **User Flow:** User leaves app, enables permission, returns to app

**Lines 72-74:** Cleanup after settings
```dart
if (!mounted || !safeContext.mounted) return;
Navigator.of(safeContext).pop(false);
widget.onPermissionDenied?.call();
```
- **Double Mounted Check:** Widget and context validity
- **Pop with false:** User didn't grant permission in this flow
- **Callback:** Notify parent of denial
- **Rationale:** Even if user enabled in settings, app doesn't know yet (would need to re-check on app resume)

**Lines 76-81:** Cancel path
```dart
} else {
  if (!mounted || !safeContext.mounted) return;
  Navigator.of(safeContext).pop();
  Navigator.of(safeContext).pop(false);
  widget.onPermissionDenied?.call();
}
```
- **Mounted Checks:** Both widget and context
- **First Pop:** Dismisses settings confirmation dialog
- **Second Pop:** Dismisses contacts permission dialog with false
- **Callback:** Notify parent of denial
- **Pattern:** Two-level dialog dismissal

**Lines 83-88:** Error handling
```dart
.catchError((e) {
  if (!mounted || !safeContext.mounted) return;
  Navigator.of(safeContext).pop();
  Navigator.of(safeContext).pop(false);
  widget.onPermissionDenied?.call();
});
```
- **Catches:** Errors from showPlatformConfirmDialog or openAppSettings
- **Same Cleanup:** Two pops and denial callback
- **Silent Failure:** No error message shown to user

## Skip Permission Method

```dart
void _skipPermission() {
  widget.onPermissionDenied?.call();
  Navigator.of(context).pop(false);
}
```

**Purpose:** Handles "Not Now" button tap

**Line 92:** Callback
- Notifies parent that user declined permission

**Line 93:** Dismiss dialog
- Returns false indicating denial
- No mounted check needed (synchronous operation)

## Build Method

```dart
@override
Widget build(BuildContext context) {
  return _buildCupertinoDialog();
}
```

**Direct Delegation:** Always returns Cupertino-styled dialog regardless of platform

**Design Decision:**
- Cupertino design used on both iOS and Android
- Consistent with app's overall design (likely Cupertino-first approach)
- CupertinoAlertDialog provides cleaner look for this specific use case

## Build Cupertino Dialog

```dart
Widget _buildCupertinoDialog() {
  final l10n = context.l10n;

  return CupertinoAlertDialog(
    title: Column(
      children: [
        PlatformWidgets.platformIcon(
          CupertinoIcons.person_2,
          color: PlatformDetection.isIOS
            ? CupertinoColors.activeBlue.resolveFrom(context)
            : AppStyles.primary600,
          size: 32
        ),
        const SizedBox(height: 8),
        Text(l10n.findYourFriends),
      ],
    ),
    content: Column(
      children: [
        const SizedBox(height: 8),
        Text(l10n.contactsPermissionMessage),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppStyles.colorWithOpacity(
              PlatformDetection.isIOS
                ? CupertinoColors.systemBlue.resolveFrom(context)
                : AppStyles.primary600,
              0.1
            ),
            borderRadius: BorderRadius.circular(8)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlatformWidgets.platformIcon(
                    CupertinoIcons.check_mark_circled,
                    color: CupertinoColors.systemGreen.resolveFrom(context),
                    size: 16
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.yourContactsStayPrivate,
                      style: AppStyles.cardSubtitle.copyWith(fontSize: 14)
                    )
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  PlatformWidgets.platformIcon(
                    CupertinoIcons.check_mark_circled,
                    color: CupertinoColors.systemGreen.resolveFrom(context),
                    size: 16
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.onlyShowMutualFriends,
                      style: AppStyles.cardSubtitle.copyWith(fontSize: 14)
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      CupertinoDialogAction(
        key: const Key('contacts_permission_not_now_button'),
        onPressed: _isRequesting ? null : _skipPermission,
        child: Text(l10n.notNow)
      ),
      CupertinoDialogAction(
        key: const Key('contacts_permission_allow_button'),
        onPressed: _isRequesting ? null : _requestPermission,
        isDefaultAction: true,
        child: _isRequesting
          ? PlatformWidgets.platformLoadingIndicator(radius: 8)
          : Text(l10n.allowAccess)
      ),
    ],
  );
}
```

### Title Section Analysis (Lines 105-111)

```dart
title: Column(
  children: [
    PlatformWidgets.platformIcon(
      CupertinoIcons.person_2,
      color: PlatformDetection.isIOS
        ? CupertinoColors.activeBlue.resolveFrom(context)
        : AppStyles.primary600,
      size: 32
    ),
    const SizedBox(height: 8),
    Text(l10n.findYourFriends),
  ],
),
```

**Icon (Lines 107-112):**
- **Type:** `CupertinoIcons.person_2` (two people silhouette)
- **Semantic:** Represents contacts/friends
- **Platform Color:**
  - **iOS:** `CupertinoColors.activeBlue.resolveFrom(context)` (adaptive to light/dark mode)
  - **Android:** `AppStyles.primary600` (app's primary color)
- **Size:** 32px (prominent header icon)

**Spacing:** 8px between icon and title text

**Title Text:**
- "Find Your Friends" (localized)
- Uses default CupertinoAlertDialog title styling
- Friendly, benefit-focused messaging

### Content Section Analysis (Lines 112-142)

**Structure:**
1. Top spacing (8px)
2. Main message text
3. Middle spacing (16px)
4. Benefit highlights container

**Main Message (Line 115):**
```dart
Text(l10n.contactsPermissionMessage),
```
- Explains why permission is needed
- Typically: "Allow access to find friends who are already using the app"

**Benefits Container (Lines 117-140):**
```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppStyles.colorWithOpacity(
      PlatformDetection.isIOS
        ? CupertinoColors.systemBlue.resolveFrom(context)
        : AppStyles.primary600,
      0.1
    ),
    borderRadius: BorderRadius.circular(8)
  ),
  child: /* checkmarks column */
)
```

**Styling:**
- **Padding:** 12px all sides
- **Background:** 10% opacity blue (platform-specific shade)
- **Border Radius:** 8px rounded corners
- **Purpose:** Visual emphasis for privacy assurances

**Benefit Items (Lines 123-137):**

Each benefit follows pattern:
```dart
Row(
  children: [
    PlatformWidgets.platformIcon(
      CupertinoIcons.check_mark_circled,
      color: CupertinoColors.systemGreen.resolveFrom(context),
      size: 16
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        l10n.benefitText,
        style: AppStyles.cardSubtitle.copyWith(fontSize: 14)
      )
    ),
  ],
)
```

**Checkmark Icon:**
- Green circle with checkmark
- 16px size (small, not overpowering)
- System green color (adaptive to theme)

**Benefit 1:** "Your contacts stay private"
**Benefit 2:** "Only show mutual friends"

**Design Pattern:**
- Builds trust by addressing privacy concerns upfront
- Visual checkmarks reinforce positive messaging
- Expands to fit text (Expanded widget)

### Actions Section Analysis (Lines 143-147)

**Action 1: Not Now Button (Line 144)**
```dart
CupertinoDialogAction(
  key: const Key('contacts_permission_not_now_button'),
  onPressed: _isRequesting ? null : _skipPermission,
  child: Text(l10n.notNow)
),
```
- **Key:** For widget testing (`find.byKey`)
- **Disabled When:** `_isRequesting == true`
- **Action:** Calls _skipPermission (denial callback + pop with false)
- **Label:** "Not Now" (non-committal, less pressure than "Deny")
- **Style:** Default action styling (gray text)

**Action 2: Allow Access Button (Lines 145-146)**
```dart
CupertinoDialogAction(
  key: const Key('contacts_permission_allow_button'),
  onPressed: _isRequesting ? null : _requestPermission,
  isDefaultAction: true,
  child: _isRequesting
    ? PlatformWidgets.platformLoadingIndicator(radius: 8)
    : Text(l10n.allowAccess)
),
```
- **Key:** For widget testing
- **Disabled When:** `_isRequesting == true`
- **Action:** Calls _requestPermission
- **isDefaultAction:** Bold text styling, indicates preferred choice
- **Label:** "Allow Access" or loading indicator
- **Conditional Child:**
  - **Loading:** Small spinner (8px radius) during request
  - **Default:** "Allow Access" text
- **Pattern:** Button transforms into loading indicator

## Technical Characteristics

### Permission Flow
1. **Initial Dialog:** User sees benefits and privacy assurances
2. **Allow Button:** Triggers OS permission dialog
3. **OS Dialog:** Native iOS/Android permission prompt
4. **If Granted:** Success callback → dialog dismisses with true
5. **If Denied:** Settings dialog offers second chance
6. **Settings Dialog:** User can open app settings
7. **Settings Navigation:** User enables permission manually
8. **Return:** Dialog dismisses with false (app needs to re-check on resume)

### State Management
- **Single Flag:** `_isRequesting` for loading state
- **Guard Clause:** Prevents concurrent requests
- **Mounted Checks:** After every async operation
- **Safe Context:** Captured before async callbacks

### Error Handling
- **Try-Catch:** Around permission request
- **Silent Failures:** Errors don't show user-facing messages
- **Graceful Degradation:** Always calls appropriate callback
- **Double Pop:** Handles nested dialog dismissal

### Platform Adaptations
- **Icon Colors:** Different blues for iOS vs Android
- **Background Colors:** Platform-specific primary colors
- **Green Checkmarks:** Resolve from context for dark mode
- **Dialog Style:** Cupertino on both platforms (design choice)

### Testing Support
- **Widget Keys:** Both action buttons have testable keys
- **Predictable Flow:** Deterministic state transitions
- **Callback Pattern:** Easy to mock and verify
- **Separated Methods:** Individual methods are unit-testable

## Usage Examples

### Basic Usage
```dart
await showDialog<bool>(
  context: context,
  builder: (context) => ContactsPermissionDialog(
    onPermissionGranted: () {
      print("Contacts permission granted!");
    },
    onPermissionDenied: () {
      print("Contacts permission denied");
    },
  ),
);
```

### With Navigation After Grant
```dart
final granted = await showDialog<bool>(
  context: context,
  builder: (context) => ContactsPermissionDialog(
    onPermissionGranted: () {
      // Permission granted, prepare to show contacts
      ref.read(contactsProvider.notifier).loadContacts();
    },
    onPermissionDenied: () {
      // Track denial for analytics
      analytics.logEvent('contacts_permission_denied');
    },
  ),
);

if (granted == true) {
  // Navigate to contacts screen
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ContactsScreen()),
  );
}
```

### With State Management
```dart
class OnboardingScreen extends ConsumerWidget {
  Future<void> _requestContactsPermission(BuildContext context, WidgetRef ref) async {
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ContactsPermissionDialog(
        onPermissionGranted: () {
          ref.read(permissionsProvider.notifier).setContactsGranted(true);
        },
        onPermissionDenied: () {
          ref.read(permissionsProvider.notifier).setContactsGranted(false);
        },
      ),
    );

    if (granted == true && context.mounted) {
      // Continue onboarding
      _goToNextStep(context);
    }
  }
}
```

### Pre-Check Before Showing
```dart
Future<void> _checkAndRequestContacts() async {
  final status = await Permission.contacts.status;

  if (status.isGranted) {
    // Already granted, proceed
    _loadContacts();
    return;
  }

  if (status.isPermanentlyDenied) {
    // Show different message if permanently denied
    _showPermanentlyDeniedDialog();
    return;
  }

  // Show permission request dialog
  final granted = await showDialog<bool>(
    context: context,
    builder: (context) => ContactsPermissionDialog(
      onPermissionGranted: _loadContacts,
      onPermissionDenied: _showAlternativeUI,
    ),
  );
}
```

## Testing Recommendations

### Unit Tests

**1. Guard Clause:**
```dart
test('_requestPermission should return early if already requesting', () async {
  final state = createTestState();
  state._isRequesting = true;

  await state._requestPermission();

  // Verify permission was not requested
  verifyNever(mockPermission.request());
});
```

**2. Success Flow:**
```dart
test('should call onPermissionGranted and pop with true when granted', () async {
  bool grantedCalled = false;
  final widget = ContactsPermissionDialog(
    onPermissionGranted: () { grantedCalled = true; },
  );

  // Mock permission as granted
  when(mockPermission.request()).thenAnswer((_) async => PermissionStatus.granted);

  await tester.pumpWidget(MaterialApp(home: widget));
  await tester.tap(find.text(context.l10n.allowAccess));
  await tester.pumpAndSettle();

  expect(grantedCalled, true);
  expect(find.byType(ContactsPermissionDialog), findsNothing); // Dialog dismissed
});
```

**3. Denial Flow:**
```dart
test('should show settings dialog when permission denied', () async {
  when(mockPermission.request()).thenAnswer((_) async => PermissionStatus.denied);

  await tester.pumpWidget(MaterialApp(home: ContactsPermissionDialog()));
  await tester.tap(find.text(context.l10n.allowAccess));
  await tester.pumpAndSettle();

  // Verify settings dialog appears
  expect(find.text(context.l10n.permissionsNeeded), findsOneWidget);
  expect(find.text(context.l10n.goToSettings), findsOneWidget);
});
```

### Widget Tests

**1. Initial Render:**
```dart
testWidgets('should display benefits and action buttons', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: ContactsPermissionDialog()),
  );

  expect(find.text(context.l10n.findYourFriends), findsOneWidget);
  expect(find.text(context.l10n.yourContactsStayPrivate), findsOneWidget);
  expect(find.text(context.l10n.onlyShowMutualFriends), findsOneWidget);
  expect(find.text(context.l10n.notNow), findsOneWidget);
  expect(find.text(context.l10n.allowAccess), findsOneWidget);
});
```

**2. Loading State:**
```dart
testWidgets('should show loading indicator when requesting', (tester) async {
  // Setup delayed permission response
  when(mockPermission.request())
    .thenAnswer((_) => Future.delayed(Duration(seconds: 1), () => PermissionStatus.granted));

  await tester.pumpWidget(MaterialApp(home: ContactsPermissionDialog()));

  // Tap allow button
  await tester.tap(find.text(context.l10n.allowAccess));
  await tester.pump();

  // Verify loading indicator appears
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text(context.l10n.allowAccess), findsNothing);

  // Verify buttons are disabled
  await tester.tap(find.text(context.l10n.notNow));
  await tester.pump();
  // Button tap should not work
});
```

**3. Skip Button:**
```dart
testWidgets('should call onPermissionDenied when not now tapped', (tester) async {
  bool deniedCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: ContactsPermissionDialog(
        onPermissionDenied: () { deniedCalled = true; },
      ),
    ),
  );

  await tester.tap(find.text(context.l10n.notNow));
  await tester.pumpAndSettle();

  expect(deniedCalled, true);
  expect(find.byType(ContactsPermissionDialog), findsNothing);
});
```

**4. Widget Keys:**
```dart
testWidgets('should have testable keys for buttons', (tester) async {
  await tester.pumpWidget(MaterialApp(home: ContactsPermissionDialog()));

  expect(
    find.byKey(Key('contacts_permission_not_now_button')),
    findsOneWidget
  );
  expect(
    find.byKey(Key('contacts_permission_allow_button')),
    findsOneWidget
  );
});
```

### Integration Tests

**1. Full Permission Flow:**
```dart
testWidgets('should complete full permission request flow', (tester) async {
  bool granted = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => ContactsPermissionDialog(
                onPermissionGranted: () { granted = true; },
              ),
            );
          },
          child: Text('Request'),
        ),
      ),
    ),
  );

  // Open dialog
  await tester.tap(find.text('Request'));
  await tester.pumpAndSettle();

  // Mock permission grant
  when(mockPermission.request()).thenAnswer((_) async => PermissionStatus.granted);

  // Tap allow
  await tester.tap(find.text(context.l10n.allowAccess));
  await tester.pumpAndSettle();

  expect(granted, true);
  expect(find.byType(ContactsPermissionDialog), findsNothing);
});
```

**2. Settings Flow:**
```dart
testWidgets('should navigate to settings when confirmed', (tester) async {
  when(mockPermission.request()).thenAnswer((_) async => PermissionStatus.denied);

  await tester.pumpWidget(MaterialApp(home: ContactsPermissionDialog()));

  // Request permission (will be denied)
  await tester.tap(find.text(context.l10n.allowAccess));
  await tester.pumpAndSettle();

  // Settings dialog appears
  expect(find.text(context.l10n.permissionsNeeded), findsOneWidget);

  // Tap go to settings
  await tester.tap(find.text(context.l10n.goToSettings));
  await tester.pumpAndSettle();

  // Verify openAppSettings was called
  verify(mockPermissionHandler.openAppSettings()).called(1);
});
```

## Comparison with Similar Widgets

### vs. Standard Permission Request
**ContactsPermissionDialog Advantages:**
- Custom UI with benefits explanation
- Privacy assurances upfront
- Settings dialog fallback
- Loading states
- Callback pattern

**Standard Request:**
- Simpler (just `await Permission.contacts.request()`)
- No custom UI
- No explanation of benefits

### vs. OnboardingScreen with Permissions
**ContactsPermissionDialog:**
- Focused on single permission
- Reusable dialog component
- Can be shown anywhere

**Onboarding:**
- Multiple permissions explained
- Sequential flow
- First-time user experience

### vs. Permission Settings Screen
**ContactsPermissionDialog:**
- One-time request
- Inline in user flow
- Immediate action

**Settings Screen:**
- Persistent access
- Review all permissions
- User-initiated

## Possible Improvements

### 1. Permission Status Check
```dart
@override
void initState() {
  super.initState();
  _checkCurrentStatus();
}

Future<void> _checkCurrentStatus() async {
  final status = await Permission.contacts.status;
  if (status.isGranted) {
    // Already granted, skip dialog
    widget.onPermissionGranted?.call();
    Navigator.of(context).pop(true);
  }
}
```
**Benefit:** Don't show dialog if permission already granted.

### 2. Analytics Integration
```dart
void _requestPermission() async {
  analytics.logEvent('contacts_permission_requested');
  // ... existing logic ...
  if (hasPermission) {
    analytics.logEvent('contacts_permission_granted');
  } else {
    analytics.logEvent('contacts_permission_denied');
  }
}
```
**Benefit:** Track permission funnel conversion rates.

### 3. Retry Mechanism
```dart
int _retryCount = 0;
final maxRetries = 3;

void _requestPermission() async {
  _retryCount++;
  // ... existing logic ...
  if (error && _retryCount < maxRetries) {
    // Show retry option
  }
}
```
**Benefit:** Handle transient errors gracefully.

### 4. Custom Illustration
```dart
Image.asset(
  'assets/images/contacts_illustration.png',
  height: 120,
)
```
**Benefit:** More engaging visual design.

### 5. Animated Transitions
```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  child: _isRequesting
    ? PlatformWidgets.platformLoadingIndicator()
    : Text(l10n.allowAccess),
)
```
**Benefit:** Smoother visual feedback.

### 6. A/B Testing Support
```dart
final showBenefits = experimentProvider.shouldShowBenefits;

if (showBenefits) {
  // Show current UI with benefits
} else {
  // Show simpler version
}
```
**Benefit:** Optimize conversion rates.

### 7. Localized Benefits
```dart
final benefits = l10n.contactsPermissionBenefits; // Returns list

for (final benefit in benefits) {
  Row(/* checkmark + benefit text */);
}
```
**Benefit:** Flexible benefit messaging per locale/market.

### 8. Permission Re-Check on App Resume
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _checkIfPermissionGranted();
  }
}
```
**Benefit:** Detect when user grants permission in settings.

## Real-World Usage Context

This dialog is typically shown:

1. **Onboarding Flow:** During initial app setup when building friend network
2. **Add Friends Feature:** When user explicitly wants to find contacts
3. **Event Invitations:** Before showing contacts picker for event invites
4. **Profile Completion:** As part of profile setup to find existing connections
5. **First-Time Actions:** When user first attempts contact-related feature

The progressive disclosure (initial dialog → settings dialog) respects user choice while providing a clear path to enable the feature if they change their mind.

## Performance Considerations

- **Lightweight State:** Single boolean flag
- **No Heavy Computations:** UI is static
- **Platform Optimization:** Native permission dialogs are OS-optimized
- **Proper Disposal:** No controllers or subscriptions to clean up
- **Mounted Checks:** Prevents memory leaks from callbacks

**Recommendation:** This dialog is lightweight and suitable for frequent display. Consider caching permission status in app state to avoid showing unnecessarily.

## Privacy Considerations

- **Transparent Messaging:** Clear explanation of what permission enables
- **Privacy Assurances:** Explicit statements about data privacy
- **Easy Opt-Out:** "Not Now" is equally prominent as "Allow"
- **No Dark Patterns:** User choice is respected without manipulation
- **Settings Access:** Provides path to enable later without nagging

**Recommendation:** Ensure privacy policy link is accessible from the dialog for users who want more details before deciding.
