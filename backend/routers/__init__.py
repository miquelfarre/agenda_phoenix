"""
Agenda Phoenix API Routers

This package contains all API endpoint routers organized by resource.
"""

from . import app_bans, calendar_memberships, calendars, contacts, event_bans, events, group_memberships, groups, interactions, recurring_configs, user_blocks, users

__all__ = ["contacts", "users", "events", "interactions", "calendars", "calendar_memberships", "groups", "group_memberships", "recurring_configs", "event_bans", "user_blocks", "app_bans"]
