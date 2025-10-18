# Ban System - 3 Levels

**Last Updated:** 2025-10-18

---

## Overview

Agenda Phoenix implements a 3-level ban system to control access at different granularities.

---

## 1. Event Ban (Level: Event)

**Model:** `EventBan`
**Router:** `/event_bans`

```python
EventBan:
  - event_id         # Specific event
  - user_id          # Banned user
  - banned_by        # Event owner who banned
  - reason
```

**Use Case:**
- Public event owner bans a specific user from ONE event
- User can still see other events from the same owner

**Endpoints:**
- `GET /event_bans` - List bans
- `POST /event_bans` - Ban user from event
- `DELETE /event_bans/{ban_id}` - Unban user

---

## 2. User Block (Level: User)

**Model:** `UserBlock`
**Router:** `/user_blocks`

```python
UserBlock:
  - blocker_user_id  # User who blocks
  - blocked_user_id  # Blocked user
```

**Use Case:**
- Private user blocks another user
- Blocked user CANNOT see ANY events from blocker
- Bi-directional blocking possible

**Endpoints:**
- `GET /user_blocks` - List blocks
- `POST /user_blocks` - Block user
- `DELETE /user_blocks/{block_id}` - Unblock user

---

## 3. App Ban (Level: Application)

**Model:** `AppBan`
**Router:** `/app_bans`

```python
AppBan:
  - user_id          # Banned user
  - banned_by        # Admin who banned
  - reason
  - banned_at
```

**Use Case:**
- EventyPop admin bans a user
- User CANNOT access the application at all
- Most severe restriction

**Endpoints:**
- `GET /app_bans` - List app bans (admin only)
- `POST /app_bans` - Ban user from app (admin only)
- `DELETE /app_bans/{ban_id}` - Unban user (admin only)

---

## Comparison Matrix

| Feature | Event Ban | User Block | App Ban |
|---------|-----------|------------|---------|
| **Scope** | 1 event | All events from 1 user | Entire app |
| **Who can apply** | Event owner | Any user | Admin only |
| **Reversible** | Yes | Yes | Yes |
| **Severity** | Low | Medium | High |

---

## Implementation Logic

### Event Ban Check
```python
# Before showing event, check if user is banned
ban = db.query(EventBan).filter(
    EventBan.event_id == event_id,
    EventBan.user_id == user_id
).first()

if ban:
    raise HTTPException(403, "You are banned from this event")
```

### User Block Check
```python
# Before showing events, filter out blocked users
blocks = db.query(UserBlock).filter(
    UserBlock.blocker_user_id == owner_id,
    UserBlock.blocked_user_id == user_id
).first()

if blocks:
    # Don't show any events from this owner
    continue
```

### App Ban Check
```python
# On login/authentication
app_ban = db.query(AppBan).filter(
    AppBan.user_id == user_id
).first()

if app_ban:
    raise HTTPException(403, "You are banned from the application")
```

---

## Future Enhancements

- [ ] Ban expiration dates (temporary bans)
- [ ] Ban appeal system
- [ ] Ban reason categories
- [ ] Ban history/audit log
- [ ] Admin dashboard for ban management
