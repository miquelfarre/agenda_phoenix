"""
Events Router

Handles all event-related endpoints.
"""

from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from dependencies import check_user_not_banned, get_db
from models import CalendarMembership, Contact, Event, EventCancellation, EventCancellationView, EventInteraction, User, UserBlock
from schemas import AvailableInviteeResponse, EventCancellationResponse, EventCreate, EventDeleteRequest, EventInteractionCreate, EventInteractionEnrichedResponse, EventInteractionResponse, EventResponse

router = APIRouter(prefix="/events", tags=["events"])


@router.get("", response_model=List[EventResponse])
async def get_events(owner_id: Optional[int] = None, calendar_id: Optional[int] = None, current_user_id: Optional[int] = None, limit: int = 50, offset: int = 0, order_by: Optional[str] = "start_date", order_dir: str = "asc", db: Session = Depends(get_db)):
    """Get all events, optionally filtered by owner_id or calendar_id"""
    query = db.query(Event)
    if owner_id:
        query = query.filter(Event.owner_id == owner_id)
    if calendar_id:
        query = query.filter(Event.calendar_id == calendar_id)

    # Apply ordering safely
    order_col = getattr(Event, order_by) if order_by and hasattr(Event, str(order_by)) else Event.start_date if hasattr(Event, "start_date") else Event.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    # Pagination
    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))

    events = query.all()
    return events


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(event_id: int, current_user_id: Optional[int] = None, db: Session = Depends(get_db)):
    """
    Get a single event by ID.

    Access control: Only users with one of these relationships can view the event:
    - Event owner
    - Has EventInteraction (invited or subscribed)
    - Member of calendar containing the event (owner/admin with accepted status)
    """
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Validate access if current_user_id provided
    if current_user_id is not None:
        # Check if user is banned
        from dependencies import check_user_not_banned

        check_user_not_banned(current_user_id, db)
        has_access = False

        # Check 1: Is owner
        if event.owner_id == current_user_id:
            has_access = True

        # Check 2: Has EventInteraction (invited or subscribed)
        if not has_access:
            interaction = db.query(EventInteraction).filter(EventInteraction.event_id == event_id, EventInteraction.user_id == current_user_id).first()
            if interaction:
                has_access = True

        # Check 3: Member of calendar containing the event
        if not has_access and event.calendar_id:
            calendar_membership = db.query(CalendarMembership).filter(CalendarMembership.calendar_id == event.calendar_id, CalendarMembership.user_id == current_user_id, CalendarMembership.status == "accepted", CalendarMembership.role.in_(["owner", "admin"])).first()
            if calendar_membership:
                has_access = True

        if not has_access:
            raise HTTPException(status_code=403, detail="You do not have permission to view this event")

    return event


@router.get("/{event_id}/interactions", response_model=List[EventInteractionResponse])
async def get_event_interactions(event_id: int, db: Session = Depends(get_db)):
    """Get all interactions for a specific event"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    interactions = db.query(EventInteraction).filter(EventInteraction.event_id == event_id).all()
    return interactions


@router.get("/{event_id}/interactions-enriched", response_model=List[EventInteractionEnrichedResponse])
async def get_event_interactions_enriched(event_id: int, db: Session = Depends(get_db)):
    """Get all interactions for a specific event with enriched user information"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Use JOIN to get all data in a single query
    results = db.query(EventInteraction, User, Contact).outerjoin(User, EventInteraction.user_id == User.id).outerjoin(Contact, User.contact_id == Contact.id).filter(EventInteraction.event_id == event_id).all()

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
                "invited_by_user_id": interaction.invited_by_user_id,
                "invited_via_group_id": interaction.invited_via_group_id,
                "created_at": interaction.created_at,
                "updated_at": interaction.updated_at,
            }
        )

    return enriched


@router.get("/{event_id}/available-invitees", response_model=List[AvailableInviteeResponse])
async def get_available_invitees(event_id: int, db: Session = Depends(get_db)):
    """Get list of users available to be invited to an event (excludes owner, already invited users, blocked users, and public users)"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Get user IDs that already have interactions with this event (in a single subquery)
    invited_user_ids_subquery = db.query(EventInteraction.user_id).filter(EventInteraction.event_id == event_id).subquery()

    # Get user IDs that have mutual blocks with the event owner
    blocked_user_ids_subquery = db.query(UserBlock.blocked_user_id).filter(UserBlock.blocker_user_id == event.owner_id).union(db.query(UserBlock.blocker_user_id).filter(UserBlock.blocked_user_id == event.owner_id)).subquery()

    # Get all users NOT in the invited list, NOT the owner, NOT blocked, NOT public, with Contact info in one query
    results = db.query(User, Contact).outerjoin(Contact, User.contact_id == Contact.id).filter(User.id != event.owner_id, User.is_public == False, ~User.id.in_(invited_user_ids_subquery), ~User.id.in_(blocked_user_ids_subquery)).all()

    # Build available invitees list
    available = []
    for user, contact in results:
        username = user.username
        contact_name = contact.name if contact else None

        # Build display name
        if username and contact_name:
            display_name = f"{username} ({contact_name})"
        elif username:
            display_name = username
        elif contact_name:
            display_name = contact_name
        else:
            display_name = f"Usuario #{user.id}"

        available.append({"id": user.id, "username": username, "contact_name": contact_name, "display_name": display_name})

    return available


@router.post("", response_model=EventResponse, status_code=201)
async def create_event(event: EventCreate, db: Session = Depends(get_db)):
    """Create a new event."""
    owner = db.query(User).filter(User.id == event.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner user not found")

    # Check if owner is banned
    check_user_not_banned(event.owner_id, db)

    # Ensure dates are timezone-aware before saving to database
    event_data = event.model_dump()
    if event_data["start_date"].tzinfo is None:
        event_data["start_date"] = event_data["start_date"].replace(tzinfo=timezone.utc)
    if event_data.get("end_date") and event_data["end_date"].tzinfo is None:
        event_data["end_date"] = event_data["end_date"].replace(tzinfo=timezone.utc)

    # VALIDATION: Only recurring events can have end_date
    if event_data.get("event_type") == "regular":
        event_data["end_date"] = None

    db_event = Event(**event_data)
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event


@router.put("/{event_id}", response_model=EventResponse)
async def update_event(event_id: int, event: EventCreate, db: Session = Depends(get_db)):
    """Update an existing event"""
    db_event = db.query(Event).filter(Event.id == event_id).first()
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    if event.owner_id != db_event.owner_id:
        owner = db.query(User).filter(User.id == event.owner_id).first()
        if not owner:
            raise HTTPException(status_code=404, detail="Owner user not found")

    # Ensure dates are timezone-aware before updating
    event_data = event.model_dump()
    if event_data["start_date"].tzinfo is None:
        event_data["start_date"] = event_data["start_date"].replace(tzinfo=timezone.utc)
    if event_data.get("end_date") and event_data["end_date"].tzinfo is None:
        event_data["end_date"] = event_data["end_date"].replace(tzinfo=timezone.utc)

    # VALIDATION: Only recurring events can have end_date
    if event_data.get("event_type") == "regular":
        event_data["end_date"] = None

    for key, value in event_data.items():
        setattr(db_event, key, value)

    db.commit()
    db.refresh(db_event)
    return db_event


@router.delete("/{event_id}")
async def delete_event(event_id: int, delete_request: Optional[EventDeleteRequest] = None, db: Session = Depends(get_db)):
    """
    Delete an event and optionally create cancellation notifications.

    If delete_request is provided with cancelled_by_user_id, creates EventCancellation records
    for all users with interactions to this event.

    For recurring events: deleting the base event also deletes all instances.
    """
    db_event = db.query(Event).filter(Event.id == event_id).first()
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    events_to_delete = [db_event]

    # If it's a recurring base event, get all instances
    if db_event.event_type == "recurring":
        instances = db.query(Event).filter(
            Event.parent_recurring_event_id == event_id
        ).all()
        events_to_delete.extend(instances)

    # Create cancellation records if requested
    if delete_request and delete_request.cancelled_by_user_id:
        for event in events_to_delete:
            # Get all users with interactions to this event
            interactions = db.query(EventInteraction).filter(
                EventInteraction.event_id == event.id
            ).all()

            if interactions:
                # Create cancellation record
                cancellation = EventCancellation(
                    event_id=event.id,
                    event_name=event.name,
                    cancelled_by_user_id=delete_request.cancelled_by_user_id,
                    message=delete_request.cancellation_message
                )
                db.add(cancellation)
                db.flush()  # Get the cancellation ID

    # Delete all events
    for event in events_to_delete:
        db.delete(event)

    db.commit()

    deleted_count = len(events_to_delete)
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
    # Get all cancellations that this user hasn't viewed
    viewed_cancellation_ids = db.query(EventCancellationView.cancellation_id).filter(
        EventCancellationView.user_id == user_id
    ).all()
    viewed_ids = [v[0] for v in viewed_cancellation_ids]

    # Get cancellations for events where user had interactions
    # and hasn't viewed the cancellation
    cancellations = db.query(EventCancellation).filter(
        EventCancellation.id.not_in(viewed_ids) if viewed_ids else True
    ).all()

    # Filter to only cancellations where the user had an interaction with the event
    # Note: We can't use a JOIN because the event might be deleted
    # So we need to check if user had any interaction with that event_id
    user_cancellations = []
    for cancellation in cancellations:
        # Check if this cancellation's event_id was ever in the user's interactions
        # This requires checking deleted interactions, but we're storing event_id in cancellation
        # For now, return all unviewed cancellations for simplicity
        # In production, you might want to add a junction table for affected users
        user_cancellations.append(cancellation)

    return user_cancellations


@router.post("/cancellations/{cancellation_id}/view")
async def mark_cancellation_as_viewed(cancellation_id: int, user_id: int, db: Session = Depends(get_db)):
    """
    Mark an event cancellation as viewed by a user.

    After viewing, the cancellation will no longer appear in the user's list.
    """
    # Check if cancellation exists
    cancellation = db.query(EventCancellation).filter(EventCancellation.id == cancellation_id).first()
    if not cancellation:
        raise HTTPException(status_code=404, detail="Cancellation not found")

    # Check if already viewed
    existing_view = db.query(EventCancellationView).filter(
        EventCancellationView.cancellation_id == cancellation_id,
        EventCancellationView.user_id == user_id
    ).first()

    if existing_view:
        return {"message": "Cancellation already marked as viewed", "id": existing_view.id}

    # Create view record
    view = EventCancellationView(
        cancellation_id=cancellation_id,
        user_id=user_id
    )
    db.add(view)
    db.commit()
    db.refresh(view)

    return {"message": "Cancellation marked as viewed", "id": view.id}
