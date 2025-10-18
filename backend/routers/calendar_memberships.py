"""
Calendar Memberships Router

Handles all calendar membership endpoints.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from models import Calendar, User, CalendarMembership
from schemas import CalendarMembershipCreate, CalendarMembershipBase, CalendarMembershipResponse
from dependencies import get_db


router = APIRouter(
    prefix="/calendar_memberships",
    tags=["calendar_memberships"]
)


@router.get("", response_model=List[CalendarMembershipResponse])
async def get_calendar_memberships(
    calendar_id: Optional[int] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get all calendar memberships, optionally filtered by calendar_id and/or user_id"""
    query = db.query(CalendarMembership)
    if calendar_id:
        query = query.filter(CalendarMembership.calendar_id == calendar_id)
    if user_id:
        query = query.filter(CalendarMembership.user_id == user_id)
    memberships = query.all()
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
