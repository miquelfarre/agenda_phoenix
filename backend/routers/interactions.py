"""
Event Interactions Router

Handles all event interaction endpoints including invitations and subscriptions.
"""

from typing import List, Optional, Union

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import event, event_interaction, recurring_config, user
from dependencies import check_user_not_banned, check_users_not_blocked, get_db
from models import EventInteraction
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
    return event_interaction.get_multi_with_optional_enrichment(
        db,
        event_id=event_id,
        user_id=user_id,
        interaction_type=interaction_type,
        status=status,
        enriched=enriched,
        skip=offset,
        limit=limit,
        order_by=order_by or "created_at",
        order_dir=order_dir
    )


@router.get("/{interaction_id}", response_model=EventInteractionResponse)
async def get_interaction(interaction_id: int, db: Session = Depends(get_db)):
    """Get a single interaction by ID"""
    db_interaction = event_interaction.get(db, id=interaction_id)
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")
    return db_interaction


@router.post("", response_model=EventInteractionResponse, status_code=201)
async def create_interaction(interaction: EventInteractionCreate, db: Session = Depends(get_db)):
    """Create a new event interaction"""
    # Verify event exists
    db_event = event.get(db, id=interaction.event_id)
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Verify user exists
    db_user = user.get(db, id=interaction.user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Public users cannot be invited to events (they can only manage their own events)
    if interaction.interaction_type == "invited" and db_user.is_public:
        raise HTTPException(
            status_code=403,
            detail="Public users cannot be invited to events. Only private users can receive invitations."
        )

    # Check if user is banned
    check_user_not_banned(interaction.user_id, db)

    # Check if the user inviting is banned (if applicable)
    if interaction.invited_by_user_id:
        check_user_not_banned(interaction.invited_by_user_id, db)
        # Check if there's a block between inviter and invitee
        check_users_not_blocked(interaction.invited_by_user_id, interaction.user_id, db)

    # Check if there's a block between event owner and invitee
    check_users_not_blocked(db_event.owner_id, interaction.user_id, db)

    # VALIDATION: For invitations, verify the inviter has permission to invite
    if interaction.interaction_type == "invited" and interaction.invited_by_user_id:
        inviter_id = interaction.invited_by_user_id

        # Get inviter user to check if they're public
        inviter_user = user.get(db, id=inviter_id)
        if not inviter_user:
            raise HTTPException(status_code=404, detail="Inviter user not found")

        # Public users (e.g., FC Barcelona) cannot invite others
        if inviter_user.is_public:
            raise HTTPException(
                status_code=403,
                detail="Public users cannot invite others to events. Only private users can invite."
            )

        # Check if inviter is the event owner
        is_owner = (db_event.owner_id == inviter_id)

        if not is_owner:
            # Check if inviter is an admin or accepted participant of this event
            inviter_interaction = event_interaction.get_interaction(db, event_id=interaction.event_id, user_id=inviter_id)

            has_permission = False
            if inviter_interaction:
                # Inviter is admin with accepted status
                if inviter_interaction.role == "admin" and inviter_interaction.status == "accepted":
                    has_permission = True
                # Inviter is a subscribed or joined participant with accepted status
                elif inviter_interaction.interaction_type in ["subscribed", "joined"] and inviter_interaction.status == "accepted":
                    has_permission = True

            if not has_permission:
                raise HTTPException(
                    status_code=403,
                    detail="User does not have permission to invite others to this event. Must be event owner, admin, or accepted participant."
                )

    # Check if interaction already exists (unique constraint)
    if event_interaction.exists_interaction(db, event_id=interaction.event_id, user_id=interaction.user_id):
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
async def update_interaction(interaction_id: int, interaction_data: EventInteractionBase, db: Session = Depends(get_db)):
    """Update an existing interaction (typically to change type or status)"""
    db_interaction = event_interaction.get(db, id=interaction_id)
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    updated_interaction = event_interaction.update(db, db_obj=db_interaction, obj_in=interaction_data)
    return updated_interaction


@router.patch("/{interaction_id}", response_model=EventInteractionResponse)
async def patch_interaction(interaction_id: int, interaction: EventInteractionUpdate, db: Session = Depends(get_db)):
    """
    Partially update an existing interaction (typically to change status) - PATCH alias for PUT

    Special cascade behavior for recurring events:
    - If rejecting a base recurring event invitation (event_type='recurring' and status='rejected'),
      automatically reject all pending invitations to instance events of that recurring event
    """
    db_interaction = event_interaction.get(db, id=interaction_id)
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    # Check if user is banned
    check_user_not_banned(db_interaction.user_id, db)

    # Get the event to check if it's a recurring event
    db_event = event.get(db, id=db_interaction.event_id)

    # Only update fields that are explicitly provided (exclude None values)
    for key, value in interaction.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(db_interaction, key, value)

    db.commit()
    db.refresh(db_interaction)

    # Cascade rejection logic: if rejecting a base recurring event invitation
    if db_event and db_event.event_type == "recurring" and db_interaction.interaction_type == "invited" and db_interaction.status == "rejected":

        # Find the recurring config for this event
        config = recurring_config.get_by_event(db, event_id=db_event.id)

        if config:
            # Find all instance events of this recurring event
            instance_events = event.get_instances_by_parent_config(db, parent_config_id=config.id)

            instance_event_ids = [e.id for e in instance_events]

            if instance_event_ids:
                # Update all pending invitations to these instances to 'rejected'
                event_interaction.bulk_reject_pending_instances(db, instance_event_ids=instance_event_ids, user_id=db_interaction.user_id)

    return db_interaction


@router.delete("/{interaction_id}")
async def delete_interaction(interaction_id: int, db: Session = Depends(get_db)):
    """Delete an interaction"""
    db_interaction = event_interaction.get(db, id=interaction_id)
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    event_interaction.delete(db, id=interaction_id)
    return {"message": "Interaction deleted successfully", "id": interaction_id}
