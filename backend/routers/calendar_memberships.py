"""
Calendar Memberships Router

Handles all calendar membership endpoints.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from models import Calendar, User, CalendarMembership
from schemas import (
    CalendarMembershipCreate, CalendarMembershipBase,
    CalendarMembershipResponse, CalendarMembershipEnrichedResponse
)
from dependencies import get_db
from typing import Union


router = APIRouter(
    prefix="/calendar_memberships",
    tags=["calendar_memberships"]
)


@router.get("", response_model=List[Union[CalendarMembershipResponse, CalendarMembershipEnrichedResponse]])
async def get_calendar_memberships(
    calendar_id: Optional[int] = None,
    user_id: Optional[int] = None,
    status: Optional[str] = None,
    enriched: bool = False,
    exclude_owned: bool = False,
    limit: int = 50,
    offset: int = 0,
    order_by: Optional[str] = "created_at",
    order_dir: str = "desc",
    db: Session = Depends(get_db)
):
    """Get all calendar memberships, optionally filtered, optionally enriched with calendar info

    Args:
        exclude_owned: If True and user_id is provided, exclude calendars where user_id is the calendar owner
    """
    query = db.query(CalendarMembership)
    if calendar_id:
        query = query.filter(CalendarMembership.calendar_id == calendar_id)
    if user_id:
        query = query.filter(CalendarMembership.user_id == user_id)
    if status:
        query = query.filter(CalendarMembership.status == status)

    # Apply ordering and pagination to base query (used when not enriched)
    order_col = getattr(CalendarMembership, order_by) if order_by and hasattr(CalendarMembership, str(order_by)) else CalendarMembership.created_at if hasattr(CalendarMembership, "created_at") else CalendarMembership.id
    if order_dir and order_dir.lower() == "asc":
        query = query.order_by(order_col.asc())
    else:
        query = query.order_by(order_col.desc())

    memberships = query.all()

    # If enriched, add calendar information
    if enriched:
        # Use JOIN to get calendar data efficiently
        results = db.query(CalendarMembership, Calendar).join(
            Calendar, CalendarMembership.calendar_id == Calendar.id
        )

        if calendar_id:
            results = results.filter(CalendarMembership.calendar_id == calendar_id)
        if user_id:
            results = results.filter(CalendarMembership.user_id == user_id)
            # If exclude_owned, filter out calendars where user_id is the owner
            if exclude_owned:
                results = results.filter(Calendar.owner_id != user_id)
        if status:
            results = results.filter(CalendarMembership.status == status)

        # Apply ordering and pagination on enriched path
        order_col = getattr(CalendarMembership, order_by) if order_by and hasattr(CalendarMembership, str(order_by)) else CalendarMembership.created_at if hasattr(CalendarMembership, "created_at") else CalendarMembership.id
        if order_dir and order_dir.lower() == "asc":
            results = results.order_by(order_col.asc())
        else:
            results = results.order_by(order_col.desc())

        results = results.offset(max(0, offset)).limit(max(1, min(200, limit))).all()

        enriched_memberships = []
        for membership, calendar in results:
            # Create CalendarMembershipEnrichedResponse instance directly
            enriched_memberships.append(CalendarMembershipEnrichedResponse(
                id=membership.id,
                calendar_id=membership.calendar_id,
                user_id=membership.user_id,
                role=membership.role,
                status=membership.status,
                invited_by_user_id=membership.invited_by_user_id,
                created_at=membership.created_at,
                updated_at=membership.updated_at,
                calendar_name=calendar.name,
                calendar_owner_id=calendar.owner_id
            ))

        return enriched_memberships

    # For non-enriched, apply exclude_owned filter if needed
    if exclude_owned and user_id:
        # Use single JOIN-based query to avoid N+1
        q = db.query(CalendarMembership).join(Calendar, CalendarMembership.calendar_id == Calendar.id)
        if calendar_id:
            q = q.filter(CalendarMembership.calendar_id == calendar_id)
        q = q.filter(CalendarMembership.user_id == user_id)
        if status:
            q = q.filter(CalendarMembership.status == status)
        q = q.filter(Calendar.owner_id != user_id)

        # Apply ordering and pagination
        order_col = getattr(CalendarMembership, order_by) if order_by and hasattr(CalendarMembership, str(order_by)) else CalendarMembership.created_at if hasattr(CalendarMembership, "created_at") else CalendarMembership.id
        if order_dir and order_dir.lower() == "asc":
            q = q.order_by(order_col.asc())
        else:
            q = q.order_by(order_col.desc())

        q = q.offset(max(0, offset)).limit(max(1, min(200, limit)))
        return q.all()

    return memberships


@router.get("/{membership_id}", response_model=CalendarMembershipResponse)
async def get_calendar_membership(membership_id: int, db: Session = Depends(get_db)):
    """Get a single calendar membership by ID"""
    membership = db.query(CalendarMembership).filter(CalendarMembership.id == membership_id).first()
    if not membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")
    return membership


@router.post("", response_model=CalendarMembershipResponse, status_code=201)
async def create_calendar_membership(membership: CalendarMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a calendar (invite or add directly)"""
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


@router.put("/{membership_id}", response_model=CalendarMembershipResponse)
async def update_calendar_membership(
    membership_id: int,
    membership: CalendarMembershipBase,
    db: Session = Depends(get_db)
):
    """Update a calendar membership (e.g., change status from pending to accepted, or change role)"""
    db_membership = db.query(CalendarMembership).filter(CalendarMembership.id == membership_id).first()
    if not db_membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")

    for key, value in membership.dict().items():
        setattr(db_membership, key, value)

    db.commit()
    db.refresh(db_membership)
    return db_membership


@router.delete("/{membership_id}")
async def delete_calendar_membership(membership_id: int, db: Session = Depends(get_db)):
    """Remove a user from a calendar"""
    db_membership = db.query(CalendarMembership).filter(CalendarMembership.id == membership_id).first()
    if not db_membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")

    db.delete(db_membership)
    db.commit()
    return {"message": "Calendar membership deleted successfully", "id": membership_id}
