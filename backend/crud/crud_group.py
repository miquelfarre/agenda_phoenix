"""
CRUD operations for Group model
"""

from typing import List, Optional

from sqlalchemy.orm import Session, joinedload

from crud.base import CRUDBase
from models import Group, User, GroupMembership
from schemas import GroupBase, GroupCreate


class CRUDGroup(CRUDBase[Group, GroupCreate, GroupBase]):
    """CRUD operations for Group"""

    def get_with_relations(self, db: Session, *, id: int) -> Optional[Group]:
        """Get a group with all its relations loaded (owner, members, admins)"""
        return (
            db.query(Group)
            .options(joinedload(Group.owner))
            .filter(Group.id == id)
            .first()
        )

    def get_multi_with_relations(self, db: Session, *, skip: int = 0, limit: int = 100) -> List[Group]:
        """Get multiple groups with all their relations loaded"""
        return (
            db.query(Group)
            .options(joinedload(Group.owner))
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_by_owner(self, db: Session, *, owner_id: int) -> List[Group]:
        """Get all groups owned by a specific user"""
        return self.get_multi(db, filters={"owner_id": owner_id})

    def get_multi_filtered(
        self,
        db: Session,
        *,
        owner_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "id",
        order_dir: str = "asc"
    ) -> List[Group]:
        """
        Get multiple groups with filters and pagination

        Args:
            owner_id: Filter by owner user ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        filters = {}
        if owner_id is not None:
            filters["owner_id"] = owner_id

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
        # Validate owner exists
        owner_exists = db.query(User.id).filter(User.id == obj_in.owner_id).first() is not None
        if not owner_exists:
            return None, "Owner user not found"

        # Create group
        db_group = self.create(db, obj_in=obj_in)
        return db_group, None


# Singleton instance
group = CRUDGroup(Group)
