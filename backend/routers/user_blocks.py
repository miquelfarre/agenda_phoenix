"""
User Blocks Router

Handles all user block endpoints.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from models import User, UserBlock
from schemas import UserBlockCreate, UserBlockResponse
from dependencies import get_db


router = APIRouter(
    prefix="/user_blocks",
    tags=["user_blocks"]
)


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
    query = db.query(UserBlock)
    if blocker_user_id:
        query = query.filter(UserBlock.blocker_user_id == blocker_user_id)
    if blocked_user_id:
        query = query.filter(UserBlock.blocked_user_id == blocked_user_id)

    order_col = getattr(UserBlock, order_by) if order_by and hasattr(UserBlock, str(order_by)) else UserBlock.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))
    blocks = query.all()
    return blocks


@router.get("/{block_id}", response_model=UserBlockResponse)
async def get_user_block(block_id: int, db: Session = Depends(get_db)):
    """Get a single user block by ID"""
    block = db.query(UserBlock).filter(UserBlock.id == block_id).first()
    if not block:
        raise HTTPException(status_code=404, detail="User block not found")
    return block


@router.post("", response_model=UserBlockResponse, status_code=201)
async def create_user_block(block: UserBlockCreate, db: Session = Depends(get_db)):
    """Block a user"""
    # Verify blocker exists
    blocker = db.query(User).filter(User.id == block.blocker_user_id).first()
    if not blocker:
        raise HTTPException(status_code=404, detail="Blocker user not found")

    # Verify blocked user exists
    blocked = db.query(User).filter(User.id == block.blocked_user_id).first()
    if not blocked:
        raise HTTPException(status_code=404, detail="Blocked user not found")

    # Check if block already exists
    existing = db.query(UserBlock).filter(
        UserBlock.blocker_user_id == block.blocker_user_id,
        UserBlock.blocked_user_id == block.blocked_user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User is already blocked")

    db_block = UserBlock(**block.dict())
    db.add(db_block)
    db.commit()
    db.refresh(db_block)
    return db_block


@router.delete("/{block_id}")
async def delete_user_block(block_id: int, db: Session = Depends(get_db)):
    """Unblock a user"""
    db_block = db.query(UserBlock).filter(UserBlock.id == block_id).first()
    if not db_block:
        raise HTTPException(status_code=404, detail="User block not found")

    db.delete(db_block)
    db.commit()
    return {"message": "User block deleted successfully", "id": block_id}
