"""
Events Router

Handles all event-related endpoints including conflict checking.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone

from models import Event, User, EventInteraction, CalendarMembership, Contact
from schemas import (
    EventCreate, EventResponse, EventInteractionResponse, EventInteractionCreate,
    EventInteractionEnrichedResponse, AvailableInviteeResponse
)
from dependencies import get_db


router = APIRouter(
    prefix="/events",
    tags=["events"]
)


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

    # Build enriched responses
    enriched_events = []
    for event in events:
        event_dict = {
            "id": event.id,
            "name": event.name,
            "description": event.description,
            "start_date": event.start_date,
            "end_date": event.end_date,
            "event_type": event.event_type,
            "owner_id": event.owner_id,
            "calendar_id": event.calendar_id,
            "parent_recurring_event_id": event.parent_recurring_event_id,
            "created_at": event.created_at,
            "updated_at": event.updated_at,
            "start_date_formatted": event.start_date.strftime("%Y-%m-%d %H:%M"),
            "end_date_formatted": event.end_date.strftime("%Y-%m-%d %H:%M") if event.end_date else None
        }

        # Add ownership info if current_user_id provided
        if current_user_id is not None:
            is_owner = event.owner_id == current_user_id
            event_dict["is_owner"] = is_owner
            event_dict["owner_display"] = "Yo" if is_owner else f"Usuario #{event.owner_id}"

        enriched_events.append(event_dict)

    return enriched_events


@router.get("/check-conflicts")
async def check_event_conflicts(
    user_id: int,
    start_date: datetime,
    end_date: Optional[datetime] = None,
    exclude_event_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Check for event conflicts for a user within a given time range"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    event_ids = set()

    # Own events
    own_events = db.query(Event.id).filter(Event.owner_id == user_id).all()
    event_ids.update([e[0] for e in own_events])

    # Subscribed events
    subscribed_events = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'subscribed'
    ).all()
    event_ids.update([e[0] for e in subscribed_events])

    # Invited events (accepted)
    invited_events = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'invited',
        EventInteraction.status == 'accepted'
    ).all()
    event_ids.update([e[0] for e in invited_events])

    # Calendar events
    calendar_memberships = db.query(CalendarMembership.calendar_id).filter(
        CalendarMembership.user_id == user_id,
        CalendarMembership.status == 'accepted',
        CalendarMembership.role.in_(['owner', 'admin'])
    ).all()

    if calendar_memberships:
        calendar_ids = [m[0] for m in calendar_memberships]
        calendar_events = db.query(Event.id).filter(
            Event.calendar_id.in_(calendar_ids)
        ).all()
        event_ids.update([e[0] for e in calendar_events])

    if event_ids:
        all_events = db.query(Event).filter(Event.id.in_(event_ids)).all()
    else:
        return []

    # Detect conflicts
    conflicts = []
    for event in all_events:
        if exclude_event_id and event.id == exclude_event_id:
            continue

        evt_start = event.start_date
        evt_end = event.end_date

        # Check overlap
        has_conflict = False
        if not end_date and not evt_end:
            if abs((start_date - evt_start).total_seconds()) < 300:
                has_conflict = True
        elif not end_date:
            if evt_end and evt_start <= start_date <= evt_end:
                has_conflict = True
        elif not evt_end:
            if start_date <= evt_start <= end_date:
                has_conflict = True
        else:
            if max(start_date, evt_start) < min(end_date, evt_end):
                has_conflict = True

        if has_conflict:
            conflicts.append({
                "id": event.id,
                "name": event.name,
                "description": event.description,
                "start_date": event.start_date,
                "end_date": event.end_date,
                "event_type": event.event_type,
                "owner_id": event.owner_id,
                "calendar_id": event.calendar_id,
                "parent_recurring_event_id": event.parent_recurring_event_id,
                "created_at": event.created_at,
                "updated_at": event.updated_at,
                "start_date_formatted": event.start_date.strftime("%Y-%m-%d %H:%M"),
                "end_date_formatted": event.end_date.strftime("%Y-%m-%d %H:%M") if event.end_date else None
            })

    return conflicts


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(
    event_id: int,
    current_user_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get a single event by ID"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    event_dict = {
        "id": event.id,
        "name": event.name,
        "description": event.description,
        "start_date": event.start_date,
        "end_date": event.end_date,
        "event_type": event.event_type,
        "owner_id": event.owner_id,
        "calendar_id": event.calendar_id,
        "parent_recurring_event_id": event.parent_recurring_event_id,
        "created_at": event.created_at,
        "updated_at": event.updated_at,
        "start_date_formatted": event.start_date.strftime("%Y-%m-%d %H:%M"),
        "end_date_formatted": event.end_date.strftime("%Y-%m-%d %H:%M") if event.end_date else None
    }

    # Add ownership info if current_user_id provided
    if current_user_id is not None:
        is_owner = event.owner_id == current_user_id
        event_dict["is_owner"] = is_owner
        event_dict["owner_display"] = "Yo" if is_owner else f"Usuario #{event.owner_id}"

    return event_dict


@router.get("/{event_id}/interactions", response_model=List[EventInteractionResponse])
async def get_event_interactions(event_id: int, db: Session = Depends(get_db)):
    """Get all interactions for a specific event"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    interactions = db.query(EventInteraction).filter(
        EventInteraction.event_id == event_id
    ).all()
    return interactions


@router.get("/{event_id}/interactions-enriched", response_model=List[EventInteractionEnrichedResponse])
async def get_event_interactions_enriched(event_id: int, db: Session = Depends(get_db)):
    """Get all interactions for a specific event with enriched user information"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Use JOIN to get all data in a single query
    results = db.query(
        EventInteraction,
        User,
        Contact
    ).outerjoin(
        User, EventInteraction.user_id == User.id
    ).outerjoin(
        Contact, User.contact_id == Contact.id
    ).filter(
        EventInteraction.event_id == event_id
    ).all()

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

        enriched.append({
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
            "updated_at": interaction.updated_at
        })

    return enriched


@router.get("/{event_id}/available-invitees", response_model=List[AvailableInviteeResponse])
async def get_available_invitees(event_id: int, db: Session = Depends(get_db)):
    """Get list of users available to be invited to an event (excludes owner and already invited users)"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Get user IDs that already have interactions with this event (in a single subquery)
    invited_user_ids_subquery = db.query(EventInteraction.user_id).filter(
        EventInteraction.event_id == event_id
    ).subquery()

    # Get all users NOT in the invited list and NOT the owner, with Contact info in one query
    results = db.query(
        User,
        Contact
    ).outerjoin(
        Contact, User.contact_id == Contact.id
    ).filter(
        User.id != event.owner_id,
        ~User.id.in_(invited_user_ids_subquery)
    ).all()

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

        available.append({
            "id": user.id,
            "username": username,
            "contact_name": contact_name,
            "display_name": display_name
        })

    return available


@router.post("", response_model=EventResponse, status_code=201)
async def create_event(
    event: EventCreate,
    force: bool = False,
    db: Session = Depends(get_db)
):
    """Create a new event with optional conflict validation.

    If force is False, validates that the event time does not conflict for the owner
    with any of their other accessible events. Returns 409 with conflict list if found.
    """
    owner = db.query(User).filter(User.id == event.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner user not found")

    # Conflict detection (server-side business logic formerly in CLI)
    if not force:
        # Collect all event IDs the owner has access to (same logic as /events/check-conflicts)
        event_ids = set()

        own_events = db.query(Event.id).filter(Event.owner_id == event.owner_id).all()
        event_ids.update([e[0] for e in own_events])

        subscribed_events = db.query(EventInteraction.event_id).filter(
            EventInteraction.user_id == event.owner_id,
            EventInteraction.interaction_type == 'subscribed'
        ).all()
        event_ids.update([e[0] for e in subscribed_events])

        invited_events = db.query(EventInteraction.event_id).filter(
            EventInteraction.user_id == event.owner_id,
            EventInteraction.interaction_type == 'invited',
            EventInteraction.status == 'accepted'
        ).all()
        event_ids.update([e[0] for e in invited_events])

        calendar_memberships = db.query(CalendarMembership.calendar_id).filter(
            CalendarMembership.user_id == event.owner_id,
            CalendarMembership.status == 'accepted',
            CalendarMembership.role.in_(['owner', 'admin'])
        ).all()
        if calendar_memberships:
            calendar_ids = [m[0] for m in calendar_memberships]
            calendar_events = db.query(Event.id).filter(
                Event.calendar_id.in_(calendar_ids)
            ).all()
            event_ids.update([e[0] for e in calendar_events])

        conflicts = []
        if event_ids:
            all_events = db.query(Event).filter(Event.id.in_(event_ids)).all()

            # Ensure incoming dates are timezone-aware (convert naive to UTC if needed)
            start_date = event.start_date
            if start_date.tzinfo is None:
                start_date = start_date.replace(tzinfo=timezone.utc)

            end_date = event.end_date
            if end_date and end_date.tzinfo is None:
                end_date = end_date.replace(tzinfo=timezone.utc)

            for ev in all_events:
                # Overlap check with same semantics as /events/check-conflicts
                evt_start = ev.start_date
                evt_end = ev.end_date

                has_conflict = False
                if not end_date and not evt_end:
                    if abs((start_date - evt_start).total_seconds()) < 300:
                        has_conflict = True
                elif not end_date:
                    if evt_end and evt_start <= start_date <= evt_end:
                        has_conflict = True
                elif not evt_end:
                    if start_date <= evt_start <= end_date:
                        has_conflict = True
                else:
                    if max(start_date, evt_start) < min(end_date, evt_end):
                        has_conflict = True

                if has_conflict:
                    conflicts.append({
                        "id": ev.id,
                        "name": ev.name,
                        "start_date": ev.start_date,
                        "end_date": ev.end_date,
                        "event_type": ev.event_type,
                        "start_date_formatted": ev.start_date.strftime("%Y-%m-%d %H:%M"),
                        "end_date_formatted": ev.end_date.strftime("%Y-%m-%d %H:%M") if ev.end_date else None
                    })

        if conflicts:
            raise HTTPException(status_code=409, detail={
                "message": "Event time conflicts detected",
                "conflicts": conflicts
            })

    # Ensure dates are timezone-aware before saving to database
    event_data = event.dict()
    if event_data['start_date'].tzinfo is None:
        event_data['start_date'] = event_data['start_date'].replace(tzinfo=timezone.utc)
    if event_data.get('end_date') and event_data['end_date'].tzinfo is None:
        event_data['end_date'] = event_data['end_date'].replace(tzinfo=timezone.utc)

    # VALIDATION: Only recurring events can have end_date
    if event_data.get('event_type') == 'regular':
        event_data['end_date'] = None

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
    event_data = event.dict()
    if event_data['start_date'].tzinfo is None:
        event_data['start_date'] = event_data['start_date'].replace(tzinfo=timezone.utc)
    if event_data.get('end_date') and event_data['end_date'].tzinfo is None:
        event_data['end_date'] = event_data['end_date'].replace(tzinfo=timezone.utc)

    # VALIDATION: Only recurring events can have end_date
    if event_data.get('event_type') == 'regular':
        event_data['end_date'] = None

    for key, value in event_data.items():
        setattr(db_event, key, value)

    db.commit()
    db.refresh(db_event)
    return db_event


@router.delete("/{event_id}")
async def delete_event(event_id: int, db: Session = Depends(get_db)):
    """Delete an event"""
    db_event = db.query(Event).filter(Event.id == event_id).first()
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    db.delete(db_event)
    db.commit()
    return {"message": "Event deleted successfully", "id": event_id}


# Alias endpoint for creating event interactions
@router.post("/event-interactions", response_model=EventInteractionResponse, status_code=201)
async def create_event_interaction_alias(interaction: EventInteractionCreate, db: Session = Depends(get_db)):
    """Create a new event interaction (alias for /interactions)"""
    event = db.query(Event).filter(Event.id == interaction.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    user = db.query(User).filter(User.id == interaction.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

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
