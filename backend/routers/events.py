"""
Events Router

Handles all event-related endpoints.
"""

from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import event, event_cancellation, event_interaction, user
from dependencies import check_event_permission, check_user_not_banned, get_db
from models import Contact, EventInteraction, User, UserBlock
from schemas import AvailableInviteeResponse, EventCancellationResponse, EventCreate, EventDeleteRequest, EventInteractionCreate, EventInteractionEnrichedResponse, EventInteractionResponse, EventResponse, UpcomingEventSummary

router = APIRouter(prefix="/events", tags=["events"])


@router.get("", response_model=List[EventResponse])
async def get_events(
    owner_id: Optional[int] = None,
    calendar_id: Optional[int] = None,
    current_user_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: Optional[str] = "start_date",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all events, optionally filtered by owner_id or calendar_id"""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return event.get_multi_filtered(
        db,
        owner_id=owner_id,
        calendar_id=calendar_id,
        skip=offset,
        limit=limit,
        order_by=order_by or "start_date",
        order_dir=order_dir
    )


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(event_id: int, current_user_id: Optional[int] = None, db: Session = Depends(get_db)):
    """
    Get a single event by ID.

    Access control: Only users with one of these relationships can view the event:
    - Event owner
    - Has EventInteraction (invited or subscribed)
    - Member of calendar containing the event (owner/admin with accepted status)

    For events owned by public users, includes:
    - Subscription status (is_subscribed_to_owner)
    - Ability to subscribe (can_subscribe_to_owner)
    - Next 10 upcoming events from the public owner (owner_upcoming_events)
    """
    db_event = event.get(db, id=event_id)
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Validate access if current_user_id provided
    if current_user_id is not None:
        # Check if user is banned
        check_user_not_banned(current_user_id, db)

        # Check access using CRUD method
        has_access = event.check_user_access(db, event_id=event_id, user_id=current_user_id)
        if not has_access:
            raise HTTPException(status_code=403, detail="You do not have permission to view this event")

    # Get owner information
    owner = user.get(db, id=db_event.owner_id)
    if not owner:
        raise HTTPException(status_code=404, detail="Event owner not found")

    # Build response dict from event
    response_data = {
        "id": db_event.id,
        "name": db_event.name,
        "description": db_event.description,
        "start_date": db_event.start_date,
        "end_date": db_event.end_date,
        "event_type": db_event.event_type,
        "owner_id": db_event.owner_id,
        "calendar_id": db_event.calendar_id,
        "parent_recurring_event_id": db_event.parent_recurring_event_id,
        "created_at": db_event.created_at,
        "updated_at": db_event.updated_at,
        "is_owner_public": owner.is_public,
    }

    # If owner is public and current_user_id is provided, add subscription info
    if owner.is_public and current_user_id is not None:
        # Check if user is subscribed to owner (any event from this owner)
        # A subscription is an interaction of type "subscribed" to any event owned by the public user
        subscriptions = db.query(EventInteraction).join(
            event.model, EventInteraction.event_id == event.model.id
        ).filter(
            event.model.owner_id == owner.id,
            EventInteraction.user_id == current_user_id,
            EventInteraction.interaction_type == "subscribed"
        ).first()
        is_subscribed = subscriptions is not None

        # Check if there's a block between users
        is_blocked = db.query(UserBlock).filter(
            ((UserBlock.blocker_user_id == current_user_id) & (UserBlock.blocked_user_id == owner.id)) |
            ((UserBlock.blocker_user_id == owner.id) & (UserBlock.blocked_user_id == current_user_id))
        ).first() is not None

        # User can subscribe if not already subscribed and not blocked
        can_subscribe = not is_subscribed and not is_blocked

        # Get upcoming events from public owner
        upcoming_events = event.get_upcoming_events_by_owner(db, owner_id=owner.id, limit=10)
        upcoming_events_data = [
            {
                "id": e.id,
                "name": e.name,
                "start_date": e.start_date,
                "end_date": e.end_date,
                "event_type": e.event_type,
            }
            for e in upcoming_events
        ]

        response_data["is_subscribed_to_owner"] = is_subscribed
        response_data["can_subscribe_to_owner"] = can_subscribe
        response_data["owner_upcoming_events"] = upcoming_events_data

    # If current_user_id is provided and user is owner or admin, add invitation stats
    if current_user_id is not None:
        is_owner = db_event.owner_id == current_user_id
        is_admin = False

        # Check if user is admin of the calendar containing this event
        if db_event.calendar_id:
            from crud import calendar_membership
            membership = calendar_membership.get_by_calendar_and_user(
                db, calendar_id=db_event.calendar_id, user_id=current_user_id
            )
            if membership and membership.role in ["owner", "admin"] and membership.status == "accepted":
                is_admin = True

        # If user is owner or admin, get invitation stats
        if is_owner or is_admin:
            stats = event_interaction.get_invitation_stats(db, event_id=event_id)
            response_data["invitation_stats"] = stats

    return EventResponse(**response_data)


@router.get("/{event_id}/interactions", response_model=List[EventInteractionResponse])
async def get_event_interactions(event_id: int, db: Session = Depends(get_db)):
    """Get all interactions for a specific event"""
    if not event.exists_event(db, event_id=event_id):
        raise HTTPException(status_code=404, detail="Event not found")

    return event_interaction.get_by_event(db, event_id=event_id)


@router.get("/{event_id}/interactions-enriched", response_model=List[EventInteractionEnrichedResponse])
async def get_event_interactions_enriched(event_id: int, db: Session = Depends(get_db)):
    """Get all interactions for a specific event with enriched user information"""
    if not event.exists_event(db, event_id=event_id):
        raise HTTPException(status_code=404, detail="Event not found")

    # Use CRUD to get enriched interactions (single JOIN query)
    results = event_interaction.get_enriched_by_event(db, event_id=event_id)

    # Build enriched responses
    enriched = []
    for interaction, user, contact in results:
        if not user:
            continue

        # Build display name
        username = user.username
        contact_name = contact.name if contact else None

        if username and contact_name:
            display_name = f"{username} ({contact_name})"
        elif username:
            display_name = username
        elif contact_name:
            display_name = contact_name
        else:
            display_name = f"Usuario #{user.id}"

        enriched.append(
            {
                "id": interaction.id,
                "event_id": interaction.event_id,
                "user_id": interaction.user_id,
                "user_name": display_name,
                "user_username": username,
                "user_contact_name": contact_name,
                "interaction_type": interaction.interaction_type,
                "status": interaction.status,
                "role": interaction.role,
                "note": interaction.note,
                "rejection_message": interaction.rejection_message,
                "invited_by_user_id": interaction.invited_by_user_id,
                "invited_via_group_id": interaction.invited_via_group_id,
                "read_at": interaction.read_at,
                "is_new": interaction.is_new,
                "created_at": interaction.created_at,
                "updated_at": interaction.updated_at,
            }
        )

    return enriched


@router.get("/{event_id}/available-invitees", response_model=List[AvailableInviteeResponse])
async def get_available_invitees(event_id: int, db: Session = Depends(get_db)):
    """Get list of users available to be invited to an event (excludes owner, already invited users, blocked users, and public users)"""
    db_event = event.get(db, id=event_id)
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Use CRUD to get available invitees
    results = event.get_available_invitees(db, event_id=event_id)

    # Build available invitees list
    available = []
    for user_obj, contact in results:
        username = user_obj.username
        contact_name = contact.name if contact else None

        # Build display name
        if username and contact_name:
            display_name = f"{username} ({contact_name})"
        elif username:
            display_name = username
        elif contact_name:
            display_name = contact_name
        else:
            display_name = f"Usuario #{user_obj.id}"

        available.append({"id": user_obj.id, "username": username, "contact_name": contact_name, "display_name": display_name})

    return available


@router.post("", response_model=EventResponse, status_code=201)
async def create_event(event_data: EventCreate, db: Session = Depends(get_db)):
    """Create a new event"""
    # Create with validation (all checks in CRUD layer)
    db_event, error, error_detail = event.create_with_validation(db, obj_in=event_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        elif "banned" in error.lower():
            # Use detailed error info if available
            raise HTTPException(status_code=403, detail=error_detail if error_detail else error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_event


@router.put("/{event_id}", response_model=EventResponse)
async def update_event(event_id: int, event_data: EventCreate, current_user_id: int, db: Session = Depends(get_db)):
    """
    Update an existing event.

    Requires current_user_id to verify permissions.
    Only the event owner or event admins can update events.
    """
    # Check permissions (owner or admin)
    check_event_permission(event_id, current_user_id, db)

    # Update with validation (all checks in CRUD layer)
    db_event, error = event.update_with_validation(db, event_id=event_id, obj_in=event_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_event


@router.delete("/{event_id}")
async def delete_event(event_id: int, current_user_id: int, delete_request: Optional[EventDeleteRequest] = None, db: Session = Depends(get_db)):
    """
    Delete an event and optionally create cancellation notifications.

    Requires current_user_id to verify permissions.
    Only the event owner or event admins can delete events.

    If delete_request is provided with cancelled_by_user_id, creates EventCancellation records
    for all users with interactions to this event.

    For recurring events: deleting the base event also deletes all instances.
    """
    # Check permissions (owner or admin)
    check_event_permission(event_id, current_user_id, db)

    # If delete_request is provided, verify cancelled_by_user_id matches current_user_id
    if delete_request and delete_request.cancelled_by_user_id:
        if delete_request.cancelled_by_user_id != current_user_id:
            raise HTTPException(
                status_code=400,
                detail="cancelled_by_user_id in request body must match current_user_id"
            )

    # Delete with cancellations (using CRUD method)
    cancelled_by = delete_request.cancelled_by_user_id if delete_request else None
    cancellation_msg = delete_request.cancellation_message if delete_request else None

    deleted_count, error = event.delete_with_cancellations(
        db,
        event_id=event_id,
        cancelled_by_user_id=cancelled_by,
        cancellation_message=cancellation_msg
    )

    if error:
        raise HTTPException(status_code=404, detail=error)

    return {
        "message": f"Event deleted successfully ({'with ' + str(deleted_count - 1) + ' instances' if deleted_count > 1 else 'single event'})",
        "id": event_id,
        "deleted_count": deleted_count
    }


@router.get("/cancellations", response_model=List[EventCancellationResponse])
async def get_event_cancellations(user_id: int, db: Session = Depends(get_db)):
    """
    Get all event cancellations that a user hasn't viewed yet.

    Returns cancellations for events where the user had an interaction
    and hasn't viewed the cancellation message yet.
    """
    return event_cancellation.get_unviewed_by_user(db, user_id=user_id)


@router.post("/cancellations/{cancellation_id}/view")
async def mark_cancellation_as_viewed(cancellation_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    Mark an event cancellation as viewed by a user.

    After viewing, the cancellation will no longer appear in the user's list.
    """
    view_id, error = event_cancellation.mark_as_viewed(db, cancellation_id=cancellation_id, user_id=user_id)

    if error:
        raise HTTPException(status_code=404, detail=error)

    return {"message": "Cancellation marked as viewed", "id": view_id}
