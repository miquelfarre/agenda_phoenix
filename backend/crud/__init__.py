"""
CRUD operations module

Exposes singleton instances of CRUD classes for each model.
Import from here to use in routers:

    from crud import user, event, calendar, contact, event_interaction, app_ban, user_block, event_ban, group

Usage example:
    from crud import user
    from dependencies import get_db

    db_user = user.get(db, user_id=1)
    users = user.get_multi(db, skip=0, limit=10)
    new_user = user.create(db, obj_in=user_schema)
"""

from crud.crud_app_ban import app_ban
from crud.crud_calendar import calendar, calendar_membership
from crud.crud_contact import contact
from crud.crud_event import event
from crud.crud_event_ban import event_ban
from crud.crud_event_cancellation import event_cancellation
from crud.crud_group import group
from crud.crud_group_membership import group_membership
from crud.crud_interaction import event_interaction
from crud.crud_recurring_config import recurring_config
from crud.crud_user import user
from crud.crud_user_block import user_block
from crud.crud_user_contact import user_contact

__all__ = [
    "user",
    "event",
    "calendar",
    "calendar_membership",
    "contact",
    "user_contact",  # NEW
    "event_interaction",
    "app_ban",
    "user_block",
    "event_ban",
    "group",
    "group_membership",
    "recurring_config",
    "event_cancellation",
]
