"""
CRUD operations for AppBan model
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from crud.base import CRUDBase
from models import AppBan, User
from schemas import AppBanCreate, AppBanResponse


class CRUDAppBan(CRUDBase[AppBan, AppBanCreate, AppBanResponse]):
    """CRUD operations for AppBan"""

    def get_by_user_id(self, db: Session, *, user_id: int) -> Optional[AppBan]:
        """Get ban by user_id"""
        return db.query(AppBan).filter(AppBan.user_id == user_id).first()

    def exists_for_user(self, db: Session, *, user_id: int) -> bool:
        """Check if user is banned (optimized - doesn't load full object)"""
        return db.query(AppBan.id).filter(AppBan.user_id == user_id).first() is not None

    def get_multi_by_user(
        self,
        db: Session,
        *,
        user_id: Optional[int] = None,
        banned_by: Optional[int] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "id",
        order_dir: str = "asc",
    ) -> List[AppBan]:
        """
        Get multiple bans with filters and pagination

        Args:
            user_id: Filter by banned user ID
            banned_by: Filter by admin who banned
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        filters = {}
        if user_id is not None:
            filters["user_id"] = user_id
        if banned_by is not None:
            filters["banned_by"] = banned_by

        return self.get_multi(db, skip=skip, limit=limit, order_by=order_by, order_dir=order_dir, filters=filters)

    def create_with_validation(
        self,
        db: Session,
        *,
        obj_in: AppBanCreate,
    ) -> tuple[Optional[AppBan], Optional[str]]:
        """
        Create a new ban with validation

        Returns:
            (AppBan, None) if successful
            (None, error_message) if validation fails
        """
        # Batch query: verify both users exist in single query
        user_ids = [obj_in.user_id, obj_in.banned_by]
        existing_users = db.query(User.id).filter(User.id.in_(user_ids)).all()
        existing_ids = {user.id for user in existing_users}

        # Validate banned user exists
        if obj_in.user_id not in existing_ids:
            return None, "User not found"

        # Validate banner (admin) exists
        if obj_in.banned_by not in existing_ids:
            return None, "Banner user (admin) not found"

        # Check if already banned (optimized query)
        if self.exists_for_user(db, user_id=obj_in.user_id):
            return None, "User is already banned from the application"

        # Create ban
        db_ban = self.create(db, obj_in=obj_in)
        return db_ban, None


# Singleton instance
app_ban = CRUDAppBan(AppBan)
