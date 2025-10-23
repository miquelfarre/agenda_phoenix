"""
CRUD operations for EventInteraction model
"""

from typing import List, Optional, Union

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Contact, Event, EventInteraction, RecurringEventConfig, User
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
        filters = {"event_id": event_id, "user_id": user_id}
        results = self.get_multi(db, filters=filters, limit=1)
        return results[0] if results else None

    def exists_interaction(self, db: Session, *, event_id: int, user_id: int) -> bool:
        """
        Check if interaction exists for event-user pair (optimized).

        Args:
            db: Database session
            event_id: Event ID
            user_id: User ID

        Returns:
            True if exists, False otherwise
        """
        return db.query(EventInteraction.id).filter(EventInteraction.event_id == event_id, EventInteraction.user_id == user_id).first() is not None

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

    def bulk_reject_pending_instances(self, db: Session, *, instance_event_ids: List[int], user_id: int) -> int:
        """
        Bulk update pending invitations to rejected status for instance events.

        Used when rejecting a recurring event base invitation - cascades to instances.

        Args:
            db: Database session
            instance_event_ids: List of instance event IDs
            user_id: User ID

        Returns:
            Number of rows updated
        """
        if not instance_event_ids:
            return 0

        result = db.query(EventInteraction).filter(
            EventInteraction.event_id.in_(instance_event_ids),
            EventInteraction.user_id == user_id,
            EventInteraction.interaction_type == "invited",
            EventInteraction.status == "pending"
        ).update({"status": "rejected"}, synchronize_session=False)
        db.commit()
        return result

    def get_event_ids_by_user_type_status(
        self,
        db: Session,
        *,
        user_id: int,
        interaction_type: str,
        status: Optional[str] = None
    ) -> List[int]:
        """
        Get list of event IDs for a user filtered by interaction type and optional status.

        Args:
            db: Database session
            user_id: User ID
            interaction_type: Interaction type ('joined', 'subscribed', 'invited')
            status: Optional status filter ('accepted', 'pending', 'rejected')

        Returns:
            List of event IDs
        """
        query = db.query(EventInteraction.event_id).filter(
            EventInteraction.user_id == user_id,
            EventInteraction.interaction_type == interaction_type
        )

        if status:
            query = query.filter(EventInteraction.status == status)

        results = query.all()
        return [eid for (eid,) in results]

    def get_invitations_by_user_and_events(
        self,
        db: Session,
        *,
        user_id: int,
        event_ids: List[int]
    ) -> dict:
        """
        Get invitation status map for a user across multiple events.

        Args:
            db: Database session
            user_id: User ID
            event_ids: List of event IDs

        Returns:
            Dict mapping event_id -> status
        """
        if not event_ids:
            return {}

        results = db.query(EventInteraction.event_id, EventInteraction.status).filter(
            EventInteraction.event_id.in_(event_ids),
            EventInteraction.user_id == user_id,
            EventInteraction.interaction_type == "invited"
        ).all()

        return {event_id: status for event_id, status in results}

    def get_by_event_ids_and_user(self, db: Session, *, event_ids: List[int], user_id: int) -> List[EventInteraction]:
        """
        Get all interactions for a user across multiple events.

        Args:
            db: Database session
            event_ids: List of event IDs
            user_id: User ID

        Returns:
            List of EventInteraction objects
        """
        if not event_ids:
            return []

        return db.query(EventInteraction).filter(
            EventInteraction.event_id.in_(event_ids),
            EventInteraction.user_id == user_id
        ).all()

    def get_multi_with_optional_enrichment(
        self,
        db: Session,
        *,
        event_id: Optional[int] = None,
        user_id: Optional[int] = None,
        interaction_type: Optional[str] = None,
        status: Optional[str] = None,
        enriched: bool = False,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "created_at",
        order_dir: str = "desc"
    ) -> Union[List[EventInteraction], List[tuple], List[dict]]:
        """
        Get interactions with optional filters, enrichment, and hierarchical filtering.

        Special hierarchical filtering for pending invitations:
        When interaction_type='invited' and status='pending', only show:
        - Base recurring events (event_type='recurring')
        - Regular events (not instances of recurring events)
        - Instances of recurring events ONLY if the parent recurring event invitation is NOT pending

        Args:
            db: Database session
            event_id: Filter by event ID
            user_id: Filter by user ID
            interaction_type: Filter by interaction type
            status: Filter by status
            enriched: Return enriched data with event information
            skip: Number of records to skip (pagination)
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)

        Returns:
            - If enriched=False: List of EventInteraction
            - If enriched=True with JOIN: List of tuples (EventInteraction, Event) or List of dicts for enriched response
        """
        # OPTIMIZATION: Use JOIN from the start if enriched=True or if we need hierarchical filtering
        needs_event_data = enriched or (user_id and interaction_type == "invited" and status == "pending")

        if needs_event_data:
            # Single optimized query with JOIN
            query = db.query(EventInteraction, Event).join(Event, EventInteraction.event_id == Event.id)
        else:
            query = db.query(EventInteraction)

        # Apply filters
        if event_id:
            query = query.filter(EventInteraction.event_id == event_id)
        if user_id:
            query = query.filter(EventInteraction.user_id == user_id)
        if interaction_type:
            query = query.filter(EventInteraction.interaction_type == interaction_type)
        if status:
            query = query.filter(EventInteraction.status == status)

        # OPTIMIZATION: Apply hierarchical filtering in SQL instead of Python
        if user_id and interaction_type == "invited" and status == "pending":
            # Subquery to get config IDs of base recurring events where THIS USER has a pending invitation
            pending_recurring_config_subquery = (
                select(RecurringEventConfig.id)
                .join(Event, RecurringEventConfig.event_id == Event.id)
                .join(EventInteraction, EventInteraction.event_id == Event.id)
                .where(Event.event_type == "recurring", EventInteraction.user_id == user_id, EventInteraction.interaction_type == "invited", EventInteraction.status == "pending")
            )

            # Filter: Include all non-instances OR instances where parent config is NOT in pending list
            query = query.filter(or_(Event.parent_recurring_event_id.is_(None), ~Event.parent_recurring_event_id.in_(pending_recurring_config_subquery)))

        # Apply ordering
        order_col = getattr(EventInteraction, order_by) if order_by and hasattr(EventInteraction, order_by) else EventInteraction.created_at
        if order_dir and order_dir.lower() == "asc":
            query = query.order_by(order_col.asc())
        else:
            query = query.order_by(order_col.desc())

        # Apply pagination
        query = query.offset(max(0, skip)).limit(max(1, min(200, limit)))

        # Execute query
        if needs_event_data:
            results = query.all()  # List of (EventInteraction, Event) tuples

            if enriched:
                # Build enriched responses directly from joined data
                enriched_interactions = []
                for interaction, event in results:
                    enriched_interactions.append(
                        {
                            "id": interaction.id,
                            "event_id": interaction.event_id,
                            "user_id": interaction.user_id,
                            "interaction_type": interaction.interaction_type,
                            "status": interaction.status,
                            "role": interaction.role,
                            "invited_by_user_id": interaction.invited_by_user_id,
                            "invited_via_group_id": interaction.invited_via_group_id,
                            "note": interaction.note,
                            "rejection_message": interaction.rejection_message,
                            "read_at": interaction.read_at,
                            "is_new": interaction.is_new,
                            "created_at": interaction.created_at,
                            "updated_at": interaction.updated_at,
                            "event_name": event.name,
                            "event_start_date": event.start_date,
                            "event_type": event.event_type,
                            "event_start_date_formatted": event.start_date.strftime("%Y-%m-%d %H:%M"),
                        }
                    )
                return enriched_interactions
            else:
                # Return only interactions (extract from tuples)
                return [interaction for interaction, _ in results]
        else:
            interactions = query.all()
            return interactions

    def mark_as_read(self, db: Session, *, interaction_id: int) -> tuple[Optional[EventInteraction], Optional[str]]:
        """
        Mark an interaction as read by setting read_at to current timestamp.

        Args:
            db: Database session
            interaction_id: Interaction ID

        Returns:
            (EventInteraction, None) if successful
            (None, error_message) if failed
        """
        from datetime import datetime, timezone

        interaction = self.get(db, id=interaction_id)
        if not interaction:
            return None, "Interaction not found"

        # Set read_at to current timestamp
        interaction.read_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(interaction)

        return interaction, None

    def get_invitation_stats(self, db: Session, *, event_id: int) -> dict:
        """
        Get invitation statistics for an event.

        Args:
            db: Database session
            event_id: Event ID

        Returns:
            Dictionary with invitation statistics:
            - total_invited: total number of invited users
            - accepted: number of accepted invitations
            - pending: number of pending invitations
            - rejected: number of rejected invitations
        """
        # Get all invitations for this event
        invitations = db.query(EventInteraction).filter(
            EventInteraction.event_id == event_id,
            EventInteraction.interaction_type == "invited"
        ).all()

        total_invited = len(invitations)
        accepted = sum(1 for i in invitations if i.status == "accepted")
        pending = sum(1 for i in invitations if i.status == "pending")
        rejected = sum(1 for i in invitations if i.status == "rejected")

        return {
            "total_invited": total_invited,
            "accepted": accepted,
            "pending": pending,
            "rejected": rejected
        }


# Singleton instance
event_interaction = CRUDEventInteraction(EventInteraction)
