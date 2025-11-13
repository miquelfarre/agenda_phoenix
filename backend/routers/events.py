"""
Events Router

Handles all event-related endpoints.
"""

from typing import List, Optional, Union

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session, noload

from auth import get_current_user_id, get_current_user_id_optional
from crud import calendar_membership, event, event_interaction, user
from dependencies import check_event_permission, check_users_not_blocked, get_db, handle_recurring_event_rejection_cascade
from models import Event, EventInteraction, User, UserBlock
from schemas import AvailableInviteeResponse, EventCreate, EventDeleteRequest, EventResponse, EventUpdate, RecurringEventCreate
from utils import validate_pagination, handle_crud_error

router = APIRouter(prefix="/api/v1/events", tags=["events"])


@router.get("", response_model=List[EventResponse])
async def get_events(owner_id: Optional[int] = None, calendar_id: Optional[int] = None, current_user_id: Optional[int] = Depends(get_current_user_id_optional), limit: int = 50, offset: int = 0, order_by: Optional[str] = "start_date", order_dir: str = "asc", db: Session = Depends(get_db)):
    """Get events accessible to the authenticated user.

    Authentication is optional - provide JWT token in Authorization header for authenticated access.

    If authenticated, returns events the user has access to:
    - Events the user created (owner)
    - Events the user was invited to (with accepted invitations)
    - Events the user subscribed to
    - Events in calendars where user is owner/admin with accepted status

    If not authenticated, returns empty list (use public event discovery endpoints instead).

    Optional filters by owner_id or calendar_id can further narrow results."""
    # Validate pagination
    limit, offset = validate_pagination(limit, offset)

    # If user is authenticated, filter by accessible events
    if current_user_id is not None:
        # Get all event IDs accessible to this user
        accessible_event_ids = event.get_user_accessible_event_ids(db, user_id=current_user_id)

        if not accessible_event_ids:
            return []

        # Build query for accessible events
        query = db.query(event.model).options(noload(event.model.interactions)).filter(event.model.id.in_(accessible_event_ids))

        # Apply optional filters
        if owner_id is not None:
            query = query.filter(event.model.owner_id == owner_id)
        if calendar_id is not None:
            query = query.filter(event.model.calendar_id == calendar_id)

        # Apply ordering
        if order_by and hasattr(event.model, order_by):
            order_col = getattr(event.model, order_by)
        else:
            order_col = event.model.id

        if order_dir.lower() == "desc":
            query = query.order_by(order_col.desc())
        else:
            query = query.order_by(order_col.asc())

        # Apply pagination
        events = query.offset(offset).limit(limit).all()
        return events

    # If not authenticated, return empty list
    # (public events should be accessed via public discovery endpoints)
    return []


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(event_id: int, current_user_id: Optional[int] = Depends(get_current_user_id_optional), db: Session = Depends(get_db)):
    """
    Get a single event by ID.

    Authentication is optional - provide JWT token in Authorization header for authenticated access.

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
        # Check access using CRUD method
        has_access = event.check_user_access(db, event_id=event_id, user_id=current_user_id)
        if not has_access:
            raise HTTPException(status_code=403, detail="You do not have permission to view this event")

    # Get owner information
    owner = user.get(db, id=db_event.owner_id)
    if not owner:
        raise HTTPException(status_code=404, detail="Event owner not found")

    # Get owner info
    owner_name = owner.display_name
    owner_profile_picture_url = owner.profile_picture_url

    # Build response dict from event
    response_data = {
        "id": db_event.id,
        "name": db_event.name,
        "description": db_event.description,
        "start_date": db_event.start_date,
        "event_type": db_event.event_type,
        "owner_id": db_event.owner_id,
        "calendar_id": db_event.calendar_id,
        "parent_recurring_event_id": db_event.parent_recurring_event_id,
        "created_at": db_event.created_at,
        "updated_at": db_event.updated_at,
        "owner_name": owner_name,
        "owner_profile_picture": owner_profile_picture_url,
        "is_owner_public": owner.is_public,
    }

    # If owner is public and current_user_id is provided, add subscription info
    if owner.is_public and current_user_id is not None:
        # Check if user is subscribed to owner (any event from this owner)
        # A subscription is an interaction of type "subscribed" to any event owned by the public user
        subscriptions = db.query(EventInteraction).join(event.model, EventInteraction.event_id == event.model.id).filter(event.model.owner_id == owner.id, EventInteraction.user_id == current_user_id, EventInteraction.interaction_type == "subscribed").first()
        is_subscribed = subscriptions is not None

        # Check if there's a block between users
        is_blocked = db.query(UserBlock).filter(((UserBlock.blocker_user_id == current_user_id) & (UserBlock.blocked_user_id == owner.id)) | ((UserBlock.blocker_user_id == owner.id) & (UserBlock.blocked_user_id == current_user_id))).first() is not None

        # User can subscribe if not already subscribed and not blocked
        can_subscribe = not is_subscribed and not is_blocked

        # Get upcoming events from public owner
        upcoming_events = event.get_upcoming_events_by_owner(db, owner_id=owner.id, limit=10)
        upcoming_events_data = [
            {
                "id": e.id,
                "name": e.name,
                "start_date": e.start_date,
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
            membership = calendar_membership.get_membership(db, calendar_id=db_event.calendar_id, user_id=current_user_id)
            if membership and membership.role in ["admin"] and membership.status == "accepted":
                is_admin = True

        # Check if user is an accepted participant who can invite others
        user_interaction_for_permission = db.query(EventInteraction).filter(EventInteraction.event_id == event_id, EventInteraction.user_id == current_user_id).first()

        can_invite = False
        if is_owner or is_admin:
            can_invite = True
        elif user_interaction_for_permission:
            # Accepted participant (subscribed/joined) can invite and see all invitations
            if user_interaction_for_permission.interaction_type in ["subscribed", "joined"] and user_interaction_for_permission.status == "accepted":
                can_invite = True

        # If user is owner, admin, or accepted participant, get invitation stats
        if can_invite:
            stats = event_interaction.get_invitation_stats(db, event_id=event_id)
            response_data["invitation_stats"] = stats

            # Get all interactions with enriched user data
            interactions_data = []
            interactions_enriched = event_interaction.get_enriched_by_event(db, event_id=event_id)

            for interaction, interaction_user in interactions_enriched:
                if not interaction_user:
                    continue

                user_display_name = interaction_user.display_name
                user_instagram_username = interaction_user.instagram_username
                user_profile_picture_url = interaction_user.profile_picture_url
                user_phone = interaction_user.phone

                # Get inviter if exists
                inviter = None
                inviter_display_name = None
                inviter_instagram_username = None
                if interaction.invited_by_user_id:
                    inviter = user.get(db, id=interaction.invited_by_user_id)
                    if inviter:
                        inviter_display_name = inviter.display_name
                        inviter_instagram_username = inviter.instagram_username

                interactions_data.append(
                    {
                        "id": interaction.id,
                        "user_id": interaction.user_id,
                        "event_id": interaction.event_id,
                        "interaction_type": interaction.interaction_type,
                        "status": interaction.status,
                        "role": interaction.role,
                        "invited_by_user_id": interaction.invited_by_user_id,
                        "personal_note": interaction.personal_note,
                        "read_at": interaction.read_at.isoformat() if interaction.read_at else None,
                        "created_at": interaction.created_at.isoformat(),
                        "updated_at": interaction.updated_at.isoformat(),
                        "user": {
                            "id": interaction_user.id,
                            "display_name": user_display_name,
                            "instagram_username": user_instagram_username,
                            "profile_picture_url": user_profile_picture_url,
                            "phone_number": user_phone,
                        },
                        "inviter": (
                            {
                                "id": inviter.id,
                                "display_name": inviter_display_name,
                                "instagram_username": inviter_instagram_username,
                            }
                            if inviter
                            else None
                        ),
                    }
                )

            response_data["interactions"] = interactions_data

        # If user is not owner/admin but is authenticated, add their own interaction
        elif current_user_id is not None:
            # Get current user's interaction only
            user_interaction = db.query(EventInteraction).filter(EventInteraction.event_id == event_id, EventInteraction.user_id == current_user_id).first()

            if user_interaction:
                inviter = None
                inviter_display_name = None
                inviter_instagram_username = None
                if user_interaction.invited_by_user_id:
                    inviter = user.get(db, id=user_interaction.invited_by_user_id)
                    if inviter:
                        inviter_display_name = inviter.display_name
                        inviter_instagram_username = inviter.instagram_username

                response_data["interactions"] = [
                    {
                        "id": user_interaction.id,
                        "user_id": user_interaction.user_id,
                        "event_id": user_interaction.event_id,
                        "interaction_type": user_interaction.interaction_type,
                        "status": user_interaction.status,
                        "role": user_interaction.role,
                        "invited_by_user_id": user_interaction.invited_by_user_id,
                        "personal_note": user_interaction.personal_note,
                        "is_attending": user_interaction.is_attending,
                        "read_at": user_interaction.read_at.isoformat() if user_interaction.read_at else None,
                        "inviter": (
                            {
                                "id": inviter.id,
                                "display_name": inviter_display_name,
                                "instagram_username": inviter_instagram_username,
                            }
                            if inviter
                            else None
                        ),
                    }
                ]

    # Get accepted users (attendees) - available for all authenticated users
    # Include users who accepted OR rejected but are attending (for public events)
    # Exclude public users (they don't attend their own events)
    #
    # SMART FILTERING: If current user was invited and accepted, show only "related attendees":
    # - The inviter
    # - Other users invited by the same inviter who accepted
    # Otherwise, show all attendees
    if current_user_id is not None:
        # Check if current user has an accepted invitation
        current_user_invitation = db.query(EventInteraction).filter(EventInteraction.event_id == event_id, EventInteraction.user_id == current_user_id, EventInteraction.interaction_type == "invited", EventInteraction.status == "accepted").first()

        # If user was invited and accepted, filter attendees by invitation relationship
        if current_user_invitation and current_user_invitation.invited_by_user_id:
            inviter_id = current_user_invitation.invited_by_user_id

            # Get attendees who are:
            # 1. The inviter themselves, OR
            # 2. Other users invited by the same inviter who accepted
            accepted_interactions = (
                db.query(EventInteraction)
                .join(User, EventInteraction.user_id == User.id)
                .filter(
                    EventInteraction.event_id == event_id,
                    or_(
                        # The inviter (any interaction type, accepted status)
                        and_(EventInteraction.user_id == inviter_id, EventInteraction.status == "accepted"),
                        # Other users invited by same inviter who accepted
                        and_(EventInteraction.invited_by_user_id == inviter_id, EventInteraction.interaction_type == "invited", EventInteraction.status == "accepted", EventInteraction.user_id != current_user_id),  # Exclude current user
                    ),
                    User.is_public == False,  # Exclude public users
                )
                .all()
            )
        else:
            # User was NOT invited (or is subscribed/joined), show all attendees
            accepted_interactions = (
                db.query(EventInteraction)
                .join(User, EventInteraction.user_id == User.id)
                .filter(
                    EventInteraction.event_id == event_id,
                    or_(EventInteraction.status == "accepted", and_(EventInteraction.status == "rejected", EventInteraction.is_attending == True)),
                    User.is_public == False,  # Exclude public users
                    EventInteraction.user_id != current_user_id,  # Exclude current user
                )
                .all()
            )

        attendees = []
        for interaction in accepted_interactions:
            user_obj = user.get(db, id=interaction.user_id)
            if user_obj:
                attendees.append(
                    {
                        "id": user_obj.id,
                        "display_name": user_obj.display_name,
                        "profile_picture_url": user_obj.profile_picture_url,
                        "phone": user_obj.phone,
                    }
                )

        response_data["attendees"] = attendees

    return EventResponse(**response_data)


# Removed unused event interactions list endpoints (/{event_id}/interactions and /{event_id}/interactions-enriched)


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
    for user_obj in results:
        available.append({"id": user_obj.id, "instagram_username": user_obj.instagram_username, "display_name": user_obj.display_name})

    return available


@router.post("", response_model=EventResponse, status_code=201)
async def create_event(event_data: Union[EventCreate, RecurringEventCreate], db: Session = Depends(get_db)):
    """Create a new event (regular or recurring)

    Use EventCreate for regular events.
    Use RecurringEventCreate for recurring events (requires patterns).
    """
    # Create with validation (all checks in CRUD layer)
    db_event, error, error_detail = event.create_with_validation(db, obj_in=event_data)

    if error:
        handle_crud_error(error, error_detail)

    # Reload without relationships to avoid serialization issues
    db.expire_all()
    db_event_clean = db.query(Event).options(noload(Event.interactions)).filter(Event.id == db_event.id).first()

    return db_event_clean


@router.put("/{event_id}", response_model=EventResponse)
async def update_event(event_id: int, event_data: EventUpdate, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Update an existing event.

    Requires JWT authentication - provide token in Authorization header.
    Only the event owner or event admins can update events.
    """
    # Check permissions (owner or admin)
    check_event_permission(event_id, current_user_id, db)

    # Update with validation (all checks in CRUD layer)
    db_event, error = event.update_with_validation(db, event_id=event_id, obj_in=event_data)

    if error:
        handle_crud_error(error)

    # Reload without relationships to avoid serialization issues
    db.expire_all()
    db_event_clean = db.query(Event).options(noload(Event.interactions)).filter(Event.id == event_id).first()

    return db_event_clean


@router.delete("/{event_id}")
async def delete_event(event_id: int, current_user_id: int = Depends(get_current_user_id), delete_request: Optional[EventDeleteRequest] = None, db: Session = Depends(get_db)):
    """
    Delete an event and optionally create cancellation notifications.

    Requires JWT authentication - provide token in Authorization header.
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
            raise HTTPException(status_code=400, detail="cancelled_by_user_id in request body must match current_user_id")

    # Delete with cancellations (using CRUD method)
    cancelled_by = delete_request.cancelled_by_user_id if delete_request else None
    cancellation_msg = delete_request.cancellation_message if delete_request else None

    deleted_count, error = event.delete_with_cancellations(db, event_id=event_id, cancelled_by_user_id=cancelled_by, cancellation_message=cancellation_msg)

    if error:
        handle_crud_error(error)

    return {"message": f"Event deleted successfully ({'with ' + str(deleted_count - 1) + ' instances' if deleted_count > 1 else 'single event'})", "id": event_id, "deleted_count": deleted_count}


# Removed unused event cancellations endpoints (/events/cancellations and /events/cancellations/{id}/view)
