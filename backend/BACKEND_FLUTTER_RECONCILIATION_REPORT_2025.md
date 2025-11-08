# Complete Backend-Flutter/Hive Reconciliation Report
**Generated:** 2025-01-08
**Scope:** ALL models between backend (Python/SQLAlchemy) and Flutter (Dart models + Hive cache)

## Executive Summary

This report provides a COMPLETE field-by-field comparison of ALL models between backend and Flutter/Hive.

**Legend:**
- ✅ **MATCH** - Fields match perfectly (accounting for snake_case → camelCase)
- ⚠️ **MISMATCH** - Field name or type difference
- ❌ **MISSING** - Field exists in one but not the other
- 📝 **NOTE** - Important implementation detail

---

## 1. Contact Model

### Backend (models.py:9-39)
```python
class Contact:
    id: int
    owner_id: int | None
    name: str
    phone: str
    created_at: datetime
    updated_at: datetime
```

### Flutter
❌ **MISSING** - No Contact model in Flutter

**Impact:** HIGH
**Issue:** Flutter has no Contact model. Contact data is enriched into User model as `contact_name` and `contact_phone`.

**Recommendation:** Create Contact model in Flutter for proper contact management.

---

## 2. User Model & UserHive

### Backend (models.py:42-96)
```python
class User:
    id: int
    contact_id: int | None
    name: str | None
    instagram_name: str | None
    phone: str | None
    auth_provider: str
    auth_id: str
    is_public: bool
    is_admin: bool
    profile_picture: str | None
    last_login: datetime | None
    created_at: datetime
    updated_at: datetime
```

### Flutter User (user.dart)
```dart
class User {
  int id;                       // ✅ MATCH
  int? contactId;               // ✅ MATCH (contact_id)
  String? instagramName;        // ✅ MATCH (instagram_name)
  String authProvider;          // ✅ MATCH (auth_provider)
  String authId;                // ✅ MATCH (auth_id)
  bool isPublic;                // ✅ MATCH (is_public)
  bool isAdmin;                 // ✅ MATCH (is_admin)
  String? profilePicture;       // ✅ MATCH (profile_picture)
  DateTime? lastLogin;          // ✅ MATCH (last_login)
  DateTime? createdAt;          // ✅ MATCH (created_at)
  DateTime? updatedAt;          // ✅ MATCH (updated_at)

  String? contactName;          // 📝 ENRICHED from Contact.name
  String? contactPhone;         // 📝 ENRICHED from Contact.phone
  String? phone;                // ✅ MATCH (phone)

  // Client-only fields
  bool isActive;                // ❌ Flutter only
  bool isBanned;                // ❌ Flutter only
  DateTime? lastSeen;           // ❌ Flutter only
  bool isOnline;                // ❌ Flutter only
  String defaultTimezone;       // ❌ Flutter only
  String defaultCountryCode;    // ❌ Flutter only
  String defaultCity;           // ❌ Flutter only
  int? newEventsCount;          // 📝 ENRICHED from UserSubscriptionStats
  int? totalEventsCount;        // 📝 ENRICHED from UserSubscriptionStats
  int? subscribersCount;        // 📝 ENRICHED from UserSubscriptionStats
}
```

### Flutter UserHive (user_hive.dart)
```dart
class UserHive {
  int id;                       // ✅ MATCH
  String? instagramName;        // ✅ MATCH (instagram_name)
  String? name;                 // ⚠️ Maps to contactName in User, but backend has User.name
  bool isPublic;                // ✅ MATCH (is_public)
  String? phone;                // ✅ MATCH (phone)
  String? profilePicture;       // ✅ MATCH (profile_picture)
  bool isBanned;                // ❌ Flutter only
  DateTime? lastSeen;           // ❌ Flutter only
  bool isOnline;                // ❌ Flutter only
  DateTime? registeredAt;       // ✅ Maps to created_at
  DateTime? updatedAt;          // ✅ MATCH (updated_at)
  int? newEventsCount;          // 📝 ENRICHED from stats
  int? totalEventsCount;        // 📝 ENRICHED from stats
  int? subscribersCount;        // 📝 ENRICHED from stats
  String authProvider;          // ✅ MATCH (auth_provider)
  String authId;                // ✅ MATCH (auth_id)
  int? contactId;               // ✅ MATCH (contact_id)
  bool isAdmin;                 // ✅ MATCH (is_admin)
  String? username;             // ⚠️ Maps to User.contactName (no backend equivalent)
}
```

**Status:** ✅ **RECONCILED** (as of 2025-01-08)

**Mappings:**
- UserHive.`name` → User.`contactName` (NOT backend User.name)
- UserHive.`username` → User.`contactName`
- UserHive.`registeredAt` → User.`createdAt`

---

## 3. Calendar Model & CalendarHive

### Backend (models.py:98-152)
```python
class Calendar:
    id: int
    owner_id: int
    name: str
    description: str | None
    is_public: bool
    is_discoverable: bool
    share_hash: str | None
    category: str | None
    subscriber_count: int
    start_date: datetime | None
    end_date: datetime | None
    created_at: datetime
    updated_at: datetime
```

### Flutter Calendar (calendar.dart)
```dart
class Calendar {
  int id;                       // ✅ MATCH
  int ownerId;                  // ✅ MATCH (owner_id)
  String name;                  // ✅ MATCH
  String? description;          // ✅ MATCH
  bool isPublic;                // ✅ MATCH (is_public)
  bool isDiscoverable;          // ✅ MATCH (is_discoverable)
  String? shareHash;            // ✅ MATCH (share_hash)
  String? category;             // ✅ MATCH
  int subscriberCount;          // ✅ MATCH (subscriber_count)
  DateTime? startDate;          // ✅ MATCH (start_date)
  DateTime? endDate;            // ✅ MATCH (end_date)
  DateTime createdAt;           // ✅ MATCH (created_at)
  DateTime updatedAt;           // ✅ MATCH (updated_at)
  bool deleteAssociatedEvents;  // ❌ Flutter only (UI state)
}
```

### Flutter CalendarHive (calendar_hive.dart)
```dart
class CalendarHive {
  int id;                       // ✅ MATCH
  int ownerId;                  // ✅ MATCH (owner_id)
  String name;                  // ✅ MATCH
  String? description;          // ✅ MATCH
  DateTime createdAt;           // ✅ MATCH (created_at)
  DateTime updatedAt;           // ✅ MATCH (updated_at)
  bool deleteAssociatedEvents;  // ❌ Flutter only
  bool isPublic;                // ✅ MATCH (is_public)
  bool isDiscoverable;          // ✅ MATCH (is_discoverable)
  String? shareHash;            // ✅ MATCH (share_hash)
  String? category;             // ✅ MATCH
  int subscriberCount;          // ✅ MATCH (subscriber_count)
  DateTime? startDate;          // ✅ MATCH (start_date)
  DateTime? endDate;            // ✅ MATCH (end_date)
}
```

**Status:** ✅ **100% COMPATIBLE**

---

## 4. CalendarMembership Model

### Backend (models.py:154-193)
```python
class CalendarMembership:
    id: int
    calendar_id: int
    user_id: int
    role: str  # 'owner', 'admin', 'member'
    status: str  # 'pending', 'accepted', 'rejected'
    invited_by_user_id: int | None
    created_at: datetime
    updated_at: datetime
```

### Flutter CalendarMembership (calendar_membership.dart)
```dart
class CalendarMembership {
  int id;                       // ✅ MATCH
  int calendarId;               // ✅ MATCH (calendar_id)
  int userId;                   // ✅ MATCH (user_id)
  String role;                  // ✅ MATCH
  String status;                // ✅ MATCH
  int? invitedByUserId;         // ✅ MATCH (invited_by_user_id)
  DateTime createdAt;           // ✅ MATCH (created_at)
  DateTime updatedAt;           // ✅ MATCH (updated_at)

  // Enriched fields
  String? calendarName;         // 📝 ENRICHED
  int? calendarOwnerId;         // 📝 ENRICHED
  User? user;                   // 📝 ENRICHED
  User? inviter;                // 📝 ENRICHED
}
```

**Status:** ✅ **100% COMPATIBLE**

---

## 5. CalendarSubscription Model

### Backend (models.py:195-241)
```python
class CalendarSubscription:
    id: int
    calendar_id: int
    user_id: int
    status: str  # 'active', 'paused'
    subscribed_at: datetime
    updated_at: datetime
```

### Flutter CalendarSubscription (calendar_subscription.dart)
```dart
class CalendarSubscription {
  int id;                       // ✅ MATCH
  int calendarId;               // ✅ MATCH (calendar_id)
  int userId;                   // ✅ MATCH (user_id)
  String status;                // ✅ MATCH
  DateTime subscribedAt;        // ✅ MATCH (subscribed_at)
  DateTime updatedAt;           // ✅ MATCH (updated_at)

  // Enriched fields
  String? calendarName;         // 📝 ENRICHED
  String? calendarDescription;  // 📝 ENRICHED
  String? calendarCategory;     // 📝 ENRICHED
  int? calendarOwnerId;         // 📝 ENRICHED
  String? calendarOwnerName;    // 📝 ENRICHED
  int? subscriberCount;         // 📝 ENRICHED (calendar_subscriber_count)
}
```

**Status:** ✅ **100% COMPATIBLE**

---

## 6. CalendarShare Model (LEGACY?)

### Backend
❌ **MISSING** - No CalendarShare table in backend

### Flutter CalendarShareHive (calendar_share_hive.dart)
```dart
class CalendarShareHive {
  String id;                    // ❌ Backend doesn't have this table
  String calendarId;
  String sharedWithUserId;
  String permission;
  DateTime createdAt;
}
```

**Status:** ❌ **FLUTTER-ONLY MODEL** (possibly legacy)

**Issue:** This model exists in Flutter but NOT in backend. Likely replaced by CalendarMembership.

**Recommendation:** DEPRECATE CalendarShare/CalendarShareHive in Flutter, use CalendarMembership instead.

---

## 7. Group Model & GroupHive

### Backend (models.py:243-272)
```python
class Group:
    id: int
    name: str
    description: str | None
    owner_id: int
    created_at: datetime
    updated_at: datetime
```

### Flutter Group (group.dart)
```dart
class Group {
  int id;                       // ✅ MATCH
  String name;                  // ✅ MATCH
  String description;           // ✅ MATCH (required, not nullable)
  int ownerId;                  // ✅ MATCH (owner_id)
  User? owner;                  // 📝 ENRICHED
  List<User> members;           // 📝 ENRICHED
  List<User> admins;            // 📝 ENRICHED
  DateTime createdAt;           // ✅ MATCH (created_at)
  DateTime? updatedAt;          // ✅ MATCH (updated_at)
}
```

### Flutter GroupHive (group_hive.dart)
```dart
class GroupHive {
  int id;                       // ✅ MATCH
  String name;                  // ✅ MATCH
  String? description;          // ✅ MATCH (nullable in Hive)
  int ownerId;                  // ✅ MATCH (owner_id)
  DateTime createdAt;           // ✅ MATCH (created_at)
  List<int> memberIds;          // 📝 Denormalized from GroupMembership
  List<String?> memberNames;    // 📝 Cache: User.instagramName
  List<String?> memberFullNames;// ⚠️ Maps to User.contactName
  List<bool?> memberIsPublic;   // 📝 Cache: User.isPublic
  List<int>? adminIds;          // 📝 Extracted from GroupMembership.role
  List<String>? pendingOperationIds; // ❌ Flutter only (offline sync)
  bool? isOptimistic;           // ❌ Flutter only (offline mode)
  bool? needsSync;              // ❌ Flutter only (sync flag)
  String? clientTempId;         // ❌ Flutter only (offline ID)
}
```

**Status:** ⚠️ **PARTIALLY COMPATIBLE**

**Issues:**
1. GroupHive.`memberFullNames` → stores User.`contactName`, but uses name "fullNames"
2. GroupHive denormalizes GroupMembership data into arrays for Hive caching

**Recommendation:**
- Rename GroupHive.`memberFullNames` → `memberContactNames` for clarity
- Document that GroupHive is a denormalized cache of Group + GroupMembership + User data

---

## 8. GroupMembership Model

### Backend (models.py:275-306)
```python
class GroupMembership:
    id: int
    group_id: int
    user_id: int
    role: str | None  # 'admin' or 'member' (null = member)
    created_at: datetime
    updated_at: datetime
```

### Flutter
❌ **MISSING** - No GroupMembership model in Flutter

**Impact:** MEDIUM
**Issue:** Flutter stores membership data denormalized in GroupHive arrays instead of separate model.

**Recommendation:** Keep current approach (denormalized in GroupHive) OR create GroupMembership model for proper relational structure.

---

## 9. Event Model & EventHive

### Backend (models.py:309-351)
```python
class Event:
    id: int
    name: str
    description: str | None
    start_date: datetime
    event_type: str  # 'regular' or 'recurring'
    owner_id: int
    calendar_id: int | None
    parent_recurring_event_id: int | None
    created_at: datetime
    updated_at: datetime
```

### Flutter Event (event.dart)
```dart
class Event {
  int? id;                      // ✅ MATCH (nullable for creation)
  String name;                  // ✅ MATCH
  String? description;          // ✅ MATCH
  DateTime startDate;           // ✅ MATCH (start_date)
  String eventType;             // ✅ MATCH (event_type)
  int ownerId;                  // ✅ MATCH (owner_id)
  int? calendarId;              // ✅ MATCH (calendar_id)
  int? parentRecurringEventId;  // ✅ MATCH (parent_recurring_event_id)
  DateTime? createdAt;          // ✅ MATCH (created_at)
  DateTime? updatedAt;          // ✅ MATCH (updated_at)

  // Enriched fields
  String? ownerName;            // 📝 ENRICHED (owner_name)
  String? ownerProfilePicture;  // 📝 ENRICHED (owner_profile_picture)
  bool? isOwnerPublic;          // 📝 ENRICHED (is_owner_public)
  String? calendarName;         // 📝 ENRICHED (calendar_name)
  String? calendarColor;        // 📝 ENRICHED (calendar_color)
  bool? isBirthdayEvent;        // 📝 ENRICHED (is_birthday)
  List<dynamic>? attendeesList; // 📝 ENRICHED (attendees)
  Map<String, dynamic>? interactionData; // 📝 ENRICHED (interaction)
  String? personalNote;         // ❌ Flutter only (local, different from interaction.personal_note)
  String? clientTempId;         // ❌ Flutter only (offline ID)
}
```

### Flutter EventHive (event_hive.dart)
```dart
class EventHive {
  int id;                       // ✅ MATCH
  String name;                  // ✅ MATCH
  String? description;          // ✅ MATCH
  DateTime startDate;           // ✅ MATCH (start_date)
  String eventType;             // ✅ MATCH (event_type)
  int ownerId;                  // ✅ MATCH (owner_id)
  int? calendarId;              // ✅ MATCH (calendar_id)
  int? parentRecurringEventId;  // ✅ MATCH (parent_recurring_event_id)
  DateTime? createdAt;          // ✅ MATCH (created_at)
  DateTime? updatedAt;          // ✅ MATCH (updated_at)
  String? ownerName;            // 📝 ENRICHED cache
  String? calendarName;         // 📝 ENRICHED cache
  String? personalNote;         // ❌ Flutter only (local note)
}
```

**Status:** ✅ **100% COMPATIBLE**

---

## 10. EventInteraction Model

### Backend (models.py:353-439)
```python
class EventInteraction:
    id: int
    event_id: int
    user_id: int
    interaction_type: str  # 'invited', 'requested', 'joined', 'subscribed'
    status: str | None  # 'pending', 'accepted', 'rejected', 'rejected_invitation_accepted_event'
    role: str | None  # 'owner', 'admin', null (member)
    invited_by_user_id: int | None
    invited_via_group_id: int | None
    personal_note: str | None
    cancellation_note: str | None
    is_attending: bool
    read_at: datetime | None
    created_at: datetime
    updated_at: datetime
    # Computed property:
    is_new: bool  # (read_at is NULL AND created < 24h ago AND not event owner)
```

### Flutter EventInteraction (event_interaction.dart)
```dart
class EventInteraction {
  int? id;                      // ✅ MATCH
  int userId;                   // ✅ MATCH (user_id)
  int eventId;                  // ✅ MATCH (event_id)
  User? user;                   // 📝 ENRICHED

  int? inviterId;               // ⚠️ Backend: invited_by_user_id
  User? inviter;                // 📝 ENRICHED
  DateTime? invitedAt;          // ⚠️ Maps to created_at

  String? participationStatus;  // ⚠️ Backend: status
  DateTime? participationDecidedAt; // ⚠️ Maps to updated_at
  String? cancellationNote;     // ✅ MATCH (cancellation_note)
  DateTime? postponeUntil;      // ❌ Flutter only (not in backend)

  bool isAttending;             // ✅ MATCH (is_attending)
  bool isEventAdmin;            // ⚠️ Derived from role == 'admin'

  bool viewed;                  // ⚠️ Derived from read_at != null
  DateTime? firstViewedAt;      // ⚠️ Maps to read_at
  DateTime? lastViewedAt;       // ⚠️ Maps to read_at (no separate field in backend)

  String? personalNote;         // ✅ MATCH (personal_note)
  DateTime? noteUpdatedAt;      // ⚠️ Maps to updated_at

  bool hidden;                  // ❌ Flutter only
  DateTime? hiddenAt;           // ❌ Flutter only

  DateTime createdAt;           // ✅ MATCH (created_at)
  DateTime updatedAt;           // ✅ MATCH (updated_at)
}
```

**Status:** ⚠️ **MISMATCHED FIELD NAMES**

**Issues:**
1. Backend `invited_by_user_id` → Flutter `inviterId`
2. Backend `status` → Flutter `participationStatus`
3. Backend `role` → Flutter derives `isEventAdmin` (bool)
4. Backend `read_at` → Flutter splits into `viewed` (bool), `firstViewedAt`, `lastViewedAt`
5. Backend has `interaction_type` → Flutter MISSING this field
6. Backend has `invited_via_group_id` → Flutter MISSING this field
7. Flutter has `postponeUntil`, `hidden`, `hiddenAt` → Backend MISSING

**Recommendation:**
- Add `interactionType` field to Flutter EventInteraction
- Add `invitedViaGroupId` field to Flutter EventInteraction
- Rename Flutter fields to match backend:
  - `inviterId` → `invitedByUserId`
  - `participationStatus` → `status`
- Add `role` field to Flutter (instead of just `isEventAdmin` bool)
- Remove Flutter-only fields (`postponeUntil`, `hidden`, `hiddenAt`) OR add to backend

---

## 11. RecurringEventConfig vs RecurrencePattern

### Backend (models.py:441-482)
```python
class RecurringEventConfig:
    id: int
    event_id: int
    recurrence_type: str  # 'daily', 'weekly', 'monthly', 'yearly'
    schedule: JSON  # Type-specific configuration
    recurrence_end_date: datetime | None  # NULL = perpetual
    created_at: datetime
    updated_at: datetime
```

### Flutter RecurrencePattern (recurrence_pattern.dart)
```dart
class RecurrencePattern {
  int? id;                      // ✅ MATCH
  int eventId;                  // ✅ MATCH (event_id)
  int dayOfWeek;                // ❌ Backend has schedule JSON instead
  String time;                  // ❌ Backend has schedule JSON instead
  DateTime? createdAt;          // ✅ MATCH (created_at)
}
```

**Status:** ❌ **INCOMPATIBLE**

**Issues:**
1. Backend uses flexible `schedule` JSON field → Flutter uses rigid `dayOfWeek` + `time` fields
2. Backend has `recurrence_type` → Flutter MISSING
3. Backend has `recurrence_end_date` → Flutter MISSING
4. Backend has `updated_at` → Flutter MISSING

**Impact:** CRITICAL - Recurring events likely broken

**Recommendation:**
- Redesign Flutter RecurrencePattern to match backend RecurringEventConfig structure
- Add `recurrenceType`, `schedule` (JSON/Map), `recurrenceEndDate`, `updatedAt` fields
- Deprecate current `dayOfWeek` + `time` approach

---

## 12. EventBan Model

### Backend (models.py:484-520)
```python
class EventBan:
    id: int
    event_id: int
    user_id: int
    banned_by: int
    reason: str | None
    created_at: datetime
    updated_at: datetime
```

### Flutter
❌ **MISSING** - No EventBan model in Flutter

**Impact:** MEDIUM
**Recommendation:** Add EventBan model to Flutter for event moderation features.

---

## 13. UserBlock Model

### Backend (models.py:522-553)
```python
class UserBlock:
    id: int
    blocker_user_id: int
    blocked_user_id: int
    created_at: datetime
    updated_at: datetime
```

### Flutter
❌ **MISSING** - No UserBlock model in Flutter

**Impact:** MEDIUM
**Recommendation:** Add UserBlock model to Flutter for user blocking features.

---

## 14. AppBan Model

### Backend (models.py:555-586)
```python
class AppBan:
    id: int
    user_id: int
    banned_by: int
    reason: str | None
    banned_at: datetime
    updated_at: datetime
```

### Flutter
❌ **MISSING** - No AppBan model in Flutter

**Impact:** LOW (admin-only feature)
**Recommendation:** Add AppBan model to Flutter for admin panel.

---

## 15. EventCancellation Model

### Backend (models.py:588-618)
```python
class EventCancellation:
    id: int
    event_id: int  # Not FK (event might be deleted)
    event_name: str
    cancelled_by_user_id: int
    message: str | None
    cancelled_at: datetime
```

### Flutter
❌ **MISSING** - No EventCancellation model in Flutter

**Impact:** HIGH
**Recommendation:** Add EventCancellation model to Flutter to show cancellation messages.

---

## 16. EventCancellationView Model

### Backend (models.py:620-650)
```python
class EventCancellationView:
    id: int
    cancellation_id: int
    user_id: int
    viewed_at: datetime
```

### Flutter
❌ **MISSING** - No EventCancellationView model in Flutter

**Impact:** MEDIUM
**Recommendation:** Add EventCancellationView to track which users have seen cancellation messages.

---

## 17. UserSubscriptionStats Model

### Backend (models.py:652-695)
```python
class UserSubscriptionStats:
    user_id: int  # Primary key
    new_events_count: int
    total_events_count: int
    subscribers_count: int
    last_event_date: datetime | None
    updated_at: datetime
```

### Flutter
📝 **ENRICHED INTO USER** - No separate model in Flutter

**Impact:** NONE
**Note:** These stats are enriched into User model as `newEventsCount`, `totalEventsCount`, `subscribersCount`.

---

## 18. Subscription Model (USER SUBSCRIPTIONS)

### Backend
❓ **UNCLEAR** - No explicit Subscription table in backend models.py

**Note:** User subscriptions are tracked via EventInteraction with `interaction_type='subscribed'`.

### Flutter SubscriptionHive (subscription_hive.dart)
```dart
class SubscriptionHive {
  int id;
  int userId;
  int subscribedToId;
  String? subscribedUserName;       // User.instagramName
  String? subscribedUserFullName;   // User.contactName
  bool? subscribedUserIsPublic;     // User.isPublic
}
```

**Status:** ❓ **UNCLEAR** - Need to verify backend implementation

**Recommendation:** Clarify if user subscriptions use EventInteraction table or separate table.

---

## Summary of Critical Issues

### 🔴 CRITICAL (Breaks Features)
1. **RecurringEventConfig vs RecurrencePattern** - Incompatible structures
2. **EventCancellation missing** - Users can't see cancellation messages
3. **EventInteraction mismatches** - Field name inconsistencies

### 🟡 HIGH (Missing Features)
4. **Contact model missing** - No proper contact management
5. **EventBan missing** - No event moderation
6. **CalendarShare is legacy** - Should use CalendarMembership instead

### 🟢 MEDIUM (Nice to Have)
7. **UserBlock missing** - No user blocking
8. **GroupMembership missing** - Denormalized into GroupHive
9. **EventCancellationView missing** - Can't track who viewed cancellations

### 🔵 LOW (Cosmetic/Naming)
10. **GroupHive uses "fullNames"** - Should be "contactNames"
11. **EventInteraction field renames** - `inviterId` vs `invited_by_user_id`, etc.

---

## Recommended Actions (Priority Order)

### Phase 1: Fix Critical Compatibility Issues
1. **Redesign RecurrencePattern** to match RecurringEventConfig
   - Add `recurrenceType`, `schedule` (Map<String, dynamic>), `recurrenceEndDate`
   - Deprecate `dayOfWeek` + `time` fields
   - Estimated effort: 4-6 hours

2. **Add EventCancellation model**
   - Create EventCancellation model matching backend
   - Update UI to show cancellation messages
   - Estimated effort: 2-3 hours

3. **Fix EventInteraction field naming**
   - Rename `inviterId` → `invitedByUserId`
   - Rename `participationStatus` → `status`
   - Add `interactionType`, `role`, `invitedViaGroupId` fields
   - Remove Flutter-only fields OR add to backend
   - Estimated effort: 2-3 hours

### Phase 2: Add Missing Features
4. **Create Contact model** in Flutter
   - Estimated effort: 1-2 hours

5. **Deprecate CalendarShare**, migrate to CalendarMembership
   - Estimated effort: 2-3 hours

6. **Add EventBan model**
   - Estimated effort: 1-2 hours

### Phase 3: Minor Improvements
7. **Rename GroupHive.memberFullNames** → `memberContactNames`
   - Estimated effort: 30 minutes

8. **Add UserBlock model**
   - Estimated effort: 1-2 hours

9. **Add EventCancellationView model**
   - Estimated effort: 1 hour

**Total Estimated Effort:** 15-23 hours

---

## Verification Checklist

- [x] User model reconciled
- [x] Calendar model verified
- [x] CalendarMembership verified
- [x] CalendarSubscription verified
- [x] Event model verified
- [ ] EventInteraction needs field renames
- [ ] RecurringEventConfig needs complete redesign
- [ ] EventCancellation needs implementation
- [ ] Contact model needs creation
- [ ] CalendarShare needs deprecation

**Report End**
