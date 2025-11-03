# CountryTimezoneSelector Widget

## Overview
`CountryTimezoneSelector` is a StatefulWidget that provides a comprehensive interface for selecting country, city, and timezone combinations. It manages three interconnected selections with progressive disclosure: country selection triggers timezone defaults, city selection updates timezone automatically, and multi-timezone countries reveal a timezone picker. The widget coordinates multiple modal pickers (CountryPicker, CitySearchPicker, timezone action sheet) with platform-adaptive UI and proper state synchronization.

## File Location
`lib/widgets/country_timezone_selector.dart`

## Dependencies
```dart
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:flutter/cupertino.dart';
import '../models/country.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import '../models/city.dart';
import '../services/country_service.dart';
import '../services/timezone_service.dart';
import 'package:eventypop/widgets/pickers/country_picker.dart';
import 'package:eventypop/widgets/pickers/city_search_picker.dart';
```

**Key Dependencies:**
- `country.dart`: Country model with name, code, flag, primaryTimezone, and timezones list
- `city.dart`: City model with name, countryCode, and timezone properties
- `country_service.dart`: `CountryService.getCountryByCode()` for country lookup
- `timezone_service.dart`: `TimezoneService.getCurrentOffset()` for offset calculation
- `country_picker.dart`: Modal for country selection with search
- `city_search_picker.dart`: Modal for city search and selection
- `dialog_helpers.dart`: `showPlatformActionSheet` for timezone selection
- `platform_navigation.dart`: `presentModal` for showing pickers
- `platform_detection.dart`: iOS/Android detection for UI adaptation

## Class Declaration

```dart
class CountryTimezoneSelector extends StatefulWidget {
  final Country? initialCountry;
  final String? initialTimezone;
  final String? initialCity;
  final Function(Country country, String timezone, String? city) onChanged;
  final bool showOffset;
  final String? label;

  const CountryTimezoneSelector({
    super.key,
    this.initialCountry,
    this.initialTimezone,
    this.initialCity,
    required this.onChanged,
    this.showOffset = true,
    this.label
  });
}
```

**Widget Type:** StatefulWidget

**Rationale for Stateful:**
- **Selection State:** Manages _selectedCountry, _selectedTimezone, _selectedCity
- **Controller Management:** TextEditingController for search functionality
- **Lifecycle Coordination:** didUpdateWidget for external prop changes
- **Complex Interactions:** Multiple interdependent selections with cascade updates

### Properties Analysis

**initialCountry** (`Country?`):
- **Type:** Nullable Country model
- **Purpose:** Pre-selects country when widget is created
- **Usage:** Event editing, user profile defaults, geolocation-based defaults
- **Default:** null (no country selected)

**initialTimezone** (`String?`):
- **Type:** Nullable IANA timezone string (e.g., "America/New_York")
- **Purpose:** Pre-selects specific timezone
- **Fallback Logic:** If null, uses initialCountry.primaryTimezone
- **Usage:** Editing existing events/profiles with saved timezone

**initialCity** (`String?`):
- **Type:** Nullable city name string
- **Purpose:** Pre-fills city field
- **Display Only:** Shows city but doesn't determine timezone selection
- **Usage:** Display saved city preference

**onChanged** (`Function(Country, String, String?)`):
- **Type:** Required callback function
- **Parameters:**
  - `country`: Selected Country object
  - `timezone`: Selected IANA timezone string
  - `city`: Optional city name (nullable)
- **Purpose:** Notifies parent of selection changes
- **Called When:**
  - Country selected (with primaryTimezone, null city)
  - Timezone changed
  - City selected (with city's timezone and name)
- **Pattern:** Immediate callback on each selection

**showOffset** (`bool`):
- **Type:** Boolean flag
- **Default:** `true`
- **Purpose:** Controls display of UTC offset (e.g., "UTC+2")
- **UI Impact:** Shows/hides offset in country subtitle
- **Usage:** Hide offset for simpler UI in space-constrained contexts

**label** (`String?`):
- **Type:** Nullable string
- **Purpose:** Optional header label above selector
- **Display:** Bold text above first tile
- **Usage:** Form field labels like "Event Timezone" or "Your Location"

## State Class

```dart
class _CountryTimezoneSelectorState extends State<CountryTimezoneSelector> {
  Country? _selectedCountry;
  String? _selectedTimezone;
  String? _selectedCity;
  final TextEditingController _searchController = TextEditingController();
```

### State Variables Analysis

**_selectedCountry** (`Country?`):
- **Type:** Nullable Country model
- **Purpose:** Currently selected country
- **Initialization:** From widget.initialCountry in initState
- **Updates:**
  - User selects from country picker
  - City selection from different country
  - External prop changes in didUpdateWidget
- **Triggers:** Timezone default, conditional UI rendering

**_selectedTimezone** (`String?`):
- **Type:** Nullable IANA timezone string
- **Purpose:** Currently selected timezone
- **Initialization:** widget.initialTimezone ?? widget.initialCountry?.primaryTimezone
- **Updates:**
  - Country selection (resets to country's primaryTimezone)
  - User selects specific timezone
  - City selection (updates to city's timezone)
- **Display:** Shown in timezone picker tile subtitle

**_selectedCity** (`String?`):
- **Type:** Nullable string
- **Purpose:** Currently selected city name
- **Initialization:** From widget.initialCity
- **Updates:**
  - Country selection (resets to null)
  - User selects from city picker
- **Display:** Shows in city tile subtitle, gray if not selected

**_searchController** (`TextEditingController`):
- **Type:** TextEditingController
- **Purpose:** Manages search input in country picker
- **Lifecycle:** Created in declaration, disposed in dispose()
- **Cleared:** Before showing country picker (ensures clean state)
- **Passed To:** CountryPickerModal for search functionality

## Lifecycle Methods

### initState

```dart
@override
void initState() {
  super.initState();
  _selectedCountry = widget.initialCountry;
  _selectedTimezone = widget.initialTimezone ?? widget.initialCountry?.primaryTimezone;
  _selectedCity = widget.initialCity;
}
```

**Line 38:** Initialize country from prop

**Line 39:** Timezone initialization with fallback
```dart
_selectedTimezone = widget.initialTimezone ?? widget.initialCountry?.primaryTimezone;
```
- **Primary:** Use explicit initialTimezone if provided
- **Fallback:** Use country's primaryTimezone
- **Null Case:** Both can be null (no selection)
- **Pattern:** Sensible default with explicit override

**Line 40:** Initialize city from prop

### didUpdateWidget

```dart
@override
void didUpdateWidget(CountryTimezoneSelector oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (widget.initialCountry != oldWidget.initialCountry ||
      widget.initialTimezone != oldWidget.initialTimezone ||
      widget.initialCity != oldWidget.initialCity) {
    setState(() {
      _selectedCountry = widget.initialCountry;
      _selectedTimezone = widget.initialTimezone ?? widget.initialCountry?.primaryTimezone;
      _selectedCity = widget.initialCity;
    });
  }
}
```

**Purpose:** Synchronizes internal state with external prop changes

**Change Detection (Lines 47):**
- Checks all three initial values for changes
- Logical OR: updates if any value changed
- **Use Case:** Parent updates selection (e.g., geolocation detected new country)

**State Update (Lines 48-52):**
- **setState Wrapper:** Triggers rebuild
- **Same Logic as initState:** Maintains consistent initialization
- **Complete Reset:** All three values updated together
- **Pattern:** Controlled component can be updated externally

**No Callback:** Doesn't call onChanged (parent initiated the change)

### dispose

```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

**Line 58:** Dispose TextEditingController
- **Critical:** Prevents memory leaks
- **Pattern:** Always dispose controllers

## Selection Methods

### Select Country

```dart
void _selectCountry(Country country) {
  setState(() {
    _selectedCountry = country;
    _selectedTimezone = country.primaryTimezone;
    _selectedCity = null;
  });
  widget.onChanged(country, country.primaryTimezone, null);
}
```

**Purpose:** Handles country selection from picker

**State Updates (Lines 63-67):**
1. **Set country:** Direct assignment
2. **Reset timezone:** Use country's primaryTimezone (sensible default)
3. **Clear city:** Reset to null (city from previous country is invalid)

**Rationale for Resets:**
- **Timezone:** Each country has a default timezone, use it
- **City:** City belongs to specific country, clear when country changes
- **Pattern:** Cascade reset for dependent selections

**Callback (Line 68):**
```dart
widget.onChanged(country, country.primaryTimezone, null);
```
- Notifies parent immediately
- Provides country, its default timezone, and null city
- Parent can update UI or save state

### Select Timezone

```dart
void _selectTimezone(String timezone) {
  if (_selectedCountry != null) {
    setState(() {
      _selectedTimezone = timezone;
    });
    widget.onChanged(_selectedCountry!, timezone, _selectedCity);
  }
}
```

**Purpose:** Handles timezone selection from action sheet

**Guard (Line 72):**
```dart
if (_selectedCountry != null)
```
- Prevents timezone selection without country context
- **Defensive:** Shouldn't happen (timezone picker only shows when country selected)
- **Safety:** Prevents invalid state

**State Update (Lines 73-75):**
- Only updates timezone
- Country and city remain unchanged
- **Rationale:** User is refining timezone, not changing location

**Callback (Line 76):**
```dart
widget.onChanged(_selectedCountry!, timezone, _selectedCity);
```
- Force unwrap country (safe due to guard)
- Maintains current city (if any)
- **Use Case:** User in multi-timezone country picks specific zone

### Select City with Timezone

```dart
void _selectCityWithTimezone(City city) {
  Country? country = _selectedCountry;

  if (city.countryCode != _selectedCountry?.code) {
    country = CountryService.getCountryByCode(city.countryCode);
  }

  setState(() {
    _selectedCountry = country;
    _selectedCity = city.name;
    _selectedTimezone = city.timezone ?? country?.primaryTimezone ?? context.l10n.utc;
  });

  if (country != null) {
    widget.onChanged(country, _selectedTimezone!, city.name);
  }
}
```

**Purpose:** Handles city selection with automatic country/timezone updates

**Country Resolution (Lines 187-191):**
```dart
Country? country = _selectedCountry;

if (city.countryCode != _selectedCountry?.code) {
  country = CountryService.getCountryByCode(city.countryCode);
}
```
- **Start:** Assume current selected country
- **Check:** If city is from different country
- **Lookup:** Fetch correct country using CountryService
- **Use Case:** User searches cities globally, selects city from different country
- **Pattern:** Automatic country switch based on city selection

**State Updates (Lines 193-197):**
```dart
setState(() {
  _selectedCountry = country;
  _selectedCity = city.name;
  _selectedTimezone = city.timezone ?? country?.primaryTimezone ?? context.l10n.utc;
});
```

**Timezone Fallback Chain:**
1. **Primary:** city.timezone (most specific)
2. **Secondary:** country.primaryTimezone (country default)
3. **Tertiary:** context.l10n.utc (fallback "UTC")
- **Rationale:** Increasingly general fallbacks ensure valid value

**Callback (Lines 199-201):**
```dart
if (country != null) {
  widget.onChanged(country, _selectedTimezone!, city.name);
}
```
- **Guard:** Only callback if country resolved successfully
- **Force Unwrap:** timezone is guaranteed non-null due to fallback chain
- **Complete Data:** Provides country, timezone, and city name

## Country Picker Methods

### Show Country Picker

```dart
Future<void> _showCountryPicker() async {
  _searchController.clear();

  final isIOS = PlatformDetection.isIOS;

  if (isIOS) {
    await _showCupertinoCountryPicker();
  } else {
    await _showMaterialCountryPicker();
  }
}
```

**Line 81:** Clear search controller
- **Purpose:** Ensures clean state for new search
- **Timing:** Before modal opens
- **User Experience:** Don't show previous search query

**Lines 83-89:** Platform branching
- Detects platform once
- Delegates to platform-specific methods
- Both methods await (block until picker dismissed)

### Show Cupertino Country Picker

```dart
Future<void> _showCupertinoCountryPicker() async {
  await PlatformNavigation.presentModal<void>(
    context,
    CountryPickerModal(
      initialCountry: _selectedCountry,
      showOffset: widget.showOffset,
      searchController: _searchController,
      onSelected: (country) => _selectCountry(country)
    ),
    isScrollControlled: true
  );
}
```

**PlatformNavigation.presentModal:**
- Utility method for showing modals
- Handles platform-specific presentation
- Returns Future that completes when modal dismissed

**CountryPickerModal Parameters:**
- **initialCountry:** Highlight currently selected country
- **showOffset:** Pass through widget prop
- **searchController:** Shared controller for search input
- **onSelected:** Callback with inline _selectCountry call
- **isScrollControlled:** Allows modal to be full-height or expand

**Callback Pattern:**
```dart
onSelected: (country) => _selectCountry(country)
```
- Inline lambda wraps _selectCountry
- Modal calls this when user selects country
- _selectCountry updates state and calls widget.onChanged

### Show Material Country Picker

```dart
Future<void> _showMaterialCountryPicker() async {
  await PlatformNavigation.presentModal<void>(
    context,
    CountryPickerModal(/* same params */),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
  );
}
```

**Difference from Cupertino:**
- **shape Parameter:** Rounded corners at top
- **Android Pattern:** Bottom sheet with rounded top corners
- **Otherwise Identical:** Same CountryPickerModal widget used

## Timezone Picker Methods

### Show Timezone Picker

```dart
Future<void> _showTimezonePicker() async {
  if (_selectedCountry == null || _selectedCountry!.timezones.length <= 1) {
    return;
  }

  final isIOS = PlatformDetection.isIOS;

  if (isIOS) {
    await _showCupertinoTimezonePicker();
  } else {
    await _showMaterialTimezonePicker();
  }
}
```

**Guard (Lines 106-108):**
```dart
if (_selectedCountry == null || _selectedCountry!.timezones.length <= 1) {
  return;
}
```
- **First Check:** No country selected (shouldn't happen, tile is hidden)
- **Second Check:** Country has 0 or 1 timezones (no choice needed)
- **Early Return:** Don't show picker if unnecessary
- **Pattern:** Defensive programming

**Platform Branching:** Same pattern as country picker

### Show Cupertino Timezone Picker

```dart
Future<void> _showCupertinoTimezonePicker() async {
  if (_selectedCountry == null) return;

  final l10n = context.l10n;
  final safeContext = context;

  try {
    final choice = await PlatformDialogHelpers.showPlatformActionSheet<String>(
      safeContext,
      title: l10n.selectTimezoneForCountry(_selectedCountry!.name),
      actions: _selectedCountry!.timezones.map((timezone) {
        final offset = TimezoneService.getCurrentOffset(timezone);
        return PlatformAction(
          text: l10n.timezoneWithOffset(timezone, offset),
          value: timezone
        );
      }).toList(),
      cancelText: l10n.cancel,
    );

    if (choice != null) {
      _selectTimezone(choice);
    }
  } catch (_) {}
}
```

**Guard (Line 120):** Additional null check

**Safe Context (Lines 122-123):**
```dart
final l10n = context.l10n;
final safeContext = context;
```
- Captures context before async gap
- Prevents stale context usage

**Action Sheet (Lines 126-134):**
```dart
final choice = await PlatformDialogHelpers.showPlatformActionSheet<String>(
  safeContext,
  title: l10n.selectTimezoneForCountry(_selectedCountry!.name),
  actions: _selectedCountry!.timezones.map((timezone) {
    final offset = TimezoneService.getCurrentOffset(timezone);
    return PlatformAction(
      text: l10n.timezoneWithOffset(timezone, offset),
      value: timezone
    );
  }).toList(),
  cancelText: l10n.cancel,
);
```

**Title:** "Select timezone for [Country Name]" (localized)

**Actions Mapping:**
- Iterates country's timezones list
- For each timezone:
  1. Calculate current UTC offset
  2. Format with localized template (e.g., "America/New_York (UTC-5)")
  3. Create PlatformAction with display text and timezone value
- **Returns List:** All timezone options

**Result Handling (Lines 136-138):**
```dart
if (choice != null) {
  _selectTimezone(choice);
}
```
- **null:** User cancelled
- **String:** Selected timezone IANA name
- Calls _selectTimezone to update state and notify parent

**Error Handling (Line 139):**
```dart
} catch (_) {}
```
- Silent error handling
- Action sheet errors are rare (typically dismissal)
- No user-facing error needed

### Show Material Timezone Picker

```dart
Future<void> _showMaterialTimezonePicker() async {
  // Identical implementation to Cupertino version
}
```

**Note:** Both methods use same `showPlatformActionSheet`
- PlatformDialogHelpers handles iOS vs Android styling
- Cupertino: UIActionSheet appearance
- Material: Bottom sheet with list items

## City Picker Methods

### Show City Picker

```dart
Future<void> _showCityPicker() async {
  final isIOS = PlatformDetection.isIOS;

  if (isIOS) {
    await _showCupertinoCitySearchPicker();
  } else {
    await _showMaterialCitySearchPicker();
  }
}
```

**Pattern:** Same platform branching as other pickers

### Show Cupertino City Search Picker

```dart
Future<void> _showCupertinoCitySearchPicker() async {
  await PlatformNavigation.presentModal<void>(
    context,
    CitySearchPickerModal(
      initialCountryCode: _selectedCountry?.code,
      onSelected: (city) => _selectCityWithTimezone(city)
    ),
    isScrollControlled: true
  );
}
```

**CitySearchPickerModal Parameters:**
- **initialCountryCode:** Filters/prioritizes cities from selected country
- **onSelected:** Callback with _selectCityWithTimezone
- **No searchController:** City picker manages its own search internally

**Callback:**
```dart
onSelected: (city) => _selectCityWithTimezone(city)
```
- Receives full City object
- _selectCityWithTimezone handles country lookup and timezone extraction

### Show Material City Search Picker

```dart
Future<void> _showMaterialCitySearchPicker() async {
  await PlatformNavigation.presentModal<void>(
    context,
    CitySearchPickerModal(/* same params */),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
  );
}
```

**Difference:** Adds rounded top corners for Android bottom sheet

## Build Method

```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  final isIOS = PlatformDetection.isIOS;
  String offset = '';

  if (_selectedCountry != null && widget.showOffset && _selectedTimezone != null) {
    try {
      offset = TimezoneService.getCurrentOffset(_selectedTimezone!);
    } catch (e) {
      offset = '';
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.label != null) ...[
        Text(
          widget.label!,
          style: AppStyles.bodyText.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppStyles.black87
          ),
        ),
        const SizedBox(height: 8),
      ],

      // Country tile
      // City tile (conditional)
      // Timezone tile (conditional)
    ],
  );
}
```

### Offset Calculation (Lines 208-215)

```dart
String offset = '';
if (_selectedCountry != null && widget.showOffset && _selectedTimezone != null) {
  try {
    offset = TimezoneService.getCurrentOffset(_selectedTimezone!);
  } catch (e) {
    offset = '';
  }
}
```

**Conditions:**
- Country selected
- showOffset flag is true
- Timezone selected

**Try-Catch:**
- `TimezoneService.getCurrentOffset()` may throw
- Fallback to empty string on error
- **Rationale:** Don't crash UI for timezone calculation errors

**Result:** String like "+5:00" or "-8:00"

### Label Section (Lines 220-226)

```dart
if (widget.label != null) ...[
  Text(
    widget.label!,
    style: AppStyles.bodyText.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppStyles.black87
    ),
  ),
  const SizedBox(height: 8),
],
```

**Conditional Rendering:** Only shows if label prop provided

**Style:**
- 16px font size
- Medium weight (w500)
- Near-black color
- 8px spacing below

### Country Tile (Lines 228-249)

```dart
Container(
  decoration: BoxDecoration(
    color: AppStyles.grey50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppStyles.grey200, width: 1),
  ),
  child: isIOS
      ? CupertinoListTile(...)
      : _buildPlatformTile(...),
),
```

**Container Styling:**
- Light gray background (grey50)
- 8px rounded corners
- Light gray border
- **Appearance:** Card-like tile

**Platform Tiles:**

**iOS:** `CupertinoListTile`
```dart
CupertinoListTile(
  leading: _selectedCountry != null
    ? Text(_selectedCountry!.flag, style: AppStyles.headlineSmall.copyWith(fontSize: 24))
    : PlatformWidgets.platformIcon(CupertinoIcons.globe),
  title: Text(_selectedCountry?.name ?? l10n.selectCountryTimezone),
  subtitle: widget.showOffset && _selectedCountry != null
    ? Text(
        l10n.timezoneWithOffset(_selectedCountry!.primaryTimezone, offset),
        style: AppStyles.cardSubtitle.copyWith(color: AppStyles.grey600, fontSize: 14)
      )
    : null,
  trailing: PlatformWidgets.platformIcon(CupertinoIcons.forward),
  onTap: _showCountryPicker,
)
```

**Leading:**
- **If Selected:** Country flag emoji (24px)
- **If Not:** Globe icon
- **Visual:** Immediate recognition of selected country

**Title:**
- **If Selected:** Country name
- **If Not:** "Select Country & Timezone" prompt

**Subtitle:**
- **Conditions:** showOffset is true AND country selected
- **Content:** "America/New_York (UTC-5)" format
- **Color:** Gray (secondary information)
- **If Hidden:** null (no subtitle)

**Trailing:** Forward chevron (indicates tappable/navigable)

**OnTap:** Opens country picker

**Android:** `_buildPlatformTile()` with identical parameters

### City Tile (Lines 251-275)

```dart
if (_selectedCountry != null) ...[
  const SizedBox(height: 12),
  Container(
    decoration: BoxDecoration(...),
    child: isIOS
        ? CupertinoListTile(...)
        : _buildPlatformTile(...),
  ),
],
```

**Conditional:** Only shows when country is selected

**Spacing:** 12px gap from previous tile

**Tile Content:**
```dart
leading: PlatformWidgets.platformIcon(CupertinoIcons.location_solid),
title: Text(l10n.city),
subtitle: Text(
  _selectedCity ?? l10n.select,
  style: AppStyles.cardSubtitle.copyWith(
    color: _selectedCity != null ? AppStyles.grey600 : AppStyles.grey400,
    fontSize: 14
  )
),
trailing: PlatformWidgets.platformIcon(CupertinoIcons.forward),
onTap: _showCityPicker,
```

**Leading:** Location pin icon

**Title:** "City" label

**Subtitle:**
- **If Selected:** City name in gray
- **If Not:** "Select" prompt in lighter gray
- **Color Difference:** Visual feedback for selection state

**Trailing:** Forward chevron

**OnTap:** Opens city search picker

### Timezone Tile (Lines 277-301)

```dart
if (_selectedCountry != null && _selectedCountry!.timezones.length > 1) ...[
  const SizedBox(height: 12),
  Container(
    decoration: BoxDecoration(...),
    child: isIOS
        ? CupertinoListTile(...)
        : _buildPlatformTile(...),
  ),
],
```

**Conditional:**
- Country selected AND
- Country has more than 1 timezone

**Rationale:** Only show timezone picker when there's a choice

**Examples:**
- **USA:** Shows (has multiple timezones)
- **UK:** Doesn't show (single timezone)
- **Russia:** Shows (spans many timezones)

**Tile Content:**
```dart
leading: PlatformWidgets.platformIcon(CupertinoIcons.time),
title: Text(l10n.specificTimezone),
subtitle: Text(
  _selectedTimezone ?? l10n.select,
  style: AppStyles.cardSubtitle.copyWith(color: AppStyles.grey600, fontSize: 14)
),
trailing: PlatformWidgets.platformIcon(CupertinoIcons.forward),
onTap: _showTimezonePicker,
```

**Leading:** Clock icon

**Title:** "Specific Timezone" or similar label

**Subtitle:** Shows selected timezone (e.g., "America/Los_Angeles")

**OnTap:** Opens timezone action sheet

## Build Platform Tile

```dart
Widget _buildPlatformTile({
  Widget? leading,
  required Widget title,
  Widget? subtitle,
  Widget? trailing,
  VoidCallback? onTap
}) {
  return Semantics(
    button: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 36, child: Center(child: leading)),
              const SizedBox(width: 12)
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(style: AppStyles.bodyText, child: title),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(style: AppStyles.cardSubtitle, child: subtitle)
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing
            ],
          ],
        ),
      ),
    ),
  );
}
```

**Purpose:** Custom list tile for Android (mimics CupertinoListTile appearance)

**Semantics Wrapper:**
- `button: true` for accessibility
- Announces element as tappable button to screen readers

**GestureDetector:**
- `onTap` callback
- `HitTestBehavior.opaque` ensures entire area is tappable

**Layout:**
```
Row
├── [Conditional] Leading (36px centered) + 12px gap
├── Expanded Column (title + subtitle)
└── [Conditional] 12px gap + Trailing
```

**Leading Section:**
- Fixed 36px width for alignment
- Centered within width
- 12px gap after

**Title/Subtitle Column:**
- Expands to fill available space
- Left-aligned
- Title uses bodyText style
- Subtitle uses cardSubtitle style
- 4px gap between them

**Trailing Section:**
- Auto-width (based on content)
- 12px gap before

**DefaultTextStyle:**
- Provides default styling to child Text widgets
- Allows title/subtitle to be Text widgets without explicit style
- Can be overridden by Text's own style

## Technical Characteristics

### Selection Flow Architecture
1. **Country Selection:** Resets timezone to primary, clears city
2. **City Selection:** Updates country if different, sets city's timezone
3. **Timezone Selection:** Refines timezone without changing country/city
- **Pattern:** Hierarchical selections with intelligent defaults

### State Synchronization
- **initState:** Initializes from props
- **didUpdateWidget:** Responds to external changes
- **Selection Methods:** Update state and immediately callback parent
- **Pattern:** Controlled component with external state sync

### Platform Adaptation
- **Pickers:** Different modals for iOS/Android with rounded corners on Android
- **Tiles:** CupertinoListTile on iOS, custom _buildPlatformTile on Android
- **Action Sheets:** Platform-styled by PlatformDialogHelpers
- **Pattern:** Complete visual consistency with platform conventions

### Progressive Disclosure
- **Country:** Always visible
- **City:** Only after country selected
- **Timezone:** Only if country has multiple timezones
- **Pattern:** Reveal options based on context

### Error Handling
- **Timezone Service:** Try-catch for offset calculation
- **Action Sheet:** Catch errors silently
- **Country Lookup:** Null-safe with fallback chain
- **Pattern:** Graceful degradation, no crashes

## Usage Examples

### Basic Usage
```dart
CountryTimezoneSelector(
  onChanged: (country, timezone, city) {
    print('Selected: ${country.name}, $timezone, $city');
  },
)
```

### With Initial Values
```dart
CountryTimezoneSelector(
  initialCountry: userProfile.country,
  initialTimezone: userProfile.timezone,
  initialCity: userProfile.city,
  label: "Your Location",
  onChanged: (country, timezone, city) {
    setState(() {
      userProfile = userProfile.copyWith(
        country: country,
        timezone: timezone,
        city: city,
      );
    });
  },
)
```

### Event Creation Form
```dart
CountryTimezoneSelector(
  initialCountry: eventCountry,
  initialTimezone: eventTimezone,
  label: "Event Timezone",
  showOffset: true,
  onChanged: (country, timezone, city) {
    setState(() {
      formData.country = country;
      formData.timezone = timezone;
      formData.city = city;
    });
    _validateForm();
  },
)
```

### Without Offset Display
```dart
CountryTimezoneSelector(
  showOffset: false,
  onChanged: (country, timezone, city) {
    _saveSelection(country, timezone, city);
  },
)
```

## Testing Recommendations

### Unit Tests

**1. Initialization:**
```dart
test('should initialize with provided initial values', () {
  final country = Country(code: 'US', name: 'United States');
  final widget = CountryTimezoneSelector(
    initialCountry: country,
    initialTimezone: 'America/New_York',
    initialCity: 'New York',
    onChanged: (_,__,___) {},
  );

  final state = widget.createState();
  state.initState();

  expect(state._selectedCountry, country);
  expect(state._selectedTimezone, 'America/New_York');
  expect(state._selectedCity, 'New York');
});
```

**2. Timezone Fallback:**
```dart
test('should fallback to country primary timezone when timezone not provided', () {
  final country = Country(
    code: 'GB',
    primaryTimezone: 'Europe/London',
  );

  final state = createTestState(
    initialCountry: country,
    initialTimezone: null,
  );

  expect(state._selectedTimezone, 'Europe/London');
});
```

**3. Country Selection:**
```dart
test('should reset timezone and city when country changes', () {
  final state = createTestState();
  final newCountry = Country(
    code: 'FR',
    primaryTimezone: 'Europe/Paris',
  );

  state._selectCountry(newCountry);

  expect(state._selectedCountry, newCountry);
  expect(state._selectedTimezone, 'Europe/Paris');
  expect(state._selectedCity, null);
});
```

### Widget Tests

**1. Initial Render:**
```dart
testWidgets('should display country tile', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CountryTimezoneSelector(
          onChanged: (_,__,___) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.selectCountryTimezone), findsOneWidget);
  expect(find.byIcon(CupertinoIcons.globe), findsOneWidget);
});
```

**2. Progressive Disclosure:**
```dart
testWidgets('should show city tile only after country selected', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CountryTimezoneSelector(
          onChanged: (_,__,___) {},
        ),
      ),
    ),
  );

  // Initially no city tile
  expect(find.text(context.l10n.city), findsNothing);

  // Select country
  final state = tester.state<_CountryTimezoneSelectorState>(
    find.byType(CountryTimezoneSelector)
  );
  state._selectCountry(Country(code: 'US', name: 'United States'));
  await tester.pump();

  // City tile appears
  expect(find.text(context.l10n.city), findsOneWidget);
});
```

**3. Multi-Timezone Display:**
```dart
testWidgets('should show timezone tile for countries with multiple timezones', (tester) async {
  final usa = Country(
    code: 'US',
    name: 'United States',
    timezones: ['America/New_York', 'America/Chicago', 'America/Los_Angeles'],
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CountryTimezoneSelector(
          initialCountry: usa,
          onChanged: (_,__,___) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.specificTimezone), findsOneWidget);
});

testWidgets('should hide timezone tile for single-timezone countries', (tester) async {
  final uk = Country(
    code: 'GB',
    name: 'United Kingdom',
    timezones: ['Europe/London'],
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CountryTimezoneSelector(
          initialCountry: uk,
          onChanged: (_,__,___) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.specificTimezone), findsNothing);
});
```

## Comparison with Similar Widgets

### vs. TimezoneHorizontalSelector
**CountryTimezoneSelector:**
- Full country + city + timezone selection
- Modal pickers for each
- Progressive disclosure
- Comprehensive for forms

**TimezoneHorizontalSelector:**
- Horizontal scrolling selector
- Country/timezone only
- Inline selection
- Compact for space-constrained UI

### vs. Separate Dropdowns
**CountryTimezoneSelector Advantages:**
- Integrated city search
- Automatic timezone detection from city
- Country-based timezone filtering
- Consistent mobile UX

**Separate Dropdowns:**
- Independent selection
- Simpler state management
- More flexible layouts

## Possible Improvements

### 1. Geolocation Auto-Detection
```dart
Future<void> _detectLocation() async {
  final position = await Geolocator.getCurrentPosition();
  final country = await CountryService.getCountryFromCoordinates(
    position.latitude,
    position.longitude,
  );
  _selectCountry(country);
}
```

### 2. Recent Selections
```dart
final recentCountries = await StorageService.getRecentCountries();
// Show at top of country picker
```

### 3. Flag Loading State
```dart
if (_isLoadingCountry)
  CircularProgressIndicator(strokeWidth: 2)
else
  Text(_selectedCountry!.flag)
```

### 4. Validation Errors
```dart
final String? errorText;

if (errorText != null)
  Text(errorText, style: TextStyle(color: Colors.red))
```

### 5. Required Field Indicator
```dart
if (widget.required)
  Text("*", style: TextStyle(color: Colors.red))
```

### 6. Clear Selection Button
```dart
if (_selectedCountry != null)
  IconButton(
    icon: Icon(CupertinoIcons.clear),
    onPressed: _clearSelection,
  )
```

### 7. Favorites/Bookmarks
```dart
IconButton(
  icon: Icon(_isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star),
  onPressed: _toggleFavorite,
)
```

### 8. Timezone Abbreviation
```dart
subtitle: Text("${_selectedTimezone} (${_getTimezoneAbbreviation()})")
// Example: "America/New_York (EST)"
```

## Real-World Usage Context

This widget is typically used in:

1. **User Profile Setup:** Setting home timezone and location
2. **Event Creation:** Specifying event timezone
3. **Meeting Scheduler:** Selecting participant timezones
4. **International Forms:** Collecting location data
5. **Travel Apps:** Selecting destinations

The progressive disclosure pattern ensures users only see relevant options based on their selections, reducing cognitive load.

## Performance Considerations

- **TextEditingController:** Single controller reused, properly disposed
- **Conditional Rendering:** Tiles only rendered when needed
- **Platform Detection:** Cached in build method
- **Offset Calculation:** Try-catch prevents UI freezing
- **Modal Pickers:** Lazy-loaded on demand

**Recommendation:** Suitable for forms and profile screens. Consider caching country list if shown frequently.
