# CLI Guide

**Last Updated:** 2025-10-18

---

## Overview

The CLI is a **pure API client** for testing and designing the backend. It contains **ZERO business logic**.

---

## Quick Start

```bash
cd cli
python3 menu.py
```

---

## Structure

```
cli/
├── menu.py         # Main menu system (~1,550 lines)
└── utils.py        # Display utilities (tables, formatting)
```

---

## Key Principles

### ✅ DO
- Call backend API endpoints
- Display data received from backend
- Use utility functions for formatting
- Handle user input for API calls

### ❌ DON'T
- Implement business logic
- Validate data (backend does this)
- Calculate or transform data
- Make decisions about event visibility, conflicts, etc.

---

## Example: Good CLI Code

```python
# ✅ GOOD: Pure API client
def ver_mis_eventos():
    response = requests.get(f"{API_URL}/users/{current_user_id}/events")
    events = response.json()

    # Use utility to display
    create_events_table(events, "Mis Eventos", current_user_id)
```

## Example: Bad CLI Code

```python
# ❌ BAD: Business logic in CLI
def ver_mis_eventos():
    response = requests.get(f"{API_URL}/users/{current_user_id}/events")
    events = response.json()

    # DON'T do this! Backend should handle this
    if event['event_type'] == 'recurring' and has_pending_invite:
        # Hide instances...
```

---

## Available Utilities (utils.py)

```python
# Formatting
format_datetime(dt_str, format="%Y-%m-%d %H:%M")
truncate_text(text, max_length)
get_user_display_name(user_info)

# Tables
create_events_table(events, title, current_user_id, max_rows)
create_invitations_table(invitations, events_map, title)
create_calendars_table(calendars, title, include_user_column)
create_conflicts_table(conflicts)

# Messages
format_count_message(count, singular, plural)
show_pagination_info(displayed, total)
```

---

## Menu Structure

1. **Ver mis eventos** - Shows user's events (owned, subscribed, invited, calendar)
2. **Ver mis invitaciones** - Shows pending event invitations
3. **Crear evento** - Create new event with conflict detection
4. **Ver eventos de usuario** - List events from a specific user
5. **Suscribirse a usuario público** - Bulk subscribe to user's events
6. **Gestión de contactos** - Contact management
7. **Salir** - Exit CLI

---

## Development Rules

See [Development Rules](../development-rules.md) for complete separation guidelines.

**Summary:**
- CLI = API Client ONLY
- Backend = ALL logic
- Frontend = UI + API Client
