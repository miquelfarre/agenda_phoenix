"""
Group Memberships Router

Handles all group membership endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import group_membership
from dependencies import get_db
from schemas import GroupMembershipCreate, GroupMembershipResponse

router = APIRouter(prefix="/group_memberships", tags=["group_memberships"])


@router.get("", response_model=List[GroupMembershipResponse])
async def get_group_memberships(
    group_id: Optional[int] = None,
    user_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all group memberships, optionally filtered by group_id and/or user_id, with pagination and ordering"""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return group_membership.get_multi_filtered(
        db,
        group_id=group_id,
        user_id=user_id,
        skip=offset,
        limit=limit,
        order_by=order_by,
        order_dir=order_dir
    )


@router.get("/{membership_id}", response_model=GroupMembershipResponse)
async def get_group_membership(membership_id: int, db: Session = Depends(get_db)):
    """Get a single group membership by ID"""
    db_membership = group_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Group membership not found")
    return db_membership


@router.post("", response_model=GroupMembershipResponse, status_code=201)
async def create_group_membership(membership_data: GroupMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a group"""
    # Create with validation (all checks in CRUD layer)
    db_membership, error = group_membership.create_with_validation(db, obj_in=membership_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_membership


@router.delete("/{membership_id}")
async def delete_group_membership(membership_id: int, db: Session = Depends(get_db)):
    """Remove a user from a group"""
    db_membership = group_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Group membership not found")

    group_membership.delete(db, id=membership_id)
    return {"message": "Group membership deleted successfully", "id": membership_id}
