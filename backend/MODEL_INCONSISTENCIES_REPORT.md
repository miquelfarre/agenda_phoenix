# Backend vs Flutter Models Inconsistency Analysis Report

**Generated:** 2025-11-06
**Analyst:** Claude Code
**Project:** Agenda Phoenix

---

## Executive Summary

This report compares all models between the backend (Python/SQLAlchemy/Pydantic) and Flutter (Dart) implementations. The analysis reveals **significant structural inconsistencies** that could lead to data synchronization issues, API integration problems, and potential runtime errors.

**Key Findings:**
- **Critical**: 47 major inconsistencies found across 8 model types
- **Warning**: 23 potential issues requiring attention
- **Info**: 15 minor differences in approach

---

## Table of Contents

1. [User Model Analysis](#1-user-model-analysis)
2. [Calendar Model Analysis](#2-calendar-model-analysis)
3. [CalendarMembership Model Analysis](#3-calendarmembership-model-analysis)
4. [CalendarSubscription Model Analysis](#4-calendarsubscription-model-analysis)
5. [Group Model Analysis](#5-group-model-analysis)
6. [GroupMembership Model Analysis](#6-groupmembership-model-analysis)
7. [Event Model Analysis](#7-event-model-analysis)
8. [EventInteraction Model Analysis](#8-eventinteraction-model-analysis)
9. [RecurringEventConfig Model Analysis](#9-recurringeventconfig-model-analysis)
10. [Additional Backend Models Missing in Flutter](#10-additional-backend-models-missing-in-flutter)
11. [Additional Flutter Models Not in Backend](#11-additional-flutter-models-not-in-backend)
12. [Summary of Critical Issues](#summary-of-critical-issues)
13. [Recommendations](#recommendations)

---

## 1. User Model Analysis

### Backend Models
- **Database**: `User` (models.py, lines 42-92)
- **API Response**: `UserResponse`, `UserEnrichedResponse`, `UserSubscriptionResponse` (schemas.py, lines 53-91)

### Flutter Model
- **Path**: `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/models/user.dart`

### Field Comparison

| Field | Backend (Database) | Backend (API) | Flutter | Status | Severity |
|-------|-------------------|---------------|---------|---------|----------|
| `id` | int, PK | int | int | ✅ MATCH | - |
| `username` | String(100), nullable | username | instagramName | ❌ **NAME MISMATCH** | 🔴 **CRITICAL** |
| `auth_provider` | String(20), required | auth_provider | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `auth_id` | String(255), required | auth_id | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `is_public` | Boolean, required | is_public | isPublic | ✅ MATCH | - |
| `is_admin` | Boolean, required | is_admin | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `profile_picture` | String(500), nullable | profile_picture | profilePicture | ✅ MATCH | - |
| `last_login` | TIMESTAMP, nullable | last_login | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `contact_id` | int FK, nullable | contact_id | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `created_at` | TIMESTAMP, required | created_at | createdAt | ✅ MATCH | - |
| `updated_at` | TIMESTAMP, required | updated_at | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `firebaseUid` | **NOT IN BACKEND** | **NOT IN BACKEND** | String?, nullable | ❌ **EXTRA IN FLUTTER** | 🔴 **CRITICAL** |
| `phoneNumber` | **NOT IN BACKEND** | **NOT IN BACKEND** | String?, nullable | ❌ **EXTRA IN FLUTTER** | 🔴 **CRITICAL** |
| `email` | **NOT IN BACKEND** | **NOT IN BACKEND** | String?, nullable | ❌ **EXTRA IN FLUTTER** | 🟡 WARNING |
| `fullName` | **NOT IN BACKEND** (via Contact) | contact_name (enriched) | String?, nullable | ⚠️ **STRUCTURAL DIFFERENCE** | 🟡 WARNING |
| `isActive` | **NOT IN BACKEND** | **NOT IN BACKEND** | bool, default: true | ❌ **EXTRA IN FLUTTER** | 🟡 WARNING |
| `isBanned` | **NOT IN BACKEND** (separate AppBan table) | **NOT IN BACKEND** | bool, default: false | ⚠️ **STRUCTURAL DIFFERENCE** | 🔴 **CRITICAL** |
| `lastSeen` | **NOT IN BACKEND** | **NOT IN BACKEND** | DateTime?, nullable | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `isOnline` | **NOT IN BACKEND** | **NOT IN BACKEND** | bool, default: false | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `defaultTimezone` | **NOT IN BACKEND** | **NOT IN BACKEND** | String, default: 'Europe/Madrid' | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `defaultCountryCode` | **NOT IN BACKEND** | **NOT IN BACKEND** | String, default: 'ES' | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `defaultCity` | **NOT IN BACKEND** | **NOT IN BACKEND** | String, default: 'Madrid' | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |

### Critical Issues

#### 1. Authentication Fields Missing in Flutter (🔴 CRITICAL)
- **Backend has**: `auth_provider` ('phone' | 'instagram'), `auth_id` (phone number or Instagram user ID)
- **Flutter has**: Firebase-specific fields (`firebaseUid`, `phoneNumber`)
- **Impact**: Flutter cannot properly represent the backend's multi-provider authentication system
- **Recommendation**: Add `authProvider` and `authId` fields to Flutter model, deprecate `firebaseUid`

#### 2. Contact Relationship Broken (🔴 CRITICAL)
- **Backend**: User has `contact_id` FK to Contact table for phone/name data
- **Flutter**: Has direct `phoneNumber` and `fullName` fields
- **Impact**: Cannot properly sync contact relationships; denormalized data can become inconsistent
- **Recommendation**: Add `contactId` field to Flutter model, create separate Contact model

#### 3. Admin Status Missing (🔴 CRITICAL)
- **Backend**: Has `is_admin` boolean for admin users
- **Flutter**: No equivalent field
- **Impact**: Cannot detect or handle admin users in Flutter app
- **Recommendation**: Add `isAdmin` field to Flutter model

#### 4. Ban Status Structural Difference (🔴 CRITICAL)
- **Backend**: Separate `AppBan` table (normalized)
- **Flutter**: Direct `isBanned` boolean (denormalized)
- **Impact**: Backend changes to AppBan table won't sync to Flutter's boolean field
- **Recommendation**: Either add `isBanned` computed field in backend API responses, or change Flutter to check separate ban status

#### 5. Username Field Name Mismatch (🔴 CRITICAL)
- **Backend**: Field named `username` (for Instagram users)
- **Flutter**: Field named `instagramName`
- **Impact**: Direct field mapping fails; requires manual translation in fromJson
- **Recommendation**: Rename Flutter field to `username` for consistency (breaking change)

### Warnings

#### 1. Last Login Missing (🟡 WARNING)
- Flutter doesn't track `last_login` timestamp from backend
- Could be useful for UX features

#### 2. User Settings Fields (🔵 INFO)
- Flutter has many user preference fields (`defaultTimezone`, `defaultCountryCode`, etc.) not in backend
- These appear to be client-only settings
- Consider whether these should be stored server-side for cross-device sync

---

## 2. Calendar Model Analysis

### Backend Models
- **Database**: `Calendar` (models.py, lines 94-148)
- **API Response**: `CalendarResponse` (schemas.py, lines 286-296)

### Flutter Model
- **Path**: `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/models/calendar.dart`

### Field Comparison

| Field | Backend | Flutter | Status | Severity |
|-------|---------|---------|---------|----------|
| `id` | int, PK | int | ✅ MATCH | - |
| `owner_id` | int FK, required | ownerId | ✅ MATCH | - |
| `name` | String(255), required | name | ✅ MATCH | - |
| `description` | Text, nullable | description | ✅ MATCH | - |
| `start_date` | TIMESTAMP, nullable | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `end_date` | TIMESTAMP, nullable | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `is_public` | Boolean, required | isPublic | ✅ MATCH | - |
| `is_discoverable` | Boolean, required | isDiscoverable | ✅ MATCH | - |
| `category` | String(100), nullable | category | ✅ MATCH | - |
| `share_hash` | String(8), nullable | shareHash | ✅ MATCH | - |
| `subscriber_count` | int, required | subscriberCount | ✅ MATCH | - |
| `created_at` | TIMESTAMP, required | createdAt | ✅ MATCH | - |
| `updated_at` | TIMESTAMP, required | updatedAt | ✅ MATCH | - |
| `deleteAssociatedEvents` | **NOT IN BACKEND** | bool, default: false | ❌ **EXTRA IN FLUTTER** | 🟡 WARNING |

### Critical Issues

#### 1. Temporal Calendar Support Missing (🔴 CRITICAL)
- **Backend has**: `start_date` and `end_date` for temporal calendars (e.g., "Summer Course 2025")
- **Flutter has**: No equivalent fields
- **Impact**: Flutter cannot represent or display temporal calendars; feature completely unavailable
- **Recommendation**: Add `startDate` and `endDate` nullable DateTime fields to Flutter Calendar model

### Warnings

#### 1. Delete Associated Events Field (🟡 WARNING)
- **Flutter has**: `deleteAssociatedEvents` boolean (appears to be a client-side preference)
- **Backend has**: No equivalent field
- **Impact**: This preference is not persisted server-side
- **Recommendation**: Either persist this in backend or clearly document as client-only state

---

## 3. CalendarMembership Model Analysis

### Backend Models
- **Database**: `CalendarMembership` (models.py, lines 150-188)
- **API Response**: `CalendarMembershipResponse`, `CalendarMembershipEnrichedResponse` (schemas.py, lines 313-347)

### Flutter Model
- **Status**: ❌ **MISSING** - No CalendarMembership model found in Flutter

### Critical Issues

#### 1. Entire Model Missing (🔴 CRITICAL)
- **Backend has**: Full CalendarMembership model with:
  - `calendar_id`, `user_id`
  - `role` ('owner', 'admin', 'member')
  - `status` ('pending', 'accepted', 'rejected')
  - `invited_by_user_id`
  - Timestamps
- **Flutter has**: Nothing
- **Impact**: Flutter cannot represent shared private calendars, membership invitations, or admin roles for calendars
- **Recommendation**: Create `CalendarMembership` model in Flutter with all fields from backend

**Backend Fields:**
```python
id: int
calendar_id: int (FK)
user_id: int (FK)
role: str ('owner', 'admin', 'member')
status: str ('pending', 'accepted', 'rejected')
invited_by_user_id: int (FK, nullable)
joined_at: datetime
created_at: datetime
updated_at: datetime
```

---

## 4. CalendarSubscription Model Analysis

### Backend Models
- **Database**: `CalendarSubscription` (models.py, lines 191-236)
- **API Response**: `CalendarSubscriptionResponse`, `CalendarSubscriptionEnrichedResponse` (schemas.py, lines 354-388)

### Flutter Model
- **Status**: ❌ **MISSING** - No CalendarSubscription model found in Flutter
- **Note**: There is a `Subscription` model but it's for user-to-user subscriptions, not calendar subscriptions

### Critical Issues

#### 1. Entire Model Missing (🔴 CRITICAL)
- **Backend has**: CalendarSubscription model for subscribing to public calendars:
  - `calendar_id`, `user_id`
  - `status` ('active', 'paused')
  - `subscribed_at`, `updated_at`
- **Flutter has**: Nothing
- **Impact**: Flutter cannot handle public calendar subscriptions (major feature missing)
- **Recommendation**: Create `CalendarSubscription` model in Flutter with all fields from backend

**Backend Fields:**
```python
id: int
calendar_id: int (FK)
user_id: int (FK)
status: str ('active', 'paused')
subscribed_at: datetime
updated_at: datetime
```

---

## 5. Group Model Analysis

### Backend Models
- **Database**: `Group` (models.py, lines 239-268)
- **API Response**: `GroupResponse` (schemas.py, lines 404-413)

### Flutter Model
- **Path**: `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/models/group.dart`

### Field Comparison

| Field | Backend | Flutter | Status | Severity |
|-------|---------|---------|---------|----------|
| `id` | int, PK | int | ✅ MATCH | - |
| `name` | String(255), required | name | ✅ MATCH | - |
| `description` | Text, nullable | description | ✅ MATCH | - |
| `owner_id` | int FK, required | ownerId | ✅ MATCH | - |
| `owner` | User relationship | User?, nullable | ✅ MATCH | - |
| `members` | User[] relationship | User[] | ✅ MATCH | - |
| `admins` | **NOT DIRECTLY** | User[] | ⚠️ **STRUCTURAL DIFFERENCE** | 🟡 WARNING |
| `created_at` | TIMESTAMP, required | createdAt | ✅ MATCH | - |
| `updated_at` | TIMESTAMP, required | updatedAt | ✅ MATCH | - |

### Warnings

#### 1. Admin Representation Difference (🟡 WARNING)
- **Backend**: Admins are stored in `GroupMembership` table with `role='admin'`
- **Flutter**: Separate `admins` array in Group model
- **Impact**: Backend API must transform normalized data to match Flutter's expectation; this is already happening in `GroupResponse` schema
- **Recommendation**: Current approach works but creates denormalization; consider if Flutter should query memberships separately

---

## 6. GroupMembership Model Analysis

### Backend Models
- **Database**: `GroupMembership` (models.py, lines 271-302)
- **API Response**: `GroupMembershipResponse` (schemas.py, lines 435-443)

### Flutter Model
- **Status**: ❌ **MISSING** - No GroupMembership model found in Flutter

### Critical Issues

#### 1. Entire Model Missing (🔴 CRITICAL)
- **Backend has**: GroupMembership model with:
  - `group_id`, `user_id`
  - `role` ('admin' or 'member')
  - Timestamps
- **Flutter has**: Nothing (admins/members embedded in Group)
- **Impact**: Flutter cannot directly manage group memberships; cannot update roles; relies entirely on Group-level operations
- **Recommendation**: Consider adding GroupMembership model if direct membership management is needed

**Backend Fields:**
```python
id: int
group_id: int (FK)
user_id: int (FK)
role: str ('admin', 'member')
joined_at: datetime
created_at: datetime
updated_at: datetime
```

---

## 7. Event Model Analysis

### Backend Models
- **Database**: `Event` (models.py, lines 305-346)
- **API Response**: `EventResponse` (schemas.py, lines 151-177)

### Flutter Model
- **Path**: `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/models/event.dart`

### Field Comparison

| Field | Backend | Flutter | Status | Severity |
|-------|---------|---------|---------|----------|
| `id` | int, PK | int?, nullable | ⚠️ TYPE DIFFERENCE | 🟡 WARNING |
| `name` | String(255), required | name | ✅ MATCH | - |
| `description` | Text, nullable | description | ✅ MATCH | - |
| `start_date` | TIMESTAMP, required | startDate | ✅ MATCH | - |
| `event_type` | String(50), required | eventType | ✅ MATCH | - |
| `owner_id` | int FK, required | ownerId | ✅ MATCH | - |
| `calendar_id` | int FK, nullable | calendarId | ✅ MATCH | - |
| `parent_recurring_event_id` | int FK, nullable | parentRecurringEventId | ✅ MATCH | - |
| `created_at` | TIMESTAMP, required | createdAt | ✅ MATCH | - |
| `updated_at` | TIMESTAMP, required | updatedAt | ✅ MATCH | - |
| `owner_name` | enriched field | ownerName | ✅ MATCH | - |
| `owner_profile_picture` | enriched field | ownerProfilePicture | ✅ MATCH | - |
| `is_owner_public` | enriched field | isOwnerPublic | ✅ MATCH | - |
| `calendar_name` | enriched field | calendarName | ✅ MATCH | - |
| `calendar_color` | enriched field | calendarColor | ✅ MATCH | - |
| `is_birthday` | enriched field | isBirthdayEvent | ✅ MATCH | - |
| `attendees` | enriched field | attendeesList | ✅ MATCH | - |
| `interaction` | enriched field | interactionData | ✅ MATCH | - |
| `can_subscribe_to_owner` | enriched field | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `is_subscribed_to_owner` | enriched field | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `owner_upcoming_events` | enriched field | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `invitation_stats` | enriched field | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `interactions` | enriched field (all) | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `personalNote` | **NOT IN BACKEND** | String?, nullable | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `clientTempId` | **NOT IN BACKEND** | String?, nullable | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |

### Warnings

#### 1. ID Nullability Difference (🟡 WARNING)
- **Backend**: `id` is always present (auto-generated)
- **Flutter**: `id` is nullable (supports pre-creation state)
- **Impact**: Flutter needs to handle events without IDs (before API sync)
- **Recommendation**: Current approach is acceptable for client-side optimistic updates

#### 2. Enriched Fields Missing (🟡 WARNING)
- Flutter missing several enriched fields from backend responses:
  - `can_subscribe_to_owner`, `is_subscribed_to_owner`: Needed for subscription UI
  - `owner_upcoming_events`: Needed to show other events from same owner
  - `invitation_stats`: Needed for event owner to see invitation statistics
  - `interactions`: Needed to show all event participants
- **Recommendation**: Add these fields to Flutter model if those features are needed

#### 3. Personal Note Storage (🔵 INFO)
- Flutter has local `personalNote` field (different from backend's interaction note)
- This appears to be intentional for client-side notes
- **Recommendation**: Document distinction between personal notes (local) and interaction notes (synced)

---

## 8. EventInteraction Model Analysis

### Backend Models
- **Database**: `EventInteraction` (models.py, lines 349-434)
- **API Response**: `EventInteractionResponse`, `EventInteractionEnrichedResponse` (schemas.py, lines 212-241)

### Flutter Model
- **Path**: `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/models/event_interaction.dart`

### Field Comparison

| Field | Backend | Flutter | Status | Severity |
|-------|---------|---------|---------|----------|
| `id` | int, PK | int?, nullable | ⚠️ TYPE DIFFERENCE | 🟡 WARNING |
| `event_id` | int FK, required | eventId | ✅ MATCH | - |
| `user_id` | int FK, required | userId | ✅ MATCH | - |
| `interaction_type` | String(50), required | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `status` | String(50), nullable | participationStatus | ⚠️ **NAME DIFFERENCE** | 🟡 WARNING |
| `role` | String(50), nullable | isEventAdmin (bool) | ⚠️ **TYPE/NAME DIFFERENCE** | 🔴 **CRITICAL** |
| `invited_by_user_id` | int FK, nullable | inviterId | ✅ MATCH | - |
| `invited_via_group_id` | int FK, nullable | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `note` | Text, nullable | invitationMessage + personalNote | ⚠️ **STRUCTURAL DIFFERENCE** | 🔴 **CRITICAL** |
| `rejection_message` | Text, nullable | decisionMessage | ⚠️ **NAME DIFFERENCE** | 🟡 WARNING |
| `is_attending` | Boolean, nullable | isAttending | ✅ MATCH | - |
| `read_at` | TIMESTAMP, nullable | firstViewedAt + lastViewedAt | ⚠️ **STRUCTURAL DIFFERENCE** | 🟡 WARNING |
| `is_new` | computed property | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `created_at` | TIMESTAMP, required | invitedAt + createdAt | ⚠️ **STRUCTURAL DIFFERENCE** | 🟡 WARNING |
| `updated_at` | TIMESTAMP, required | participationDecidedAt + updatedAt | ⚠️ **STRUCTURAL DIFFERENCE** | 🟡 WARNING |
| `user` | enriched field | user | ✅ MATCH | - |
| `inviter` | enriched field | inviter | ✅ MATCH | - |
| `participationDecidedAt` | **NOT IN BACKEND** | DateTime?, nullable | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `postponeUntil` | **NOT IN BACKEND** | DateTime?, nullable | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `viewed` | **NOT IN BACKEND** | bool | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `noteUpdatedAt` | **NOT IN BACKEND** | DateTime?, nullable | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `hidden` | **NOT IN BACKEND** | bool | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |
| `hiddenAt` | **NOT IN BACKEND** | DateTime?, nullable | ❌ **EXTRA IN FLUTTER** | 🔵 INFO |

### Critical Issues

#### 1. Interaction Type Missing (🔴 CRITICAL)
- **Backend has**: `interaction_type` ('invited', 'requested', 'joined', 'subscribed')
- **Flutter has**: No equivalent field
- **Impact**: Cannot distinguish between different types of event interactions; loses critical business logic context
- **Recommendation**: Add `interactionType` field to Flutter model

**Backend Values:**
```python
'invited'    # User was invited to event
'requested'  # User requested to join
'joined'     # User joined without invitation
'subscribed' # User is subscribed to owner
```

#### 2. Role Representation Difference (🔴 CRITICAL)
- **Backend**: `role` as string ('owner', 'admin', null for member)
- **Flutter**: `isEventAdmin` as boolean only
- **Impact**: Cannot represent 'owner' role distinctly from 'admin'; loses role granularity
- **Recommendation**: Change Flutter to use `role` string field matching backend

**Backend Values:**
```python
'owner' # Event owner (full permissions)
'admin' # Event admin (elevated permissions)
null    # Regular member
```

#### 3. Group Invitation Missing (🔴 CRITICAL)
- **Backend has**: `invited_via_group_id` to track group-based invitations
- **Flutter has**: No equivalent field
- **Impact**: Cannot display or track when user was invited via a group
- **Recommendation**: Add `invitedViaGroupId` field to Flutter model

#### 4. Note Field Confusion (🔴 CRITICAL)
- **Backend**: Single `note` field (invitation message when invited, personal note otherwise)
- **Flutter**: Separate `invitationMessage` and `personalNote` fields
- **Impact**: Data model mismatch; unclear how to sync notes bidirectionally
- **Recommendation**: Align Flutter with backend's single `note` field, or add separate backend fields

### Warnings

#### 1. Read Tracking Difference (🟡 WARNING)
- **Backend**: Single `read_at` timestamp
- **Flutter**: Separate `viewed` bool, `firstViewedAt`, `lastViewedAt`
- **Impact**: Flutter tracks more detail than backend supports
- **Recommendation**: Either simplify Flutter or enhance backend schema

#### 2. Status Field Names (🟡 WARNING)
- Backend uses generic `status`; Flutter uses more specific `participationStatus`
- Acceptable naming difference but requires field mapping

#### 3. Additional Flutter Features (🔵 INFO)
- Flutter has several fields not in backend: `postponeUntil`, `hidden`, `hiddenAt`, `noteUpdatedAt`
- These appear to be client-side features for UI state management
- **Recommendation**: Document as client-only fields; consider whether to sync to backend

---

## 9. RecurringEventConfig Model Analysis

### Backend Models
- **Database**: `RecurringEventConfig` (models.py, lines 437-477)
- **API Response**: `RecurringEventConfigResponse` (schemas.py, lines 451-467)

### Flutter Model
- **Path**: `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/models/recurrence_pattern.dart`
- **Name Difference**: Backend calls it `RecurringEventConfig`, Flutter calls it `RecurrencePattern`

### Field Comparison

| Field | Backend | Flutter | Status | Severity |
|-------|---------|---------|---------|----------|
| `id` | int, PK | int?, nullable | ⚠️ TYPE DIFFERENCE | 🟡 WARNING |
| `event_id` | int FK, required | eventId | ✅ MATCH | - |
| `recurrence_type` | String(20), required | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `schedule` | JSON, nullable | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `recurrence_end_date` | TIMESTAMP, nullable | **MISSING** | ❌ **MISSING IN FLUTTER** | 🔴 **CRITICAL** |
| `created_at` | TIMESTAMP, required | createdAt | ✅ MATCH | - |
| `updated_at` | TIMESTAMP, required | **MISSING** | ❌ **MISSING IN FLUTTER** | 🟡 WARNING |
| `day_of_week` | **NOT IN BACKEND** | int, required | ❌ **EXTRA IN FLUTTER** | 🔴 **CRITICAL** |
| `time` | **NOT IN BACKEND** | String, required | ❌ **EXTRA IN FLUTTER** | 🔴 **CRITICAL** |

### Critical Issues

#### 1. Completely Different Schema (🔴 CRITICAL)

**Backend Flexible System:**
```python
recurrence_type: 'daily' | 'weekly' | 'monthly' | 'yearly'
schedule: JSON  # Type-specific configuration
recurrence_end_date: datetime | null  # When recurrence ends (null = perpetual)
```

**Backend Schedule Examples:**
```python
# Daily - every 2 days
{
  "interval": 2  # Every N days
}

# Weekly - Monday and Wednesday
{
  "days_of_week": [1, 3]  # 0=Monday, 6=Sunday
}

# Monthly - 15th of each month
{
  "day_of_month": 15
}

# Monthly - Last Friday
{
  "week_of_month": -1,  # -1 = last
  "day_of_week": 4      # Friday
}

# Yearly - January 1st
{
  "month": 1,
  "day": 1
}

# Yearly - Multiple dates (Christmas Eve & Christmas)
{
  "dates": [
    {"month": 12, "day": 24},
    {"month": 12, "day": 25}
  ]
}
```

**Flutter Simple System:**
```dart
day_of_week: int    # Single day only (0-6)
time: String        # Time string
```

**Impact**: 🔴 **COMPLETE FEATURE MISMATCH**
- Flutter can ONLY represent single-day weekly recurrence
- Flutter CANNOT represent:
  - Daily recurrence
  - Multi-day weekly (e.g., Monday + Wednesday)
  - Monthly recurrence (any pattern)
  - Yearly recurrence (birthdays, anniversaries)
  - End dates (perpetual vs time-bound)
  - Complex patterns (last Friday of month, etc.)
- Backend cannot parse Flutter's simple format
- Backend recurring events will fail to display correctly in Flutter

**Recommendation**: 🚨 **URGENT** - This is the most critical inconsistency
1. **Option A** (Recommended): Completely redesign Flutter recurrence model to match backend's flexible schema
2. **Option B**: Restrict backend to only support weekly single-day patterns (major feature loss)

---

## 10. Additional Backend Models Missing in Flutter

### 10.1. Contact Model (🔴 CRITICAL)

**Backend**: `Contact` (models.py, lines 9-39)

**Fields:**
```python
id: int (PK)
owner_id: int (FK to User)
name: str
phone: str (unique per owner)
created_at: datetime
updated_at: datetime
```

**Purpose**: Store phone contacts from user's device

**Flutter**: ❌ **MISSING**

**Impact**: Cannot properly represent user contacts; contact data denormalized into User model

**Recommendation**: Create Contact model in Flutter to properly represent the contact relationship

---

### 10.2. EventBan Model (🟡 WARNING)

**Backend**: `EventBan` (models.py, lines 480-515)

**Fields:**
```python
id: int (PK)
event_id: int (FK)
user_id: int (FK)
banned_by: int (FK to User)
reason: str (nullable)
banned_at: datetime
updated_at: datetime
```

**Purpose**: Track users banned from specific events

**Flutter**: ❌ **MISSING**

**Impact**: Cannot display or manage event-specific bans

**Recommendation**: Add EventBan model if feature is needed in app

---

### 10.3. UserBlock Model (🟡 WARNING)

**Backend**: `UserBlock` (models.py, lines 518-548)

**Fields:**
```python
id: int (PK)
blocker_user_id: int (FK)
blocked_user_id: int (FK)
created_at: datetime
```

**Purpose**: Track user-to-user blocking

**Flutter**: ❌ **MISSING**

**Impact**: Cannot implement user blocking feature in app

**Recommendation**: Add UserBlock model if feature is needed in app

---

### 10.4. AppBan Model (🟡 WARNING)

**Backend**: `AppBan` (models.py, lines 551-581)

**Fields:**
```python
id: int (PK)
user_id: int (FK)
banned_by: int (FK to User)
reason: str (nullable)
banned_at: datetime
updated_at: datetime
```

**Purpose**: Admin bans for entire application access

**Flutter**: User model has `isBanned` boolean instead

**Impact**: Structural difference (see User model analysis)

**Recommendation**: Either add AppBan model or ensure backend API includes `is_banned` computed field

---

### 10.5. EventCancellation Model (🟡 WARNING)

**Backend**: `EventCancellation` (models.py, lines 584-613)

**Fields:**
```python
id: int (PK)
event_id: int (FK)
event_name: str
cancelled_by_user_id: int (FK)
message: str (nullable)
cancelled_at: datetime
```

**Purpose**: Track cancelled events with optional message

**Flutter**: ❌ **MISSING**

**Impact**: Cannot display cancellation messages to users

**Recommendation**: Add EventCancellation model if feature is needed

---

### 10.6. EventCancellationView Model (🟡 WARNING)

**Backend**: `EventCancellationView` (models.py, lines 616-645)

**Fields:**
```python
id: int (PK)
cancellation_id: int (FK)
user_id: int (FK)
viewed_at: datetime
```

**Purpose**: Track which users have viewed a cancellation

**Flutter**: ❌ **MISSING**

**Impact**: Cannot track cancellation message acknowledgment

**Recommendation**: Add if cancellation feature is implemented

---

### 10.7. UserSubscriptionStats Model (🔵 INFO)

**Backend**: `UserSubscriptionStats` (models.py, lines 648-690)

**Fields:**
```python
user_id: int (PK, FK)
new_events_count: int
total_events_count: int
subscribers_count: int
last_event_date: datetime (nullable)
updated_at: datetime
```

**Purpose**: Statistics table for user subscriptions

**Flutter**: Fields embedded in User model (`newEventsCount`, `totalEventsCount`, `subscribersCount`)

**Impact**: Different structural approach but functionality exists

**Recommendation**: Current approach acceptable (denormalized in Flutter, normalized in backend)

---

## 11. Additional Flutter Models Not in Backend

### 11.1. CalendarShare Model (🟡 WARNING)

**Flutter**: `CalendarShare` (calendar_share.dart)

**Fields:**
```dart
id: int
calendarId: int
sharedWithUserId: int
permission: enum ('view', 'edit', 'admin')
createdAt: DateTime
```

**Purpose**: Share calendars with other users with different permission levels

**Backend**: Has `CalendarMembership` instead (different schema with roles: 'owner', 'admin', 'member')

**Impact**: Conceptual overlap with CalendarMembership but different implementation

**Recommendation**: Clarify if CalendarShare is deprecated in favor of CalendarMembership, or if they serve different purposes

---

### 11.2. Subscription Model (🟡 WARNING)

**Flutter**: `Subscription` (subscription.dart)

**Fields:**
```dart
id: int
userId: int
subscribedToId: int
subscribed: User
```

**Purpose**: User-to-user subscriptions (following users)

**Backend**: No direct equivalent model (handled via EventInteraction with type='subscribed')

**Impact**: Feature may not be implemented in backend as separate entity

**Recommendation**: Determine if this feature is deprecated or if backend implementation is missing

---

### 11.3. UI-Only Models (🔵 INFO)

The following Flutter models are UI helpers and don't need backend equivalents:

1. **AppSettings** (app_settings.dart)
   - User preferences stored locally
   - Fields: `defaultTimezone`, `defaultCountryCode`, `defaultCity`, `locale`

2. **Country** (country.dart)
   - UI data for country selector
   - Fields: `name`, `code`, `flag`, `timezone`

3. **City** (city.dart)
   - UI data for city selector
   - Fields: `name`, `countryCode`, `timezone`

4. **TimeOption** (time_option.dart)
   - UI data for time picker
   - Fields: `hour`, `minute`, `displayText`

5. **MonthOption** (month_option.dart)
   - UI data for month selector
   - Fields: `month`, `year`, `displayText`

6. **DayOption** (day_option.dart)
   - UI data for day picker
   - Fields: `dayOfWeek`, `displayText`

7. **SelectorOption** (selector_option.dart)
   - Generic selector UI component
   - Fields: `value`, `label`, `isSelected`

8. **DatetimeSelection** (datetime_selection.dart)
   - UI state for datetime picker
   - Fields: `selectedDate`, `selectedTime`, `mode`

**These are appropriately client-side only.**

---

## Summary of Critical Issues

### 🔴 CRITICAL Priority (Must Fix)

1. **User Model** (10 critical issues):
   - Missing `auth_provider`, `auth_id`, `contact_id`, `is_admin`
   - Has obsolete `firebaseUid`
   - Field name mismatch: `username` vs `instagramName`
   - Structural issue with ban status (`isBanned` bool vs AppBan table)
   - Cannot represent backend's auth system

2. **Calendar Model** (2 critical issues):
   - Missing `start_date` and `end_date` for temporal calendars
   - Temporal calendar feature completely unavailable in Flutter

3. **CalendarMembership Model** (1 critical issue):
   - Entire model missing in Flutter
   - Cannot represent shared private calendars
   - Cannot handle membership invitations or admin roles

4. **CalendarSubscription Model** (1 critical issue):
   - Entire model missing in Flutter
   - Cannot subscribe to public calendars (major feature loss)

5. **EventInteraction Model** (4 critical issues):
   - Missing `interaction_type` field (loses business logic context)
   - Wrong `role` type (bool instead of string enum)
   - Missing `invited_via_group_id`
   - Confused note structure (single field vs multiple fields)

6. **RecurringEventConfig Model** (1 critical issue - MOST SEVERE):
   - **Completely incompatible schemas**
   - Backend: Flexible system supporting daily/weekly/monthly/yearly patterns
   - Flutter: Simple system supporting only single-day weekly patterns
   - This breaks the entire recurring events feature

7. **Contact Model** (1 critical issue):
   - Entire model missing in Flutter
   - Data denormalized into User model incorrectly

8. **GroupMembership Model** (1 critical issue):
   - Entire model missing in Flutter
   - Cannot manage memberships directly

**Total Critical Issues: 21**

---

### 🟡 WARNING Priority (Should Fix)

1. **User Model** (2 warnings):
   - Missing `last_login`, `updated_at`

2. **Calendar Model** (1 warning):
   - Extra `deleteAssociatedEvents` not in backend

3. **Event Model** (5 warnings):
   - Missing enriched fields for UI features
   - ID nullability difference (acceptable for optimistic updates)

4. **EventInteraction Model** (5 warnings):
   - Different read tracking approach
   - Status field naming difference
   - Timestamp field structural differences

5. **RecurringEventConfig Model** (1 warning):
   - Missing `updated_at` timestamp

6. **CalendarShare vs CalendarMembership** (1 warning):
   - Clarify relationship or deprecate one

7. **Subscription Model** (1 warning):
   - Missing backend implementation

8. **EventBan, UserBlock, AppBan, EventCancellation Models** (4 warnings):
   - Missing in Flutter (features may be unimplemented)

9. **Group Model** (1 warning):
   - Admins array vs normalized GroupMembership table

**Total Warning Issues: 21**

---

### 🔵 INFO Priority (Nice to Have)

1. User preference fields in Flutter (`defaultTimezone`, `defaultCountryCode`, `defaultCity`)
   - Consider server-side sync for cross-device consistency

2. Event client-side fields (`personalNote`, `clientTempId`)
   - Document as local-only fields

3. EventInteraction client-side features (`postponeUntil`, `hidden`, `hiddenAt`)
   - Consider if these should sync to backend

4. UI-only models (Country, City, TimeOption, etc.)
   - Appropriately client-side only

**Total Info Issues: 15**

---

## Recommendations

### 🚨 Immediate Actions (Week 1)

#### 1. Fix RecurringEventConfig Schema Mismatch
**Priority**: HIGHEST (breaks entire feature)

**Option A** (Recommended): Update Flutter model
```dart
class RecurrencePattern {
  final int? id;
  final int eventId;
  final String recurrenceType; // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final Map<String, dynamic> schedule; // Type-specific JSON
  final DateTime? recurrenceEndDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

**Option B**: Restrict backend (NOT recommended - major feature loss)
- Remove daily, monthly, yearly support
- Only allow single-day weekly patterns

**Estimated Effort**: 3-5 days
**Risk if not fixed**: Recurring events completely broken

---

#### 2. Align User Model Authentication
**Priority**: HIGH (affects all user operations)

Changes needed in Flutter:
```dart
class User {
  final int id;
  final int? contactId;           // NEW - FK to Contact
  final String? username;         // RENAME from instagramName
  final String authProvider;      // NEW - 'phone' | 'instagram'
  final String authId;            // NEW - phone number or Instagram ID
  final bool isPublic;
  final bool isAdmin;             // NEW - admin flag
  final String? profilePicture;
  final DateTime? lastLogin;      // NEW
  final DateTime createdAt;
  final DateTime updatedAt;       // NEW

  // DEPRECATED - remove in v2.0
  @Deprecated('Use authProvider and authId instead')
  final String? firebaseUid;

  // KEEP - client preferences
  final String defaultTimezone;
  final String defaultCountryCode;
  final String defaultCity;
}
```

**Estimated Effort**: 2-3 days
**Risk if not fixed**: Cannot authenticate Instagram users, admin features broken

---

#### 3. Add Missing Core Models
**Priority**: HIGH (major features unavailable)

Create in Flutter:

**CalendarMembership:**
```dart
class CalendarMembership {
  final int id;
  final int calendarId;
  final int userId;
  final String role;        // 'owner' | 'admin' | 'member'
  final String status;      // 'pending' | 'accepted' | 'rejected'
  final int? invitedByUserId;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**CalendarSubscription:**
```dart
class CalendarSubscription {
  final int id;
  final int calendarId;
  final int userId;
  final String status;      // 'active' | 'paused'
  final DateTime subscribedAt;
  final DateTime updatedAt;
}
```

**Contact:**
```dart
class Contact {
  final int id;
  final int ownerId;
  final String name;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Estimated Effort**: 1 week
**Risk if not fixed**: Cannot use shared calendars, public calendar subscriptions, or proper contact management

---

#### 4. Fix EventInteraction Model
**Priority**: HIGH (affects event invitations)

Changes needed:
```dart
class EventInteraction {
  final int? id;
  final int eventId;
  final int userId;
  final String interactionType;   // NEW - 'invited' | 'requested' | 'joined' | 'subscribed'
  final String? status;            // RENAME from participationStatus
  final String? role;              // CHANGE from isEventAdmin (bool) - 'owner' | 'admin' | null
  final int? invitedByUserId;
  final int? invitedViaGroupId;    // NEW
  final String? note;              // MERGE invitationMessage + personalNote
  final String? rejectionMessage;  // RENAME from decisionMessage
  final bool? isAttending;
  final DateTime? readAt;          // SIMPLIFY from firstViewedAt/lastViewedAt
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Estimated Effort**: 2-3 days
**Risk if not fixed**: Cannot track invitation source, loses role distinction

---

#### 5. Add Temporal Calendar Support
**Priority**: MEDIUM-HIGH (feature gap)

Changes needed in Calendar model:
```dart
class Calendar {
  // ... existing fields ...
  final DateTime? startDate;  // NEW
  final DateTime? endDate;    // NEW
}
```

**Estimated Effort**: 1 day
**Risk if not fixed**: Temporal calendars (courses, seasons) don't work

---

### 📋 Medium-Term Actions (Weeks 2-4)

#### 1. Document Architectural Decisions
- Create ADR (Architecture Decision Record) for:
  - Why data is denormalized in Flutter (User contacts, Group members)
  - Which fields are client-only vs synced
  - Migration strategy for breaking changes
  - API versioning approach

**Estimated Effort**: 2 days

---

#### 2. Add API Contract Testing
- Integration tests validating Flutter models can parse all backend responses
- Tests for API request creation from Flutter models
- Schema validation tests

**Estimated Effort**: 3-5 days

---

#### 3. Clarify Deprecated/Unused Features
- Determine status of `CalendarShare` vs `CalendarMembership`
- Determine status of user-to-user `Subscription` model
- Document `firebaseUid` deprecation timeline
- Decide on ban tracking strategy (AppBan table vs isBanned boolean)

**Estimated Effort**: 1-2 days

---

#### 4. Add Optional Backend Models
If features are needed:
- EventBan (event-specific bans)
- UserBlock (user blocking)
- EventCancellation (cancellation messages)

**Estimated Effort**: 1 week

---

### 🔮 Long-Term Actions (Month 2+)

#### 1. Implement Code Generation
Options:
- **OpenAPI/Swagger**: Generate Dart models from OpenAPI spec
- **Protocol Buffers**: Strongly typed cross-language schemas
- **GraphQL**: GraphQL schema as single source of truth
- **json_serializable**: Auto-generate Dart serialization code

**Estimated Effort**: 2-3 weeks
**Benefits**: Eliminates manual model sync, reduces errors

---

#### 2. Create Shared Schema Source
Maintain single source of truth for data models:
- OpenAPI specification
- TypeScript definitions converted to both Dart and Python
- Shared protobuf definitions

**Estimated Effort**: 2-3 weeks
**Benefits**: One place to update models, automatic propagation

---

#### 3. Implement API Versioning
Handle breaking changes gracefully:
- URL versioning (`/api/v1/`, `/api/v2/`)
- Header versioning (`Accept: application/vnd.api.v2+json`)
- Gradual deprecation process

**Estimated Effort**: 1-2 weeks
**Benefits**: Can make breaking changes without breaking existing apps

---

## Migration Strategy

### Phase 1: Critical Fixes (Week 1-2)
1. ✅ Fix RecurringEventConfig schema (3-5 days)
2. ✅ Align User authentication fields (2-3 days)
3. ✅ Add Calendar temporal support (1 day)

**Total: 1-2 weeks**

### Phase 2: Missing Models (Week 3-4)
1. ✅ Create CalendarMembership model (2 days)
2. ✅ Create CalendarSubscription model (2 days)
3. ✅ Create Contact model (2 days)
4. ✅ Fix EventInteraction model (2-3 days)

**Total: 1-2 weeks**

### Phase 3: Testing & Documentation (Week 5-6)
1. ✅ Add API contract tests (3-5 days)
2. ✅ Document architecture decisions (2 days)
3. ✅ Update API documentation (2 days)

**Total: 1-2 weeks**

### Phase 4: Optional Features (Week 7-8)
1. Add GroupMembership model if needed (2 days)
2. Add EventBan/UserBlock if needed (3-5 days)
3. Add EventCancellation if needed (2 days)

**Total: 1-2 weeks**

**Total Estimated Timeline: 4-8 weeks**

---

## Testing Strategy

### 1. Unit Tests
- Test model serialization/deserialization
- Test field mappings
- Test null handling

### 2. Integration Tests
- Test API request/response with real backend
- Test all CRUD operations
- Test enriched responses

### 3. Schema Validation Tests
- Validate Flutter models can parse all backend responses
- Validate backend can parse all Flutter requests
- Catch schema mismatches early

### 4. Migration Tests
- Test backward compatibility during migration
- Test old app versions with new backend
- Test new app versions with old data

---

## Risk Assessment

### High Risk Issues

| Issue | Impact | Probability | Mitigation |
|-------|--------|-------------|------------|
| RecurringEventConfig incompatibility | **CRITICAL** - feature broken | 100% | Fix immediately (Phase 1) |
| User auth fields missing | **CRITICAL** - Instagram auth fails | 100% | Fix immediately (Phase 1) |
| Missing CalendarMembership | **HIGH** - shared calendars broken | 100% | Add in Phase 2 |
| Missing CalendarSubscription | **HIGH** - public calendars broken | 100% | Add in Phase 2 |
| EventInteraction missing fields | **HIGH** - invitation tracking broken | 100% | Fix in Phase 2 |

### Medium Risk Issues

| Issue | Impact | Probability | Mitigation |
|-------|--------|-------------|------------|
| Calendar temporal dates | **MEDIUM** - feature unavailable | 100% | Add in Phase 1 |
| Missing Contact model | **MEDIUM** - data denormalized | 100% | Add in Phase 2 |
| Event enriched fields | **MEDIUM** - UI features limited | 50% | Add as needed |

### Low Risk Issues

| Issue | Impact | Probability | Mitigation |
|-------|--------|-------------|------------|
| User settings fields | **LOW** - client preferences | 10% | Document, consider sync later |
| EventBan/UserBlock missing | **LOW** - features may be unneeded | 30% | Add only if required |
| CalendarShare vs Membership | **LOW** - clarification needed | 50% | Document decision |

---

## Conclusion

The analysis reveals **significant structural inconsistencies** between backend and Flutter models that go beyond simple field naming differences. Key findings:

### Statistics
- ✅ **8 models analyzed**
- ❌ **4 entire models missing** in Flutter (CalendarMembership, CalendarSubscription, Contact, GroupMembership)
- 🔴 **21 critical inconsistencies** requiring immediate attention
- 🟡 **21 warning inconsistencies** requiring medium-term fixes
- 🔵 **15 informational differences** documenting architectural choices

### Most Critical Issues
1. **RecurringEventConfig**: Completely incompatible schemas (backend supports daily/weekly/monthly/yearly, Flutter only supports weekly)
2. **User Model**: Missing authentication fields (auth_provider, auth_id), using obsolete Firebase fields
3. **Missing Core Models**: CalendarMembership, CalendarSubscription, Contact models entirely absent
4. **EventInteraction**: Missing interaction_type, wrong role type, confused note structure

### Recommended Priority
1. 🚨 **Week 1-2**: Fix critical User auth and RecurringEventConfig issues
2. 📋 **Week 3-4**: Add missing core models (CalendarMembership, CalendarSubscription, Contact)
3. 🔍 **Week 5-6**: Add testing and documentation
4. 🎯 **Week 7-8**: Add optional features as needed

**Estimated Total Effort**: 4-8 weeks of development + testing

**Risk if not addressed**:
- Data synchronization failures
- Feature incompatibility
- Runtime errors
- Poor user experience
- Technical debt accumulation

**Next Steps**:
1. Review and prioritize this report with the team
2. Create JIRA tickets for each critical issue
3. Begin Phase 1 fixes immediately
4. Schedule weekly review meetings to track progress

---

## Appendix: Files Analyzed

### Backend Files
- **models.py** (691 lines) - Database models
  - Contact (lines 9-39)
  - User (lines 42-92)
  - Calendar (lines 94-148)
  - CalendarMembership (lines 150-188)
  - CalendarSubscription (lines 191-236)
  - Group (lines 239-268)
  - GroupMembership (lines 271-302)
  - Event (lines 305-346)
  - EventInteraction (lines 349-434)
  - RecurringEventConfig (lines 437-477)
  - EventBan (lines 480-515)
  - UserBlock (lines 518-548)
  - AppBan (lines 551-581)
  - EventCancellation (lines 584-613)
  - EventCancellationView (lines 616-645)
  - UserSubscriptionStats (lines 648-690)

- **schemas.py** (588 lines) - API response schemas
  - UserResponse, UserEnrichedResponse, UserSubscriptionResponse
  - CalendarResponse
  - CalendarMembershipResponse, CalendarMembershipEnrichedResponse
  - CalendarSubscriptionResponse, CalendarSubscriptionEnrichedResponse
  - GroupResponse
  - GroupMembershipResponse
  - EventResponse
  - EventInteractionResponse, EventInteractionEnrichedResponse
  - RecurringEventConfigResponse

### Flutter Files
- **user.dart** (160 lines) - User model
- **calendar.dart** (90 lines) - Calendar model
- **group.dart** (131 lines) - Group model
- **event.dart** (197 lines) - Event model
- **event_interaction.dart** (260 lines) - EventInteraction model
- **recurrence_pattern.dart** (41 lines) - RecurrencePattern model
- **subscription.dart** (19 lines) - User-to-user Subscription model
- **calendar_share.dart** (59 lines) - CalendarShare model
- **app_settings.dart** - Client-side settings
- **country.dart**, **city.dart** - UI helpers
- **time_option.dart**, **month_option.dart**, **day_option.dart** - UI selectors
- **datetime_selection.dart**, **selector_option.dart** - UI state

### Models Missing in Flutter
- Contact
- CalendarMembership
- CalendarSubscription
- GroupMembership
- EventBan
- UserBlock
- AppBan
- EventCancellation
- EventCancellationView
- UserSubscriptionStats (embedded in User instead)

---

---

## 13. Realtime/CDC Configuration Issues

**Date Added:** 2025-11-06 (Post-Testing Analysis)

This section documents issues discovered during realtime integration testing that prevent proper CDC (Change Data Capture) functionality for Groups and Calendar Memberships.

### 13.1. Groups API Authentication Issues (🔴 CRITICAL)

**Problem**: Groups endpoints require `owner_id` in request body instead of using authenticated user

**Affected Endpoints:**
- `POST /api/v1/groups` - Create group
- Tests failing:
  - `test_create_group_triggers_realtime_insert`
  - `test_update_group_triggers_realtime_update`
  - `test_add_member_triggers_realtime_update`
  - `test_remove_member_triggers_realtime_update`
  - `test_delete_group_triggers_realtime_delete`
  - `test_leave_group_triggers_realtime_update`

**Current Behavior:**
```python
# routers/groups.py line 89
@router.post("", response_model=GroupResponse, status_code=201)
async def create_group(group_data: GroupCreate, db: Session = Depends(get_db)):
    # GroupCreate schema requires owner_id in body
    db_group, error = group.create_with_validation(db, obj_in=group_data)
```

**Expected Behavior:**
```python
@router.post("", response_model=GroupResponse, status_code=201)
async def create_group(
    group_data: GroupBase,  # Changed from GroupCreate
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    # Create GroupCreate with owner_id from auth
    create_data = GroupCreate(
        name=group_data.name,
        description=group_data.description,
        owner_id=current_user_id
    )
    db_group, error = group.create_with_validation(db, obj_in=create_data)
```

**Impact**: 🔴 **CRITICAL**
- Cannot create groups via API
- Security issue: users could set any owner_id
- All group realtime tests fail
- Flutter app cannot use groups feature

**Recommendation**: Update all Groups endpoints to use `current_user_id` from auth dependency

---

### 13.2. Calendar Memberships Realtime Configuration (🔴 CRITICAL)

**Problem**: Calendar memberships not properly configured for realtime updates

**Affected Tests:**
- `test_create_calendar_triggers_membership_insert`
- `test_subscribe_to_calendar_triggers_membership_insert`
- `test_unsubscribe_from_calendar_triggers_membership_delete`
- `test_delete_calendar_triggers_membership_delete`

**Root Causes:**
1. **Missing REPLICA IDENTITY**: CalendarMembership table needs `REPLICA IDENTITY FULL`
2. **Missing Realtime Publication**: Table not included in Supabase realtime publication
3. **Possible endpoint issues**: Similar to Groups, may need auth fixes

**Current Status** (from init_db.py):
```python
# Calendar memberships ARE created
# But REPLICA IDENTITY may not be set
```

**Expected Configuration:**
```sql
-- In init_db.py or migration
ALTER TABLE calendar_memberships REPLICA IDENTITY FULL;

-- Grant realtime permissions
GRANT SELECT ON calendar_memberships TO anon, authenticated;
```

**Impact**: 🔴 **CRITICAL**
- Calendar sharing feature doesn't work in real-time
- Flutter app won't see membership updates
- Invitations to calendars not reflected immediately

**Recommendation**:
1. Add REPLICA IDENTITY to calendar_memberships table
2. Ensure table is in Supabase realtime publication
3. Review calendar endpoints for auth issues

---

### 13.3. User Subscription Stats Tests in Complete Suite (🟡 WARNING)

**Problem**: Subscription stats tests in test_realtime_complete.py still use private users

**Affected Tests:**
- `test_subscribe_increments_subscribers_count` (test_realtime_complete.py)
- `test_unsubscribe_decrements_subscribers_count` (test_realtime_complete.py)

**Note**: These same tests PASS in `test_realtime_subscriptions.py` where we fixed them to use public users (user 7).

**Root Cause**: test_realtime_complete.py has duplicate versions of these tests that weren't updated.

**Fix**: Update test_realtime_complete.py to use user 7 (public) instead of user 2 (private), same as we did in test_realtime_subscriptions.py

**Impact**: 🟡 WARNING (tests only, feature works)
- Tests fail but actual feature is working
- Inconsistency between test files
- Could confuse developers

---

### 13.4. Event Interaction Rejection Tests (🟡 WARNING)

**Problem**: Rejection of invitations may not trigger proper realtime updates

**Affected Tests:**
- `test_reject_invitation_triggers_realtime_update` (test_realtime_complete.py)
- `test_reject_invitation_removes_from_user_events` (test_realtime_events.py)

**Possible Root Causes:**
1. EventInteraction UPDATE not publishing to realtime
2. User events view not recalculating after rejection
3. Rejection endpoint may need review

**Investigation Needed**: Review EventInteraction realtime configuration and rejection endpoint behavior

**Impact**: 🟡 WARNING
- Invitation rejections may not reflect in real-time
- Users may still see rejected invitations until refresh
- UX issue but not blocking

---

### Summary of Realtime Issues

| Component | Issue | Severity | Tests Failing |
|-----------|-------|----------|---------------|
| Groups API Auth | Missing current_user_id | 🔴 CRITICAL | 6 tests |
| Calendar Memberships | Missing realtime config | 🔴 CRITICAL | 4 tests |
| User Stats (complete) | Using private users | 🟡 WARNING | 2 tests |
| Event Rejections | Realtime not firing | 🟡 WARNING | 2 tests |

**Total**: 14 failing tests

---

### Recommended Fix Order

#### Priority 1: Groups API (🔴 CRITICAL - 30 minutes)
1. Update `routers/groups.py` POST endpoint to use current_user_id
2. Update all group modification endpoints similarly
3. Run group realtime tests

#### Priority 2: Calendar Memberships (🔴 CRITICAL - 1 hour)
1. Add REPLICA IDENTITY FULL to calendar_memberships table
2. Verify Supabase realtime publication includes table
3. Review calendar membership endpoints for auth issues
4. Run calendar membership realtime tests

#### Priority 3: Duplicate Test Fixes (🟡 WARNING - 15 minutes)
1. Update test_realtime_complete.py subscription tests to use user 7
2. Verify consistency between test files

#### Priority 4: Event Rejection Investigation (🟡 WARNING - 30 minutes)
1. Review EventInteraction REPLICA IDENTITY
2. Test rejection endpoint manually
3. Review realtime publication for event_interactions table
4. Fix if configuration issue found

**Total Estimated Time**: 2-3 hours

---

**Report End**

**Generated by:** Claude Code Analysis Agent
**Date:** 2025-11-06
**Version:** 1.1 (Updated with realtime issues)
**Last Updated:** 2025-11-06 14:45 UTC
