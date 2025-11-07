"""
Events Router

Handles all event-related endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from auth import get_current_user_id, get_current_user_id_optional
from crud import event, event_cancellation, event_interaction, user
from dependencies import check_event_permission, check_user_not_banned, check_users_not_blocked, get_db, handle_recurring_event_rejection_cascade
from models import EventInteraction, UserBlock
from schemas import AvailableInviteeResponse, EventCancellationResponse, EventCreate, EventDeleteRequest, EventInteractionCreate, EventInteractionEnrichedResponse, EventInteractionResponse, EventInteractionUpdate, EventResponse, EventUpdate

router = APIRouter(prefix="/api/v1/events", tags=["events"])


@router.get("", response_model=List[EventResponse])
async def get_events(
    owner_id: Optional[int] = None,
    calendar_id: Optional[int] = None,
    current_user_id: Optional[int] = Depends(get_current_user_id_optional),
    limit: int = 50,
    offset: int = 0,
    order_by: Optional[str] = "start_date",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all events, optionally filtered by owner_id or calendar_id.

    Authentication is optional - provide JWT token in Authorization header for authenticated access."""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    events = event.get_multi_filtered(
        db,
        owner_id=owner_id,
        calendar_id=calendar_id,
        skip=offset,
        limit=limit,
        order_by=order_by or "start_date",
        order_dir=order_dir
    )

    return events


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(
    event_id: int,
    current_user_id: Optional[int] = Depends(get_current_user_id_optional),
    db: Session = Depends(get_db)
):
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

    # Get owner contact for full name
    from crud import contact as contact_crud
    owner_contact = None
    if owner.contact_id:
        owner_contact = contact_crud.get(db, id=owner.contact_id)

    # Determine owner name: use contact name if available, otherwise username (for Instagram users)
    owner_name = owner_contact.name if owner_contact else owner.username

    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[GET /events/{event_id}] OWNER INFO: user_id={owner.id}, is_public={owner.is_public}, "
               f"has_contact={owner_contact is not None}, owner_name={owner_name}, username={owner.username}")

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
        "owner_profile_picture": owner.profile_picture,
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
                "event_type": e.event_type,
            }
            for e in upcoming_events
        ]

        response_data["is_subscribed_to_owner"] = is_subscribed
        response_data["can_subscribe_to_owner"] = can_subscribe
        response_data["owner_upcoming_events"] = upcoming_events_data

    # If current_user_id is provided and user is owner or admin, add invitation stats
    print(f"🔍 DEBUG BACKEND PRE-CHECK: current_user_id = {current_user_id}, type = {type(current_user_id)}")
    print(f"🔍 DEBUG BACKEND PRE-CHECK: current_user_id is not None = {current_user_id is not None}")
    if current_user_id is not None:
        is_owner = db_event.owner_id == current_user_id
        is_admin = False
        print(f"🔍 DEBUG BACKEND: GET /events/{event_id}")
        print(f"🔍 DEBUG BACKEND: current_user_id = {current_user_id}")
        print(f"🔍 DEBUG BACKEND: db_event.owner_id = {db_event.owner_id}")
        print(f"🔍 DEBUG BACKEND: is_owner = {is_owner}")

        # Check if user is admin of the calendar containing this event
        if db_event.calendar_id:
            from crud import calendar_membership
            membership = calendar_membership.get_by_calendar_and_user(
                db, calendar_id=db_event.calendar_id, user_id=current_user_id
            )
            if membership and membership.role in ["owner", "admin"] and membership.status == "accepted":
                is_admin = True

        print(f"🔍 DEBUG BACKEND: is_admin = {is_admin}")

        # Check if user is an accepted participant who can invite others
        user_interaction_for_permission = db.query(EventInteraction).filter(
            EventInteraction.event_id == event_id,
            EventInteraction.user_id == current_user_id
        ).first()

        can_invite = False
        if is_owner or is_admin:
            can_invite = True
        elif user_interaction_for_permission:
            # Accepted participant (subscribed/joined) can invite and see all invitations
            if user_interaction_for_permission.interaction_type in ["subscribed", "joined"] and user_interaction_for_permission.status == "accepted":
                can_invite = True

        print(f"🔍 DEBUG BACKEND: can_invite = {can_invite}")
        print(f"🔍 DEBUG BACKEND: Will enter owner/admin/participant block = {can_invite}")

        # If user is owner, admin, or accepted participant, get invitation stats
        if can_invite:
            print(f"🔍 DEBUG BACKEND: Entering OWNER/ADMIN/PARTICIPANT block (can_invite={can_invite})")
            stats = event_interaction.get_invitation_stats(db, event_id=event_id)
            response_data["invitation_stats"] = stats

            # Get all interactions with enriched user data
            interactions_data = []
            interactions_enriched = event_interaction.get_enriched_by_event(db, event_id=event_id)

            for interaction, interaction_user, contact in interactions_enriched:
                if not interaction_user:
                    continue

                # Get user display name from contact or username
                user_name = contact.name if contact else interaction_user.username or f"User {interaction_user.id}"
                user_phone = contact.phone if contact else None

                # Get inviter if exists
                inviter = None
                inviter_contact = None
                inviter_name = None
                if interaction.invited_by_user_id:
                    inviter = user.get(db, id=interaction.invited_by_user_id)
                    if inviter and inviter.contact_id:
                        from crud import contact as contact_crud
                        inviter_contact = contact_crud.get(db, id=inviter.contact_id)
                    inviter_name = inviter_contact.name if inviter_contact else (inviter.username if inviter else None)

                interactions_data.append({
                    "id": interaction.id,
                    "user_id": interaction.user_id,
                    "event_id": interaction.event_id,
                    "interaction_type": interaction.interaction_type,
                    "status": interaction.status,
                    "role": interaction.role,
                    "invited_by_user_id": interaction.invited_by_user_id,
                    "note": interaction.note,
                    "read_at": interaction.read_at.isoformat() if interaction.read_at else None,
                    "created_at": interaction.created_at.isoformat(),
                    "updated_at": interaction.updated_at.isoformat(),
                    "user": {
                        "id": interaction_user.id,
                        "full_name": user_name,
                        "username": interaction_user.username,
                        "phone_number": user_phone,
                        "profile_picture": interaction_user.profile_picture,
                    },
                    "inviter": {
                        "id": inviter.id,
                        "full_name": inviter_name,
                        "username": inviter.username,
                    } if inviter else None
                })

            response_data["interactions"] = interactions_data

        # If user is not owner/admin but is authenticated, add their own interaction
        elif current_user_id is not None:
            print(f"🔍 DEBUG BACKEND: Entering REGULAR USER block")
            print(f"🔍 DEBUG BACKEND: current_user_id = {current_user_id}, event_id = {event_id}")
            # Get current user's interaction only
            user_interaction = db.query(EventInteraction).filter(
                EventInteraction.event_id == event_id,
                EventInteraction.user_id == current_user_id
            ).first()

            print(f"🔍 DEBUG BACKEND: user_interaction found = {user_interaction is not None}")
            if user_interaction:
                print(f"🔍 DEBUG BACKEND: interaction.id = {user_interaction.id}")
                print(f"🔍 DEBUG BACKEND: interaction.interaction_type = {user_interaction.interaction_type}")
                print(f"🔍 DEBUG BACKEND: interaction.status = {user_interaction.status}")
                print(f"🔍 DEBUG BACKEND: interaction.invited_by_user_id = {user_interaction.invited_by_user_id}")
            else:
                print(f"🔍 DEBUG BACKEND: No interaction found for user {current_user_id} and event {event_id}")

            if user_interaction:
                inviter = None
                inviter_contact = None
                inviter_name = None
                if user_interaction.invited_by_user_id:
                    inviter = user.get(db, id=user_interaction.invited_by_user_id)
                    if inviter and inviter.contact_id:
                        from crud import contact as contact_crud
                        inviter_contact = contact_crud.get(db, id=inviter.contact_id)
                    inviter_name = inviter_contact.name if inviter_contact else (inviter.username if inviter else None)

                response_data["interactions"] = [{
                    "id": user_interaction.id,
                    "user_id": user_interaction.user_id,
                    "event_id": user_interaction.event_id,
                    "interaction_type": user_interaction.interaction_type,
                    "status": user_interaction.status,
                    "role": user_interaction.role,
                    "invited_by_user_id": user_interaction.invited_by_user_id,
                    "note": user_interaction.note,
                    "is_attending": user_interaction.is_attending,
                    "read_at": user_interaction.read_at.isoformat() if user_interaction.read_at else None,
                    "inviter": {
                        "id": inviter.id,
                        "full_name": inviter_name,
                        "username": inviter.username,
                    } if inviter else None
                }]

    # Get accepted users (attendees) - available for all authenticated users
    # Include users who accepted OR rejected but are attending (for public events)
    # Exclude public users (they don't attend their own events)
    if current_user_id is not None:
        from models import User
        accepted_interactions = db.query(EventInteraction).join(
            User, EventInteraction.user_id == User.id
        ).filter(
            EventInteraction.event_id == event_id,
            or_(
                EventInteraction.status == "accepted",
                and_(
                    EventInteraction.status == "rejected",
                    EventInteraction.is_attending == True
                )
            ),
            User.is_public == False  # Exclude public users
        ).all()

        attendees = []
        print(f"🔍 DEBUG BACKEND: Building attendees list from {len(accepted_interactions)} accepted interactions")
        for interaction in accepted_interactions:
            user_obj = user.get(db, id=interaction.user_id)
            print(f"🔍 DEBUG BACKEND: Processing interaction for user_id={interaction.user_id}, user_obj found={user_obj is not None}")
            if user_obj:
                # Get user name from contact or username
                user_contact = None
                user_name = user_obj.username or f"User {user_obj.id}"
                print(f"🔍 DEBUG BACKEND: user_obj.username={user_obj.username}, user_obj.contact_id={user_obj.contact_id}")
                if user_obj.contact_id:
                    from crud import contact as contact_crud
                    user_contact = contact_crud.get(db, id=user_obj.contact_id)
                    print(f"🔍 DEBUG BACKEND: contact found={user_contact is not None}")
                    if user_contact:
                        print(f"🔍 DEBUG BACKEND: contact.name={user_contact.name}")
                    user_name = user_contact.name if user_contact else user_name

                print(f"🔍 DEBUG BACKEND: Final user_name={user_name}, profile_picture={user_obj.profile_picture}")
                attendees.append({
                    "id": user_obj.id,
                    "full_name": user_name,
                    "username": user_obj.username,
                    "profile_picture": user_obj.profile_picture,
                })

        response_data["attendees"] = attendees

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
async def update_event(
    event_id: int,
    event_data: EventUpdate,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
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
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_event


@router.delete("/{event_id}")
async def delete_event(
    event_id: int,
    current_user_id: int = Depends(get_current_user_id),
    delete_request: Optional[EventDeleteRequest] = None,
    db: Session = Depends(get_db)
):
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


@router.get("/{event_id}/interaction", response_model=EventInteractionResponse)
async def get_current_user_interaction(
    event_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Get the current user's interaction with this event.

    Requires JWT authentication - provide token in Authorization header.
    Returns 404 if no interaction exists.
    """
    db_interaction = event_interaction.get_interaction(db, event_id=event_id, user_id=current_user_id)
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    return db_interaction


@router.patch("/{event_id}/interaction", response_model=EventInteractionResponse)
async def update_current_user_interaction(
    event_id: int,
    interaction: EventInteractionUpdate,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Update or create the current user's interaction with this event.

    Requires JWT authentication - provide token in Authorization header.
    Creates a new interaction if one doesn't exist.

    Special cascade behavior for recurring events:
    - If rejecting a base recurring event invitation (event_type='recurring' and status='rejected'),
      automatically reject all pending invitations to instance events of that recurring event
    """
    # Check if event exists
    db_event = event.get(db, id=event_id)
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Check if user is banned
    check_user_not_banned(current_user_id, db)

    # Get or create interaction
    db_interaction = event_interaction.get_interaction(db, event_id=event_id, user_id=current_user_id)

    if not db_interaction:
        # Create new interaction with provided fields
        interaction_data = EventInteractionCreate(
            event_id=event_id,
            user_id=current_user_id,
            interaction_type=interaction.interaction_type or "subscribed",
            status=interaction.status or "pending",
            role=interaction.role,
            note=interaction.note,
            rejection_message=interaction.rejection_message
        )
        db_interaction = event_interaction.create(db, obj_in=interaction_data)
    else:
        # Update existing interaction (only fields that are explicitly provided)
        for key, value in interaction.model_dump(exclude_unset=True).items():
            if value is not None:
                setattr(db_interaction, key, value)

        db.commit()
        db.refresh(db_interaction)

    # Handle cascade rejection logic for recurring events
    handle_recurring_event_rejection_cascade(db, db_interaction, db_event)

    return db_interaction


@router.delete("/{event_id}/interaction")
async def delete_current_user_interaction(
    event_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Delete the current user's interaction with this event.

    Requires JWT authentication - provide token in Authorization header.
    Returns 404 if no interaction exists.
    """
    db_interaction = event_interaction.get_interaction(db, event_id=event_id, user_id=current_user_id)
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    event_interaction.delete(db, id=db_interaction.id)

    return {"message": "Interaction deleted successfully", "id": db_interaction.id}


@router.post("/{event_id}/interaction/invite", response_model=EventInteractionResponse, status_code=201)
async def invite_user_to_event(
    event_id: int,
    invite_data: dict,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Invite a user to an event by creating an 'invited' interaction.

    Requires JWT authentication - provide token in Authorization header.
    Body should contain 'invited_user_id' and optionally 'invitation_message'.

    The inviter (current user) must be:
    - Event owner, OR
    - Event admin, OR
    - Accepted participant (subscribed/joined)

    Returns 409 if the user already has an interaction with this event.
    """
    # Check if event exists
    db_event = event.get(db, id=event_id)
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Extract invited_user_id from request
    invited_user_id = invite_data.get("invited_user_id")
    invitation_message = invite_data.get("invitation_message")

    if not invited_user_id:
        raise HTTPException(status_code=400, detail="invited_user_id is required")

    # Check if invited user exists
    invited_user = user.get(db, id=invited_user_id)
    if not invited_user:
        raise HTTPException(status_code=404, detail="Invited user not found")

    # Public users cannot be invited to events
    if invited_user.is_public:
        raise HTTPException(
            status_code=403,
            detail="Public users cannot be invited to events. Only private users can receive invitations."
        )

    # Check if inviter (current user) is public
    inviter_user = user.get(db, id=current_user_id)
    if inviter_user and inviter_user.is_public:
        raise HTTPException(
            status_code=403,
            detail="Public users cannot invite others to events. Only private users can invite."
        )

    # Check if invited user is banned
    check_user_not_banned(invited_user_id, db)

    # Check if inviter is banned
    check_user_not_banned(current_user_id, db)

    # Check if there's a block between inviter and invitee
    check_users_not_blocked(current_user_id, invited_user_id, db)

    # Check if there's a block between event owner and invitee
    check_users_not_blocked(db_event.owner_id, invited_user_id, db)

    # Check if inviter has permission to invite
    is_owner = (db_event.owner_id == current_user_id)

    if not is_owner:
        # Check if inviter is an admin or accepted participant of this event
        inviter_interaction = event_interaction.get_interaction(db, event_id=event_id, user_id=current_user_id)

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

    # Check if interaction already exists
    existing_interaction = event_interaction.get_interaction(db, event_id=event_id, user_id=invited_user_id)
    if existing_interaction:
        raise HTTPException(status_code=409, detail="User already has an interaction with this event")

    # Create the invitation
    interaction_data = EventInteractionCreate(
        event_id=event_id,
        user_id=invited_user_id,
        interaction_type="invited",
        status="pending",
        note=invitation_message
    )

    db_interaction = event_interaction.create(db, obj_in=interaction_data)

    return db_interaction


@router.get("/cancellations", response_model=List[EventCancellationResponse])
async def get_event_cancellations(
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Get all event cancellations that the authenticated user hasn't viewed yet.

    Requires JWT authentication - provide token in Authorization header.

    Returns cancellations for events where the user had an interaction
    and hasn't viewed the cancellation message yet.
    """
    return event_cancellation.get_unviewed_by_user(db, user_id=current_user_id)


@router.post("/cancellations/{cancellation_id}/view")
async def mark_cancellation_as_viewed(
    cancellation_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Mark an event cancellation as viewed by the authenticated user.

    Requires JWT authentication - provide token in Authorization header.

    After viewing, the cancellation will no longer appear in the user's list.
    """
    view_id, error = event_cancellation.mark_as_viewed(db, cancellation_id=cancellation_id, user_id=current_user_id)

    if error:
        raise HTTPException(status_code=404, detail=error)

    return {"message": "Cancellation marked as viewed", "id": view_id}
