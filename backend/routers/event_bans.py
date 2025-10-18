"""
Event Bans Router

Handles all event ban endpoints.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from models import Event, User, EventBan
from schemas import EventBanCreate, EventBanResponse
from dependencies import get_db


router = APIRouter(
    prefix="/event_bans",
    tags=["event_bans"]
)


@router.get("", response_model=List[EventBanResponse])
async def get_event_bans(
    event_id: Optional[int] = None,
    user_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all event bans, optionally filtered by event_id and/or user_id, with pagination and ordering"""
    query = db.query(EventBan)
    if event_id:
        query = query.filter(EventBan.event_id == event_id)
    if user_id:
        query = query.filter(EventBan.user_id == user_id)

    order_col = getattr(EventBan, order_by) if order_by and hasattr(EventBan, str(order_by)) else EventBan.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))
    bans = query.all()
    return bans


@router.get("/{ban_id}", response_model=EventBanResponse)
async def get_event_ban(ban_id: int, db: Session = Depends(get_db)):
    """Get a single event ban by ID"""
    ban = db.query(EventBan).filter(EventBan.id == ban_id).first()
    if not ban:
        raise HTTPException(status_code=404, detail="Event ban not found")
    return ban


@router.post("", response_model=EventBanResponse, status_code=201)
async def create_event_ban(ban: EventBanCreate, db: Session = Depends(get_db)):
    """Ban a user from an event"""
    # Verify event exists
    event = db.query(Event).filter(Event.id == ban.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Verify banned user exists
    user = db.query(User).filter(User.id == ban.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Verify banner exists
    banner = db.query(User).filter(User.id == ban.banned_by).first()
    if not banner:
        raise HTTPException(status_code=404, detail="Banner user not found")

    # Check if ban already exists
    existing = db.query(EventBan).filter(
        EventBan.event_id == ban.event_id,
        EventBan.user_id == ban.user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User is already banned from this event")

    db_ban = EventBan(**ban.dict())
    db.add(db_ban)
    db.commit()
    db.refresh(db_ban)
    return db_ban


@router.delete("/{ban_id}")
async def delete_event_ban(ban_id: int, db: Session = Depends(get_db)):
    """Unban a user from an event"""
    db_ban = db.query(EventBan).filter(EventBan.id == ban_id).first()
    if not db_ban:
        raise HTTPException(status_code=404, detail="Event ban not found")

    db.delete(db_ban)
    db.commit()
    return {"message": "Event ban deleted successfully", "id": ban_id}
