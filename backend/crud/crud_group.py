"""
CRUD operations for Group model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Group, User
from schemas import GroupBase, GroupCreate


class CRUDGroup(CRUDBase[Group, GroupCreate, GroupBase]):
    """CRUD operations for Group"""

    def get_by_creator(self, db: Session, *, created_by: int) -> List[Group]:
        """Get all groups created by a specific user"""
        return self.get_multi(db, filters={"created_by": created_by})

    def get_multi_filtered(
        self,
        db: Session,
        *,
        created_by: Optional[int] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "id",
        order_dir: str = "asc"
    ) -> List[Group]:
        """
        Get multiple groups with filters and pagination

        Args:
            created_by: Filter by creator user ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        filters = {}
        if created_by is not None:
            filters["created_by"] = created_by

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
        obj_in: GroupCreate
    ) -> tuple[Optional[Group], Optional[str]]:
        """
        Create a new group with validation

        Returns:
            (Group, None) if successful
            (None, error_message) if validation fails
        """
        # Validate creator exists
        creator_exists = db.query(User.id).filter(User.id == obj_in.created_by).first() is not None
        if not creator_exists:
            return None, "Creator user not found"

        # Create group
        db_group = self.create(db, obj_in=obj_in)
        return db_group, None


# Singleton instance
group = CRUDGroup(Group)
