"""
CRUD operations for UserBlock model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import User, UserBlock
from schemas import UserBlockCreate, UserBlockResponse


class CRUDUserBlock(CRUDBase[UserBlock, UserBlockCreate, UserBlockResponse]):
    """CRUD operations for UserBlock"""

    def get_by_blocker(self, db: Session, *, blocker_user_id: int) -> List[UserBlock]:
        """Get all blocks created by a user"""
        return self.get_multi(db, filters={"blocker_user_id": blocker_user_id})

    def get_by_blocked(self, db: Session, *, blocked_user_id: int) -> List[UserBlock]:
        """Get all blocks where a user is blocked"""
        return self.get_multi(db, filters={"blocked_user_id": blocked_user_id})

    def exists_block(self, db: Session, *, blocker_user_id: int, blocked_user_id: int) -> bool:
        """Check if a block exists between two users (optimized)"""
        return db.query(UserBlock.id).filter(
            UserBlock.blocker_user_id == blocker_user_id,
            UserBlock.blocked_user_id == blocked_user_id
        ).first() is not None

    def get_multi_filtered(
        self,
        db: Session,
        *,
        blocker_user_id: Optional[int] = None,
        blocked_user_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "id",
        order_dir: str = "asc"
    ) -> List[UserBlock]:
        """
        Get multiple blocks with filters and pagination

        Args:
            blocker_user_id: Filter by blocker user ID
            blocked_user_id: Filter by blocked user ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        filters = {}
        if blocker_user_id is not None:
            filters["blocker_user_id"] = blocker_user_id
        if blocked_user_id is not None:
            filters["blocked_user_id"] = blocked_user_id

        return self.get_multi(
            db,
            skip=skip,
            limit=limit,
            order_by=order_by,
            order_dir=order_dir,
            filters=filters
        )

    def create_with_validation(
        self,
        db: Session,
        *,
        obj_in: UserBlockCreate
    ) -> tuple[Optional[UserBlock], Optional[str]]:
        """
        Create a new block with validation

        Returns:
            (UserBlock, None) if successful
            (None, error_message) if validation fails
        """
        # Batch query: verify both users exist in single query
        user_ids = [obj_in.blocker_user_id, obj_in.blocked_user_id]
        existing_users = db.query(User.id).filter(User.id.in_(user_ids)).all()
        existing_ids = {user.id for user in existing_users}

        # Validate blocker user exists
        if obj_in.blocker_user_id not in existing_ids:
            return None, "Blocker user not found"

        # Validate blocked user exists
        if obj_in.blocked_user_id not in existing_ids:
            return None, "Blocked user not found"

        # Check if block already exists (optimized query)
        if self.exists_block(db, blocker_user_id=obj_in.blocker_user_id, blocked_user_id=obj_in.blocked_user_id):
            return None, "User is already blocked"

        # Create block
        db_block = self.create(db, obj_in=obj_in)
        return db_block, None

    def get_blocked_user_ids_bidirectional(self, db: Session, *, user_id: int) -> set:
        """
        Get all user IDs that have mutual blocks with the specified user.

        Includes:
        - Users blocked by this user
        - Users who blocked this user

        Args:
            db: Database session
            user_id: User ID

        Returns:
            Set of blocked user IDs
        """
        blocked_ids = set()

        # Users blocked by this user
        blocks_by_me = db.query(UserBlock.blocked_user_id).filter(
            UserBlock.blocker_user_id == user_id
        ).all()
        blocked_ids.update([bid for (bid,) in blocks_by_me])

        # Users who blocked this user
        blocks_on_me = db.query(UserBlock.blocker_user_id).filter(
            UserBlock.blocked_user_id == user_id
        ).all()
        blocked_ids.update([bid for (bid,) in blocks_on_me])

        return blocked_ids


# Singleton instance
user_block = CRUDUserBlock(UserBlock)
