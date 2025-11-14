"""
Event Interactions Router

Handles all event interaction endpoints including invitations and subscriptions.
"""

from typing import List, Optional, Union

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import event, event_interaction, group_membership, user
from dependencies import check_user_not_public, check_users_not_blocked, get_db, handle_recurring_event_rejection_cascade, is_event_owner_or_admin
from models import EventInteraction
from schemas import EventInteractionBase, EventInteractionCreate, EventInteractionResponse, EventInteractionUpdate, EventInteractionWithEventResponse

router = APIRouter(prefix="/api/v1/interactions", tags=["interactions"])


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
    return event_interaction.get_multi_with_optional_enrichment(db, event_id=event_id, user_id=user_id, interaction_type=interaction_type, status=status, enriched=enriched, skip=offset, limit=limit, order_by=order_by or "created_at", order_dir=order_dir)


# Removed unused GET /interactions/{interaction_id}


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
        raise HTTPException(status_code=403, detail="Public users cannot be invited to events. Only private users can receive invitations.")

    # Check if the user inviting is banned (if applicable)
    if interaction.invited_by_user_id:
        # Check if there's a block between inviter and invitee
        check_users_not_blocked(interaction.invited_by_user_id, interaction.user_id, db)

    # Check if there's a block between event owner and invitee
    check_users_not_blocked(db_event.owner_id, interaction.user_id, db)

    # VALIDATION: role='admin' can only be assigned with 'joined' interaction type
    if interaction.role == "admin" and interaction.interaction_type != "joined":
        raise HTTPException(status_code=400, detail="Admins must be added directly using 'joined' interaction type, not 'invited'. Use 'joined' with role='admin' to add an admin without requiring acceptance.")

    # VALIDATION: Public users cannot be admins
    if interaction.role == "admin":
        check_user_not_public(interaction.user_id, db, "be added as admin to events")

    # VALIDATION: For 'joined' interactions, only the event owner can add users directly
    if interaction.interaction_type == "joined":
        # For 'joined' interactions, invited_by_user_id must be provided and must be the owner
        if not interaction.invited_by_user_id:
            raise HTTPException(status_code=400, detail="For 'joined' interaction type, 'invited_by_user_id' must be provided (the event owner).")

        if interaction.invited_by_user_id != db_event.owner_id:
            raise HTTPException(status_code=403, detail="Only the event owner can add users directly with 'joined' interaction type.")

    # VALIDATION: For invitations, verify the inviter has permission to invite
    if interaction.interaction_type == "invited" and interaction.invited_by_user_id:
        inviter_id = interaction.invited_by_user_id

        # Get inviter user to check if they're public
        inviter_user = user.get(db, id=inviter_id)
        if not inviter_user:
            raise HTTPException(status_code=404, detail="Inviter user not found")

        # Public users (e.g., FC Barcelona) cannot invite others
        if inviter_user.is_public:
            raise HTTPException(status_code=403, detail="Public users cannot invite others to events. Only private users can invite.")

        # Check if inviter is the event owner
        is_owner = db_event.owner_id == inviter_id

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
                raise HTTPException(status_code=403, detail="User does not have permission to invite others to this event. Must be event owner, admin, or accepted participant.")

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


@router.patch("/{interaction_id}", response_model=EventInteractionResponse)
async def patch_interaction(interaction_id: int, interaction: EventInteractionUpdate, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Partially update an existing interaction (typically to change status or role).

    Requires JWT authentication - provide token in Authorization header.

    For status changes: Only the user of the interaction can update it (to accept/reject invitations).
    For role changes: Only event owners or admins can change roles (attendee <-> admin).

    Special cascade behavior for recurring events:
    - If rejecting a base recurring event invitation (event_type='recurring' and status='rejected'),
      automatically reject all pending invitations to instance events of that recurring event
    """
    db_interaction = event_interaction.get(db, id=interaction_id)
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    # Get update data
    update_data = interaction.model_dump(exclude_unset=True)

    # Special validation for role changes
    if 'role' in update_data:
        # Only joined interactions can have their role changed
        if db_interaction.interaction_type != "joined":
            raise HTTPException(
                status_code=400,
                detail="Can only change role for joined participants"
            )

        # Check permissions (owner or admin)
        is_admin = is_event_owner_or_admin(
            db_interaction.event_id,
            current_user_id,
            db
        )
        if not is_admin:
            raise HTTPException(
                status_code=403,
                detail="Only event owners or admins can change roles"
            )

        # Cannot change your own role
        if db_interaction.user_id == current_user_id:
            raise HTTPException(
                status_code=403,
                detail="Cannot change your own role"
            )

        # Validate role
        new_role = update_data['role']
        if new_role not in ["attendee", "admin"]:
            raise HTTPException(
                status_code=400,
                detail="Role must be 'attendee' or 'admin'"
            )

        # Public users cannot be admins
        if new_role == "admin":
            check_user_not_public(db_interaction.user_id, db, "be promoted to admin")
    else:
        # For non-role changes, check if user is the interaction user
        if db_interaction.user_id != current_user_id:
            raise HTTPException(status_code=403, detail="You don't have permission to update this interaction. Only the user themselves can accept/reject invitations.")

    # Get the event to check if it's a recurring event
    db_event = event.get(db, id=db_interaction.event_id)

    # Only update fields that are explicitly provided (exclude None values)
    for key, value in update_data.items():
        if value is not None:
            setattr(db_interaction, key, value)

    db.commit()
    db.refresh(db_interaction)

    # Handle cascade rejection logic for recurring events
    if db_event:
        handle_recurring_event_rejection_cascade(db, db_interaction, db_event)

    return db_interaction


# Removed unused DELETE /interactions/{interaction_id}


@router.post("/{interaction_id}/mark-read", response_model=EventInteractionResponse)
async def mark_interaction_as_read(interaction_id: int, db: Session = Depends(get_db)):
    """
    Mark an event interaction as read.

    This sets the read_at timestamp and causes is_new to become False.
    Useful for tracking which events/invitations the user has seen.
    """
    interaction, error = event_interaction.mark_as_read(db, interaction_id=interaction_id)

    if error:
        raise HTTPException(status_code=404, detail=error)

    return interaction


@router.post("/bulk", status_code=201)
async def add_event_participants_bulk(
    event_id: int,
    user_ids: List[int] = [],
    group_ids: List[int] = [],
    role: str = "attendee",
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Add multiple users or entire groups to an event as participants.

    Only event owners or admins can add participants.
    Participants are added directly with 'joined' status (no invitation needed).
    Returns summary of successful and failed additions.
    """
    # Verify event exists
    db_event = event.get(db, id=event_id)
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Check permissions (owner or admin)
    is_admin = is_event_owner_or_admin(event_id, current_user_id, db)
    if not is_admin:
        raise HTTPException(status_code=403, detail="Only event owners or admins can add participants")

    results = {
        "successful": [],
        "failed": [],
        "total_added": 0
    }

    # Add individual users
    for user_id in user_ids:
        try:
            interaction_data = EventInteractionCreate(
                event_id=event_id,
                user_id=user_id,
                interaction_type="joined",
                role=role,
                invited_by_user_id=current_user_id
            )

            # Verify user exists
            db_user = user.get(db, id=user_id)
            if not db_user:
                results["failed"].append({
                    "user_id": user_id,
                    "error": "User not found"
                })
                continue

            # Public users cannot be participants
            if db_user.is_public:
                results["failed"].append({
                    "user_id": user_id,
                    "error": "Public users cannot be added to events"
                })
                continue

            # Public users cannot be admins
            if role == "admin":
                check_user_not_public(user_id, db, "be added as admin to events")

            # Check if interaction already exists
            existing = event_interaction.get_interaction(db, event_id=event_id, user_id=user_id)
            if existing:
                results["failed"].append({
                    "user_id": user_id,
                    "error": "User already has an interaction with this event"
                })
                continue

            # Check for blocks
            try:
                check_users_not_blocked(current_user_id, user_id, db)
                check_users_not_blocked(db_event.owner_id, user_id, db)
            except HTTPException as e:
                results["failed"].append({
                    "user_id": user_id,
                    "error": e.detail
                })
                continue

            # Create interaction
            db_interaction = event_interaction.create(db, obj_in=interaction_data)
            results["successful"].append(db_interaction.id)
            results["total_added"] += 1

        except Exception as e:
            results["failed"].append({
                "user_id": user_id,
                "error": str(e)
            })

    # Add group members
    for group_id in group_ids:
        # Get all members of the group
        group_members = group_membership.get_by_group(db, group_id=group_id)
        for member in group_members:
            try:
                interaction_data = EventInteractionCreate(
                    event_id=event_id,
                    user_id=member.user_id,
                    interaction_type="joined",
                    role=role,
                    invited_by_user_id=current_user_id
                )

                # Verify user exists
                db_user = user.get(db, id=member.user_id)
                if not db_user:
                    results["failed"].append({
                        "user_id": member.user_id,
                        "group_id": group_id,
                        "error": "User not found"
                    })
                    continue

                # Public users cannot be participants
                if db_user.is_public:
                    results["failed"].append({
                        "user_id": member.user_id,
                        "group_id": group_id,
                        "error": "Public users cannot be added to events"
                    })
                    continue

                # Public users cannot be admins
                if role == "admin":
                    try:
                        check_user_not_public(member.user_id, db, "be added as admin to events")
                    except HTTPException as e:
                        results["failed"].append({
                            "user_id": member.user_id,
                            "group_id": group_id,
                            "error": e.detail
                        })
                        continue

                # Check if interaction already exists
                existing = event_interaction.get_interaction(db, event_id=event_id, user_id=member.user_id)
                if existing:
                    results["failed"].append({
                        "user_id": member.user_id,
                        "group_id": group_id,
                        "error": "User already has an interaction with this event"
                    })
                    continue

                # Check for blocks
                try:
                    check_users_not_blocked(current_user_id, member.user_id, db)
                    check_users_not_blocked(db_event.owner_id, member.user_id, db)
                except HTTPException as e:
                    results["failed"].append({
                        "user_id": member.user_id,
                        "group_id": group_id,
                        "error": e.detail
                    })
                    continue

                # Create interaction
                db_interaction = event_interaction.create(db, obj_in=interaction_data)
                results["successful"].append(db_interaction.id)
                results["total_added"] += 1

            except Exception as e:
                results["failed"].append({
                    "user_id": member.user_id,
                    "group_id": group_id,
                    "error": str(e)
                })

    return results
