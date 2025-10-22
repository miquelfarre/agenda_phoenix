"""
Groups Router

Handles all group-related endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import group
from dependencies import get_db
from schemas import GroupBase, GroupCreate, GroupResponse

router = APIRouter(prefix="/groups", tags=["groups"])


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
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return group.get_multi_filtered(
        db,
        created_by=created_by,
        skip=offset,
        limit=limit,
        order_by=order_by,
        order_dir=order_dir
    )


@router.get("/{group_id}", response_model=GroupResponse)
async def get_group(group_id: int, db: Session = Depends(get_db)):
    """Get a single group by ID"""
    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")
    return db_group


@router.post("", response_model=GroupResponse, status_code=201)
async def create_group(group_data: GroupCreate, db: Session = Depends(get_db)):
    """Create a new group"""
    # Create with validation (all checks in CRUD layer)
    db_group, error = group.create_with_validation(db, obj_in=group_data)

    if error:
        raise HTTPException(status_code=404, detail=error)

    return db_group


@router.put("/{group_id}", response_model=GroupResponse)
async def update_group(group_id: int, group_data: GroupBase, db: Session = Depends(get_db)):
    """Update an existing group"""
    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    updated_group = group.update(db, db_obj=db_group, obj_in=group_data)
    return updated_group


@router.delete("/{group_id}")
async def delete_group(group_id: int, db: Session = Depends(get_db)):
    """Delete a group"""
    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    group.delete(db, id=group_id)
    return {"message": "Group deleted successfully", "id": group_id}
