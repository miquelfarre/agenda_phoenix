"""
Calendars Router

Handles all calendar-related endpoints.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import calendar, calendar_membership, event, group_membership
from crud.crud_calendar_subscription import calendar_subscription
from dependencies import check_calendar_permission, get_db
from schemas import (
    CalendarBase,
    CalendarCreate,
    CalendarMembershipCreate,
    CalendarMembershipResponse,
    CalendarResponse,
    CalendarSubscriptionCreate,
    CalendarSubscriptionResponse,
)
from utils import validate_pagination, handle_crud_error

router = APIRouter(prefix="/api/v1/calendars", tags=["calendars"])


@router.get("", response_model=List[CalendarResponse])
async def get_calendars(current_user_id: int = Depends(get_current_user_id), limit: int = 50, offset: int = 0, db: Session = Depends(get_db)):
    """
    Get all calendars accessible to the authenticated user.

    Requires JWT authentication - provide token in Authorization header.

    Returns:
    - Calendars owned by the user
    - Calendars where the user is a member (excluding calendars from public users)
    - Public calendars the user is subscribed to (excluding calendars from public users)
    """
    # Validate pagination
    limit, offset = validate_pagination(limit, offset)

    return calendar.get_all_user_calendars(db, user_id=current_user_id, skip=offset, limit=limit)


@router.get("/share/{share_hash}", response_model=CalendarResponse)
async def get_calendar_by_share_hash(share_hash: str, db: Session = Depends(get_db)):
    """
    Get a public calendar by its share hash.

    This endpoint is for looking up public calendars using their unique 8-character
    share hash. Returns 403 if the calendar is not public.
    """
    db_calendar = calendar.get_by_share_hash(db, share_hash=share_hash)
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")
    if not db_calendar.is_public:
        raise HTTPException(status_code=403, detail="Calendar is not public")
    return db_calendar


# Removed unused GET /public and GET /{calendar_id} endpoints (not used by Flutter)


@router.post("", response_model=CalendarResponse, status_code=201)
async def create_calendar(calendar_data: CalendarBase, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """Create a new calendar"""
    # Create CalendarCreate with owner_id from authenticated user
    # Use model_dump to get all fields and add owner_id
    data_dict = calendar_data.model_dump()
    data_dict["owner_id"] = current_user_id
    create_data = CalendarCreate(**data_dict)

    # Create with validation (checks owner exists)
    db_calendar, error = calendar.create_with_validation(db, obj_in=create_data)

    if error:
        raise HTTPException(status_code=404, detail=error)

    return db_calendar


@router.put("/{calendar_id}", response_model=CalendarResponse)
async def update_calendar(calendar_id: int, calendar_data: CalendarBase, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Update an existing calendar.

    Requires JWT authentication - provide token in Authorization header.
    Only the calendar owner or calendar admins can update calendars.
    """
    # Check permissions (owner or admin)
    check_calendar_permission(calendar_id, current_user_id, db)

    db_calendar = calendar.get(db, id=calendar_id)
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    updated_calendar = calendar.update(db, db_obj=db_calendar, obj_in=calendar_data)
    return updated_calendar


@router.delete("/{calendar_id}")
async def delete_calendar(calendar_id: int, delete_events: bool = False, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Delete a calendar.

    Requires JWT authentication - provide token in Authorization header.
    Only the calendar owner or calendar admins can delete calendars.

    Args:
        delete_events: If True, delete all events in the calendar.
                      If False, events remain but lose their calendar association.
    """
    # Check permissions (owner or admin)
    check_calendar_permission(calendar_id, current_user_id, db)

    db_calendar = calendar.get(db, id=calendar_id)
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    # Handle associated events based on delete_events parameter
    calendar_events = event.get_by_calendar(db, calendar_id=calendar_id)

    if delete_events:
        # Delete all events in the calendar
        for calendar_event in calendar_events:
            event.delete(db, id=calendar_event.id)
    else:
        # Remove calendar association (set calendar_id to NULL)
        for calendar_event in calendar_events:
            event.update(db, db_obj=calendar_event, obj_in={"calendar_id": None})

    # Delete the calendar
    calendar.delete(db, id=calendar_id)

    events_msg = f" and {len(calendar_events)} events" if delete_events else ""
    return {"message": f"Calendar deleted successfully{events_msg}", "id": calendar_id}


@router.get("/{calendar_id}/memberships", response_model=List[CalendarMembershipResponse])
async def get_calendar_members(calendar_id: int, db: Session = Depends(get_db)):
    """Get all members of a specific calendar"""
    memberships = calendar.get_members(db, calendar_id=calendar_id)

    if memberships is None:
        raise HTTPException(status_code=404, detail="Calendar not found")

    return memberships


@router.post("/{calendar_id}/memberships", response_model=CalendarMembershipResponse, status_code=201)
async def add_calendar_member(calendar_id: int, membership_data: CalendarMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a calendar (creates membership)"""
    # Override calendar_id from path
    membership_data.calendar_id = calendar_id

    # Create with validation (uses calendar_membership CRUD)
    db_membership, error = calendar_membership.create_with_validation(db, obj_in=membership_data)

    if error:
        handle_crud_error(error)

    return db_membership


@router.post("/{calendar_id}/memberships/bulk", status_code=201)
async def add_calendar_members_bulk(
    calendar_id: int,
    user_ids: List[int] = [],
    group_ids: List[int] = [],
    role: str = "member",
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Add multiple users or entire groups to a calendar.

    Only calendar owners or admins can add members.
    Returns summary of successful and failed additions.
    """
    # Check permissions
    check_calendar_permission(calendar_id, current_user_id, db)

    # Get calendar to verify it exists
    db_calendar = calendar.get(db, id=calendar_id)
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    results = {
        "successful": [],
        "failed": [],
        "total_invited": 0
    }

    # Add individual users
    for user_id in user_ids:
        try:
            membership_data = CalendarMembershipCreate(
                calendar_id=calendar_id,
                user_id=user_id,
                role=role,
                status="accepted"  # Direct add, no invitation needed
            )
            db_membership, error = calendar_membership.create_with_validation(
                db,
                obj_in=membership_data
            )
            if error:
                results["failed"].append({
                    "user_id": user_id,
                    "error": error
                })
            else:
                results["successful"].append(db_membership.id)
                results["total_invited"] += 1
        except Exception as e:
            results["failed"].append({
                "user_id": user_id,
                "error": str(e)
            })

    # Add group members
    for group_id in group_ids:
        # Get all members of the group
        group_members = group_membership.get_by_group(db, group_id=group_id)
        for member in group_members:
            try:
                membership_data = CalendarMembershipCreate(
                    calendar_id=calendar_id,
                    user_id=member.user_id,
                    role=role,
                    status="accepted"
                )
                db_membership, error = calendar_membership.create_with_validation(
                    db,
                    obj_in=membership_data
                )
                if error:
                    results["failed"].append({
                        "user_id": member.user_id,
                        "group_id": group_id,
                        "error": error
                    })
                else:
                    results["successful"].append(db_membership.id)
                    results["total_invited"] += 1
            except Exception as e:
                results["failed"].append({
                    "user_id": member.user_id,
                    "group_id": group_id,
                    "error": str(e)
                })

    return results


@router.post("/{share_hash}/subscribe", response_model=CalendarSubscriptionResponse, status_code=201)
async def subscribe_to_calendar(share_hash: str, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Subscribe to a public calendar using its share hash.

    Requires JWT authentication - provide token in Authorization header.
    Only public calendars can be subscribed to.

    Args:
        share_hash: The 8-character unique identifier for the public calendar
    """
    # Find calendar by share_hash
    db_calendar = calendar.get_by_share_hash(db, share_hash=share_hash)

    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    if not db_calendar.is_public:
        raise HTTPException(status_code=400, detail="Cannot subscribe to private calendars")

    # Create subscription data
    subscription_data = CalendarSubscriptionCreate(calendar_id=db_calendar.id, user_id=current_user_id, status="active")

    # Create with validation (checks calendar is public, user exists, no duplicate)
    db_subscription, error = calendar_subscription.create_with_validation(db, obj_in=subscription_data)

    if error:
        handle_crud_error(error)

    return db_subscription


@router.delete("/{share_hash}/subscribe")
async def unsubscribe_from_calendar(share_hash: str, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Unsubscribe from a public calendar using its share hash.

    Requires JWT authentication - provide token in Authorization header.

    Args:
        share_hash: The 8-character unique identifier for the public calendar
    """
    # Find calendar by share_hash
    db_calendar = calendar.get_by_share_hash(db, share_hash=share_hash)

    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    # Get existing subscription
    db_subscription = calendar_subscription.get_subscription(db, calendar_id=db_calendar.id, user_id=current_user_id)

    if not db_subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")

    # Delete subscription (this will trigger the subscriber_count update)
    calendar_subscription.delete(db, id=db_subscription.id)

    return {"message": "Unsubscribed successfully", "share_hash": share_hash}
