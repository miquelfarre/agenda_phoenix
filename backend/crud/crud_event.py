"""
CRUD operations for Event model
"""

from datetime import datetime, timezone
from typing import List, Optional, Set, Tuple

from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import AppBan, CalendarMembership, Event, EventCancellation, EventInteraction, User
from schemas import EventBase, EventCreate


class CRUDEvent(CRUDBase[Event, EventCreate, EventBase]):
    """CRUD operations for Event model with specific methods"""

    def exists_event(self, db: Session, *, event_id: int) -> bool:
        """Check if event exists (optimized)"""
        return db.query(Event.id).filter(Event.id == event_id).first() is not None

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

    def get_multi_filtered(
        self,
        db: Session,
        *,
        owner_id: Optional[int] = None,
        calendar_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "start_date",
        order_dir: str = "asc"
    ) -> List[Event]:
        """
        Get multiple events with filters and pagination

        Args:
            owner_id: Filter by owner ID
            calendar_id: Filter by calendar ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        from sqlalchemy.orm import noload

        filters = {}
        if owner_id is not None:
            filters["owner_id"] = owner_id
        if calendar_id is not None:
            filters["calendar_id"] = calendar_id

        # Use noload for interactions relationship - list endpoint doesn't need them
        query = db.query(self.model).options(noload(self.model.interactions))

        # Apply filters
        for key, value in filters.items():
            if hasattr(self.model, key):
                query = query.filter(getattr(self.model, key) == value)

        # Apply ordering
        if order_by and hasattr(self.model, order_by):
            order_col = getattr(self.model, order_by)
        else:
            order_col = self.model.id

        if order_dir.lower() == "desc":
            query = query.order_by(order_col.desc())
        else:
            query = query.order_by(order_col.asc())

        # Apply pagination
        return query.offset(skip).limit(limit).all()

    def check_user_access(self, db: Session, *, event_id: int, user_id: int) -> bool:
        """
        Check if a user has access to an event.

        Access granted if user is:
        - Event owner
        - Has EventInteraction (invited or subscribed)
        - Member of calendar containing the event (owner/admin with accepted status)
        """
        event = self.get(db, id=event_id)
        if not event:
            return False

        # Check 1: Is owner
        if event.owner_id == user_id:
            return True

        # Check 2: Has EventInteraction
        has_interaction = db.query(EventInteraction.id).filter(
            EventInteraction.event_id == event_id,
            EventInteraction.user_id == user_id
        ).first() is not None
        if has_interaction:
            return True

        # Check 3: Member of calendar containing the event
        if event.calendar_id:
            has_calendar_access = db.query(CalendarMembership.id).filter(
                CalendarMembership.calendar_id == event.calendar_id,
                CalendarMembership.user_id == user_id,
                CalendarMembership.status == "accepted",
                CalendarMembership.role.in_(["owner", "admin"])
            ).first() is not None
            if has_calendar_access:
                return True

        return False

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

    def create_with_validation(
        self,
        db: Session,
        *,
        obj_in: EventCreate
    ) -> Tuple[Optional[Event], Optional[str], Optional[dict]]:
        """
        Create a new event with validation

        Returns:
            (Event, None, None) if successful
            (None, error_message, error_detail_dict) if validation fails
        """
        # Validate owner exists
        owner_exists = db.query(User.id).filter(User.id == obj_in.owner_id).first() is not None
        if not owner_exists:
            return None, "Owner user not found", None

        # Check if owner is banned - return detailed info
        ban = db.query(AppBan).filter(AppBan.user_id == obj_in.owner_id).first()
        if ban:
            ban_detail = {
                "message": "User is banned from the application",
                "reason": ban.reason,
                "banned_at": ban.banned_at.isoformat() if ban.banned_at else None
            }
            return None, "User is banned from the application", ban_detail

        # Prepare event data
        event_data = obj_in.model_dump()

        # Ensure dates are timezone-aware
        if event_data["start_date"].tzinfo is None:
            event_data["start_date"] = event_data["start_date"].replace(tzinfo=timezone.utc)

        # Create event directly from dict
        db_event = Event(**event_data)
        db.add(db_event)
        db.commit()
        db.refresh(db_event)
        return db_event, None, None

    def update_with_validation(
        self,
        db: Session,
        *,
        event_id: int,
        obj_in
    ) -> Tuple[Optional[Event], Optional[str]]:
        """
        Update an event with validation

        Args:
            obj_in: EventCreate or EventUpdate schema

        Returns:
            (Event, None) if successful
            (None, error_message) if validation fails
        """
        # Validate event exists
        db_event = self.get(db, id=event_id)
        if not db_event:
            return None, "Event not found"

        # Prepare event data - exclude unset fields for partial updates
        event_data = obj_in.model_dump(exclude_unset=True)

        # If owner changed, validate new owner exists
        if "owner_id" in event_data and event_data["owner_id"] != db_event.owner_id:
            owner_exists = db.query(User.id).filter(User.id == event_data["owner_id"]).first() is not None
            if not owner_exists:
                return None, "Owner user not found"

        # Ensure dates are timezone-aware
        if "start_date" in event_data and event_data["start_date"] is not None:
            if event_data["start_date"].tzinfo is None:
                event_data["start_date"] = event_data["start_date"].replace(tzinfo=timezone.utc)

        # Update event
        for key, value in event_data.items():
            setattr(db_event, key, value)

        db.add(db_event)
        db.commit()
        db.refresh(db_event)
        return db_event, None

    def delete_with_cancellations(
        self,
        db: Session,
        *,
        event_id: int,
        cancelled_by_user_id: Optional[int] = None,
        cancellation_message: Optional[str] = None
    ) -> Tuple[Optional[int], Optional[str]]:
        """
        Delete an event and optionally create cancellation notifications.

        For recurring events: deleting the base event also deletes all instances.

        Returns:
            (deleted_count, None) if successful
            (None, error_message) if validation fails
        """
        db_event = self.get(db, id=event_id)
        if not db_event:
            return None, "Event not found"

        events_to_delete = [db_event]

        # If it's a recurring base event, get all instances
        if db_event.event_type == "recurring":
            instances = db.query(Event).filter(
                Event.parent_recurring_event_id == event_id
            ).all()
            events_to_delete.extend(instances)

        # Create cancellation records if requested
        if cancelled_by_user_id:
            for event in events_to_delete:
                # Get all users with interactions to this event
                interactions = db.query(EventInteraction).filter(
                    EventInteraction.event_id == event.id
                ).all()

                if interactions:
                    # Create cancellation record
                    cancellation = EventCancellation(
                        event_id=event.id,
                        event_name=event.name,
                        cancelled_by_user_id=cancelled_by_user_id,
                        message=cancellation_message
                    )
                    db.add(cancellation)
                    db.flush()

        # Delete all events
        for event in events_to_delete:
            db.delete(event)

        db.commit()
        return len(events_to_delete), None

    def get_available_invitees(self, db: Session, *, event_id: int) -> List[tuple]:
        """
        Get list of users available to invite to an event.

        Excludes:
        - Event owner
        - Already invited users
        - Blocked users (mutual blocks with owner)
        - Public users

        Returns:
            List of tuples (User, Contact)
        """
        from models import Contact, EventInteraction, User, UserBlock

        db_event = self.get(db, id=event_id)
        if not db_event:
            return []

        # Get user IDs that already have interactions with this event
        invited_user_ids_subquery = db.query(EventInteraction.user_id).filter(
            EventInteraction.event_id == event_id
        ).scalar_subquery()

        # Get user IDs that have mutual blocks with the event owner
        blocked_user_ids_subquery = db.query(UserBlock.blocked_user_id).filter(
            UserBlock.blocker_user_id == db_event.owner_id
        ).union(
            db.query(UserBlock.blocker_user_id).filter(
                UserBlock.blocked_user_id == db_event.owner_id
            )
        ).scalar_subquery()

        # Get all users NOT in the invited list, NOT the owner, NOT blocked, NOT public
        results = db.query(User, Contact).outerjoin(
            Contact, User.contact_id == Contact.id
        ).filter(
            User.id != db_event.owner_id,
            User.is_public == False,
            ~User.id.in_(invited_user_ids_subquery),
            ~User.id.in_(blocked_user_ids_subquery)
        ).all()

        return results

    def get_instances_by_parent_config(self, db: Session, *, parent_config_id: int) -> List[Event]:
        """
        Get all instance events for a recurring event configuration.

        Args:
            db: Database session
            parent_config_id: Recurring event configuration ID

        Returns:
            List of instance events
        """
        return db.query(Event).filter(Event.parent_recurring_event_id == parent_config_id).all()

    def get_event_ids_by_owner(self, db: Session, *, owner_id: int) -> List[int]:
        """
        Get list of event IDs owned by a user.

        Args:
            db: Database session
            owner_id: Owner user ID

        Returns:
            List of event IDs
        """
        results = db.query(Event.id).filter(Event.owner_id == owner_id).all()
        return [eid for (eid,) in results]

    def get_event_ids_by_calendars(self, db: Session, *, calendar_ids: List[int]) -> List[int]:
        """
        Get list of event IDs in specified calendars.

        Args:
            db: Database session
            calendar_ids: List of calendar IDs

        Returns:
            List of event IDs
        """
        if not calendar_ids:
            return []
        results = db.query(Event.id).filter(Event.calendar_id.in_(calendar_ids)).all()
        return [eid for (eid,) in results]

    def get_by_ids_in_date_range(self, db: Session, *, event_ids: List[int], from_date, to_date, search: Optional[str] = None) -> List[Event]:
        """
        Get events by IDs filtered by date range and optional search.

        Args:
            db: Database session
            event_ids: List of event IDs
            from_date: Start date
            to_date: End date
            search: Optional search string for event name

        Returns:
            List of events
        """
        if not event_ids:
            return []

        query = db.query(Event).filter(
            Event.id.in_(event_ids),
            Event.start_date >= from_date,
            Event.start_date <= to_date
        )

        if search:
            like = f"%{search}%"
            query = query.filter(Event.name.ilike(like))

        return query.order_by(Event.start_date).all()

    def get_upcoming_events_by_owner(self, db: Session, *, owner_id: int, limit: int = 10) -> List[Event]:
        """
        Get upcoming events for a specific owner (used for public users).

        Args:
            db: Database session
            owner_id: User ID of the owner
            limit: Maximum number of events to return (default 10)

        Returns:
            List of upcoming events ordered by start_date
        """
        now = datetime.now(timezone.utc)

        return db.query(Event).filter(
            Event.owner_id == owner_id,
            Event.start_date >= now
        ).order_by(Event.start_date.asc()).limit(limit).all()


# Singleton instance
event = CRUDEvent(Event)
