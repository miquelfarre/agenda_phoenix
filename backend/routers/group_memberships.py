"""
Group Memberships Router

Handles all group membership endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from dependencies import get_db
from models import Group, GroupMembership, User
from schemas import GroupMembershipCreate, GroupMembershipResponse

router = APIRouter(prefix="/group_memberships", tags=["group_memberships"])


@router.get("", response_model=List[GroupMembershipResponse])
async def get_group_memberships(group_id: Optional[int] = None, user_id: Optional[int] = None, limit: int = 50, offset: int = 0, order_by: str = "id", order_dir: str = "asc", db: Session = Depends(get_db)):
    """Get all group memberships, optionally filtered by group_id and/or user_id, with pagination and ordering"""
    query = db.query(GroupMembership)
    if group_id:
        query = query.filter(GroupMembership.group_id == group_id)
    if user_id:
        query = query.filter(GroupMembership.user_id == user_id)

    order_col = getattr(GroupMembership, order_by) if order_by and hasattr(GroupMembership, str(order_by)) else GroupMembership.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))
    memberships = query.all()
    return memberships


@router.get("/{membership_id}", response_model=GroupMembershipResponse)
async def get_group_membership(membership_id: int, db: Session = Depends(get_db)):
    """Get a single group membership by ID"""
    membership = db.query(GroupMembership).filter(GroupMembership.id == membership_id).first()
    if not membership:
        raise HTTPException(status_code=404, detail="Group membership not found")
    return membership


@router.post("", response_model=GroupMembershipResponse, status_code=201)
async def create_group_membership(membership: GroupMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a group"""
    # Verify group exists
    group = db.query(Group).filter(Group.id == membership.group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Verify user exists
    user = db.query(User).filter(User.id == membership.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if membership already exists
    existing = db.query(GroupMembership).filter(GroupMembership.group_id == membership.group_id, GroupMembership.user_id == membership.user_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="User is already a member of this group")

    db_membership = GroupMembership(**membership.model_dump())
    db.add(db_membership)
    db.commit()
    db.refresh(db_membership)
    return db_membership


@router.delete("/{membership_id}")
async def delete_group_membership(membership_id: int, db: Session = Depends(get_db)):
    """Remove a user from a group"""
    db_membership = db.query(GroupMembership).filter(GroupMembership.id == membership_id).first()
    if not db_membership:
        raise HTTPException(status_code=404, detail="Group membership not found")

    db.delete(db_membership)
    db.commit()
    return {"message": "Group membership deleted successfully", "id": membership_id}
