"""
CRUD operations for GroupMembership model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Group, GroupMembership, User
from schemas import GroupMembershipCreate


class CRUDGroupMembership(CRUDBase[GroupMembership, GroupMembershipCreate, GroupMembershipCreate]):
    """CRUD operations for GroupMembership"""

    def get_by_group(self, db: Session, *, group_id: int) -> List[GroupMembership]:
        """Get all memberships for a specific group"""
        return self.get_multi(db, filters={"group_id": group_id})

    def get_by_user(self, db: Session, *, user_id: int) -> List[GroupMembership]:
        """Get all group memberships for a specific user"""
        return self.get_multi(db, filters={"user_id": user_id})

    def get_multi_filtered(self, db: Session, *, group_id: Optional[int] = None, user_id: Optional[int] = None, skip: int = 0, limit: int = 50, order_by: str = "id", order_dir: str = "asc") -> List[GroupMembership]:
        """
        Get multiple group memberships with filters and pagination

        Args:
            group_id: Filter by group ID
            user_id: Filter by user ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)
        """
        filters = {}
        if group_id is not None:
            filters["group_id"] = group_id
        if user_id is not None:
            filters["user_id"] = user_id

        return self.get_multi(db, skip=skip, limit=limit, order_by=order_by, order_dir=order_dir, filters=filters)

    def exists_membership(self, db: Session, *, group_id: int, user_id: int) -> bool:
        """Check if membership exists for group-user pair (optimized)"""
        return db.query(GroupMembership.id).filter(GroupMembership.group_id == group_id, GroupMembership.user_id == user_id).first() is not None

    def create_with_validation(self, db: Session, *, obj_in: GroupMembershipCreate) -> tuple[Optional[GroupMembership], Optional[str]]:
        """
        Create a new group membership with validation

        Returns:
            (GroupMembership, None) if successful
            (None, error_message) if validation fails
        """
        # Validate group exists
        group_exists = db.query(Group.id).filter(Group.id == obj_in.group_id).first() is not None
        if not group_exists:
            return None, "Group not found"

        # Validate user exists
        user_exists = db.query(User.id).filter(User.id == obj_in.user_id).first() is not None
        if not user_exists:
            return None, "User not found"

        # Check if membership already exists
        if self.exists_membership(db, group_id=obj_in.group_id, user_id=obj_in.user_id):
            return None, "User is already a member of this group"

        # Create membership
        db_membership = self.create(db, obj_in=obj_in)
        return db_membership, None


# Singleton instance
group_membership = CRUDGroupMembership(GroupMembership)
