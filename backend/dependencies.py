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


def check_users_not_blocked(user_a_id: int, user_b_id: int, db: Session):
    """
    Validates that neither user has blocked the other.

    Args:
        user_a_id: First user ID
        user_b_id: Second user ID
        db: Database session

    Raises:
        HTTPException 403 if there's a block between the users
    """
    from models import UserBlock

    # Check if A blocked B or B blocked A
    block = db.query(UserBlock).filter(
        ((UserBlock.blocker_user_id == user_a_id) & (UserBlock.blocked_user_id == user_b_id)) |
        ((UserBlock.blocker_user_id == user_b_id) & (UserBlock.blocked_user_id == user_a_id))
    ).first()

    if block:
        raise HTTPException(
            status_code=403,
            detail="Cannot interact with this user due to blocking"
        )
