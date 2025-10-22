"""
Event Bans Router

Handles all event ban endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import event_ban
from dependencies import get_db
from schemas import EventBanCreate, EventBanResponse

router = APIRouter(prefix="/event_bans", tags=["event_bans"])


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
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return event_ban.get_multi_filtered(
        db,
        event_id=event_id,
        user_id=user_id,
        skip=offset,
        limit=limit,
        order_by=order_by,
        order_dir=order_dir
    )


@router.get("/{ban_id}", response_model=EventBanResponse)
async def get_event_ban(ban_id: int, db: Session = Depends(get_db)):
    """Get a single event ban by ID"""
    ban = event_ban.get(db, id=ban_id)
    if not ban:
        raise HTTPException(status_code=404, detail="Event ban not found")
    return ban


@router.post("", response_model=EventBanResponse, status_code=201)
async def create_event_ban(ban_data: EventBanCreate, db: Session = Depends(get_db)):
    """Ban a user from an event"""
    # Create with validation (all checks in CRUD layer)
    db_ban, error = event_ban.create_with_validation(db, obj_in=ban_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_ban


@router.delete("/{ban_id}")
async def delete_event_ban(ban_id: int, db: Session = Depends(get_db)):
    """Unban a user from an event"""
    db_ban = event_ban.get(db, id=ban_id)
    if not db_ban:
        raise HTTPException(status_code=404, detail="Event ban not found")

    event_ban.delete(db, id=ban_id)
    return {"message": "Event ban deleted successfully", "id": ban_id}
