"""
Common dependencies for FastAPI routes
"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal


def get_db():
    """
    Database session dependency.
    Yields a database session and ensures it's closed after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_user_not_banned(user_id: int, db: Session):
    """
    Validates that a user is not banned from the application.

    Args:
        user_id: The ID of the user to check
        db: Database session

    Raises:
        HTTPException 403 if user is banned
    """
    from models import AppBan

    app_ban = db.query(AppBan).filter(AppBan.user_id == user_id).first()
    if app_ban:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "User is banned from the application",
                "reason": app_ban.reason,
                "banned_at": app_ban.banned_at.isoformat() if app_ban.banned_at else None
            }
        )
