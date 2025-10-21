"""
CRUD operations module

Exposes singleton instances of CRUD classes for each model.
Import from here to use in routers:

    from crud import user, event, calendar, contact, event_interaction

Usage example:
    from crud import user
    from dependencies import get_db

    db_user = user.get(db, user_id=1)
    users = user.get_multi(db, skip=0, limit=10)
    new_user = user.create(db, obj_in=user_schema)
"""

from crud.crud_calendar import calendar, calendar_membership
from crud.crud_contact import contact
from crud.crud_event import event
from crud.crud_interaction import event_interaction
from crud.crud_user import user

__all__ = [
    "user",
    "event",
    "calendar",
    "calendar_membership",
    "contact",
    "event_interaction",
]
