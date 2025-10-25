"""
Users Router

Handles all user-related endpoints including user events.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional, Union

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id, get_current_user_id_optional
from crud import calendar_membership, contact, event, event_interaction, recurring_config, user, user_block
from dependencies import check_user_not_banned, get_db
import models
from models import EventInteraction
from schemas import EventResponse, UserCreate, UserEnrichedResponse, UserPublicStats, UserResponse, UserSubscriptionResponse

logger = logging.getLogger(__name__)


router = APIRouter(prefix="/api/v1/users", tags=["users"])


@router.get("", response_model=List[Union[UserResponse, UserEnrichedResponse]])
async def get_users(public: Optional[bool] = None, enriched: bool = False, limit: int = 50, offset: int = 0, order_by: Optional[str] = "id", order_dir: str = "asc", db: Session = Depends(get_db)):
    """Get all users, optionally filtered by public status, optionally enriched with contact info"""
    return user.get_multi_with_optional_enrichment(
        db,
        public=public,
        enriched=enriched,
        skip=offset,
        limit=limit,
        order_by=order_by or "id",
        order_dir=order_dir
    )


@router.get("/me", response_model=Union[UserResponse, UserEnrichedResponse])
async def get_current_user(
    current_user_id: int = Depends(get_current_user_id),
    enriched: bool = False,
    db: Session = Depends(get_db)
):
    """Get the current authenticated user's information.

    Requires JWT authentication - provide token in Authorization header."""
    db_user = user.get(db, id=current_user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if enriched:
        # Get contact info if exists
        db_contact = None
        if db_user.contact_id:
            db_contact = contact.get(db, id=db_user.contact_id)

        # Build display name
        contact_name = db_contact.name if db_contact else None
        username = db_user.username
        if username and contact_name:
            display_name = f"{username} ({contact_name})"
        elif username:
            display_name = username
        elif contact_name:
            display_name = contact_name
        else:
            display_name = f"Usuario #{db_user.id}"

        return UserEnrichedResponse(
            id=db_user.id,
            username=db_user.username,
            auth_provider=db_user.auth_provider,
            auth_id=db_user.auth_id,
            profile_picture_url=db_user.profile_picture_url,
            contact_id=db_user.contact_id,
            contact_name=db_contact.name if db_contact else None,
            contact_phone=db_contact.phone if db_contact else None,
            display_name=display_name,
            last_login=db_user.last_login,
            created_at=db_user.created_at,
            updated_at=db_user.updated_at,
        )

    return db_user


@router.get("/{user_id}", response_model=Union[UserResponse, UserEnrichedResponse])
async def get_user(user_id: int, enriched: bool = False, db: Session = Depends(get_db)):
    """Get a single user by ID, optionally enriched with contact info"""
    db_user = user.get(db, id=user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if enriched:
        # Get contact info if exists
        db_contact = None
        if db_user.contact_id:
            db_contact = contact.get(db, id=db_user.contact_id)

        # Build display name
        contact_name = db_contact.name if db_contact else None
        username = db_user.username
        if username and contact_name:
            display_name = f"{username} ({contact_name})"
        elif username:
            display_name = username
        elif contact_name:
            display_name = contact_name
        else:
            display_name = f"Usuario #{db_user.id}"

        return UserEnrichedResponse(
            id=db_user.id,
            username=db_user.username,
            auth_provider=db_user.auth_provider,
            auth_id=db_user.auth_id,
            profile_picture_url=db_user.profile_picture_url,
            contact_id=db_user.contact_id,
            contact_name=db_contact.name if db_contact else None,
            contact_phone=db_contact.phone if db_contact else None,
            display_name=display_name,
            last_login=db_user.last_login,
            created_at=db_user.created_at,
            updated_at=db_user.updated_at,
        )

    return db_user


@router.get("/{user_id}/stats", response_model=UserPublicStats)
async def get_user_stats(user_id: int, db: Session = Depends(get_db)):
    """
    Get statistics for a public user.

    Returns:
    - Total number of subscribers
    - Total number of events created
    - Stats for each event (event_id, event_name, event_start_date, total_joined)

    Only available for public users. Returns 403 for private users.
    """
    stats = user.get_public_user_stats(db, user_id=user_id)

    if not stats:
        # User doesn't exist or is not public
        db_user = user.get(db, id=user_id)
        if not db_user:
            raise HTTPException(status_code=404, detail="User not found")
        else:
            raise HTTPException(status_code=403, detail="Statistics are only available for public users")

    return UserPublicStats(**stats)


@router.post("", response_model=UserResponse, status_code=201)
async def create_user(user_data: UserCreate, db: Session = Depends(get_db)):
    """Create a new user"""
    # Check if auth_id already exists for this provider
    existing = user.get_by_auth(db, auth_provider=user_data.auth_provider, auth_id=user_data.auth_id)
    if existing:
        raise HTTPException(status_code=400, detail="User already exists for this auth provider")

    db_user = user.create(db, obj_in=user_data)
    return db_user


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserCreate,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Update an existing user.

    Requires JWT authentication - provide token in Authorization header.
    Only the user themselves can update their account.
    """
    # Check if user exists first
    db_user = user.get(db, id=user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if user is updating their own account
    if user_id != current_user_id:
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to update this user. You can only update your own account."
        )

    updated_user = user.update(db, db_obj=db_user, obj_in=user_data)
    return updated_user


@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Delete a user.

    Requires JWT authentication - provide token in Authorization header.
    Only the user themselves can delete their account.
    """
    # Check if user exists first
    db_user = user.get(db, id=user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if user is deleting their own account
    if user_id != current_user_id:
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to delete this user. You can only delete your own account."
        )

    user.delete(db, id=user_id)
    return {"message": "User deleted successfully", "id": user_id}


@router.get("/{user_id}/events", response_model=List[EventResponse])
async def get_user_events(user_id: int, include_past: bool = False, from_date: Optional[datetime] = None, to_date: Optional[datetime] = None, search: Optional[str] = None, filter: Optional[str] = None, limit: Optional[int] = None, offset: int = 0, db: Session = Depends(get_db)):
    """
    Get all events for a user from multiple sources:
    - Own events (where user is owner)
    - Joined events (via EventInteraction type='joined' with status='accepted' - admin/member roles)
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
    - filter: predefined filters ('today', 'next_7_days', 'this_month') - overrides from_date/to_date
    - limit: maximum number of events to return (default: all)
    - offset: number of events to skip for pagination (default: 0)
    """
    # ============================================================
    # 1. VALIDATION AND DATE SETUP
    # ============================================================
    db_user = user.get(db, id=user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if user is banned
    check_user_not_banned(user_id, db)

    # Apply predefined filters
    now = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

    if filter == "today":
        from_date = now
        to_date = now + timedelta(days=1)  # Until end of today
    elif filter == "next_7_days":
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
            to_date = from_date + timedelta(days=30 * 30)  # 30 months

    if not include_past:
        now_midnight = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        if from_date < now_midnight:
            from_date = now_midnight

    # ============================================================
    # 2. COLLECT EVENT IDs WITH SOURCES (priority: owned > joined > subscribed > invited > calendar)
    # ============================================================
    event_sources = {}  # event_id -> source_type

    # Own events (highest priority)
    own_event_ids = event.get_event_ids_by_owner(db, owner_id=user_id)
    for event_id in own_event_ids:
        event_sources[event_id] = "owned"

    # Joined events (events where user is admin/member with accepted status)
    joined_event_ids = event_interaction.get_event_ids_by_user_type_status(db, user_id=user_id, interaction_type="joined", status="accepted")
    for event_id in joined_event_ids:
        if event_id not in event_sources:
            event_sources[event_id] = "joined"

    # Subscribed events
    subscribed_event_ids = event_interaction.get_event_ids_by_user_type_status(db, user_id=user_id, interaction_type="subscribed")
    for event_id in subscribed_event_ids:
        if event_id not in event_sources:
            event_sources[event_id] = "subscribed"

    # Invited events
    invited_event_ids = event_interaction.get_event_ids_by_user_type_status(db, user_id=user_id, interaction_type="invited")
    for event_id in invited_event_ids:
        if event_id not in event_sources:
            event_sources[event_id] = "invited"

    # Calendar events (lowest priority)
    calendar_ids = calendar_membership.get_calendar_ids_by_user(db, user_id=user_id, status="accepted", roles=["owner", "admin"])

    if calendar_ids:
        calendar_event_ids = event.get_event_ids_by_calendars(db, calendar_ids=calendar_ids)
        for event_id in calendar_event_ids:
            if event_id not in event_sources:
                event_sources[event_id] = "calendar"

    if not event_sources:
        return []

    # ============================================================
    # 3. FETCH EVENTS (single query)
    # ============================================================
    events = event.get_by_ids_in_date_range(
        db,
        event_ids=list(event_sources.keys()),
        from_date=from_date,
        to_date=to_date,
        search=search
    )

    if not events:
        return []

    # ============================================================
    # 3.5. FILTER OUT BLOCKED USERS
    # ============================================================
    # Get IDs of users that have mutual blocks with the current user
    blocked_user_ids = user_block.get_blocked_user_ids_bidirectional(db, user_id=user_id)

    # Filter out events owned by blocked users
    if blocked_user_ids:
        events = [e for e in events if e.owner_id not in blocked_user_ids]

    if not events:
        return []

    # ============================================================
    # 3.6. FETCH ENRICHMENT DATA (owners, calendars, attendees)
    # ============================================================
    # Get unique owner IDs and calendar IDs
    owner_ids = list(set(e.owner_id for e in events))
    calendar_ids = list(set(e.calendar_id for e in events if e.calendar_id))

    # Fetch owner info (name, is_public, profile_picture)
    owner_info = {}  # owner_id -> {name, is_public, profile_picture}
    if owner_ids:
        owners_query = db.query(models.User, models.Contact).join(
            models.Contact, models.User.contact_id == models.Contact.id, isouter=True
        ).filter(models.User.id.in_(owner_ids)).all()

        for user_obj, contact_obj in owners_query:
            owner_info[user_obj.id] = {
                "name": contact_obj.name if contact_obj else None,
                "is_public": user_obj.is_public,
                "profile_picture": user_obj.profile_picture_url
            }

    # Fetch calendar info (name, color) - assuming calendars table has these fields
    calendar_info = {}  # calendar_id -> {name, color}
    if calendar_ids:
        calendars_query = db.query(models.Calendar).filter(
            models.Calendar.id.in_(calendar_ids)
        ).all()

        for cal in calendars_query:
            calendar_info[cal.id] = {
                "name": cal.name,
                "color": getattr(cal, 'color', None) if hasattr(cal, 'color') else None
            }

    # Fetch attendees for all events (users with accepted interactions)
    event_ids = [e.id for e in events]
    attendees_map = {}  # event_id -> [user_dict]
    if event_ids:
        attendees_query = db.query(
            models.EventInteraction.event_id,
            models.User,
            models.Contact
        ).join(
            models.User, models.EventInteraction.user_id == models.User.id
        ).join(
            models.Contact, models.User.contact_id == models.Contact.id, isouter=True
        ).filter(
            models.EventInteraction.event_id.in_(event_ids),
            models.EventInteraction.status == "accepted"
        ).all()

        for event_id, user_obj, contact_obj in attendees_query:
            if event_id not in attendees_map:
                attendees_map[event_id] = []
            attendees_map[event_id].append({
                "id": user_obj.id,
                "name": contact_obj.name if contact_obj else None,
                "profile_picture": user_obj.profile_picture_url
            })

    # ============================================================
    # 4. FETCH ALL RECURRING CONFIGS AND INVITATIONS (batch queries)
    # ============================================================
    # Get all recurring event IDs in one go
    recurring_event_ids = [e.id for e in events if e.event_type == "recurring"]

    # Fetch all recurring configs at once
    recurring_configs = {}  # event_id -> config_id
    if recurring_event_ids:
        recurring_configs = recurring_config.get_configs_by_event_ids(db, event_ids=recurring_event_ids)

    # Fetch all invitations for this user at once
    invitations = {}  # event_id -> status
    if recurring_event_ids:
        invitations = event_interaction.get_invitations_by_user_and_events(db, user_id=user_id, event_ids=recurring_event_ids)

    # ============================================================
    # 5. PROCESS RECURRING EVENTS VISIBILITY
    # ============================================================
    events_to_hide = set()

    # Build parent->instances map
    instance_map = {}  # config_id -> [instance_event_ids]
    for ev in events:
        if ev.parent_recurring_event_id:
            parent_config_id = ev.parent_recurring_event_id
            if parent_config_id not in instance_map:
                instance_map[parent_config_id] = []
            instance_map[parent_config_id].append(ev.id)

    # Determine what to hide based on user permissions
    for ev in events:
        if ev.event_type != "recurring":
            continue

        base_id = ev.id
        config_id = recurring_configs.get(base_id)
        if not config_id:
            continue

        source = event_sources.get(base_id, "owned")
        invitation_status = invitations.get(base_id)

        # Determine user's access level
        is_owner = source == "owned"
        has_calendar_access = source == "calendar"
        has_accepted_invite = invitation_status == "accepted"
        has_pending_invite = invitation_status == "pending"

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
    # 5.5. GET USER INTERACTIONS FOR VISIBLE EVENTS
    # ============================================================
    visible_event_ids = [e.id for e in visible_events]
    user_interactions = {}
    if visible_event_ids:
        interactions = event_interaction.get_by_event_ids_and_user(db, event_ids=visible_event_ids, user_id=user_id)
        for interaction in interactions:
            user_interactions[interaction.event_id] = {"interaction_type": interaction.interaction_type, "status": interaction.status, "role": interaction.role, "invited_by_user_id": interaction.invited_by_user_id, "note": interaction.note, "is_new": interaction.is_new}

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
    for ev in visible_events:
        rounded_start = round_to_5min(ev.start_date)

        # Get owner info
        owner = owner_info.get(ev.owner_id, {})

        # Get calendar info
        calendar = calendar_info.get(ev.calendar_id, {}) if ev.calendar_id else {}

        # Determine if birthday (check calendar name or event name)
        is_birthday = False
        if calendar.get("name"):
            is_birthday = "cumpleaños" in calendar["name"].lower() or "birthday" in calendar["name"].lower()
        if not is_birthday and ev.name:
            is_birthday = "cumpleaños" in ev.name.lower() or "birthday" in ev.name.lower()

        event_dict = {
            "id": ev.id,
            "name": ev.name,
            "description": ev.description,
            "start_date": rounded_start.isoformat(),
            "event_type": ev.event_type,
            "owner_id": ev.owner_id,
            "calendar_id": ev.calendar_id,
            "parent_recurring_event_id": ev.parent_recurring_event_id,
            "created_at": ev.created_at.isoformat(),
            "updated_at": ev.updated_at.isoformat(),
            "interaction": user_interactions.get(ev.id),
            # Owner info
            "owner_name": owner.get("name"),
            "owner_profile_picture": owner.get("profile_picture"),
            "is_owner_public": owner.get("is_public"),
            # Calendar info
            "calendar_name": calendar.get("name"),
            "calendar_color": calendar.get("color"),
            # Event characteristics
            "is_birthday": is_birthday,
            # Attendees
            "attendees": attendees_map.get(ev.id, []),
        }
        result.append(event_dict)

    # Apply pagination
    if limit is not None:
        start_idx = max(0, offset)
        end_idx = start_idx + limit
        result = result[start_idx:end_idx]

    return result


@router.post("/{target_user_id}/subscribe")
async def subscribe_to_user(
    target_user_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Subscribe the authenticated user to all events of another user (bulk operation).

    Requires JWT authentication - provide token in Authorization header.

    This creates 'subscribed' interactions for all events owned by target_user_id.
    Returns the count of successful subscriptions and any errors.
    """
    # Verify both users exist
    db_user = user.get(db, id=current_user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db_target_user = user.get(db, id=target_user_id)
    if not db_target_user:
        raise HTTPException(status_code=404, detail="Target user not found")

    # Get all events owned by target user
    events = event.get_by_owner(db, owner_id=target_user_id)

    if not events:
        return {"message": "Target user has no events", "subscribed_count": 0, "already_subscribed_count": 0, "error_count": 0}

    subscribed_count = 0
    already_subscribed_count = 0
    error_count = 0

    for db_event in events:
        # Check if subscription already exists
        existing = event_interaction.get_interaction(db, event_id=db_event.id, user_id=current_user_id)

        if existing and existing.interaction_type == "subscribed":
            already_subscribed_count += 1
            continue

        try:
            # Create subscription
            interaction = EventInteraction(event_id=db_event.id, user_id=current_user_id, interaction_type="subscribed")
            db.add(interaction)
            subscribed_count += 1
        except Exception as e:
            logger.error(f"Error subscribing to event {db_event.id}: {e}")
            error_count += 1

    db.commit()

    return {"message": f"Subscribed to {subscribed_count} events", "subscribed_count": subscribed_count, "already_subscribed_count": already_subscribed_count, "error_count": error_count, "total_events": len(events)}


@router.get("/{user_id}/subscriptions", response_model=List[UserSubscriptionResponse])
async def get_user_subscriptions(user_id: int, db: Session = Depends(get_db)):
    """
    Get all public users that the given user is subscribed to with statistics.

    This endpoint is optimized to avoid N+1 queries by using JOINs and aggregations.
    It returns a list of unique public users with:
    - new_events_count: Events created in the last 7 days
    - total_events_count: Total events owned by this user
    - subscribers_count: Total unique subscribers to this user's events

    Returns:
    - List of UserSubscriptionResponse objects for each public user
    """
    from datetime import timedelta
    from sqlalchemy import func, distinct

    # Verify user exists
    db_user = user.get(db, id=user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Query to get unique public users from subscribed events
    subscribed_users = (
        db.query(models.User)
        .join(models.Event, models.Event.owner_id == models.User.id)
        .join(models.EventInteraction, models.EventInteraction.event_id == models.Event.id)
        .filter(
            models.EventInteraction.user_id == user_id,
            models.EventInteraction.interaction_type == "subscribed",
            models.User.is_public == True
        )
        .distinct()
        .all()
    )

    # Calculate statistics for each user
    result = []
    seven_days_ago = datetime.now() - timedelta(days=7)

    for public_user in subscribed_users:
        # Count total events
        total_events = db.query(func.count(models.Event.id)).filter(
            models.Event.owner_id == public_user.id
        ).scalar()

        # Count new events (created in last 7 days)
        new_events = db.query(func.count(models.Event.id)).filter(
            models.Event.owner_id == public_user.id,
            models.Event.created_at >= seven_days_ago
        ).scalar()

        # Count unique subscribers (distinct users subscribed to any event of this owner)
        subscribers = db.query(func.count(distinct(models.EventInteraction.user_id))).join(
            models.Event, models.Event.id == models.EventInteraction.event_id
        ).filter(
            models.Event.owner_id == public_user.id,
            models.EventInteraction.interaction_type == "subscribed"
        ).scalar()

        # Build response
        result.append(UserSubscriptionResponse(
            id=public_user.id,
            contact_id=public_user.contact_id,
            username=public_user.username,
            auth_provider=public_user.auth_provider,
            auth_id=public_user.auth_id,
            is_public=public_user.is_public,
            is_admin=public_user.is_admin,
            profile_picture_url=public_user.profile_picture_url,
            last_login=public_user.last_login,
            created_at=public_user.created_at,
            updated_at=public_user.updated_at,
            new_events_count=new_events or 0,
            total_events_count=total_events or 0,
            subscribers_count=subscribers or 0,
        ))

    return result
