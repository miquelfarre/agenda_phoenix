# API Endpoints Inventory - Agenda Phoenix

**Version:** 2.0.0
**Base URL:** `http://localhost:8001`

---

## 1. ROOT & HEALTH

### GET /
- **Description:** Root endpoint with API information
- **Response:** API metadata and available endpoint categories
- **Auth:** None

### GET /health
- **Description:** Health check endpoint
- **Response:** Status and timestamp
- **Auth:** None

---

## 2. CONTACTS

### GET /contacts
- **Description:** List all contacts
- **Response:** List[ContactResponse]
- **Auth:** None

### GET /contacts/{contact_id}
- **Description:** Get a single contact by ID
- **Params:** contact_id (int)
- **Response:** ContactResponse
- **Auth:** None

### POST /contacts
- **Description:** Create a new contact
- **Body:** ContactCreate (name, phone)
- **Response:** ContactResponse (201)
- **Auth:** None

### PUT /contacts/{contact_id}
- **Description:** Update an existing contact
- **Params:** contact_id (int)
- **Body:** ContactCreate
- **Response:** ContactResponse
- **Auth:** None

### DELETE /contacts/{contact_id}
- **Description:** Delete a contact
- **Params:** contact_id (int)
- **Response:** Success message
- **Auth:** None

---

## 3. USERS

### GET /users
- **Description:** List all users
- **Response:** List[UserResponse]
- **Auth:** None

### GET /users/{user_id}
- **Description:** Get a single user by ID
- **Params:** user_id (int)
- **Response:** UserResponse
- **Auth:** None

### POST /users
- **Description:** Create a new user
- **Body:** UserCreate (username, auth_provider, auth_id, contact_id, profile_picture_url)
- **Response:** UserResponse (201)
- **Auth:** None

### PUT /users/{user_id}
- **Description:** Update an existing user
- **Params:** user_id (int)
- **Body:** UserCreate
- **Response:** UserResponse
- **Auth:** None

### DELETE /users/{user_id}
- **Description:** Delete a user
- **Params:** user_id (int)
- **Response:** Success message
- **Auth:** None

### GET /users/{user_id}/events
- **Description:** Get all events for a user (own, subscribed, invited, calendar events)
- **Params:** user_id (int)
- **Query Params:**
  - include_past (bool, default: false)
  - from_date (datetime, optional)
  - to_date (datetime, optional)
  - search (str, optional) - filter by event name
- **Response:** List of event objects with additional 'source' field
- **Response Fields:**
  - id, name, description, start_date, end_date
  - event_type (regular/recurring/birthday)
  - **source** (NEW): 'owned'/'subscribed'/'invited'/'calendar' - indicates how user has access to this event
  - owner_id, calendar_id, birthday_user_id
  - parent_calendar_id, parent_recurring_event_id
- **Notes:**
  - Default shows events from today 00:00 for next 30 months
  - Times rounded to 5-minute intervals
  - Includes owned events, subscribed events, accepted invitations, calendar events
  - **Source priority:** owned > subscribed > invited > calendar (if event matches multiple, highest priority wins)
  - **Recurring events filtering:**
    - If user is owner OR has accepted invitation → shows only instances (hides base/template)
    - If user has pending invitation → shows only base/template (hides instances)
    - This prevents duplicate recurring events from appearing
    - Instances inherit the source from their parent recurring event
- **Auth:** None

### GET /users/{user_id}/dashboard
- **Description:** Get dashboard statistics for a user
- **Params:** user_id (int)
- **Response:** Dashboard object with:
  - total_events (int)
  - owned_events (int)
  - subscribed_events (int)
  - calendars_count (int)
  - upcoming_7_days (int)
  - upcoming_7_days_events (list of events)
  - this_month_count (int)
  - pending_invitations (int)
  - next_event (object or null)
- **Auth:** None

### POST /users/{user_id}/subscribe/{target_user_id}
- **Description:** Subscribe a user to all events of another user (bulk operation)
- **Params:**
  - user_id (int) - User who is subscribing
  - target_user_id (int) - User to subscribe to
- **Response:** Object with:
  - message (str)
  - subscribed_count (int) - Number of new subscriptions created
  - already_subscribed_count (int) - Number of events already subscribed to
  - error_count (int) - Number of errors during subscription
  - total_events (int) - Total events owned by target user
- **Notes:**
  - Creates 'subscribed' interactions for all events owned by target_user_id
  - Skips events already subscribed to
  - Returns detailed counts of success/failures
- **Auth:** None

---

## 4. EVENTS

### GET /events
- **Description:** List all events, optionally filtered by owner
- **Query Params:** owner_id (int, optional)
- **Response:** List[EventResponse]
- **Auth:** None

### GET /events/{event_id}
- **Description:** Get a single event by ID
- **Params:** event_id (int)
- **Response:** EventResponse
- **Auth:** None

### POST /events
- **Description:** Create a new event
- **Body:** EventCreate (name, description, start_date, end_date, event_type, owner_id, calendar_id, birthday_user_id, parent_calendar_id, parent_recurring_event_id)
- **Response:** EventResponse (201)
- **Auth:** None

### PUT /events/{event_id}
- **Description:** Update an existing event
- **Params:** event_id (int)
- **Body:** EventCreate
- **Response:** EventResponse
- **Auth:** None

### DELETE /events/{event_id}
- **Description:** Delete an event
- **Params:** event_id (int)
- **Response:** Success message
- **Auth:** None

### GET /events/check-conflicts
- **Description:** Check for event conflicts for a user within a time range
- **Query Params:**
  - user_id (int, required)
  - start_date (datetime, required)
  - end_date (datetime, optional)
  - exclude_event_id (int, optional) - useful when editing
- **Response:** List[EventResponse] - overlapping events
- **Notes:**
  - Checks all user events (owned, subscribed, invited accepted, calendar)
  - Point events: conflict if within 5 minutes
  - Range events: conflict if intervals overlap
- **Auth:** None

### GET /events/{event_id}/interactions
- **Description:** Get all interactions for a specific event
- **Params:** event_id (int)
- **Response:** List[EventInteractionResponse]
- **Auth:** None

### POST /event-interactions
- **Description:** Create a new event interaction (alias for /interactions)
- **Body:** EventInteractionCreate
- **Response:** EventInteractionResponse (201)
- **Auth:** None

---

## 5. EVENT INTERACTIONS

### GET /interactions
- **Description:** List all interactions with optional filters
- **Query Params:**
  - event_id (int, optional)
  - user_id (int, optional)
  - interaction_type (str, optional) - 'invited', 'subscribed', etc.
  - status (str, optional) - 'pending', 'accepted', 'rejected'
- **Response:** List[EventInteractionResponse]
- **Notes:**
  - Special hierarchical filtering for pending invitations
  - For recurring events: hides instance invitations if parent is pending
- **Auth:** None

### GET /interactions/{interaction_id}
- **Description:** Get a single interaction by ID
- **Params:** interaction_id (int)
- **Response:** EventInteractionResponse
- **Auth:** None

### POST /interactions
- **Description:** Create a new event interaction
- **Body:** EventInteractionCreate (event_id, user_id, interaction_type, status, role, invited_by_user_id, invited_via_group_id)
- **Response:** EventInteractionResponse (201)
- **Auth:** None

### PUT /interactions/{interaction_id}
- **Description:** Update an existing interaction
- **Params:** interaction_id (int)
- **Body:** EventInteractionBase
- **Response:** EventInteractionResponse
- **Auth:** None

### PATCH /interactions/{interaction_id}
- **Description:** Partially update an interaction (typically to change status)
- **Params:** interaction_id (int)
- **Body:** EventInteractionBase
- **Response:** EventInteractionResponse
- **Notes:**
  - Cascade behavior: rejecting a base recurring event automatically rejects all pending instance invitations
- **Auth:** None

### DELETE /interactions/{interaction_id}
- **Description:** Delete an interaction
- **Params:** interaction_id (int)
- **Response:** Success message
- **Auth:** None

---

## 6. CALENDARS

### GET /calendars
- **Description:** List all calendars, optionally filtered by user
- **Query Params:** user_id (int, optional)
- **Response:** List[CalendarResponse]
- **Auth:** None

### GET /calendars/{calendar_id}
- **Description:** Get a single calendar by ID
- **Params:** calendar_id (int)
- **Response:** CalendarResponse
- **Auth:** None

### POST /calendars
- **Description:** Create a new calendar
- **Body:** CalendarCreate (name, color, is_default, is_private_birthdays, user_id)
- **Response:** CalendarResponse (201)
- **Auth:** None

### PUT /calendars/{calendar_id}
- **Description:** Update an existing calendar
- **Params:** calendar_id (int)
- **Body:** CalendarBase
- **Response:** CalendarResponse
- **Auth:** None

### DELETE /calendars/{calendar_id}
- **Description:** Delete a calendar
- **Params:** calendar_id (int)
- **Response:** Success message
- **Auth:** None

### GET /calendars/{calendar_id}/memberships
- **Description:** Get all members of a specific calendar
- **Params:** calendar_id (int)
- **Response:** List[CalendarMembershipResponse]
- **Auth:** None

### POST /calendars/memberships
- **Description:** Add a user to a calendar (alias for /calendar_memberships)
- **Body:** CalendarMembershipCreate
- **Response:** CalendarMembershipResponse (201)
- **Auth:** None

---

## 7. CALENDAR MEMBERSHIPS

### GET /calendar_memberships
- **Description:** List all calendar memberships with optional filters
- **Query Params:**
  - calendar_id (int, optional)
  - user_id (int, optional)
- **Response:** List[CalendarMembershipResponse]
- **Auth:** None

### GET /calendar_memberships/{membership_id}
- **Description:** Get a single calendar membership by ID
- **Params:** membership_id (int)
- **Response:** CalendarMembershipResponse
- **Auth:** None

### POST /calendar_memberships
- **Description:** Add a user to a calendar (invite or add directly)
- **Body:** CalendarMembershipCreate (calendar_id, user_id, role, status, invited_by_user_id)
- **Response:** CalendarMembershipResponse (201)
- **Auth:** None

### PUT /calendar_memberships/{membership_id}
- **Description:** Update a calendar membership (e.g., change status or role)
- **Params:** membership_id (int)
- **Body:** CalendarMembershipBase
- **Response:** CalendarMembershipResponse
- **Auth:** None

### DELETE /calendar_memberships/{membership_id}
- **Description:** Remove a user from a calendar
- **Params:** membership_id (int)
- **Response:** Success message
- **Auth:** None

---

## 8. GROUPS

### GET /groups
- **Description:** List all groups, optionally filtered by creator
- **Query Params:** created_by (int, optional)
- **Response:** List[GroupResponse]
- **Auth:** None

### GET /groups/{group_id}
- **Description:** Get a single group by ID
- **Params:** group_id (int)
- **Response:** GroupResponse
- **Auth:** None

### POST /groups
- **Description:** Create a new group
- **Body:** GroupCreate (name, description, created_by)
- **Response:** GroupResponse (201)
- **Auth:** None

### PUT /groups/{group_id}
- **Description:** Update an existing group
- **Params:** group_id (int)
- **Body:** GroupBase
- **Response:** GroupResponse
- **Auth:** None

### DELETE /groups/{group_id}
- **Description:** Delete a group
- **Params:** group_id (int)
- **Response:** Success message
- **Auth:** None

---

## 9. GROUP MEMBERSHIPS

### GET /group_memberships
- **Description:** List all group memberships with optional filters
- **Query Params:**
  - group_id (int, optional)
  - user_id (int, optional)
- **Response:** List[GroupMembershipResponse]
- **Auth:** None

### GET /group_memberships/{membership_id}
- **Description:** Get a single group membership by ID
- **Params:** membership_id (int)
- **Response:** GroupMembershipResponse
- **Auth:** None

### POST /group_memberships
- **Description:** Add a user to a group
- **Body:** GroupMembershipCreate (group_id, user_id)
- **Response:** GroupMembershipResponse (201)
- **Auth:** None

### DELETE /group_memberships/{membership_id}
- **Description:** Remove a user from a group
- **Params:** membership_id (int)
- **Response:** Success message
- **Auth:** None

---

## 10. RECURRING EVENT CONFIGS

### GET /recurring_configs
- **Description:** List all recurring event configs, optionally filtered by event
- **Query Params:** event_id (int, optional)
- **Response:** List[RecurringEventConfigResponse]
- **Auth:** None

### GET /recurring_configs/{config_id}
- **Description:** Get a single recurring config by ID
- **Params:** config_id (int)
- **Response:** RecurringEventConfigResponse
- **Auth:** None

### POST /recurring_configs
- **Description:** Create a new recurring event config
- **Body:** RecurringEventConfigCreate (event_id, days_of_week, time_slots, recurrence_end_date)
- **Response:** RecurringEventConfigResponse (201)
- **Auth:** None

### PUT /recurring_configs/{config_id}
- **Description:** Update an existing recurring config
- **Params:** config_id (int)
- **Body:** RecurringEventConfigBase
- **Response:** RecurringEventConfigResponse
- **Auth:** None

### DELETE /recurring_configs/{config_id}
- **Description:** Delete a recurring config
- **Params:** config_id (int)
- **Response:** Success message
- **Auth:** None

---

## 11. EVENT BANS

### GET /event_bans
- **Description:** List all event bans with optional filters
- **Query Params:**
  - event_id (int, optional)
  - user_id (int, optional)
- **Response:** List[EventBanResponse]
- **Auth:** None

### GET /event_bans/{ban_id}
- **Description:** Get a single event ban by ID
- **Params:** ban_id (int)
- **Response:** EventBanResponse
- **Auth:** None

### POST /event_bans
- **Description:** Ban a user from an event
- **Body:** EventBanCreate (event_id, user_id, banned_by, reason)
- **Response:** EventBanResponse (201)
- **Auth:** None

### DELETE /event_bans/{ban_id}
- **Description:** Unban a user from an event
- **Params:** ban_id (int)
- **Response:** Success message
- **Auth:** None

---

## 12. USER BLOCKS

### GET /user_blocks
- **Description:** List all user blocks with optional filters
- **Query Params:**
  - blocker_user_id (int, optional)
  - blocked_user_id (int, optional)
- **Response:** List[UserBlockResponse]
- **Auth:** None

### GET /user_blocks/{block_id}
- **Description:** Get a single user block by ID
- **Params:** block_id (int)
- **Response:** UserBlockResponse
- **Auth:** None

### POST /user_blocks
- **Description:** Block a user
- **Body:** UserBlockCreate (blocker_user_id, blocked_user_id)
- **Response:** UserBlockResponse (201)
- **Auth:** None

### DELETE /user_blocks/{block_id}
- **Description:** Unblock a user
- **Params:** block_id (int)
- **Response:** Success message
- **Auth:** None

---

## 13. APP BANS

### GET /app_bans
- **Description:** List all app bans with optional filters (admin only)
- **Query Params:**
  - user_id (int, optional)
  - banned_by (int, optional)
- **Response:** List[AppBanResponse]
- **Auth:** Admin only

### GET /app_bans/{ban_id}
- **Description:** Get a single app ban by ID
- **Params:** ban_id (int)
- **Response:** AppBanResponse
- **Auth:** Admin only

### POST /app_bans
- **Description:** Ban a user from the entire application (admin only)
- **Body:** AppBanCreate (user_id, banned_by, reason)
- **Response:** AppBanResponse (201)
- **Auth:** Admin only

### DELETE /app_bans/{ban_id}
- **Description:** Unban a user from the application (admin only)
- **Params:** ban_id (int)
- **Response:** Success message
- **Auth:** Admin only

---

## TOTAL ENDPOINTS: 83

### Breakdown by Resource:
- Root & Health: 2
- Contacts: 5
- Users: 8 (added bulk subscription endpoint)
- Events: 8
- Event Interactions: 6
- Calendars: 8
- Calendar Memberships: 5
- Groups: 5
- Group Memberships: 4
- Recurring Event Configs: 5
- Event Bans: 4
- User Blocks: 4
- App Bans: 4

---

## NOTES

1. **Authentication:** Currently all endpoints are public. Authentication should be added in production.

2. **Data Relationships:**
   - Events belong to Users (owner)
   - Events can belong to Calendars
   - Users can interact with Events (EventInteraction)
   - Users can be members of Calendars (CalendarMembership)
   - Users can be members of Groups (GroupMembership)

3. **Special Logic:**
   - Conflict detection for events
   - Hierarchical invitation filtering for recurring events
   - Cascade rejection for recurring event invitations
   - Time rounding to 5-minute intervals

4. **Missing Endpoints (Future):**
   - Bulk operations
   - Search/filter endpoints
   - Statistics/analytics endpoints
   - Notification endpoints
