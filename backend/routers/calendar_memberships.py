"""
Calendar Memberships Router

Handles all calendar membership endpoints.
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import calendar_membership
from dependencies import get_db, is_calendar_owner_or_admin
from schemas import CalendarMembershipBase

router = APIRouter(prefix="/api/v1/calendar_memberships", tags=["calendar_memberships"])


# Removed unused aggregator endpoints: GET list/detail and POST/PUT (Flutter only uses DELETE)


@router.delete("/{membership_id}")
async def delete_calendar_membership(membership_id: int, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Remove a user from a calendar.

    Requires JWT authentication - provide token in Authorization header.
    Either the calendar owner/admin OR the user themselves can delete the membership.
    """
    db_membership = calendar_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")

    # Check if user is calendar owner/admin OR the member themselves
    is_calendar_admin = is_calendar_owner_or_admin(db_membership.calendar_id, current_user_id, db)
    is_self = db_membership.user_id == current_user_id

    if not (is_calendar_admin or is_self):
        raise HTTPException(status_code=403, detail="You don't have permission to delete this membership. Only the calendar owner/admin or the member themselves can do this.")

    calendar_membership.delete(db, id=membership_id)
    return {"message": "Calendar membership deleted successfully", "id": membership_id}
