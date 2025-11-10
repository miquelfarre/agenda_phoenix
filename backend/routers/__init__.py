"""
Agenda Phoenix API Routers

This package contains all API endpoint routers organized by resource.
"""

from . import calendar_memberships, calendars, event_bans, events, group_memberships, groups, interactions, recurring_configs, user_blocks, users

__all__ = ["users", "events", "interactions", "calendars", "calendar_memberships", "groups", "group_memberships", "recurring_configs", "event_bans", "user_blocks"]
