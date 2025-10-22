"""
CRUD operations for EventCancellation model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import EventCancellation, EventCancellationView
from schemas import EventCancellationCreate


class CRUDEventCancellation(CRUDBase[EventCancellation, EventCancellationCreate, EventCancellationCreate]):
    """CRUD operations for EventCancellation"""

    def get_unviewed_by_user(self, db: Session, *, user_id: int) -> List[EventCancellation]:
        """
        Get all unviewed cancellations for a user.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            List of EventCancellation instances not yet viewed by the user
        """
        # Get cancellation IDs already viewed by this user
        viewed_cancellation_ids = db.query(EventCancellationView.cancellation_id).filter(
            EventCancellationView.user_id == user_id
        ).scalar_subquery()

        # Get all cancellations for this user that haven't been viewed
        cancellations = db.query(EventCancellation).filter(
            EventCancellation.event_id.in_(
                db.query(EventCancellation.event_id).distinct()
            ),
            ~EventCancellation.id.in_(viewed_cancellation_ids)
        ).all()

        return cancellations

    def mark_as_viewed(self, db: Session, *, cancellation_id: int, user_id: int) -> tuple[Optional[int], Optional[str]]:
        """
        Mark a cancellation as viewed by a user.

        Args:
            db: Database session
            cancellation_id: Cancellation ID
            user_id: User ID

        Returns:
            (view_id, None) if successful
            (None, error_message) if failed
        """
        # Check if cancellation exists
        cancellation = db.query(EventCancellation).filter(
            EventCancellation.id == cancellation_id
        ).first()

        if not cancellation:
            return None, "Cancellation not found"

        # Check if already viewed
        existing_view = db.query(EventCancellationView).filter(
            EventCancellationView.cancellation_id == cancellation_id,
            EventCancellationView.user_id == user_id
        ).first()

        if existing_view:
            return existing_view.id, None  # Already viewed, return existing view ID

        # Create view record
        view = EventCancellationView(
            cancellation_id=cancellation_id,
            user_id=user_id
        )
        db.add(view)
        db.commit()
        db.refresh(view)

        return view.id, None


# Singleton instance
event_cancellation = CRUDEventCancellation(EventCancellation)
