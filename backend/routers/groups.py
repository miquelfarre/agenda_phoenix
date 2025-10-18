"""
Groups Router

Handles all group-related endpoints.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from models import Group, User
from schemas import GroupCreate, GroupBase, GroupResponse
from dependencies import get_db


router = APIRouter(
    prefix="/groups",
    tags=["groups"]
)


@router.get("", response_model=List[GroupResponse])
async def get_groups(
    created_by: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all groups, optionally filtered by creator, with pagination and ordering"""
    query = db.query(Group)
    if created_by:
        query = query.filter(Group.created_by == created_by)

    order_col = getattr(Group, order_by) if order_by and hasattr(Group, str(order_by)) else Group.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))
    groups = query.all()
    return groups


@router.get("/{group_id}", response_model=GroupResponse)
async def get_group(group_id: int, db: Session = Depends(get_db)):
    """Get a single group by ID"""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
    return group


@router.post("", response_model=GroupResponse, status_code=201)
async def create_group(group: GroupCreate, db: Session = Depends(get_db)):
    """Create a new group"""
    # Verify creator exists
    creator = db.query(User).filter(User.id == group.created_by).first()
    if not creator:
        raise HTTPException(status_code=404, detail="Creator user not found")

    db_group = Group(**group.dict())
    db.add(db_group)
    db.commit()
    db.refresh(db_group)
    return db_group


@router.put("/{group_id}", response_model=GroupResponse)
async def update_group(group_id: int, group: GroupBase, db: Session = Depends(get_db)):
    """Update an existing group"""
    db_group = db.query(Group).filter(Group.id == group_id).first()
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    for key, value in group.dict().items():
        setattr(db_group, key, value)

    db.commit()
    db.refresh(db_group)
    return db_group


@router.delete("/{group_id}")
async def delete_group(group_id: int, db: Session = Depends(get_db)):
    """Delete a group"""
    db_group = db.query(Group).filter(Group.id == group_id).first()
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    db.delete(db_group)
    db.commit()
    return {"message": "Group deleted successfully", "id": group_id}
