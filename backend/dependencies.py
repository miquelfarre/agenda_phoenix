"""
Common dependencies for FastAPI routes
"""

from typing import Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from database import SessionLocal
from models import AppBan, Calendar, CalendarMembership, Contact, Event, EventInteraction, Group, GroupMembership, User, UserBlock


def get_db():
    """
    Database session dependency.
    Yields a database session and ensures it's closed after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_user_not_banned(user_id: int, db: Session):
    """
    Validates that a user is not banned from the application.

    Args:
        user_id: The ID of the user to check
        db: Database session

    Raises:
        HTTPException 403 if user is banned
    """
    app_ban = db.query(AppBan).filter(AppBan.user_id == user_id).first()
    if app_ban:
        raise HTTPException(status_code=403, detail={"message": "User is banned from the application", "reason": app_ban.reason, "banned_at": app_ban.banned_at.isoformat() if app_ban.banned_at else None})


def check_users_not_blocked(user_a_id: int, user_b_id: int, db: Session):
    """
    Validates that neither user has blocked the other.

    Args:
        user_a_id: First user ID
        user_b_id: Second user ID
        db: Database session

    Raises:
        HTTPException 403 if there's a block between the users
    """
    # Check if A blocked B or B blocked A
    block = db.query(UserBlock).filter(((UserBlock.blocker_user_id == user_a_id) & (UserBlock.blocked_user_id == user_b_id)) | ((UserBlock.blocker_user_id == user_b_id) & (UserBlock.blocked_user_id == user_a_id))).first()

    if block:
        raise HTTPException(status_code=403, detail="Cannot interact with this user due to blocking")


def check_event_permission(event_id: int, current_user_id: int, db: Session) -> None:
    """
    Validates that current user has permission to modify/delete an event.
    User must be either:
    - Event owner, OR
    - Event admin (interaction_type='joined', role='admin', status='accepted')

    Args:
        event_id: The ID of the event
        current_user_id: The ID of the user making the request
        db: Database session

    Raises:
        HTTPException 404 if event not found
        HTTPException 403 if user doesn't have permission
    """
    # Get event
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Check if user is owner
    if event.owner_id == current_user_id:
        return  # Owner has permission

    # Check if user is admin of this event
    interaction = db.query(EventInteraction).filter(
        EventInteraction.event_id == event_id,
        EventInteraction.user_id == current_user_id,
        EventInteraction.interaction_type == "joined",
        EventInteraction.role == "admin",
        EventInteraction.status == "accepted"
    ).first()

    if interaction:
        return  # Admin has permission

    # No permission
    raise HTTPException(
        status_code=403,
        detail="You don't have permission to modify this event. Only the event owner or admins can perform this action."
    )


def check_calendar_permission(calendar_id: int, current_user_id: int, db: Session) -> None:
    """
    Validates that current user has permission to modify/delete a calendar.
    User must be either:
    - Calendar owner, OR
    - Calendar admin (CalendarMembership with role='admin', status='accepted')

    Args:
        calendar_id: The ID of the calendar
        current_user_id: The ID of the user making the request
        db: Database session

    Raises:
        HTTPException 404 if calendar not found
        HTTPException 403 if user doesn't have permission
    """
    # Get calendar
    calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    # Check if user is owner
    if calendar.owner_id == current_user_id:
        return  # Owner has permission

    # Check if user is admin of this calendar
    membership = db.query(CalendarMembership).filter(
        CalendarMembership.calendar_id == calendar_id,
        CalendarMembership.user_id == current_user_id,
        CalendarMembership.role == "admin",
        CalendarMembership.status == "accepted"
    ).first()

    if membership:
        return  # Admin has permission

    # No permission
    raise HTTPException(
        status_code=403,
        detail="You don't have permission to modify this calendar. Only the calendar owner or admins can perform this action."
    )


def check_group_permission(group_id: int, current_user_id: int, db: Session) -> None:
    """
    Validates that current user has permission to modify/delete a group.
    Only the group creator can modify/delete groups.

    Args:
        group_id: The ID of the group
        current_user_id: The ID of the user making the request
        db: Database session

    Raises:
        HTTPException 404 if group not found
        HTTPException 403 if user doesn't have permission
    """
    # Get group
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Check if user is creator
    if group.created_by == current_user_id:
        return  # Creator has permission

    # No permission
    raise HTTPException(
        status_code=403,
        detail="You don't have permission to modify this group. Only the group creator can perform this action."
    )


def is_event_owner_or_admin(event_id: int, user_id: int, db: Session) -> bool:
    """
    Check if user is owner or admin of an event (without raising exception).

    Args:
        event_id: The ID of the event
        user_id: The ID of the user
        db: Database session

    Returns:
        True if user is owner or admin, False otherwise
    """
    # Get event
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        return False

    # Check if user is owner
    if event.owner_id == user_id:
        return True

    # Check if user is admin
    interaction = db.query(EventInteraction).filter(
        EventInteraction.event_id == event_id,
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == "joined",
        EventInteraction.role == "admin",
        EventInteraction.status == "accepted"
    ).first()

    return interaction is not None


def is_calendar_owner_or_admin(calendar_id: int, user_id: int, db: Session) -> bool:
    """
    Check if user is owner or admin of a calendar (without raising exception).

    Args:
        calendar_id: The ID of the calendar
        user_id: The ID of the user
        db: Database session

    Returns:
        True if user is owner or admin, False otherwise
    """
    # Get calendar
    calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not calendar:
        return False

    # Check if user is owner
    if calendar.owner_id == user_id:
        return True

    # Check if user is admin
    membership = db.query(CalendarMembership).filter(
        CalendarMembership.calendar_id == calendar_id,
        CalendarMembership.user_id == user_id,
        CalendarMembership.role == "admin",
        CalendarMembership.status == "accepted"
    ).first()

    return membership is not None


def check_contact_permission(contact_id: int, current_user_id: int, db: Session) -> None:
    """
    Validates that current user has permission to modify/delete a contact.
    Only the contact owner can modify/delete contacts.
    Contacts without owner (representing registered users) cannot be edited directly.

    Args:
        contact_id: The ID of the contact
        current_user_id: The ID of the user making the request
        db: Database session

    Raises:
        HTTPException 404 if contact not found
        HTTPException 403 if user doesn't have permission
    """
    # Get contact
    contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    # Contacts without owner (representing registered users) cannot be edited
    if contact.owner_id is None:
        raise HTTPException(
            status_code=403,
            detail="This contact represents a registered user and cannot be edited directly."
        )

    # Check if user is owner
    if contact.owner_id != current_user_id:
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to modify this contact. Only the contact owner can perform this action."
        )


def check_is_admin(current_user_id: int, db: Session) -> None:
    """
    Validates that current user is a super admin.

    Args:
        current_user_id: The ID of the user making the request
        db: Database session

    Raises:
        HTTPException 404 if user not found
        HTTPException 403 if user is not admin
    """
    # Get user
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if user is admin
    if not user.is_admin:
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to perform this action. Only administrators can perform this action."
        )


def check_user_not_public(user_id: int, db: Session, action_description: str = "this action") -> None:
    """
    Validates that a user is NOT a public user.
    Public users cannot be added to certain roles or memberships.

    Args:
        user_id: The ID of the user to check
        db: Database session
        action_description: Description of the action being prevented for error message

    Raises:
        HTTPException 404 if user not found
        HTTPException 403 if user is public
    """
    # Get user
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if user is public
    if user.is_public:
        raise HTTPException(
            status_code=403,
            detail=f"Public users cannot {action_description}. Only private users can perform this action."
        )


def handle_recurring_event_rejection_cascade(db: Session, interaction: EventInteraction, db_event: Event) -> None:
    """
    Handle cascade rejection logic for recurring events.

    When a user rejects an invitation to a base recurring event, automatically reject
    all pending invitations to instance events of that recurring event.

    Args:
        db: Database session
        interaction: The event interaction being updated
        db_event: The event associated with the interaction
    """
    # Only cascade if it's a recurring event invitation being rejected
    if not (db_event.event_type == "recurring" and
            interaction.interaction_type == "invited" and
            interaction.status == "rejected"):
        return

    # Import here to avoid circular imports
    from crud import event_interaction, recurring_config, event

    # Find the recurring config for this event
    config = recurring_config.get_by_event(db, event_id=db_event.id)

    if not config:
        return

    # Find all instance events of this recurring event
    instance_events = event.get_instances_by_parent_config(db, parent_config_id=config.id)
    instance_event_ids = [e.id for e in instance_events]

    if instance_event_ids:
        # Update all pending invitations to these instances to 'rejected'
        event_interaction.bulk_reject_pending_instances(
            db,
            instance_event_ids=instance_event_ids,
            user_id=interaction.user_id
        )
