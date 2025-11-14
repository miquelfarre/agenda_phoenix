"""
CRUD operations for EventMembership model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Event, EventMembership, User
from schemas import EventMembershipCreate


class CRUDEventMembership(CRUDBase[EventMembership, EventMembershipCreate, EventMembershipCreate]):
    """CRUD operations for EventMembership"""

    def get_by_event(self, db: Session, *, event_id: int) -> List[EventMembership]:
        """Get all memberships for a specific event"""
        return self.get_multi(db, filters={"event_id": event_id})

    def get_by_user(self, db: Session, *, user_id: int) -> List[EventMembership]:
        """Get all event memberships for a specific user"""
        return self.get_multi(db, filters={"user_id": user_id})

    def get_by_event_and_user(self, db: Session, *, event_id: int, user_id: int) -> Optional[EventMembership]:
        """Get membership for a specific event-user pair"""
        return db.query(EventMembership).filter(
            EventMembership.event_id == event_id,
            EventMembership.user_id == user_id
        ).first()

    def get_multi_filtered(self, db: Session, *, event_id: Optional[int] = None, user_id: Optional[int] = None, skip: int = 0, limit: int = 50, order_by: str = "id", order_dir: str = "asc") -> List[EventMembership]:
        """
        Get multiple event memberships with filters and pagination

        Args:
            event_id: Filter by event ID
            user_id: Filter by user ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        filters = {}
        if event_id is not None:
            filters["event_id"] = event_id
        if user_id is not None:
            filters["user_id"] = user_id

        return self.get_multi(db, skip=skip, limit=limit, order_by=order_by, order_dir=order_dir, filters=filters)

    def exists_membership(self, db: Session, *, event_id: int, user_id: int) -> bool:
        """Check if membership exists for event-user pair (optimized)"""
        return db.query(EventMembership.id).filter(EventMembership.event_id == event_id, EventMembership.user_id == user_id).first() is not None

    def create_with_validation(self, db: Session, *, obj_in: EventMembershipCreate) -> tuple[Optional[EventMembership], Optional[str]]:
        """
        Create a new event membership with validation

        Returns:
            (EventMembership, None) if successful
            (None, error_message) if validation fails
        """
        # Validate event exists
        event_exists = db.query(Event.id).filter(Event.id == obj_in.event_id).first() is not None
        if not event_exists:
            return None, "Event not found"

        # Validate user exists
        user_exists = db.query(User.id).filter(User.id == obj_in.user_id).first() is not None
        if not user_exists:
            return None, "User not found"

        # Check if membership already exists
        if self.exists_membership(db, event_id=obj_in.event_id, user_id=obj_in.user_id):
            return None, "User is already a member of this event"

        # Create membership
        db_membership = self.create(db, obj_in=obj_in)
        return db_membership, None


# Singleton instance
event_membership = CRUDEventMembership(EventMembership)
