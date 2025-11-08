"""
CRUD operations for EventBan model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Event, EventBan, User
from schemas import EventBanCreate, EventBanResponse


class CRUDEventBan(CRUDBase[EventBan, EventBanCreate, EventBanResponse]):
    """CRUD operations for EventBan"""

    def get_by_event(self, db: Session, *, event_id: int) -> List[EventBan]:
        """Get all bans for a specific event"""
        return self.get_multi(db, filters={"event_id": event_id})

    def get_by_user(self, db: Session, *, user_id: int) -> List[EventBan]:
        """Get all event bans for a specific user"""
        return self.get_multi(db, filters={"user_id": user_id})

    def exists_ban(self, db: Session, *, event_id: int, user_id: int) -> bool:
        """Check if a user is banned from an event (optimized)"""
        return db.query(EventBan.id).filter(EventBan.event_id == event_id, EventBan.user_id == user_id).first() is not None

    def get_multi_filtered(self, db: Session, *, event_id: Optional[int] = None, user_id: Optional[int] = None, skip: int = 0, limit: int = 50, order_by: str = "id", order_dir: str = "asc") -> List[EventBan]:
        """
        Get multiple event bans with filters and pagination

        Args:
            event_id: Filter by event ID
            user_id: Filter by banned user ID
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

    def create_with_validation(self, db: Session, *, obj_in: EventBanCreate) -> tuple[Optional[EventBan], Optional[str]]:
        """
        Create a new event ban with validation

        Returns:
            (EventBan, None) if successful
            (None, error_message) if validation fails
        """
        # Batch query: verify event exists
        event_exists = db.query(Event.id).filter(Event.id == obj_in.event_id).first() is not None
        if not event_exists:
            return None, "Event not found"

        # Batch query: verify both users exist in single query
        user_ids = [obj_in.user_id, obj_in.banned_by]
        existing_users = db.query(User.id).filter(User.id.in_(user_ids)).all()
        existing_ids = {user.id for user in existing_users}

        # Validate banned user exists
        if obj_in.user_id not in existing_ids:
            return None, "User not found"

        # Validate banner user exists
        if obj_in.banned_by not in existing_ids:
            return None, "Banner user not found"

        # Check if ban already exists (optimized query)
        if self.exists_ban(db, event_id=obj_in.event_id, user_id=obj_in.user_id):
            return None, "User is already banned from this event"

        # Create ban
        db_ban = self.create(db, obj_in=obj_in)
        return db_ban, None


# Singleton instance
event_ban = CRUDEventBan(EventBan)
