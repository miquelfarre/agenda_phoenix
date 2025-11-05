"""
Group Memberships Router

Handles all group membership endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import group_membership
from dependencies import check_user_not_public, get_db
from models import Group, GroupMembership
from schemas import GroupMembershipCreate, GroupMembershipResponse, GroupMembershipUpdate

router = APIRouter(prefix="/api/v1/group_memberships", tags=["group_memberships"])


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
    # VALIDATION: Public users cannot be added to groups
    check_user_not_public(membership_data.user_id, db, "be added to groups")

    # Create with validation (all checks in CRUD layer)
    db_membership, error = group_membership.create_with_validation(db, obj_in=membership_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_membership


@router.put("/{membership_id}", response_model=GroupMembershipResponse)
async def update_group_membership(
    membership_id: int,
    membership_data: GroupMembershipUpdate,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Update a group membership (currently only role can be updated).

    Requires JWT authentication - provide token in Authorization header.
    Only the group creator or admins can update memberships.

    Valid roles: 'admin', 'member'
    """
    db_membership = group_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Group membership not found")

    # Get group to check creator/admin
    group = db.query(Group).filter(Group.id == db_membership.group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Check if user is creator
    is_creator = group.created_by == current_user_id

    # Check if user is admin
    is_admin = db.query(GroupMembership).filter(
        GroupMembership.group_id == db_membership.group_id,
        GroupMembership.user_id == current_user_id,
        GroupMembership.role == "admin"
    ).first() is not None

    # Only group creator or admins can update memberships
    if not (is_creator or is_admin):
        raise HTTPException(
            status_code=403,
            detail="Only the group creator or admins can update memberships"
        )

    # Validate role if provided
    if membership_data.role and membership_data.role not in ["admin", "member"]:
        raise HTTPException(
            status_code=400,
            detail="Role must be 'admin' or 'member'"
        )

    updated = group_membership.update(db, db_obj=db_membership, obj_in=membership_data)
    return updated


@router.delete("/{membership_id}")
async def delete_group_membership(
    membership_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Remove a user from a group.

    Requires JWT authentication - provide token in Authorization header.
    Either the group creator, admins, OR the user themselves can delete the membership.
    """
    db_membership = group_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Group membership not found")

    # Get group to check creator
    group = db.query(Group).filter(Group.id == db_membership.group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Check if user is group creator
    is_creator = group.created_by == current_user_id

    # Check if user is admin
    is_admin = db.query(GroupMembership).filter(
        GroupMembership.group_id == db_membership.group_id,
        GroupMembership.user_id == current_user_id,
        GroupMembership.role == "admin"
    ).first() is not None

    # Check if user is the member themselves
    is_self = db_membership.user_id == current_user_id

    if not (is_creator or is_admin or is_self):
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to delete this membership. Only the group creator, admins, or the member themselves can do this."
        )

    group_membership.delete(db, id=membership_id)
    return {"message": "Group membership deleted successfully", "id": membership_id}
