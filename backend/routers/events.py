"""
Events Router

Handles all event-related endpoints including conflict checking.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from models import Event, User, EventInteraction, CalendarMembership
from schemas import EventCreate, EventResponse, EventInteractionResponse, EventInteractionCreate
from dependencies import get_db


router = APIRouter(
    prefix="/events",
    tags=["events"]
)


@router.get("", response_model=List[EventResponse])
async def get_events(owner_id: Optional[int] = None, db: Session = Depends(get_db)):
    """Get all events, optionally filtered by owner_id"""
    query = db.query(Event)
    if owner_id:
        query = query.filter(Event.owner_id == owner_id)
    events = query.all()
    return events


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
        if not end_date and not evt_end:
            if abs((start_date - evt_start).total_seconds()) < 300:
                conflicts.append(event)
        elif not end_date:
            if evt_end and evt_start <= start_date <= evt_end:
                conflicts.append(event)
        elif not evt_end:
            if start_date <= evt_start <= end_date:
                conflicts.append(event)
        else:
            if max(start_date, evt_start) < min(end_date, evt_end):
                conflicts.append(event)

    return conflicts


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(event_id: int, db: Session = Depends(get_db)):
    """Get a single event by ID"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event


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


@router.post("", response_model=EventResponse, status_code=201)
async def create_event(event: EventCreate, db: Session = Depends(get_db)):
    """Create a new event"""
    owner = db.query(User).filter(User.id == event.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner user not found")

    db_event = Event(**event.dict())
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

    for key, value in event.dict().items():
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
@router.post("-interactions", response_model=EventInteractionResponse, status_code=201)
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
