"""
User Blocks Router

Handles all user block endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import user_block
from dependencies import get_db
from schemas import UserBlockCreate, UserBlockResponse

router = APIRouter(prefix="/api/v1/user_blocks", tags=["user_blocks"])


@router.get("", response_model=List[UserBlockResponse])
async def get_user_blocks(
    blocker_user_id: Optional[int] = None,
    blocked_user_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all user blocks, optionally filtered by blocker or blocked user, with pagination and ordering"""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return user_block.get_multi_filtered(
        db,
        blocker_user_id=blocker_user_id,
        blocked_user_id=blocked_user_id,
        skip=offset,
        limit=limit,
        order_by=order_by,
        order_dir=order_dir
    )


@router.get("/{block_id}", response_model=UserBlockResponse)
async def get_user_block(block_id: int, db: Session = Depends(get_db)):
    """Get a single user block by ID"""
    block = user_block.get(db, id=block_id)
    if not block:
        raise HTTPException(status_code=404, detail="User block not found")
    return block


@router.post("", response_model=UserBlockResponse, status_code=201)
async def create_user_block(block_data: UserBlockCreate, db: Session = Depends(get_db)):
    """Block a user"""
    # Create with validation (all checks in CRUD layer)
    db_block, error = user_block.create_with_validation(db, obj_in=block_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_block


@router.delete("/{block_id}")
async def delete_user_block(block_id: int, current_user_id: int, db: Session = Depends(get_db)):
    """
    Unblock a user.

    Requires current_user_id to verify permissions.
    Only the blocker can unblock a user.
    """
    db_block = user_block.get(db, id=block_id)
    if not db_block:
        raise HTTPException(status_code=404, detail="User block not found")

    # Check if user is the blocker
    if db_block.blocker_user_id != current_user_id:
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to delete this block. Only the blocker can unblock."
        )

    user_block.delete(db, id=block_id)
    return {"message": "User block deleted successfully", "id": block_id}
