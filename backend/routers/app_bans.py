"""
App Bans Router

Handles application-level bans (admin only).
When a user is banned here, they cannot access the application at all.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import app_ban
from dependencies import check_is_admin, get_db
from schemas import AppBanCreate, AppBanResponse

router = APIRouter(prefix="/app_bans", tags=["app_bans"])


@router.get("", response_model=List[AppBanResponse])
async def get_app_bans(
    user_id: Optional[int] = None,
    banned_by: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all app bans, optionally filtered by user_id or banned_by (admin), with pagination and ordering"""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return app_ban.get_multi_by_user(
        db,
        user_id=user_id,
        banned_by=banned_by,
        skip=offset,
        limit=limit,
        order_by=order_by,
        order_dir=order_dir
    )


@router.get("/{ban_id}", response_model=AppBanResponse)
async def get_app_ban(ban_id: int, db: Session = Depends(get_db)):
    """Get a single app ban by ID"""
    ban = app_ban.get(db, id=ban_id)
    if not ban:
        raise HTTPException(status_code=404, detail="App ban not found")
    return ban


@router.post("", response_model=AppBanResponse, status_code=201)
async def create_app_ban(ban_data: AppBanCreate, current_user_id: int, db: Session = Depends(get_db)):
    """
    Ban a user from the entire application (admin only).

    Requires current_user_id to verify permissions.
    Only super admins can ban users from the application.
    """
    # Check if current user is admin
    check_is_admin(current_user_id, db)

    # Create with validation (all checks in CRUD layer)
    db_ban, error = app_ban.create_with_validation(db, obj_in=ban_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_ban


@router.delete("/{ban_id}")
async def delete_app_ban(ban_id: int, current_user_id: int, db: Session = Depends(get_db)):
    """
    Unban a user from the application (admin only).

    Requires current_user_id to verify permissions.
    Only super admins can unban users from the application.
    """
    # Check if current user is admin
    check_is_admin(current_user_id, db)

    db_ban = app_ban.get(db, id=ban_id)
    if not db_ban:
        raise HTTPException(status_code=404, detail="App ban not found")

    app_ban.delete(db, id=ban_id)
    return {"message": "App ban deleted successfully", "id": ban_id}
