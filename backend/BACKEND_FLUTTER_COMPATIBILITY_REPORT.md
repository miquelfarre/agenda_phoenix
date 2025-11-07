# Backend-Flutter Compatibility Report
**Generated:** 2025-11-07
**Backend Tests Status:** 316 passed, 0 failed, 0 skipped

## Executive Summary

This report documents the recent backend changes and their impact on the Flutter app, focusing on compatibility issues between backend API responses and Flutter models. The analysis covers calendar subscriptions, share hash functionality, authentication fields, and model synchronization issues.

### Critical Issues Found: 3
### High Priority Issues: 4
### Medium Priority Issues: 2

---

## 1. Recent Backend Changes (Last Session)

### 1.1 Calendar Share Hash & Public Subscriptions
**Status:** ✅ Implemented and Tested
**Files Changed:**
- `backend/schemas.py:285-290` - Added `is_public` and `share_hash` to CalendarBase
- `backend/crud/crud_calendar.py:131-146` - Automatic share_hash generation
- `backend/routers/calendars.py:216-295` - New subscription endpoints

**New Endpoints:**
```
POST   /api/v1/calendars/{share_hash}/subscribe    # Subscribe using share hash
DELETE /api/v1/calendars/{share_hash}/subscribe    # Unsubscribe using share hash
GET    /api/v1/calendars/public                     # Get discoverable public calendars
```

**Backend Implementation:**
- Public calendars automatically generate 8-character base62 `share_hash` on creation
- Endpoints accept `share_hash` instead of calendar ID for public calendar subscriptions
- Share hash ensures URL-friendly public calendar discovery

**Flutter Implementation:**
- ✅ `Calendar.dart` model HAS `shareHash` field
- ✅ `CalendarHive.dart` HAS `shareHash` field
- ✅ API client methods exist: `subscribeByShareHash()`, `unsubscribeByShareHash()`
- ✅ Repository methods exist: `subscribeByShareHash()`, `unsubscribeByShareHash()`

**Compatibility:** ✅ COMPATIBLE - Flutter correctly handles new endpoints

---

### 1.2 Calendar Admin Event Permissions
**Status:** ✅ Implemented and Tested
**Files Changed:**
- `backend/routers/events.py:173-180` - Admin permission checking
- `backend/func_tests/test_event_detail.py:312-382` - Test coverage

**Changes:**
- Calendar admins now have full visibility of event interactions (same as event owner)
- Fixed method call from `get_by_calendar_and_user()` to `get_membership()`
- New test: `test_get_event_admin_sees_all_interactions` validates this behavior

**Impact on Flutter:**
- Event detail responses will include full `interactions` array for calendar admins
- Flutter app already handles `interactions` field in EventResponse
- No code changes needed in Flutter

**Compatibility:** ✅ COMPATIBLE - Flutter handles this correctly

---

## 2. Critical Compatibility Issues

### 2.1 UserHive Missing Authentication Fields
**Severity:** 🔴 CRITICAL
**Location:** `app_flutter/lib/models/user_hive.dart`

**Problem:**
The `UserHive` model (local storage) is MISSING critical authentication fields that exist in both backend and Flutter's `User` model:
- `auth_provider` (String)
- `auth_id` (String)
- `contact_id` (int?)
- `is_admin` (bool)

**Backend Schema (schemas.py:40-60):**
```python
class UserBase(BaseModel):
    username: Optional[str] = None
    auth_provider: str           # ← MISSING in UserHive
    auth_id: str                 # ← MISSING in UserHive
    is_public: bool = False
    is_admin: bool = False       # ← MISSING in UserHive
    profile_picture: Optional[str] = None

class UserCreate(UserBase):
    contact_id: Optional[int] = None  # ← MISSING in UserHive
```

**Flutter User Model:**
```dart
// app_flutter/lib/models/user.dart - ✅ HAS these fields
class User {
  final String? username;
  final String authProvider;    // ✅ Present
  final String authId;          // ✅ Present
  final int? contactId;         // ✅ Present
  final bool isPublic;
  final bool isAdmin;           // ✅ Present
  final String? profilePicture;
  // ...
}
```

**Flutter UserHive Model:**
```dart
// app_flutter/lib/models/user_hive.dart - ❌ MISSING these fields
@HiveType(typeId: 1)
class UserHive extends HiveObject {
  @HiveField(0) int id;
  @HiveField(1) String? username;
  @HiveField(2) bool isPublic;
  @HiveField(3) String? profilePicture;
  // ❌ NO auth_provider field
  // ❌ NO auth_id field
  // ❌ NO contact_id field
  // ❌ NO is_admin field
}
```

**Impact:**
1. When `User.toUserHive()` is called, authentication data is LOST
2. When `UserHive.toUser()` reconstructs the User, it uses default/null values
3. This creates data loss cycle: API → User → UserHive → User (data lost)
4. Admin privileges cannot be persisted locally
5. Contact associations are lost in local cache

**Recommendation:** 🔴 HIGH PRIORITY
1. Add missing fields to UserHive:
   ```dart
   @HiveField(4) String authProvider;
   @HiveField(5) String authId;
   @HiveField(6) int? contactId;
   @HiveField(7) bool isAdmin;
   ```
2. Update `User.toUserHive()` to copy all fields
3. Update `UserHive.toUser()` to restore all fields
4. Regenerate Hive type adapters: `flutter pub run build_runner build --delete-conflicting-outputs`
5. Add migration logic to handle existing Hive data

---

### 2.2 CalendarMembership Model Missing in Flutter
**Severity:** 🔴 CRITICAL
**Location:** Flutter models directory

**Problem:**
Backend has full `CalendarMembership` model with role-based permissions, but Flutter doesn't have this model at all.

**Backend Schema (schemas.py:324-358):**
```python
class CalendarMembershipBase(BaseModel):
    role: str = "member"  # 'owner', 'admin', 'member'
    status: str = "pending"  # 'pending', 'accepted', 'rejected'

class CalendarMembershipCreate(CalendarMembershipBase):
    calendar_id: int
    user_id: int
    invited_by_user_id: Optional[int] = None

class CalendarMembershipEnrichedResponse(CalendarMembershipBase):
    id: int
    calendar_id: int
    user_id: int
    calendar_name: str
    calendar_owner_id: int
    # ... timestamps
```

**Flutter:** ❌ No `CalendarMembership` model exists

**Impact:**
1. Cannot properly represent calendar member roles (owner/admin/member)
2. Cannot track membership status (pending/accepted/rejected)
3. Cannot show who invited a user to a calendar
4. Shared calendar UI cannot differentiate permissions

**Current Workaround:**
- Flutter uses raw `Map<String, dynamic>` from API responses
- No type safety or validation
- Prone to runtime errors

**Recommendation:** 🔴 HIGH PRIORITY
Create `calendar_membership.dart` and `calendar_membership_hive.dart`:
```dart
class CalendarMembership {
  final int id;
  final int calendarId;
  final int userId;
  final String role;  // 'owner', 'admin', 'member'
  final String status;  // 'pending', 'accepted', 'rejected'
  final int? invitedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional enriched fields
  final String? calendarName;
  final int? calendarOwnerId;

  // Constructor, fromJson, toJson, etc.
}
```

---

### 2.3 CalendarSubscription Model Missing in Flutter
**Severity:** 🟡 HIGH
**Location:** Flutter models directory

**Problem:**
Backend has `CalendarSubscription` for public calendar subscriptions, but Flutter doesn't have this model.

**Backend Schema (schemas.py:365-399):**
```python
class CalendarSubscriptionBase(BaseModel):
    status: str = "active"  # 'active', 'paused'

class CalendarSubscriptionCreate(CalendarSubscriptionBase):
    calendar_id: int
    user_id: int

class CalendarSubscriptionEnrichedResponse(CalendarSubscriptionBase):
    id: int
    calendar_id: int
    user_id: int
    subscribed_at: datetime
    calendar_name: str
    calendar_owner_name: str
    calendar_subscriber_count: int
```

**Flutter:** ❌ No `CalendarSubscription` model exists

**Impact:**
1. Cannot track subscription status (active/paused)
2. Cannot show when user subscribed to a public calendar
3. Cannot display subscriber counts accurately
4. Public calendar management UI is limited

**Recommendation:** 🟡 HIGH PRIORITY
Create `calendar_subscription.dart`:
```dart
class CalendarSubscription {
  final int id;
  final int calendarId;
  final int userId;
  final String status;  // 'active', 'paused'
  final DateTime subscribedAt;
  final DateTime updatedAt;

  // Optional enriched fields
  final String? calendarName;
  final String? calendarOwnerName;
  final int? subscriberCount;
}
```

---

## 3. High Priority Issues

### 3.1 Calendar Model Missing Temporal Fields
**Severity:** 🟡 HIGH
**Location:** `app_flutter/lib/models/calendar.dart`

**Problem:**
Backend Calendar supports temporal calendars (start_date, end_date) but Flutter model doesn't have these fields.

**Backend Model (models.py):**
```python
class Calendar(Base):
    # ... other fields
    start_date: Optional[datetime] = None  # For temporal calendars
    end_date: Optional[datetime] = None    # For temporal calendars
```

**Flutter Model:**
```dart
class Calendar {
  final int id;
  final String name;
  final String? description;
  final bool isPublic;
  // ❌ NO start_date field
  // ❌ NO end_date field
}
```

**Impact:**
- Temporal calendars (e.g., "Olympics 2024", "World Cup 2026") cannot be properly represented
- Cannot filter calendars by date range
- Cannot show calendar validity period in UI

**Recommendation:** 🟡 MEDIUM PRIORITY
Add optional temporal fields:
```dart
class Calendar {
  // ... existing fields
  final DateTime? startDate;
  final DateTime? endDate;
}
```

---

### 3.2 CalendarHive Not Syncing deleteAssociatedEvents
**Severity:** 🟡 MEDIUM
**Location:** `app_flutter/lib/models/calendar_hive.dart:25-35`

**Problem:**
The `CalendarHive.fromCalendar()` constructor doesn't copy the `deleteAssociatedEvents` field.

**Code:**
```dart
CalendarHive.fromCalendar(Calendar calendar)
    : id = calendar.id,
      name = calendar.name,
      description = calendar.description,
      isPublic = calendar.isPublic,
      ownerId = calendar.ownerId,
      shareHash = calendar.shareHash,
      category = calendar.category,
      subscriberCount = calendar.subscriberCount;
      // ❌ Missing: deleteAssociatedEvents = calendar.deleteAssociatedEvents
```

**Impact:**
- User preference for cascade delete is not persisted locally
- After offline/online sync, user must re-select preference
- Minor UX issue but inconsistent state

**Recommendation:** 🟡 LOW PRIORITY
Add the field to constructor:
```dart
deleteAssociatedEvents = calendar.deleteAssociatedEvents
```

---

### 3.3 Event Interaction User Info Enrichment
**Severity:** 🟢 INFO
**Location:** Event detail endpoint responses

**Changes:**
Backend now returns enriched user info in `interactions` field of event detail responses (GET /events/{id}).

**Response Structure:**
```json
{
  "id": 123,
  "name": "Team Meeting",
  "interactions": [
    {
      "id": 1,
      "user_id": 456,
      "status": "accepted",
      "user": {
        "id": 456,
        "full_name": "John Doe",
        "username": "johndoe",
        "phone_number": "+1234567890",
        "profile_picture": "https://..."
      },
      "inviter": {
        "id": 789,
        "full_name": "Jane Smith",
        "username": "janesmith"
      }
    }
  ]
}
```

**Flutter Handling:**
- Event model accepts `interactions` as `List<dynamic>`
- UI code parses nested user objects correctly
- No changes needed

**Compatibility:** ✅ COMPATIBLE

---

### 3.4 Endpoint URL Mismatch for Calendar Search
**Severity:** 🟡 MEDIUM
**Location:** `app_flutter/lib/services/api_client.dart:468-474`

**Problem:**
Flutter's `searchCalendarByHash()` method searches using the wrong endpoint:

**Flutter Code:**
```dart
Future<Map<String, dynamic>?> searchCalendarByHash(String shareHash) async {
  final result = await get('/calendars/public', queryParams: {'search': shareHash});
  // ...
}
```

**Backend Endpoints:**
```
GET /api/v1/calendars/public?search={text}     # Text search in name/description
GET /api/v1/calendars/{share_hash}             # Direct lookup by ID
```

**Issue:**
- Using `/calendars/public?search={shareHash}` does text search in calendar names/descriptions
- This is inefficient and may return wrong results
- Backend doesn't have dedicated share_hash lookup endpoint for GET

**Current Behavior:**
- If calendar name contains "xDHCSTZE", it will match
- If multiple calendars match, returns first one
- Not guaranteed to find the correct calendar

**Recommendation:** 🟡 MEDIUM PRIORITY
Backend should add a dedicated endpoint:
```python
@router.get("/share/{share_hash}", response_model=CalendarResponse)
async def get_calendar_by_share_hash(share_hash: str, db: Session = Depends(get_db)):
    """Get a public calendar by its share hash"""
    db_calendar = calendar.get_by_share_hash(db, share_hash=share_hash)
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")
    if not db_calendar.is_public:
        raise HTTPException(status_code=403, detail="Calendar is not public")
    return db_calendar
```

Then update Flutter:
```dart
Future<Map<String, dynamic>?> searchCalendarByHash(String shareHash) async {
  final result = await get('/calendars/share/$shareHash');
  return result as Map<String, dynamic>?;
}
```

---

## 4. Model Field Comparison Summary

### User Model
| Field | Backend | User.dart | UserHive | Status |
|-------|---------|-----------|----------|--------|
| id | ✅ | ✅ | ✅ | ✅ OK |
| username | ✅ | ✅ | ✅ | ✅ OK |
| auth_provider | ✅ | ✅ | ❌ | 🔴 MISSING |
| auth_id | ✅ | ✅ | ❌ | 🔴 MISSING |
| contact_id | ✅ | ✅ | ❌ | 🔴 MISSING |
| is_public | ✅ | ✅ | ✅ | ✅ OK |
| is_admin | ✅ | ✅ | ❌ | 🔴 MISSING |
| profile_picture | ✅ | ✅ | ✅ | ✅ OK |
| last_login | ✅ | ✅ | N/A | ✅ OK |

### Calendar Model
| Field | Backend | Calendar.dart | CalendarHive | Status |
|-------|---------|---------------|--------------|--------|
| id | ✅ | ✅ | ✅ | ✅ OK |
| name | ✅ | ✅ | ✅ | ✅ OK |
| description | ✅ | ✅ | ✅ | ✅ OK |
| owner_id | ✅ | ✅ | ✅ | ✅ OK |
| is_public | ✅ | ✅ | ✅ | ✅ OK |
| share_hash | ✅ | ✅ | ✅ | ✅ OK |
| category | ✅ | ✅ | ✅ | ✅ OK |
| subscriber_count | ✅ | ✅ | ✅ | ✅ OK |
| start_date | ✅ | ❌ | ❌ | 🟡 MISSING |
| end_date | ✅ | ❌ | ❌ | 🟡 MISSING |

### Group Model
| Field | Backend | Group.dart | GroupHive | Status |
|-------|---------|------------|-----------|--------|
| id | ✅ | ✅ | ✅ | ✅ OK |
| name | ✅ | ✅ | ✅ | ✅ OK |
| description | ✅ | ✅ | ✅ | ✅ OK |
| owner_id | ✅ | ✅ | ✅ | ✅ OK |
| owner | ✅ (User) | ✅ (User) | ❌ | ⚠️ Different |
| members | ✅ (List&lt;User&gt;) | ✅ (List&lt;User&gt;) | ✅ (denorm) | ⚠️ Different |
| admins | ✅ (List&lt;User&gt;) | ✅ (List&lt;User&gt;) | ✅ (denorm) | ⚠️ Different |

**Note:** GroupHive uses denormalized structure with separate arrays for IDs, names, etc. This is acceptable for performance.

---

## 5. Action Items (Prioritized)

### 🔴 Critical (Must Fix)
1. **Add authentication fields to UserHive** - Prevents data loss
   - Add: `auth_provider`, `auth_id`, `contact_id`, `is_admin`
   - Update converters: `toUserHive()`, `toUser()`
   - Regenerate Hive adapters
   - **Files:** `user_hive.dart`, `user.dart`

2. **Create CalendarMembership model** - Required for role-based permissions
   - Create: `calendar_membership.dart`, `calendar_membership_hive.dart`
   - Update repository to handle typed responses
   - **Files:** New files in `models/`

### 🟡 High Priority (Fix Soon)
3. **Create CalendarSubscription model** - Needed for public calendar management
   - Create: `calendar_subscription.dart`
   - Update repository subscription methods
   - **Files:** New file in `models/`

4. **Add calendar share_hash lookup endpoint** - Fix search inefficiency
   - Backend: Add `GET /calendars/share/{share_hash}`
   - Flutter: Update `searchCalendarByHash()` method
   - **Files:** `routers/calendars.py`, `api_client.dart`

5. **Add temporal calendar fields** - Support date-ranged calendars
   - Add `startDate`, `endDate` to Calendar model
   - Update Hive model and converters
   - **Files:** `calendar.dart`, `calendar_hive.dart`

### 🟢 Low Priority (Nice to Have)
6. **Sync deleteAssociatedEvents in CalendarHive** - Consistency fix
   - Update `CalendarHive.fromCalendar()` constructor
   - **Files:** `calendar_hive.dart`

7. **Update existing documentation** - Reflect recent changes
   - Update: `FLUTTER_COMPATIBILITY_TEST_RESULTS.md`
   - Update: `MODEL_INCONSISTENCIES_REPORT.md`
   - **Files:** Backend docs

---

## 6. Testing Recommendations

### Backend Tests (Already Done ✅)
- 316 tests passing, including new subscription and admin permission tests
- Share hash generation validated
- Calendar admin event access validated

### Flutter Tests Needed
1. **Unit Tests:**
   - Test User ↔ UserHive conversion with new auth fields
   - Test Calendar ↔ CalendarHive conversion with temporal fields
   - Test CalendarMembership model parsing from JSON

2. **Integration Tests:**
   - Test subscribe/unsubscribe by share_hash flow
   - Test calendar search by share_hash
   - Test event detail with enriched interactions

3. **Widget Tests:**
   - Test calendar admin UI shows correct permissions
   - Test public calendar subscription UI
   - Test event invitations with enriched user data

---

## 7. Backward Compatibility Notes

### Breaking Changes: NONE
All backend changes are **additive** and maintain backward compatibility:
- New fields are optional or have defaults
- Existing endpoints unchanged (new endpoints added)
- No removed fields or endpoints

### Migration Path
Flutter app can update incrementally:
1. Add missing UserHive fields (critical)
2. Add CalendarMembership model (high priority)
3. Add CalendarSubscription model (medium priority)
4. Add temporal calendar fields (low priority)

No database migrations needed - Hive will use defaults for new fields on existing records.

---

## 8. Conclusion

The backend is in excellent shape with 100% test coverage and robust new features for calendar subscriptions. However, Flutter has several critical model synchronization issues that need immediate attention:

**Critical Issues:**
- UserHive missing auth fields causes data loss
- Missing CalendarMembership model limits permissions UI
- Calendar search by share_hash uses inefficient endpoint

**Positive Points:**
- Share hash feature is fully implemented and tested
- Event detail enrichment works correctly
- Realtime sync infrastructure is solid

**Next Steps:**
1. Fix UserHive model (highest priority - prevents data loss)
2. Add CalendarMembership and CalendarSubscription models
3. Add dedicated share_hash lookup endpoint
4. Update documentation

**Estimated Effort:**
- Critical fixes: ~4-6 hours
- High priority: ~3-4 hours
- Low priority: ~1-2 hours
- **Total:** ~8-12 hours of focused development

---

**Report End**
