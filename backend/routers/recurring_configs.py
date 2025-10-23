"""
Recurring Event Configs Router

Handles all recurring event configuration endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import recurring_config
from dependencies import check_event_permission, get_db
from schemas import RecurringEventConfigBase, RecurringEventConfigCreate, RecurringEventConfigResponse

router = APIRouter(prefix="/api/v1/recurring_configs", tags=["recurring_configs"])


@router.get("", response_model=List[RecurringEventConfigResponse])
async def get_recurring_configs(
    event_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all recurring event configs, optionally filtered by event_id, with pagination and ordering"""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return recurring_config.get_multi_filtered(
        db,
        event_id=event_id,
        skip=offset,
        limit=limit,
        order_by=order_by,
        order_dir=order_dir
    )


@router.get("/{config_id}", response_model=RecurringEventConfigResponse)
async def get_recurring_config(config_id: int, db: Session = Depends(get_db)):
    """Get a single recurring config by ID"""
    db_config = recurring_config.get(db, id=config_id)
    if not db_config:
        raise HTTPException(status_code=404, detail="Recurring config not found")
    return db_config


@router.post("", response_model=RecurringEventConfigResponse, status_code=201)
async def create_recurring_config(config_data: RecurringEventConfigCreate, db: Session = Depends(get_db)):
    """Create a new recurring event config"""
    # Create with validation (all checks in CRUD layer)
    db_config, error = recurring_config.create_with_validation(db, obj_in=config_data)

    if error:
        # Map error messages to appropriate status codes
        if "not found" in error.lower():
            raise HTTPException(status_code=404, detail=error)
        else:
            raise HTTPException(status_code=400, detail=error)

    return db_config


@router.put("/{config_id}", response_model=RecurringEventConfigResponse)
async def update_recurring_config(
    config_id: int,
    config_data: RecurringEventConfigBase,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Update an existing recurring config.

    Requires JWT authentication - provide token in Authorization header.
    Only the event owner or event admins can update recurring configs.
    """
    db_config = recurring_config.get(db, id=config_id)
    if not db_config:
        raise HTTPException(status_code=404, detail="Recurring config not found")

    # Check permissions on the event
    check_event_permission(db_config.event_id, current_user_id, db)

    updated_config = recurring_config.update(db, db_obj=db_config, obj_in=config_data)
    return updated_config


@router.delete("/{config_id}")
async def delete_recurring_config(
    config_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Delete a recurring config.

    Requires JWT authentication - provide token in Authorization header.
    Only the event owner or event admins can delete recurring configs.
    """
    db_config = recurring_config.get(db, id=config_id)
    if not db_config:
        raise HTTPException(status_code=404, detail="Recurring config not found")

    # Check permissions on the event
    check_event_permission(db_config.event_id, current_user_id, db)

    recurring_config.delete(db, id=config_id)
    return {"message": "Recurring config deleted successfully", "id": config_id}
