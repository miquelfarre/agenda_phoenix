"""
Event Interactions Router

Handles all event interaction endpoints including invitations and subscriptions.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from models import Event, User, EventInteraction, RecurringEventConfig
from schemas import EventInteractionCreate, EventInteractionBase, EventInteractionResponse
from dependencies import get_db


router = APIRouter(
    prefix="/interactions",
    tags=["interactions"]
)


@router.get("", response_model=List[EventInteractionResponse])
async def get_interactions(
    event_id: Optional[int] = None,
    user_id: Optional[int] = None,
    interaction_type: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get all interactions, optionally filtered by event_id, user_id, interaction_type, and status.

    Special hierarchical filtering for pending invitations:
    When interaction_type='invited' and status='pending', only show:
    - Base recurring events (event_type='recurring')
    - Regular events (not instances of recurring events)
    - Instances of recurring events ONLY if the parent recurring event invitation is NOT pending
    """
    query = db.query(EventInteraction)
    if event_id:
        query = query.filter(EventInteraction.event_id == event_id)
    if user_id:
        query = query.filter(EventInteraction.user_id == user_id)
    if interaction_type:
        query = query.filter(EventInteraction.interaction_type == interaction_type)
    if status:
        query = query.filter(EventInteraction.status == status)

    interactions = query.all()

    # Apply hierarchical filtering for pending invitations to recurring events
    if user_id and interaction_type == 'invited' and status == 'pending':
        # Get all events that have pending invitations for this user
        event_ids = [i.event_id for i in interactions]

        if event_ids:
            # Query event details to check for recurring event hierarchy
            events = db.query(Event).filter(Event.id.in_(event_ids)).all()
            events_map = {e.id: e for e in events}

            # Find recurring event base IDs that have pending invitations
            pending_parent_ids = set()
            for interaction in interactions:
                event = events_map.get(interaction.event_id)
                if event and event.event_type == 'recurring':
                    # This is a base recurring event with pending invitation
                    # Find the recurring config ID
                    config = db.query(RecurringEventConfig).filter(
                        RecurringEventConfig.event_id == event.id
                    ).first()
                    if config:
                        pending_parent_ids.add(config.id)

            # Filter out instances whose parent recurring event has a pending invitation
            filtered_interactions = []
            for interaction in interactions:
                event = events_map.get(interaction.event_id)
                if event:
                    # If it's an instance of a recurring event, check if parent is pending
                    if event.parent_recurring_event_id:
                        # This is an instance - only include if parent is NOT in pending list
                        if event.parent_recurring_event_id not in pending_parent_ids:
                            filtered_interactions.append(interaction)
                    else:
                        # Not an instance (it's either a base recurring event or a regular event)
                        filtered_interactions.append(interaction)

            return filtered_interactions

    return interactions


@router.get("/{interaction_id}", response_model=EventInteractionResponse)
async def get_interaction(interaction_id: int, db: Session = Depends(get_db)):
    """Get a single interaction by ID"""
    interaction = db.query(EventInteraction).filter(EventInteraction.id == interaction_id).first()
    if not interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")
    return interaction


@router.post("", response_model=EventInteractionResponse, status_code=201)
async def create_interaction(interaction: EventInteractionCreate, db: Session = Depends(get_db)):
    """Create a new event interaction"""
    # Verify event exists
    event = db.query(Event).filter(Event.id == interaction.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Verify user exists
    user = db.query(User).filter(User.id == interaction.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if interaction already exists (unique constraint)
    existing = db.query(EventInteraction).filter(
        EventInteraction.event_id == interaction.event_id,
        EventInteraction.user_id == interaction.user_id
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail="User already has an interaction with this event"
        )

    db_interaction = EventInteraction(**interaction.dict())
    db.add(db_interaction)
    db.commit()
    db.refresh(db_interaction)
    return db_interaction


@router.put("/{interaction_id}", response_model=EventInteractionResponse)
async def update_interaction(
    interaction_id: int,
    interaction: EventInteractionBase,
    db: Session = Depends(get_db)
):
    """Update an existing interaction (typically to change type or status)"""
    db_interaction = db.query(EventInteraction).filter(
        EventInteraction.id == interaction_id
    ).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    for key, value in interaction.dict().items():
        setattr(db_interaction, key, value)

    db.commit()
    db.refresh(db_interaction)
    return db_interaction


@router.patch("/{interaction_id}", response_model=EventInteractionResponse)
async def patch_interaction(
    interaction_id: int,
    interaction: EventInteractionBase,
    db: Session = Depends(get_db)
):
    """
    Partially update an existing interaction (typically to change status) - PATCH alias for PUT

    Special cascade behavior for recurring events:
    - If rejecting a base recurring event invitation (event_type='recurring' and status='rejected'),
      automatically reject all pending invitations to instance events of that recurring event
    """
    db_interaction = db.query(EventInteraction).filter(
        EventInteraction.id == interaction_id
    ).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    # Get the event to check if it's a recurring event
    event = db.query(Event).filter(Event.id == db_interaction.event_id).first()

    # Only update fields that are explicitly provided (exclude None values)
    for key, value in interaction.dict(exclude_unset=True).items():
        if value is not None:
            setattr(db_interaction, key, value)

    db.commit()
    db.refresh(db_interaction)

    # Cascade rejection logic: if rejecting a base recurring event invitation
    if (event and
        event.event_type == 'recurring' and
        db_interaction.interaction_type == 'invited' and
        db_interaction.status == 'rejected'):

        # Find the recurring config for this event
        config = db.query(RecurringEventConfig).filter(
            RecurringEventConfig.event_id == event.id
        ).first()

        if config:
            # Find all instance events of this recurring event
            instance_events = db.query(Event).filter(
                Event.parent_recurring_event_id == config.id
            ).all()

            instance_event_ids = [e.id for e in instance_events]

            if instance_event_ids:
                # Update all pending invitations to these instances to 'rejected'
                db.query(EventInteraction).filter(
                    EventInteraction.event_id.in_(instance_event_ids),
                    EventInteraction.user_id == db_interaction.user_id,
                    EventInteraction.interaction_type == 'invited',
                    EventInteraction.status == 'pending'
                ).update(
                    {'status': 'rejected'},
                    synchronize_session=False
                )
                db.commit()

    return db_interaction


@router.delete("/{interaction_id}")
async def delete_interaction(interaction_id: int, db: Session = Depends(get_db)):
    """Delete an interaction"""
    db_interaction = db.query(EventInteraction).filter(
        EventInteraction.id == interaction_id
    ).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    db.delete(db_interaction)
    db.commit()
    return {"message": "Interaction deleted successfully", "id": interaction_id}
