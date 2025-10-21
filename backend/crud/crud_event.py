"""
CRUD operations for Event model
"""

from datetime import datetime
from typing import List, Optional, Set

from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import CalendarMembership, Event, EventInteraction
from schemas import EventBase, EventCreate


class CRUDEvent(CRUDBase[Event, EventCreate, EventBase]):
    """CRUD operations for Event model with specific methods"""

    def get_by_owner(self, db: Session, *, owner_id: int, skip: int = 0, limit: int = 100) -> List[Event]:
        """
        Get events owned by a specific user.

        Args:
            db: Database session
            owner_id: User ID of the owner
            skip: Number of records to skip
            limit: Maximum number of records

        Returns:
            List of events
        """
        return self.get_multi(db, skip=skip, limit=limit, filters={"owner_id": owner_id})

    def get_by_calendar(self, db: Session, *, calendar_id: int, skip: int = 0, limit: int = 100) -> List[Event]:
        """
        Get events in a specific calendar.

        Args:
            db: Database session
            calendar_id: Calendar ID
            skip: Number of records to skip
            limit: Maximum number of records

        Returns:
            List of events
        """
        return self.get_multi(db, skip=skip, limit=limit, filters={"calendar_id": calendar_id})

    def get_user_accessible_event_ids(self, db: Session, user_id: int) -> Set[int]:
        """
        Get all event IDs accessible to a user (owned, invited, subscribed, calendar).

        Optimized single query to get all event IDs at once.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            Set of event IDs
        """
        event_ids = set()

        # Own events
        own_events = db.query(Event.id).filter(Event.owner_id == user_id).all()
        event_ids.update([e[0] for e in own_events])

        # Subscribed and invited events
        interactions = db.query(EventInteraction.event_id).filter(EventInteraction.user_id == user_id, or_(EventInteraction.interaction_type == "subscribed", and_(EventInteraction.interaction_type == "invited", EventInteraction.status == "accepted"))).all()
        event_ids.update([i[0] for i in interactions])

        # Calendar events (where user is owner or admin with accepted status)
        calendar_ids = db.query(CalendarMembership.calendar_id).filter(CalendarMembership.user_id == user_id, CalendarMembership.status == "accepted", CalendarMembership.role.in_(["owner", "admin"])).all()

        if calendar_ids:
            calendar_events = db.query(Event.id).filter(Event.calendar_id.in_([c[0] for c in calendar_ids])).all()
            event_ids.update([e[0] for e in calendar_events])

        return event_ids

    def get_conflicts(self, db: Session, *, user_id: int, start_date: datetime, end_date: Optional[datetime] = None, exclude_event_id: Optional[int] = None) -> List[Event]:
        """
        Find conflicting events for a user within a time range.

        Args:
            db: Database session
            user_id: User ID to check conflicts for
            start_date: Start datetime
            end_date: End datetime (optional)
            exclude_event_id: Event ID to exclude from check

        Returns:
            List of conflicting events
        """
        # Get all accessible event IDs for user
        event_ids = self.get_user_accessible_event_ids(db, user_id)

        if not event_ids:
            return []

        # Query events
        query = db.query(Event).filter(Event.id.in_(event_ids))

        if exclude_event_id:
            query = query.filter(Event.id != exclude_event_id)

        all_events = query.all()

        # Check for time overlaps
        conflicts = []
        for event in all_events:
            evt_start = event.start_date
            evt_end = event.end_date

            # Overlap detection logic
            has_conflict = False
            if not end_date and not evt_end:
                # Both are point events - check if within 5 minutes
                if abs((start_date - evt_start).total_seconds()) < 300:
                    has_conflict = True
            elif not end_date:
                # New event is point, existing has duration
                if evt_end and evt_start <= start_date <= evt_end:
                    has_conflict = True
            elif not evt_end:
                # New event has duration, existing is point
                if start_date <= evt_start <= end_date:
                    has_conflict = True
            else:
                # Both have duration - check overlap
                if max(start_date, evt_start) < min(end_date, evt_end):
                    has_conflict = True

            if has_conflict:
                conflicts.append(event)

        return conflicts


# Singleton instance
event = CRUDEvent(Event)
