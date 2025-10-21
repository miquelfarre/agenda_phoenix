"""
App Bans Router

Handles application-level bans (admin only).
When a user is banned here, they cannot access the application at all.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from dependencies import get_db
from models import AppBan, User
from schemas import AppBanCreate, AppBanResponse

router = APIRouter(prefix="/app_bans", tags=["app_bans"])


@router.get("", response_model=List[AppBanResponse])
async def get_app_bans(user_id: Optional[int] = None, banned_by: Optional[int] = None, limit: int = 50, offset: int = 0, order_by: str = "id", order_dir: str = "asc", db: Session = Depends(get_db)):
    """Get all app bans, optionally filtered by user_id or banned_by (admin), with pagination and ordering"""
    query = db.query(AppBan)
    if user_id:
        query = query.filter(AppBan.user_id == user_id)
    if banned_by:
        query = query.filter(AppBan.banned_by == banned_by)

    order_col = getattr(AppBan, order_by) if order_by and hasattr(AppBan, str(order_by)) else AppBan.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))
    bans = query.all()
    return bans


@router.get("/{ban_id}", response_model=AppBanResponse)
async def get_app_ban(ban_id: int, db: Session = Depends(get_db)):
    """Get a single app ban by ID"""
    ban = db.query(AppBan).filter(AppBan.id == ban_id).first()
    if not ban:
        raise HTTPException(status_code=404, detail="App ban not found")
    return ban


@router.post("", response_model=AppBanResponse, status_code=201)
async def create_app_ban(ban: AppBanCreate, db: Session = Depends(get_db)):
    """Ban a user from the entire application (admin only)"""
    # Verify banned user exists
    user = db.query(User).filter(User.id == ban.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Verify admin/banner exists
    banner = db.query(User).filter(User.id == ban.banned_by).first()
    if not banner:
        raise HTTPException(status_code=404, detail="Banner user (admin) not found")

    # Check if ban already exists
    existing = db.query(AppBan).filter(AppBan.user_id == ban.user_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="User is already banned from the application")

    db_ban = AppBan(**ban.model_dump())
    db.add(db_ban)
    db.commit()
    db.refresh(db_ban)
    return db_ban


@router.delete("/{ban_id}")
async def delete_app_ban(ban_id: int, db: Session = Depends(get_db)):
    """Unban a user from the application (admin only)"""
    db_ban = db.query(AppBan).filter(AppBan.id == ban_id).first()
    if not db_ban:
        raise HTTPException(status_code=404, detail="App ban not found")

    db.delete(db_ban)
    db.commit()
    return {"message": "App ban deleted successfully", "id": ban_id}
