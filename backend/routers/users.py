"""
Users Router

Handles all user-related endpoints including user events and dashboard.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from models import User, Event, EventInteraction, CalendarMembership, RecurringEventConfig, Calendar, Contact
from schemas import UserCreate, UserResponse, UserEnrichedResponse, EventResponse
from dependencies import get_db
from typing import Union

logger = logging.getLogger(__name__)


router = APIRouter(
    prefix="/users",
    tags=["users"]
)


@router.get("", response_model=List[Union[UserResponse, UserEnrichedResponse]])
async def get_users(
    public: Optional[bool] = None,
    enriched: bool = False,
    limit: int = 50,
    offset: int = 0,
    order_by: Optional[str] = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all users, optionally filtered by public status, optionally enriched with contact info"""
    query = db.query(User)
    if public is not None:
        if public:
            # Public users have a username
            query = query.filter(User.username.isnot(None))
        else:
            # Private users don't have a username
            query = query.filter(User.username.is_(None))

    # Apply ordering and pagination
    order_col = getattr(User, order_by) if order_by and hasattr(User, str(order_by)) else User.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))

    users = query.all()

    # If enriched, add contact information
    if enriched:
        # Use JOIN to get contact data efficiently
        results = db.query(User, Contact).outerjoin(
            Contact, User.contact_id == Contact.id
        )

        if public is not None:
            if public:
                results = results.filter(User.username.isnot(None))
            else:
                results = results.filter(User.username.is_(None))

        # Apply ordering and pagination consistently on enriched path
        order_col = getattr(User, order_by) if order_by and hasattr(User, str(order_by)) else User.id
        if order_dir and order_dir.lower() == "desc":
            results = results.order_by(order_col.desc())
        else:
            results = results.order_by(order_col.asc())

        results = results.offset(max(0, offset)).limit(max(1, min(200, limit))).all()

        enriched_users = []
        for user, contact in results:
            contact_name = contact.name if contact else None
            contact_phone = contact.phone if contact else None

            # Build display name
            username = user.username
            if username and contact_name:
                display_name = f"{username} ({contact_name})"
            elif username:
                display_name = username
            elif contact_name:
                display_name = contact_name
            else:
                display_name = f"Usuario #{user.id}"

            # Create UserEnrichedResponse instance directly
            enriched_users.append(UserEnrichedResponse(
                id=user.id,
                username=user.username,
                auth_provider=user.auth_provider,
                auth_id=user.auth_id,
                profile_picture_url=user.profile_picture_url,
                contact_id=user.contact_id,
                contact_name=contact_name,
                contact_phone=contact_phone,
                display_name=display_name,
                last_login=user.last_login,
                created_at=user.created_at,
                updated_at=user.updated_at
            ))

        return enriched_users

    return users


@router.get("/{user_id}", response_model=Union[UserResponse, UserEnrichedResponse])
async def get_user(user_id: int, enriched: bool = False, db: Session = Depends(get_db)):
    """Get a single user by ID, optionally enriched with contact info"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if enriched:
        # Get contact info if exists
        contact = None
        if user.contact_id:
            contact = db.query(Contact).filter(Contact.id == user.contact_id).first()

        # Build display name
        contact_name = contact.name if contact else None
        username = user.username
        if username and contact_name:
            display_name = f"{username} ({contact_name})"
        elif username:
            display_name = username
        elif contact_name:
            display_name = contact_name
        else:
            display_name = f"Usuario #{user.id}"

        return UserEnrichedResponse(
            id=user.id,
            username=user.username,
            auth_provider=user.auth_provider,
            auth_id=user.auth_id,
            profile_picture_url=user.profile_picture_url,
            contact_id=user.contact_id,
            contact_name=contact.name if contact else None,
            contact_phone=contact.phone if contact else None,
            display_name=display_name,
            last_login=user.last_login,
            created_at=user.created_at,
            updated_at=user.updated_at
        )

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
    filter: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get all events for a user from multiple sources:
    - Own events (where user is owner)
    - Subscribed events (via EventInteraction type='subscribed')
    - Invited events (via EventInteraction type='invited')
    - Calendar events (via CalendarMembership with role owner/admin)

    Recurring events logic:
    - For owned/calendar/accepted events: show instances, hide base
    - For pending invitations: show base, hide instances

    Params:
    - include_past: if False, filters out past events
    - from_date, to_date: date range (default: today to +30 months)
    - search: case-insensitive name filter
    - filter: predefined filters ('next_7_days', 'this_month') - overrides from_date/to_date
    """
    # ============================================================
    # 1. VALIDATION AND DATE SETUP
    # ============================================================
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Apply predefined filters
    now = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

    if filter == "next_7_days":
        from_date = now
        to_date = now + timedelta(days=7)
    elif filter == "this_month":
        from_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        if now.month == 12:
            to_date = from_date.replace(year=now.year + 1, month=1, day=1) - timedelta(seconds=1)
        else:
            to_date = from_date.replace(month=now.month + 1, day=1) - timedelta(seconds=1)
    else:
        if from_date is None:
            from_date = now
        if to_date is None:
            to_date = from_date + timedelta(days=30*30)  # 30 months

    if not include_past:
        now_midnight = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        if from_date < now_midnight:
            from_date = now_midnight

    # ============================================================
    # 2. COLLECT EVENT IDs WITH SOURCES (priority: owned > subscribed > invited > calendar)
    # ============================================================
    event_sources = {}  # event_id -> source_type

    # Own events (highest priority)
    own_event_ids = db.query(Event.id).filter(Event.owner_id == user_id).all()
    for (event_id,) in own_event_ids:
        event_sources[event_id] = 'owned'

    # Subscribed events
    subscribed_event_ids = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'subscribed'
    ).all()
    for (event_id,) in subscribed_event_ids:
        if event_id not in event_sources:
            event_sources[event_id] = 'subscribed'

    # Invited events
    invited_event_ids = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'invited'
    ).all()
    for (event_id,) in invited_event_ids:
        if event_id not in event_sources:
            event_sources[event_id] = 'invited'

    # Calendar events (lowest priority)
    calendar_ids = db.query(CalendarMembership.calendar_id).filter(
        CalendarMembership.user_id == user_id,
        CalendarMembership.status == 'accepted',
        CalendarMembership.role.in_(['owner', 'admin'])
    ).all()

    if calendar_ids:
        calendar_event_ids = db.query(Event.id).filter(
            Event.calendar_id.in_([cid for (cid,) in calendar_ids])
        ).all()
        for (event_id,) in calendar_event_ids:
            if event_id not in event_sources:
                event_sources[event_id] = 'calendar'

    if not event_sources:
        return []

    # ============================================================
    # 3. FETCH EVENTS (single query)
    # ============================================================
    base_query = db.query(Event).filter(
        Event.id.in_(event_sources.keys()),
        Event.start_date >= from_date,
        Event.start_date <= to_date
    )

    # Apply search in DB when provided
    if search:
        like = f"%{search}%"
        base_query = base_query.filter(Event.name.ilike(like))

    events = base_query.order_by(Event.start_date).all()

    if not events:
        return []

    # No additional in-memory search needed; handled by DB ilike

    # ============================================================
    # 4. FETCH ALL RECURRING CONFIGS AND INVITATIONS (batch queries)
    # ============================================================
    # Get all recurring event IDs in one go
    recurring_event_ids = [e.id for e in events if e.event_type == 'recurring']

    # Fetch all recurring configs at once
    recurring_configs = {}  # event_id -> config_id
    if recurring_event_ids:
        configs = db.query(
            RecurringEventConfig.event_id,
            RecurringEventConfig.id
        ).filter(
            RecurringEventConfig.event_id.in_(recurring_event_ids)
        ).all()
        recurring_configs = {event_id: config_id for event_id, config_id in configs}

    # Fetch all invitations for this user at once
    invitations = {}  # event_id -> status
    if recurring_event_ids:
        user_invitations = db.query(
            EventInteraction.event_id,
            EventInteraction.status
        ).filter(
            EventInteraction.event_id.in_(recurring_event_ids),
            EventInteraction.user_id == user_id,
            EventInteraction.interaction_type == 'invited'
        ).all()
        invitations = {event_id: status for event_id, status in user_invitations}

    # ============================================================
    # 5. PROCESS RECURRING EVENTS VISIBILITY
    # ============================================================
    events_to_hide = set()

    # Build parent->instances map
    instance_map = {}  # config_id -> [instance_event_ids]
    for event in events:
        if event.parent_recurring_event_id:
            parent_config_id = event.parent_recurring_event_id
            if parent_config_id not in instance_map:
                instance_map[parent_config_id] = []
            instance_map[parent_config_id].append(event.id)

    # Determine what to hide based on user permissions
    for event in events:
        if event.event_type != 'recurring':
            continue

        base_id = event.id
        config_id = recurring_configs.get(base_id)
        if not config_id:
            continue

        source = event_sources.get(base_id, 'owned')
        invitation_status = invitations.get(base_id)

        # Determine user's access level
        is_owner = (source == 'owned')
        has_calendar_access = (source == 'calendar')
        has_accepted_invite = (invitation_status == 'accepted')
        has_pending_invite = (invitation_status == 'pending')

        instance_ids = instance_map.get(config_id, [])

        if is_owner or has_calendar_access or has_accepted_invite:
            # User has full access -> hide base, show instances
            events_to_hide.add(base_id)
            # Propagate source to instances
            for inst_id in instance_ids:
                if inst_id in event_sources:
                    event_sources[inst_id] = source
        elif has_pending_invite:
            # User has pending invite -> show base, hide instances
            events_to_hide.update(instance_ids)

    # Filter out hidden events
    visible_events = [e for e in events if e.id not in events_to_hide]

    # ============================================================
    # 6. BUILD RESPONSE (round times, convert to dict)
    # ============================================================
    def round_to_5min(dt):
        """Round datetime to nearest 5-minute interval"""
        if not dt:
            return None
        minute = (dt.minute // 5) * 5
        return dt.replace(minute=minute, second=0, microsecond=0)

    result = []
    for event in visible_events:
        rounded_start = round_to_5min(event.start_date)
        rounded_end = round_to_5min(event.end_date) if event.end_date else None

        is_owner = event.owner_id == user_id
        owner_display = "Yo" if is_owner else f"Usuario #{event.owner_id}"

        event_dict = {
            'id': event.id,
            'name': event.name,
            'description': event.description,
            'start_date': rounded_start.isoformat(),
            'end_date': rounded_end.isoformat() if rounded_end else None,
            'event_type': event.event_type,
            'source': event_sources.get(event.id, 'owned'),
            'owner_id': event.owner_id,
            'calendar_id': event.calendar_id,
            'birthday_user_id': event.birthday_user_id,
            'parent_calendar_id': event.parent_calendar_id,
            'parent_recurring_event_id': event.parent_recurring_event_id,
            'created_at': event.created_at.isoformat(),
            'updated_at': event.updated_at.isoformat(),
            'start_date_formatted': rounded_start.strftime("%Y-%m-%d %H:%M"),
            'end_date_formatted': rounded_end.strftime("%Y-%m-%d %H:%M") if rounded_end else None,
            'is_owner': is_owner,
            'owner_display': owner_display
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

    # Prepare next event with formatted data
    next_event_data = None
    if next_event:
        days_until = (next_event.start_date.replace(tzinfo=None) - now).days

        # Format time until text
        if days_until == 0:
            time_until_text = "¡Hoy!"
        elif days_until == 1:
            time_until_text = "Mañana"
        else:
            time_until_text = f"En {days_until} días"

        next_event_data = {
            "id": next_event.id,
            "name": next_event.name,
            "start_date": next_event.start_date.isoformat(),
            "start_date_formatted": next_event.start_date.strftime("%Y-%m-%d %H:%M"),
            "days_until": days_until,
            "time_until_text": time_until_text
        }

    # Format month name
    month_name = now.strftime('%B %Y')

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
                "start_date_formatted": e.start_date.strftime("%Y-%m-%d %H:%M"),
                "event_type": e.event_type
            } for e in sorted(upcoming_events, key=lambda e: e.start_date)[:10]
        ],
        "this_month_count": this_month_count,
        "this_month_name": month_name,
        "pending_invitations": pending_invitations,
        "next_event": next_event_data
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
