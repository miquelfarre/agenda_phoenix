"""
Recurring Event Configs Router

Handles all recurring event configuration endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from dependencies import get_db
from models import Event, RecurringEventConfig
from schemas import RecurringEventConfigBase, RecurringEventConfigCreate, RecurringEventConfigResponse

router = APIRouter(prefix="/recurring_configs", tags=["recurring_configs"])


@router.get("", response_model=List[RecurringEventConfigResponse])
async def get_recurring_configs(event_id: Optional[int] = None, limit: int = 50, offset: int = 0, order_by: str = "id", order_dir: str = "asc", db: Session = Depends(get_db)):
    """Get all recurring event configs, optionally filtered by event_id, with pagination and ordering"""
    query = db.query(RecurringEventConfig)
    if event_id:
        query = query.filter(RecurringEventConfig.event_id == event_id)

    order_col = getattr(RecurringEventConfig, order_by) if order_by and hasattr(RecurringEventConfig, str(order_by)) else RecurringEventConfig.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())

    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))
    configs = query.all()
    return configs


@router.get("/{config_id}", response_model=RecurringEventConfigResponse)
async def get_recurring_config(config_id: int, db: Session = Depends(get_db)):
    """Get a single recurring config by ID"""
    config = db.query(RecurringEventConfig).filter(RecurringEventConfig.id == config_id).first()
    if not config:
        raise HTTPException(status_code=404, detail="Recurring config not found")
    return config


@router.post("", response_model=RecurringEventConfigResponse, status_code=201)
async def create_recurring_config(config: RecurringEventConfigCreate, db: Session = Depends(get_db)):
    """Create a new recurring event config"""
    # Verify event exists
    event = db.query(Event).filter(Event.id == config.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Check if config already exists for this event
    existing = db.query(RecurringEventConfig).filter(RecurringEventConfig.event_id == config.event_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Event already has a recurring config")

    db_config = RecurringEventConfig(**config.model_dump())
    db.add(db_config)
    db.commit()
    db.refresh(db_config)
    return db_config


@router.put("/{config_id}", response_model=RecurringEventConfigResponse)
async def update_recurring_config(config_id: int, config: RecurringEventConfigBase, db: Session = Depends(get_db)):
    """Update an existing recurring config"""
    db_config = db.query(RecurringEventConfig).filter(RecurringEventConfig.id == config_id).first()
    if not db_config:
        raise HTTPException(status_code=404, detail="Recurring config not found")

    for key, value in config.model_dump().items():
        setattr(db_config, key, value)

    db.commit()
    db.refresh(db_config)
    return db_config


@router.delete("/{config_id}")
async def delete_recurring_config(config_id: int, db: Session = Depends(get_db)):
    """Delete a recurring config"""
    db_config = db.query(RecurringEventConfig).filter(RecurringEventConfig.id == config_id).first()
    if not db_config:
        raise HTTPException(status_code=404, detail="Recurring config not found")

    db.delete(db_config)
    db.commit()
    return {"message": "Recurring config deleted successfully", "id": config_id}
