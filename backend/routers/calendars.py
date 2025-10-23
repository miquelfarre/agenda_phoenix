"""
Calendars Router

Handles all calendar-related endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import calendar, calendar_membership
from dependencies import check_calendar_permission, get_db
from schemas import CalendarBase, CalendarCreate, CalendarMembershipCreate, CalendarMembershipResponse, CalendarResponse

router = APIRouter(prefix="/api/v1/calendars", tags=["calendars"])


@router.get("", response_model=List[CalendarResponse])
async def get_calendars(
    user_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: Optional[str] = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all calendars, optionally filtered by owner user_id"""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return calendar.get_multi_filtered(
        db,
        owner_id=user_id,
        skip=offset,
        limit=limit,
        order_by=order_by or "id",
        order_dir=order_dir
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
async def update_calendar(calendar_id: int, calendar_data: CalendarBase, current_user_id: int, db: Session = Depends(get_db)):
    """
    Update an existing calendar.

    Requires current_user_id to verify permissions.
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
async def delete_calendar(calendar_id: int, current_user_id: int, db: Session = Depends(get_db)):
    """
    Delete a calendar.

    Requires current_user_id to verify permissions.
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
