# EventLocationFields Widget

## Overview
`EventLocationFields` is a StatelessWidget that provides a labeled location input section for events, wrapping the CountryTimezoneSelector with a header and coordinating three separate callbacks. It includes an extension with utility methods for validation, emptiness checking, and summary generation. The widget serves as a high-level abstraction for event location management with proper callback decomposition.

## File Location
`lib/widgets/event_location_fields.dart`

## Dependencies
```dart
import 'package:flutter/widgets.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../services/country_service.dart';
import 'country_timezone_selector.dart';
```

**Key Dependencies:**
- `country_timezone_selector.dart`: Main UI component for country/city/timezone selection
- `country_service.dart`: `CountryService.getCountryByCode()` for country lookup
- `app_constants.dart`: Font sizes and padding constants
- `l10n_helpers.dart`: Localization for labels

## Class Declaration

```dart
class EventLocationFields extends StatelessWidget {
  final String? city;
  final String? countryCode;
  final String? timezone;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onTimezoneChanged;
  final bool enabled;
  final bool isRequired;

  const EventLocationFields({
    super.key,
    this.city,
    this.countryCode,
    this.timezone,
    required this.onCityChanged,
    required this.onCountryChanged,
    required this.onTimezoneChanged,
    this.enabled = true,
    this.isRequired = false
  });
}
```

**Widget Type:** StatelessWidget

**Rationale for Stateless:**
- Pure presentational component
- No internal state management
- Delegates all state to parent via callbacks
- Wraps CountryTimezoneSelector which manages its own state

### Properties Analysis

**city** (`String?`):
- **Type:** Nullable String
- **Purpose:** Initial/current city name
- **Passed To:** CountryTimezoneSelector as initialCity
- **Usage:** Display saved city in UI
- **Validation:** Not required for validation (country is primary)

**countryCode** (`String?`):
- **Type:** Nullable String (ISO country code, e.g., "US", "ES")
- **Purpose:** Initial/current country code
- **Conversion:** Converted to Country object via CountryService
- **Validation:** Required if isRequired is true
- **Usage:** Primary location identifier

**timezone** (`String?`):
- **Type:** Nullable IANA timezone string (e.g., "America/New_York")
- **Purpose:** Initial/current timezone
- **Passed To:** CountryTimezoneSelector as initialTimezone
- **Usage:** Event scheduling context

**onCityChanged** (`ValueChanged<String?>`):
- **Type:** Required callback `void Function(String?)`
- **Purpose:** Called when city selection changes
- **Parameter:** New city name or null
- **Pattern:** Decomposed callback (city only)
- **Called:** Only when city is not null in CountryTimezoneSelector callback

**onCountryChanged** (`ValueChanged<String?>`):
- **Type:** Required callback `void Function(String?)`
- **Purpose:** Called when country selection changes
- **Parameter:** Country code (e.g., "US")
- **Pattern:** Decomposed callback (country only)
- **Called:** Always when CountryTimezoneSelector callback fires

**onTimezoneChanged** (`ValueChanged<String?>`):
- **Type:** Required callback `void Function(String?)`
- **Purpose:** Called when timezone selection changes
- **Parameter:** IANA timezone string
- **Pattern:** Decomposed callback (timezone only)
- **Called:** Always when CountryTimezoneSelector callback fires

**enabled** (`bool`):
- **Type:** Boolean flag
- **Default:** `true`
- **Purpose:** Controls whether selector is interactive
- **Current Limitation:** Not currently passed to CountryTimezoneSelector
- **Intended Usage:** Disable during save operations or permission restrictions

**isRequired** (`bool`):
- **Type:** Boolean flag
- **Default:** `false`
- **Purpose:** Determines if location is mandatory
- **Usage:** Used in extension's `validate()` method
- **Validation:** If true, countryCode must be non-null and non-empty

## Build Method

```dart
@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.eventLocation,
        style: TextStyle(
          fontSize: AppConstants.bodyFontSize,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none
        ),
      ),

      const SizedBox(height: AppConstants.smallPadding),

      CountryTimezoneSelector(
        initialCountry: countryCode != null
          ? CountryService.getCountryByCode(countryCode!)
          : null,
        initialTimezone: timezone,
        initialCity: city,
        onChanged: (country, timezone, city) {
          onCountryChanged(country.code);
          onTimezoneChanged(timezone);
          if (city != null) onCityChanged(city);
        },
      ),
    ],
  );
}
```

### Detailed Analysis

**Lines 21-23: Column Container**
```dart
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
```
- **Layout:** Vertical stacking
- **Alignment:** Left-aligned (start)
- **Purpose:** Header above selector

**Lines 24-27: Header Text**
```dart
Text(
  context.l10n.eventLocation,
  style: TextStyle(
    fontSize: AppConstants.bodyFontSize,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.none
  ),
),
```

**Content:** Localized "Event Location" label

**Style Properties:**
- **fontSize:** `AppConstants.bodyFontSize` (typically 16px)
- **fontWeight:** `FontWeight.bold` for section header emphasis
- **decoration:** `TextDecoration.none` (no underline)

**Pattern:** Section header style used throughout app

**Line 29: Spacing**
```dart
const SizedBox(height: AppConstants.smallPadding),
```
- **Height:** `AppConstants.smallPadding` (typically 8-12px)
- **Purpose:** Visual separation between header and selector
- **Const:** Compile-time optimization

**Lines 31-40: CountryTimezoneSelector**
```dart
CountryTimezoneSelector(
  initialCountry: countryCode != null
    ? CountryService.getCountryByCode(countryCode!)
    : null,
  initialTimezone: timezone,
  initialCity: city,
  onChanged: (country, timezone, city) {
    onCountryChanged(country.code);
    onTimezoneChanged(timezone);
    if (city != null) onCityChanged(city);
  },
),
```

### Initial Country Conversion (Lines 32-34)

```dart
initialCountry: countryCode != null
  ? CountryService.getCountryByCode(countryCode!)
  : null,
```

**Logic:**
1. Check if countryCode exists
2. If yes: lookup Country object via CountryService
3. If no: pass null (no initial selection)

**CountryService.getCountryByCode:**
- Takes ISO country code ("US", "ES", etc.)
- Returns Country object with name, flag, timezones, etc.
- **Pattern:** Separation of storage (codes) and display (objects)

**Example:**
- Input: "US"
- Output: `Country(code: "US", name: "United States", flag: "🇺🇸", primaryTimezone: "America/New_York", ...)`

### Initial Values (Lines 34-35)

```dart
initialTimezone: timezone,
initialCity: city,
```
- Direct pass-through of string values
- No conversion needed

### Callback Decomposition (Lines 35-39)

```dart
onChanged: (country, timezone, city) {
  onCountryChanged(country.code);
  onTimezoneChanged(timezone);
  if (city != null) onCityChanged(city);
},
```

**Purpose:** Transforms single unified callback into three separate callbacks

**CountryTimezoneSelector Callback:**
- **Signature:** `Function(Country country, String timezone, String? city)`
- **Returns:** All three values together

**Decomposition Logic:**

**Line 36:** `onCountryChanged(country.code);`
- Extracts country code from Country object
- Passes to parent's onCountryChanged
- **Always called** when CountryTimezoneSelector fires

**Line 37:** `onTimezoneChanged(timezone);`
- Direct pass-through of timezone string
- **Always called** when CountryTimezoneSelector fires

**Lines 38:** `if (city != null) onCityChanged(city);`
- **Conditional:** Only calls if city is not null
- **Rationale:** City is optional in CountryTimezoneSelector
- User may select country without selecting city
- **Pattern:** Prevents unnecessary null updates

**Design Benefits:**
1. Parent doesn't need to handle Country objects (just codes)
2. Parent receives granular updates (can handle each field separately)
3. Parent doesn't receive null city updates unnecessarily

## Extension Methods

```dart
extension EventLocationFieldsExtension on EventLocationFields {
  bool validate() {
    if (!isRequired) return true;

    return countryCode != null && countryCode!.isNotEmpty;
  }

  bool get isEmpty {
    return (city == null || city!.isEmpty) &&
           (countryCode == null || countryCode!.isEmpty) &&
           (timezone == null || timezone!.isEmpty);
  }

  bool get isNotEmpty => !isEmpty;

  String getLocationSummary(BuildContext context) {
    final parts = <String>[];

    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }

    if (countryCode != null && countryCode!.isNotEmpty) {
      parts.add(countryCode!);
    }

    if (parts.isEmpty) {
      return context.l10n.noLocationSet;
    }

    return parts.join(', ');
  }
}
```

**Extension Purpose:** Adds utility methods to EventLocationFields instances

**Pattern:** Extension methods for validation and display logic

### Validate Method

```dart
bool validate() {
  if (!isRequired) return true;

  return countryCode != null && countryCode!.isNotEmpty;
}
```

**Purpose:** Validates location data based on isRequired flag

**Logic:**
1. **Line 48:** If not required → always valid (return true)
2. **Line 50:** If required → check countryCode exists and non-empty

**Validation Criteria:**
- **City:** NOT validated (optional)
- **Country:** Required if isRequired is true
- **Timezone:** NOT validated (auto-set with country)

**Return Type:** Boolean
- `true`: Valid (either not required, or has country code)
- `false`: Invalid (required but missing country)

**Usage Example:**
```dart
final locationFields = EventLocationFields(...);
if (!locationFields.validate()) {
  showError("Country is required");
}
```

### isEmpty Getter

```dart
bool get isEmpty {
  return (city == null || city!.isEmpty) &&
         (countryCode == null || countryCode!.isEmpty) &&
         (timezone == null || timezone!.isEmpty);
}
```

**Purpose:** Checks if all location fields are empty

**Logic:** Returns true if ALL three fields are null or empty

**Conditions (all must be true):**
1. City is null OR empty string
2. CountryCode is null OR empty string
3. Timezone is null OR empty string

**Pattern:** Logical AND - all must be empty for result to be true

**Examples:**
- `city: null, countryCode: null, timezone: null` → `true`
- `city: "", countryCode: "", timezone: ""` → `true`
- `city: "Paris", countryCode: null, timezone: null` → `false`
- `city: null, countryCode: "FR", timezone: null` → `false`

**Usage Example:**
```dart
if (locationFields.isEmpty) {
  hideLocationSection();
}
```

### isNotEmpty Getter

```dart
bool get isNotEmpty => !isEmpty;
```

**Purpose:** Inverse of isEmpty

**Logic:** Returns true if ANY field has a value

**Convenience Method:** Simpler to read than `!locationFields.isEmpty`

**Usage Example:**
```dart
if (locationFields.isNotEmpty) {
  showLocationSection();
}
```

### getLocationSummary Method

```dart
String getLocationSummary(BuildContext context) {
  final parts = <String>[];

  if (city != null && city!.isNotEmpty) {
    parts.add(city!);
  }

  if (countryCode != null && countryCode!.isNotEmpty) {
    parts.add(countryCode!);
  }

  if (parts.isEmpty) {
    return context.l10n.noLocationSet;
  }

  return parts.join(', ');
}
```

**Purpose:** Generates human-readable location summary string

**Algorithm:**
1. Create empty parts list
2. Add city if not null/empty
3. Add countryCode if not null/empty
4. If no parts: return localized "No location set"
5. Otherwise: join parts with ", "

**Examples:**
- City: "Paris", Country: "FR" → "Paris, FR"
- City: null, Country: "FR" → "FR"
- City: "Paris", Country: null → "Paris"
- City: null, Country: null → "No location set"

**Note on Timezone:**
- Timezone is NOT included in summary
- **Rationale:** Timezone is technical detail, not user-facing location info
- Country code provides sufficient context

**Usage Example:**
```dart
final summary = locationFields.getLocationSummary(context);
Text("Location: $summary"); // "Location: Paris, FR"
```

## Technical Characteristics

### Callback Pattern
- **Single Source:** CountryTimezoneSelector provides unified callback
- **Decomposition:** Widget splits into three separate callbacks
- **Granularity:** Parent can handle each field independently
- **Type Conversion:** Country object → country code string

### Validation Strategy
- **Required Field:** Only country code validated when isRequired
- **Optional Fields:** City and timezone not validated
- **Default:** Not required (isRequired = false)
- **Pattern:** Simple boolean validation, no error messages

### Display Logic
- **Summary Generation:** Joins non-empty fields with comma
- **Fallback:** Localized "No location set" message
- **Timezone Exclusion:** Not shown in user-facing summary
- **Extension Pattern:** Display logic separate from widget

### State Management
- **Stateless Widget:** No internal state
- **External State:** All values from parent props
- **Callback Pattern:** Updates flow back to parent
- **Immutable:** Each change creates new prop values

## Usage Examples

### Basic Usage
```dart
EventLocationFields(
  city: event.city,
  countryCode: event.countryCode,
  timezone: event.timezone,
  onCityChanged: (city) {
    setState(() => event = event.copyWith(city: city));
  },
  onCountryChanged: (code) {
    setState(() => event = event.copyWith(countryCode: code));
  },
  onTimezoneChanged: (tz) {
    setState(() => event = event.copyWith(timezone: tz));
  },
)
```

### With Validation
```dart
final locationFields = EventLocationFields(
  city: formData.city,
  countryCode: formData.countryCode,
  timezone: formData.timezone,
  onCityChanged: (city) => _updateField('city', city),
  onCountryChanged: (code) => _updateField('countryCode', code),
  onTimezoneChanged: (tz) => _updateField('timezone', tz),
  isRequired: true,
);

// Validate before submit
if (!locationFields.validate()) {
  showError("Country is required");
  return;
}
```

### With Summary Display
```dart
EventLocationFields locationFields = EventLocationFields(
  city: event.city,
  countryCode: event.countryCode,
  timezone: event.timezone,
  onCityChanged: _handleCityChange,
  onCountryChanged: _handleCountryChange,
  onTimezoneChanged: _handleTimezoneChange,
);

// Display summary elsewhere
Text(locationFields.getLocationSummary(context));
// Shows: "Paris, FR" or "No location set"
```

### Disabled State
```dart
EventLocationFields(
  city: event.city,
  countryCode: event.countryCode,
  timezone: event.timezone,
  onCityChanged: (_) {}, // No-op during save
  onCountryChanged: (_) {},
  onTimezoneChanged: (_) {},
  enabled: false, // Intent: disable UI
)
```

**Note:** enabled prop currently not passed to CountryTimezoneSelector - implementation gap

### Check if Empty
```dart
if (locationFields.isEmpty) {
  // No location data provided
  hideLocationBadge();
} else {
  // Has some location data
  showLocationBadge(locationFields.getLocationSummary(context));
}
```

## Testing Recommendations

### Unit Tests

**1. Validation Logic:**
```dart
test('validate should return true when not required', () {
  final fields = EventLocationFields(
    isRequired: false,
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.validate(), true);
});

test('validate should return false when required and no country', () {
  final fields = EventLocationFields(
    isRequired: true,
    countryCode: null,
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.validate(), false);
});

test('validate should return true when required and has country', () {
  final fields = EventLocationFields(
    isRequired: true,
    countryCode: 'US',
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.validate(), true);
});
```

**2. isEmpty/isNotEmpty:**
```dart
test('isEmpty should return true when all fields null', () {
  final fields = EventLocationFields(
    city: null,
    countryCode: null,
    timezone: null,
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.isEmpty, true);
  expect(fields.isNotEmpty, false);
});

test('isEmpty should return false when any field has value', () {
  final fields = EventLocationFields(
    city: 'Paris',
    countryCode: null,
    timezone: null,
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.isEmpty, false);
  expect(fields.isNotEmpty, true);
});
```

**3. Location Summary:**
```dart
test('getLocationSummary should return joined city and country', () {
  final fields = EventLocationFields(
    city: 'Paris',
    countryCode: 'FR',
    timezone: 'Europe/Paris',
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.getLocationSummary(context), 'Paris, FR');
});

test('getLocationSummary should return country only when no city', () {
  final fields = EventLocationFields(
    city: null,
    countryCode: 'FR',
    timezone: 'Europe/Paris',
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.getLocationSummary(context), 'FR');
});

test('getLocationSummary should return no location message when empty', () {
  final fields = EventLocationFields(
    city: null,
    countryCode: null,
    timezone: null,
    onCityChanged: (_) {},
    onCountryChanged: (_) {},
    onTimezoneChanged: (_) {},
  );

  expect(fields.getLocationSummary(context), context.l10n.noLocationSet);
});
```

### Widget Tests

**1. Rendering:**
```dart
testWidgets('should render header and selector', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EventLocationFields(
          onCityChanged: (_) {},
          onCountryChanged: (_) {},
          onTimezoneChanged: (_) {},
        ),
      ),
    ),
  );

  expect(find.text(context.l10n.eventLocation), findsOneWidget);
  expect(find.byType(CountryTimezoneSelector), findsOneWidget);
});
```

**2. Initial Values:**
```dart
testWidgets('should pass initial values to selector', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EventLocationFields(
          city: 'Paris',
          countryCode: 'FR',
          timezone: 'Europe/Paris',
          onCityChanged: (_) {},
          onCountryChanged: (_) {},
          onTimezoneChanged: (_) {},
        ),
      ),
    ),
  );

  final selector = tester.widget<CountryTimezoneSelector>(
    find.byType(CountryTimezoneSelector)
  );

  expect(selector.initialCity, 'Paris');
  expect(selector.initialTimezone, 'Europe/Paris');
});
```

**3. Callback Decomposition:**
```dart
testWidgets('should call separate callbacks on change', (tester) async {
  String? receivedCity;
  String? receivedCountry;
  String? receivedTimezone;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EventLocationFields(
          onCityChanged: (city) { receivedCity = city; },
          onCountryChanged: (code) { receivedCountry = code; },
          onTimezoneChanged: (tz) { receivedTimezone = tz; },
        ),
      ),
    ),
  );

  // Simulate selector callback
  final selector = tester.widget<CountryTimezoneSelector>(
    find.byType(CountryTimezoneSelector)
  );

  final country = Country(code: 'FR', name: 'France');
  selector.onChanged(country, 'Europe/Paris', 'Paris');

  expect(receivedCountry, 'FR');
  expect(receivedTimezone, 'Europe/Paris');
  expect(receivedCity, 'Paris');
});
```

## Comparison with Similar Widgets

### vs. Direct CountryTimezoneSelector Usage
**EventLocationFields Advantages:**
- Labeled section header
- Callback decomposition (simpler parent)
- Validation methods built-in
- Summary generation utility

**Direct Usage:**
- More flexible (no enforced header)
- Single callback (simpler if parent works with Country objects)
- Less abstraction layers

### vs. Individual Form Fields
**EventLocationFields:**
- Integrated country/city/timezone selection
- Automatic timezone updates
- Progressive disclosure (city, timezone conditionals)

**Individual Fields:**
- Independent selection
- More customizable layout
- Manual coordination needed

## Possible Improvements

### 1. Pass enabled Prop to Selector
```dart
CountryTimezoneSelector(
  // ...existing props...
  enabled: enabled, // Currently not passed
)
```

### 2. Error State Display
```dart
final String? errorMessage;

// In build:
if (errorMessage != null)
  Text(
    errorMessage,
    style: TextStyle(color: Colors.red, fontSize: 12),
  )
```

### 3. Required Field Indicator
```dart
Text(
  "${context.l10n.eventLocation}${isRequired ? ' *' : ''}",
  style: TextStyle(
    fontSize: AppConstants.bodyFontSize,
    fontWeight: FontWeight.bold,
  ),
),
```

### 4. Custom Label
```dart
final String? customLabel;

// In build:
Text(
  customLabel ?? context.l10n.eventLocation,
  // ...
),
```

### 5. Validation Error Messages
```dart
String? getValidationError(BuildContext context) {
  if (isRequired && (countryCode == null || countryCode!.isEmpty)) {
    return context.l10n.countryRequired;
  }
  return null;
}
```

### 6. City Validation
```dart
final bool isCityRequired;

bool validate() {
  if (!isRequired) return true;

  final hasCountry = countryCode != null && countryCode!.isNotEmpty;
  if (!hasCountry) return false;

  if (isCityRequired) {
    return city != null && city!.isNotEmpty;
  }

  return true;
}
```

### 7. Timezone in Summary
```dart
String getLocationSummary(BuildContext context, {bool includeTimezone = false}) {
  final parts = <String>[];

  if (city != null && city!.isNotEmpty) parts.add(city!);
  if (countryCode != null && countryCode!.isNotEmpty) parts.add(countryCode!);
  if (includeTimezone && timezone != null) parts.add(timezone!);

  return parts.isEmpty ? context.l10n.noLocationSet : parts.join(', ');
}
```

### 8. Country Name in Summary
```dart
String getLocationSummary(BuildContext context) {
  final parts = <String>[];

  if (city != null && city!.isNotEmpty) {
    parts.add(city!);
  }

  if (countryCode != null && countryCode!.isNotEmpty) {
    final country = CountryService.getCountryByCode(countryCode!);
    parts.add(country.name); // "France" instead of "FR"
  }

  return parts.isEmpty ? context.l10n.noLocationSet : parts.join(', ');
}
```

### 9. Analytics Integration
```dart
onChanged: (country, timezone, city) {
  analytics.logEvent('location_changed', {
    'country': country.code,
    'has_city': city != null,
  });

  onCountryChanged(country.code);
  onTimezoneChanged(timezone);
  if (city != null) onCityChanged(city);
}
```

### 10. Geolocation Auto-Fill
```dart
Future<void> autoFillLocation() async {
  final position = await Geolocator.getCurrentPosition();
  final country = await CountryService.getCountryFromCoordinates(
    position.latitude,
    position.longitude,
  );
  onCountryChanged(country.code);
}
```

## Real-World Usage Context

This widget is typically used in:

1. **Event Creation Forms:** Setting event location
2. **Event Editing:** Modifying location details
3. **Profile Settings:** User home location
4. **Business Listings:** Business address input
5. **Meeting Scheduling:** Location coordination

The widget is particularly useful in event management apps where location and timezone are critical for scheduling across different regions.

## Performance Considerations

- **Stateless Design:** No internal state overhead
- **CountryService Lookup:** Synchronous, in-memory lookup (fast)
- **Extension Methods:** No performance impact (compile-time)
- **Callback Decomposition:** Minimal overhead (simple function calls)

**Recommendation:** Suitable for any form context. The CountryTimezoneSelector it wraps handles the heavy lifting.

## Security Considerations

- **Input Validation:** Basic validation via extension method
- **Country Code:** Should validate against known codes before database storage
- **Timezone:** Should validate against IANA timezone database
- **User Input:** City is free text, consider sanitization

**Recommendation:** Add server-side validation for all location fields before persisting to database.
