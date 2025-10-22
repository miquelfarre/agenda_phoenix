"""
Calendar Memberships Router

Handles all calendar membership endpoints.
"""

from typing import List, Optional, Union

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import calendar_membership
from dependencies import check_user_not_public, get_db, is_calendar_owner_or_admin
from schemas import CalendarMembershipBase, CalendarMembershipCreate, CalendarMembershipEnrichedResponse, CalendarMembershipResponse

router = APIRouter(prefix="/calendar_memberships", tags=["calendar_memberships"])


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
        calendar_id: Filter by calendar ID
        user_id: Filter by user ID
        status: Filter by status (pending, accepted, rejected)
        enriched: If True, include calendar info (name, owner_id)
        exclude_owned: If True and user_id provided, exclude calendars owned by user
        limit: Max results (1-200)
        offset: Skip results
        order_by: Column to order by
        order_dir: Order direction (asc/desc)
    """
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    # If enriched, return with calendar information
    if enriched:
        results = calendar_membership.get_enriched(
            db,
            calendar_id=calendar_id,
            user_id=user_id,
            status=status,
            exclude_owned=exclude_owned,
            skip=offset,
            limit=limit,
            order_by=order_by or "created_at",
            order_dir=order_dir
        )

        # Transform to enriched response
        return [
            CalendarMembershipEnrichedResponse(
                id=membership.id,
                calendar_id=membership.calendar_id,
                user_id=membership.user_id,
                role=membership.role,
                status=membership.status,
                invited_by_user_id=membership.invited_by_user_id,
                created_at=membership.created_at,
                updated_at=membership.updated_at,
                calendar_name=calendar.name,
                calendar_owner_id=calendar.owner_id,
            )
            for membership, calendar in results
        ]

    # Return plain memberships
    return calendar_membership.get_multi_filtered(
        db,
        calendar_id=calendar_id,
        user_id=user_id,
        status=status,
        exclude_owned=exclude_owned,
        skip=offset,
        limit=limit,
        order_by=order_by or "created_at",
        order_dir=order_dir
    )


@router.get("/{membership_id}", response_model=CalendarMembershipResponse)
async def get_calendar_membership(membership_id: int, db: Session = Depends(get_db)):
    """Get a single calendar membership by ID"""
    membership = calendar_membership.get(db, id=membership_id)
    if not membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")
    return membership


@router.post("", response_model=CalendarMembershipResponse, status_code=201)
async def create_calendar_membership(membership_data: CalendarMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a calendar (invite or add directly)"""
    # VALIDATION: Public users cannot be added to calendars
    check_user_not_public(membership_data.user_id, db, "be added to calendars")

    # Create with validation (all checks in CRUD layer)
    db_membership, error = calendar_membership.create_with_validation(db, obj_in=membership_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_membership


@router.put("/{membership_id}", response_model=CalendarMembershipResponse)
async def update_calendar_membership(membership_id: int, membership_data: CalendarMembershipBase, current_user_id: int, db: Session = Depends(get_db)):
    """
    Update a calendar membership (e.g., change status from pending to accepted, or change role).

    Requires current_user_id to verify permissions.
    Either the calendar owner/admin OR the user themselves can update the membership.
    """
    db_membership = calendar_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")

    # Check if user is calendar owner/admin OR the member themselves
    is_calendar_admin = is_calendar_owner_or_admin(db_membership.calendar_id, current_user_id, db)
    is_self = db_membership.user_id == current_user_id

    if not (is_calendar_admin or is_self):
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to update this membership. Only the calendar owner/admin or the member themselves can do this."
        )

    updated_membership = calendar_membership.update(db, db_obj=db_membership, obj_in=membership_data)
    return updated_membership


@router.delete("/{membership_id}")
async def delete_calendar_membership(membership_id: int, current_user_id: int, db: Session = Depends(get_db)):
    """
    Remove a user from a calendar.

    Requires current_user_id to verify permissions.
    Either the calendar owner/admin OR the user themselves can delete the membership.
    """
    db_membership = calendar_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")

    # Check if user is calendar owner/admin OR the member themselves
    is_calendar_admin = is_calendar_owner_or_admin(db_membership.calendar_id, current_user_id, db)
    is_self = db_membership.user_id == current_user_id

    if not (is_calendar_admin or is_self):
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to delete this membership. Only the calendar owner/admin or the member themselves can do this."
        )

    calendar_membership.delete(db, id=membership_id)
    return {"message": "Calendar membership deleted successfully", "id": membership_id}
