"""
CRUD operations for RecurringEventConfig model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Event, RecurringEventConfig
from schemas import RecurringEventConfigBase, RecurringEventConfigCreate


class CRUDRecurringConfig(CRUDBase[RecurringEventConfig, RecurringEventConfigCreate, RecurringEventConfigBase]):
    """CRUD operations for RecurringEventConfig"""

    def get_by_event(self, db: Session, *, event_id: int) -> Optional[RecurringEventConfig]:
        """Get recurring config for a specific event"""
        return db.query(self.model).filter(self.model.event_id == event_id).first()

    def get_multi_filtered(
        self,
        db: Session,
        *,
        event_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "id",
        order_dir: str = "asc"
    ) -> List[RecurringEventConfig]:
        """
        Get multiple recurring configs with filters and pagination

        Args:
            event_id: Filter by event ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        filters = {}
        if event_id is not None:
            filters["event_id"] = event_id

        return self.get_multi(
            db,
            skip=skip,
            limit=limit,
            order_by=order_by,
            order_dir=order_dir,
            filters=filters
        )

    def exists_for_event(self, db: Session, *, event_id: int) -> bool:
        """Check if recurring config exists for event (optimized)"""
        return db.query(self.model.id).filter(self.model.event_id == event_id).first() is not None

    def create_with_validation(
        self,
        db: Session,
        *,
        obj_in: RecurringEventConfigCreate
    ) -> tuple[Optional[RecurringEventConfig], Optional[str]]:
        """
        Create a new recurring config with validation

        Returns:
            (RecurringEventConfig, None) if successful
            (None, error_message) if validation fails
        """
        # Validate event exists
        event_exists = db.query(Event.id).filter(Event.id == obj_in.event_id).first() is not None
        if not event_exists:
            return None, "Event not found"

        # Check if config already exists for this event
        if self.exists_for_event(db, event_id=obj_in.event_id):
            return None, "Event already has a recurring config"

        # Create config
        db_config = self.create(db, obj_in=obj_in)
        return db_config, None

    def get_configs_by_event_ids(self, db: Session, *, event_ids: List[int]) -> dict:
        """
        Get recurring configs for multiple events as a map.

        Args:
            db: Database session
            event_ids: List of event IDs

        Returns:
            Dict mapping event_id -> config_id
        """
        if not event_ids:
            return {}

        results = db.query(RecurringEventConfig.event_id, RecurringEventConfig.id).filter(
            RecurringEventConfig.event_id.in_(event_ids)
        ).all()

        return {event_id: config_id for event_id, config_id in results}


# Singleton instance
recurring_config = CRUDRecurringConfig(RecurringEventConfig)
