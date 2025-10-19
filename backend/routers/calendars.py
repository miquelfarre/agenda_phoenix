"""
Calendars Router

Handles all calendar-related endpoints.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from models import Calendar, User, CalendarMembership
from schemas import CalendarCreate, CalendarBase, CalendarResponse, CalendarEnrichedResponse, CalendarMembershipCreate, CalendarMembershipResponse
from dependencies import get_db
from typing import Union


router = APIRouter(
    prefix="/calendars",
    tags=["calendars"]
)


@router.get("", response_model=List[Union[CalendarResponse, CalendarEnrichedResponse]])
async def get_calendars(
    user_id: Optional[int] = None,
    enriched: bool = False,
    limit: int = 50,
    offset: int = 0,
    order_by: Optional[str] = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all calendars, optionally filtered by user_id, optionally enriched with display fields"""
    query = db.query(Calendar)
    if user_id:
        query = query.filter(Calendar.owner_id == user_id)
    # Apply ordering and pagination
    order_col = getattr(Calendar, order_by) if order_by and hasattr(Calendar, str(order_by)) else Calendar.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))

    calendars = query.all()

    if enriched:
        enriched_calendars = []
        for cal in calendars:
            enriched_calendars.append(CalendarEnrichedResponse(
                id=cal.id,
                name=cal.name,
                owner_id=cal.owner_id,
                created_at=cal.created_at,
                updated_at=cal.updated_at
            ))
        return enriched_calendars

    return calendars


@router.get("/{calendar_id}", response_model=CalendarResponse)
async def get_calendar(calendar_id: int, db: Session = Depends(get_db)):
    """Get a single calendar by ID"""
    calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")
    return calendar


@router.post("", response_model=CalendarResponse, status_code=201)
async def create_calendar(calendar: CalendarCreate, db: Session = Depends(get_db)):
    """Create a new calendar"""
    # Verify user exists
    user = db.query(User).filter(User.id == calendar.owner_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db_calendar = Calendar(**calendar.dict())
    db.add(db_calendar)
    db.commit()
    db.refresh(db_calendar)
    return db_calendar


@router.put("/{calendar_id}", response_model=CalendarResponse)
async def update_calendar(calendar_id: int, calendar: CalendarBase, db: Session = Depends(get_db)):
    """Update an existing calendar"""
    db_calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    for key, value in calendar.dict().items():
        setattr(db_calendar, key, value)

    db.commit()
    db.refresh(db_calendar)
    return db_calendar


@router.delete("/{calendar_id}")
async def delete_calendar(calendar_id: int, db: Session = Depends(get_db)):
    """Delete a calendar"""
    db_calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    db.delete(db_calendar)
    db.commit()
    return {"message": "Calendar deleted successfully", "id": calendar_id}


@router.get("/{calendar_id}/memberships", response_model=List[CalendarMembershipResponse])
async def get_calendar_members(calendar_id: int, db: Session = Depends(get_db)):
    """Get all members of a specific calendar (REST-ful alias)"""
    # Verify calendar exists
    calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    memberships = db.query(CalendarMembership).filter(
        CalendarMembership.calendar_id == calendar_id
    ).all()
    return memberships


@router.post("/memberships", response_model=CalendarMembershipResponse, status_code=201)
async def create_calendar_membership_alias(membership: CalendarMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a calendar (REST-ful alias for /calendar_memberships)"""
    # Verify calendar exists
    calendar = db.query(Calendar).filter(Calendar.id == membership.calendar_id).first()
    if not calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    # Verify user exists
    user = db.query(User).filter(User.id == membership.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if membership already exists
    existing = db.query(CalendarMembership).filter(
        CalendarMembership.calendar_id == membership.calendar_id,
        CalendarMembership.user_id == membership.user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already has a membership in this calendar")

    db_membership = CalendarMembership(**membership.dict())
    db.add(db_membership)
    db.commit()
    db.refresh(db_membership)
    return db_membership
