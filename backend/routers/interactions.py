"""
Event Interactions Router

Handles all event interaction endpoints including invitations and subscriptions.
"""

from typing import List, Optional, Union

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from dependencies import check_user_not_banned, check_users_not_blocked, get_db
from models import Event, EventInteraction, RecurringEventConfig, User
from schemas import EventInteractionBase, EventInteractionCreate, EventInteractionResponse, EventInteractionUpdate, EventInteractionWithEventResponse

router = APIRouter(prefix="/interactions", tags=["interactions"])


@router.get("", response_model=List[Union[EventInteractionWithEventResponse, EventInteractionResponse]])
async def get_interactions(
    event_id: Optional[int] = None, user_id: Optional[int] = None, interaction_type: Optional[str] = None, status: Optional[str] = None, enriched: bool = False, limit: int = 50, offset: int = 0, order_by: Optional[str] = "created_at", order_dir: str = "desc", db: Session = Depends(get_db)
):
    """
    Get all interactions, optionally filtered by event_id, user_id, interaction_type, and status.

    Special hierarchical filtering for pending invitations:
    When interaction_type='invited' and status='pending', only show:
    - Base recurring events (event_type='recurring')
    - Regular events (not instances of recurring events)
    - Instances of recurring events ONLY if the parent recurring event invitation is NOT pending
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
        query = query.filter(or_(Event.parent_recurring_event_id.is_(None), ~Event.parent_recurring_event_id.in_(pending_recurring_config_subquery)))  # Not an instance  # Instance but parent not pending

    # Apply ordering
    order_col = getattr(EventInteraction, order_by) if order_by and hasattr(EventInteraction, str(order_by)) else EventInteraction.created_at
    if order_dir and order_dir.lower() == "asc":
        query = query.order_by(order_col.asc())
    else:
        query = query.order_by(order_col.desc())

    # Apply pagination
    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))

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
                        "created_at": interaction.created_at,
                        "updated_at": interaction.updated_at,
                        "event_name": event.name,
                        "event_start_date": event.start_date,
                        "event_end_date": event.end_date,
                        "event_type": event.event_type,
                        "event_start_date_formatted": event.start_date.strftime("%Y-%m-%d %H:%M"),
                        "event_end_date_formatted": event.end_date.strftime("%Y-%m-%d %H:%M") if event.end_date else None,
                    }
                )
            return enriched_interactions
        else:
            # Return only interactions (extract from tuples)
            return [interaction for interaction, _ in results]
    else:
        interactions = query.all()
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

    # Check if user is banned
    check_user_not_banned(interaction.user_id, db)

    # Check if the user inviting is banned (if applicable)
    if interaction.invited_by_user_id:
        check_user_not_banned(interaction.invited_by_user_id, db)
        # Check if there's a block between inviter and invitee
        check_users_not_blocked(interaction.invited_by_user_id, interaction.user_id, db)

    # Check if there's a block between event owner and invitee
    check_users_not_blocked(event.owner_id, interaction.user_id, db)

    # Check if interaction already exists (unique constraint)
    existing = db.query(EventInteraction).filter(EventInteraction.event_id == interaction.event_id, EventInteraction.user_id == interaction.user_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already has an interaction with this event")

    # Set default status if not provided
    interaction_data = interaction.model_dump()
    if interaction_data.get("status") is None:
        # For invited interactions, default status is 'pending'
        if interaction_data.get("interaction_type") == "invited":
            interaction_data["status"] = "pending"
        # For joined interactions, default status is 'accepted'
        elif interaction_data.get("interaction_type") == "joined":
            interaction_data["status"] = "accepted"

    db_interaction = EventInteraction(**interaction_data)
    db.add(db_interaction)
    db.commit()
    db.refresh(db_interaction)
    return db_interaction


@router.put("/{interaction_id}", response_model=EventInteractionResponse)
async def update_interaction(interaction_id: int, interaction: EventInteractionBase, db: Session = Depends(get_db)):
    """Update an existing interaction (typically to change type or status)"""
    db_interaction = db.query(EventInteraction).filter(EventInteraction.id == interaction_id).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    for key, value in interaction.model_dump().items():
        setattr(db_interaction, key, value)

    db.commit()
    db.refresh(db_interaction)
    return db_interaction


@router.patch("/{interaction_id}", response_model=EventInteractionResponse)
async def patch_interaction(interaction_id: int, interaction: EventInteractionUpdate, db: Session = Depends(get_db)):
    """
    Partially update an existing interaction (typically to change status) - PATCH alias for PUT

    Special cascade behavior for recurring events:
    - If rejecting a base recurring event invitation (event_type='recurring' and status='rejected'),
      automatically reject all pending invitations to instance events of that recurring event
    """
    db_interaction = db.query(EventInteraction).filter(EventInteraction.id == interaction_id).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    # Check if user is banned
    check_user_not_banned(db_interaction.user_id, db)

    # Get the event to check if it's a recurring event
    event = db.query(Event).filter(Event.id == db_interaction.event_id).first()

    # Only update fields that are explicitly provided (exclude None values)
    for key, value in interaction.dict(exclude_unset=True).items():
        if value is not None:
            setattr(db_interaction, key, value)

    db.commit()
    db.refresh(db_interaction)

    # Cascade rejection logic: if rejecting a base recurring event invitation
    if event and event.event_type == "recurring" and db_interaction.interaction_type == "invited" and db_interaction.status == "rejected":

        # Find the recurring config for this event
        config = db.query(RecurringEventConfig).filter(RecurringEventConfig.event_id == event.id).first()

        if config:
            # Find all instance events of this recurring event
            instance_events = db.query(Event).filter(Event.parent_recurring_event_id == config.id).all()

            instance_event_ids = [e.id for e in instance_events]

            if instance_event_ids:
                # Update all pending invitations to these instances to 'rejected'
                db.query(EventInteraction).filter(EventInteraction.event_id.in_(instance_event_ids), EventInteraction.user_id == db_interaction.user_id, EventInteraction.interaction_type == "invited", EventInteraction.status == "pending").update({"status": "rejected"}, synchronize_session=False)
                db.commit()

    return db_interaction


@router.delete("/{interaction_id}")
async def delete_interaction(interaction_id: int, db: Session = Depends(get_db)):
    """Delete an interaction"""
    db_interaction = db.query(EventInteraction).filter(EventInteraction.id == interaction_id).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    db.delete(db_interaction)
    db.commit()
    return {"message": "Interaction deleted successfully", "id": interaction_id}
