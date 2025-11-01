"""
Calendars Router

Handles all calendar-related endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import calendar, calendar_membership
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

router = APIRouter(prefix="/api/v1/calendars", tags=["calendars"])


@router.get("", response_model=List[CalendarResponse])
async def get_calendars(
    current_user_id: int = Depends(get_current_user_id),
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """
    Get all calendars accessible to the authenticated user.

    Requires JWT authentication - provide token in Authorization header.

    Returns:
    - Calendars owned by the user
    - Calendars where the user is a member (excluding calendars from public users)
    - Public calendars the user is subscribed to (excluding calendars from public users)
    """
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return calendar.get_all_user_calendars(
        db,
        user_id=current_user_id,
        skip=offset,
        limit=limit
    )


@router.get("/public", response_model=List[CalendarResponse])
async def get_public_calendars(
    category: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """
    Get discoverable public calendars.

    Args:
        category: Filter by category (e.g., 'holidays', 'sports', 'music')
        search: Search in calendar name or description
        limit: Maximum number of results (1-200)
        offset: Number of records to skip
    """
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return calendar_subscription.get_public_calendars(
        db,
        category=category,
        search=search,
        skip=offset,
        limit=limit
    )


@router.get("/{calendar_id}", response_model=CalendarResponse)
async def get_calendar(calendar_id: int, db: Session = Depends(get_db)):
    """Get a single calendar by ID"""
    db_calendar = calendar.get(db, id=calendar_id)
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")
    return db_calendar


@router.post("", response_model=CalendarResponse, status_code=201)
async def create_calendar(calendar_data: CalendarCreate, db: Session = Depends(get_db)):
    """Create a new calendar"""
    # Create with validation (checks owner exists)
    db_calendar, error = calendar.create_with_validation(db, obj_in=calendar_data)

    if error:
        raise HTTPException(status_code=404, detail=error)

    return db_calendar


@router.put("/{calendar_id}", response_model=CalendarResponse)
async def update_calendar(
    calendar_id: int,
    calendar_data: CalendarBase,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
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
async def delete_calendar(
    calendar_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Delete a calendar.

    Requires JWT authentication - provide token in Authorization header.
    Only the calendar owner or calendar admins can delete calendars.
    """
    # Check permissions (owner or admin)
    check_calendar_permission(calendar_id, current_user_id, db)

    db_calendar = calendar.get(db, id=calendar_id)
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    calendar.delete(db, id=calendar_id)
    return {"message": "Calendar deleted successfully", "id": calendar_id}


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
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_membership


@router.post("/{share_hash}/subscribe", response_model=CalendarSubscriptionResponse, status_code=201)
async def subscribe_to_calendar(
    share_hash: str,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
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
    subscription_data = CalendarSubscriptionCreate(
        calendar_id=db_calendar.id,
        user_id=current_user_id,
        status="active"
    )

    # Create with validation (checks calendar is public, user exists, no duplicate)
    db_subscription, error = calendar_subscription.create_with_validation(db, obj_in=subscription_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        elif "already subscribed" in error.lower():
            raise HTTPException(status_code=409, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_subscription


@router.delete("/{share_hash}/subscribe")
async def unsubscribe_from_calendar(
    share_hash: str,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
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
    db_subscription = calendar_subscription.get_subscription(
        db,
        calendar_id=db_calendar.id,
        user_id=current_user_id
    )

    if not db_subscription:
        raise HTTPException(status_code=404, detail="Subscription not found")

    # Delete subscription (this will trigger the subscriber_count update)
    calendar_subscription.delete(db, id=db_subscription.id)

    return {"message": "Unsubscribed successfully", "share_hash": share_hash}
