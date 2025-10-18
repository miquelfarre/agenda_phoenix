"""
Users Router

Handles all user-related endpoints including user events and dashboard.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from models import User, Event, EventInteraction, CalendarMembership, RecurringEventConfig, Calendar
from schemas import UserCreate, UserResponse, EventResponse
from dependencies import get_db

logger = logging.getLogger(__name__)


router = APIRouter(
    prefix="/users",
    tags=["users"]
)


@router.get("", response_model=List[UserResponse])
async def get_users(db: Session = Depends(get_db)):
    """Get all users"""
    users = db.query(User).all()
    return users


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get a single user by ID"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("", response_model=UserResponse, status_code=201)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """Create a new user"""
    # Check if auth_id already exists for this provider
    existing = db.query(User).filter(
        User.auth_provider == user.auth_provider,
        User.auth_id == user.auth_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already exists for this auth provider")

    db_user = User(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, user: UserCreate, db: Session = Depends(get_db)):
    """Update an existing user"""
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    for key, value in user.dict().items():
        setattr(db_user, key, value)

    db.commit()
    db.refresh(db_user)
    return db_user


@router.delete("/{user_id}")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    """Delete a user"""
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(db_user)
    db.commit()
    return {"message": "User deleted successfully", "id": user_id}


@router.get("/{user_id}/events", response_model=List[EventResponse])
async def get_user_events(
    user_id: int,
    include_past: bool = False,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get all events for a user including:
    - Own events (where user is owner)
    - Events from subscribed users
    - Events where user has been invited

    By default shows events from today 00:00 for the next 30 months.
    Times are rounded to 5-minute intervals.

    Optional parameters:
    - search: filter events by name (case-insensitive substring match)
    - from_date, to_date: date range filters
    """
    # Verify user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Set default date range
    if from_date is None:
        from_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    if to_date is None:
        to_date = from_date + timedelta(days=30*30)  # 30 months

    # If not including past events, ensure from_date is not in the past
    if not include_past:
        now_midnight = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        if from_date < now_midnight:
            from_date = now_midnight

    # Get all relevant event IDs and track their source
    event_sources = {}  # event_id -> source type

    # 1. Own events
    own_events = db.query(Event.id).filter(Event.owner_id == user_id).all()
    for e in own_events:
        event_sources[e[0]] = 'owned'

    # 2. Events from subscribed users (through EventInteraction with type 'subscribed')
    subscribed_events = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'subscribed'
    ).all()
    for e in subscribed_events:
        if e[0] not in event_sources:  # Don't override if already owned
            event_sources[e[0]] = 'subscribed'

    # 3. Events where user has been invited
    invited_events = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'invited'
    ).all()
    for e in invited_events:
        if e[0] not in event_sources:  # Don't override if already owned/subscribed
            event_sources[e[0]] = 'invited'

    # 4. Events from calendars where user is owner or admin
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
        for e in calendar_events:
            if e[0] not in event_sources:  # Don't override
                event_sources[e[0]] = 'calendar'

    event_ids = set(event_sources.keys())

    # Query events with date filtering
    if event_ids:
        events = db.query(Event).filter(
            Event.id.in_(event_ids),
            Event.start_date >= from_date,
            Event.start_date <= to_date
        ).order_by(Event.start_date).all()
    else:
        events = []

    # Apply search filter if provided
    if search:
        events = [e for e in events if search.lower() in e.name.lower()]

    # Filter recurring events logic:
    # - If user is owner OR has accepted invitation → show only instances (hide base)
    # - If user has pending invitation → show only base (hide instances)

    events_to_hide = set()

    # Build map of recurring configs
    recurring_configs = {}
    for event in events:
        if event.event_type == 'recurring':
            config = db.query(RecurringEventConfig).filter(
                RecurringEventConfig.event_id == event.id
            ).first()
            if config:
                recurring_configs[event.id] = config.id

    # Process each recurring base event
    for event in events:
        if event.event_type != 'recurring':
            continue

        base_id = event.id
        source = event_sources.get(base_id, 'owned')

        # Check if user owns this event
        is_owner = (source == 'owned')

        # Check invitation status
        invitation = db.query(EventInteraction).filter(
            EventInteraction.event_id == base_id,
            EventInteraction.user_id == user_id,
            EventInteraction.interaction_type == 'invited'
        ).first()

        has_accepted = invitation and invitation.status == 'accepted'
        has_pending = invitation and invitation.status == 'pending'

        # Get all instances of this recurring event
        config_id = recurring_configs.get(base_id)
        if config_id:
            instance_ids = [e.id for e in events if e.parent_recurring_event_id == config_id]

            # Apply filtering rules
            if is_owner or has_accepted:
                # Hide base, show instances
                events_to_hide.add(base_id)
                # Instances inherit the source from base
                for inst_id in instance_ids:
                    if inst_id in event_sources:
                        event_sources[inst_id] = source
            elif has_pending:
                # Hide instances, show base
                events_to_hide.update(instance_ids)

    # Filter out hidden events
    events = [e for e in events if e.id not in events_to_hide]

    # Round times to 5-minute intervals and convert to dict with source
    result = []
    for event in events:
        # Round start_date
        minute = (event.start_date.minute // 5) * 5
        rounded_start = event.start_date.replace(minute=minute, second=0, microsecond=0)

        # Round end_date if exists
        rounded_end = None
        if event.end_date:
            minute = (event.end_date.minute // 5) * 5
            rounded_end = event.end_date.replace(minute=minute, second=0, microsecond=0)

        # Get source for this event
        source = event_sources.get(event.id, 'owned')

        # Convert to dict and add source
        event_dict = {
            'id': event.id,
            'name': event.name,
            'description': event.description,
            'start_date': rounded_start.isoformat(),
            'end_date': rounded_end.isoformat() if rounded_end else None,
            'event_type': event.event_type,
            'source': source,  # New field: owned/subscribed/invited/calendar
            'owner_id': event.owner_id,
            'calendar_id': event.calendar_id,
            'birthday_user_id': event.birthday_user_id,
            'parent_calendar_id': event.parent_calendar_id,
            'parent_recurring_event_id': event.parent_recurring_event_id
        }
        result.append(event_dict)

    return result


@router.get("/{user_id}/dashboard")
async def get_user_dashboard(user_id: int, db: Session = Depends(get_db)):
    """
    Get dashboard statistics for a user.
    Returns calculated statistics including event counts, upcoming events, and pending invitations.
    """
    # Verify user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    now = datetime.now()

    # Get all user events
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

    # Query all events
    if event_ids:
        all_events = db.query(Event).filter(Event.id.in_(event_ids)).all()
    else:
        all_events = []

    # Count owned vs subscribed
    owned_count = len([e for e in all_events if e.owner_id == user_id])
    subscribed_count = len([e for e in all_events if e.owner_id != user_id])

    # Upcoming 7 days
    next_7_days = now + timedelta(days=7)
    upcoming_events = [e for e in all_events if now <= e.start_date <= next_7_days]

    # This month
    start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if now.month == 12:
        end_of_month = start_of_month.replace(year=now.year + 1, month=1, day=1) - timedelta(seconds=1)
    else:
        end_of_month = start_of_month.replace(month=now.month + 1, day=1) - timedelta(seconds=1)

    this_month_count = len([e for e in all_events if start_of_month <= e.start_date <= end_of_month])

    # Next event
    future_events = [e for e in all_events if e.start_date >= now]
    next_event = None
    if future_events:
        next_event = min(future_events, key=lambda e: e.start_date)

    # Pending invitations count
    pending_invitations = db.query(EventInteraction).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'invited',
        EventInteraction.status == 'pending'
    ).count()

    # Calendars count (owned)
    calendars_count = db.query(Calendar).filter(Calendar.user_id == user_id).count()

    return {
        "total_events": len(all_events),
        "owned_events": owned_count,
        "subscribed_events": subscribed_count,
        "calendars_count": calendars_count,
        "upcoming_7_days": len(upcoming_events),
        "upcoming_7_days_events": [
            {
                "id": e.id,
                "name": e.name,
                "start_date": e.start_date.isoformat(),
                "event_type": e.event_type
            } for e in sorted(upcoming_events, key=lambda e: e.start_date)[:10]
        ],
        "this_month_count": this_month_count,
        "pending_invitations": pending_invitations,
        "next_event": {
            "id": next_event.id,
            "name": next_event.name,
            "start_date": next_event.start_date.isoformat(),
            "days_until": (next_event.start_date - now).days
        } if next_event else None
    }


@router.post("/{user_id}/subscribe/{target_user_id}")
async def subscribe_to_user(user_id: int, target_user_id: int, db: Session = Depends(get_db)):
    """
    Subscribe a user to all events of another user (bulk operation).

    This creates 'subscribed' interactions for all events owned by target_user_id.
    Returns the count of successful subscriptions and any errors.
    """
    # Verify both users exist
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    target_user = db.query(User).filter(User.id == target_user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")

    # Get all events owned by target user
    events = db.query(Event).filter(Event.owner_id == target_user_id).all()

    if not events:
        return {
            "message": "Target user has no events",
            "subscribed_count": 0,
            "already_subscribed_count": 0,
            "error_count": 0
        }

    subscribed_count = 0
    already_subscribed_count = 0
    error_count = 0

    for event in events:
        # Check if subscription already exists
        existing = db.query(EventInteraction).filter(
            EventInteraction.event_id == event.id,
            EventInteraction.user_id == user_id,
            EventInteraction.interaction_type == 'subscribed'
        ).first()

        if existing:
            already_subscribed_count += 1
            continue

        try:
            # Create subscription
            interaction = EventInteraction(
                event_id=event.id,
                user_id=user_id,
                interaction_type='subscribed'
            )
            db.add(interaction)
            subscribed_count += 1
        except Exception as e:
            logger.error(f"Error subscribing to event {event.id}: {e}")
            error_count += 1

    db.commit()

    return {
        "message": f"Subscribed to {subscribed_count} events",
        "subscribed_count": subscribed_count,
        "already_subscribed_count": already_subscribed_count,
        "error_count": error_count,
        "total_events": len(events)
    }
