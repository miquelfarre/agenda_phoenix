"""
CRUD operations for EventInteraction model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Contact, Event, EventInteraction, User
from schemas import EventInteractionCreate, EventInteractionUpdate


class CRUDEventInteraction(CRUDBase[EventInteraction, EventInteractionCreate, EventInteractionUpdate]):
    """CRUD operations for EventInteraction model with specific methods"""

    def get_by_event(self, db: Session, *, event_id: int, interaction_type: Optional[str] = None, status: Optional[str] = None) -> List[EventInteraction]:
        """
        Get all interactions for an event.

        Args:
            db: Database session
            event_id: Event ID
            interaction_type: Optional filter by type ('invited', 'subscribed', 'joined')
            status: Optional filter by status ('pending', 'accepted', 'rejected')

        Returns:
            List of interactions
        """
        filters = {"event_id": event_id}
        if interaction_type:
            filters["interaction_type"] = interaction_type
        if status:
            filters["status"] = status

        return self.get_multi(db, filters=filters)

    def get_by_user(self, db: Session, *, user_id: int, interaction_type: Optional[str] = None, status: Optional[str] = None) -> List[EventInteraction]:
        """
        Get all interactions for a user.

        Args:
            db: Database session
            user_id: User ID
            interaction_type: Optional filter by type
            status: Optional filter by status

        Returns:
            List of interactions
        """
        filters = {"user_id": user_id}
        if interaction_type:
            filters["interaction_type"] = interaction_type
        if status:
            filters["status"] = status

        return self.get_multi(db, filters=filters)

    def get_interaction(self, db: Session, *, event_id: int, user_id: int) -> Optional[EventInteraction]:
        """
        Get interaction for specific event-user pair.

        Args:
            db: Database session
            event_id: Event ID
            user_id: User ID

        Returns:
            Interaction or None
        """
        return db.query(EventInteraction).filter(EventInteraction.event_id == event_id, EventInteraction.user_id == user_id).first()

    def exists_interaction(self, db: Session, *, event_id: int, user_id: int) -> bool:
        """
        Check if interaction exists for event-user pair.

        Args:
            db: Database session
            event_id: Event ID
            user_id: User ID

        Returns:
            True if exists, False otherwise
        """
        return db.query(db.query(EventInteraction).filter(EventInteraction.event_id == event_id, EventInteraction.user_id == user_id).exists()).scalar()

    def get_enriched_by_event(self, db: Session, event_id: int) -> List[tuple[EventInteraction, User, Optional[Contact]]]:
        """
        Get event interactions with user information (enriched).

        Single JOIN query to avoid N+1 problem.

        Args:
            db: Database session
            event_id: Event ID

        Returns:
            List of (EventInteraction, User, Contact) tuples
        """
        return db.query(EventInteraction, User, Contact).outerjoin(User, EventInteraction.user_id == User.id).outerjoin(Contact, User.contact_id == Contact.id).filter(EventInteraction.event_id == event_id).all()

    def get_enriched_by_user(self, db: Session, user_id: int, *, interaction_type: Optional[str] = None, status: Optional[str] = None) -> List[tuple[EventInteraction, Event]]:
        """
        Get user interactions with event information (enriched).

        Single JOIN query to avoid N+1 problem.

        Args:
            db: Database session
            user_id: User ID
            interaction_type: Optional filter by type
            status: Optional filter by status

        Returns:
            List of (EventInteraction, Event) tuples
        """
        query = db.query(EventInteraction, Event).join(Event, EventInteraction.event_id == Event.id).filter(EventInteraction.user_id == user_id)

        if interaction_type:
            query = query.filter(EventInteraction.interaction_type == interaction_type)
        if status:
            query = query.filter(EventInteraction.status == status)

        return query.all()

    def get_user_interactions_map(self, db: Session, *, user_id: int, event_ids: List[int]) -> dict[int, EventInteraction]:
        """
        Get user's interactions for multiple events as a map.

        Efficient batch query instead of multiple get_interaction() calls.

        Args:
            db: Database session
            user_id: User ID
            event_ids: List of event IDs

        Returns:
            Dictionary mapping event_id -> EventInteraction
        """
        interactions = db.query(EventInteraction).filter(EventInteraction.user_id == user_id, EventInteraction.event_id.in_(event_ids)).all()

        return {i.event_id: i for i in interactions}


# Singleton instance
event_interaction = CRUDEventInteraction(EventInteraction)
