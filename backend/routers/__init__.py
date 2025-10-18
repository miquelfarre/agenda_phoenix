"""
Agenda Phoenix API Routers

This package contains all API endpoint routers organized by resource.
"""
from . import (
    contacts,
    users,
    events,
    interactions,
    calendars,
    calendar_memberships,
    groups,
    group_memberships,
    recurring_configs,
    event_bans,
    user_blocks,
    app_bans
)

__all__ = [
    "contacts",
    "users",
    "events",
    "interactions",
    "calendars",
    "calendar_memberships",
    "groups",
    "group_memberships",
    "recurring_configs",
    "event_bans",
    "user_blocks",
    "app_bans"
]
