"""
CRUD operations for User model
"""

from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Contact, User
from schemas import UserBase, UserCreate


class CRUDUser(CRUDBase[User, UserCreate, UserBase]):
    """CRUD operations for User model with specific methods"""

    def get_by_auth(self, db: Session, *, auth_provider: str, auth_id: str) -> Optional[User]:
        """
        Get user by authentication credentials.

        Args:
            db: Database session
            auth_provider: Authentication provider (e.g., 'phone', 'google')
            auth_id: Provider-specific user ID

        Returns:
            User instance or None
        """
        return db.query(User).filter(User.auth_provider == auth_provider, User.auth_id == auth_id).first()

    def get_with_contact(self, db: Session, user_id: int) -> Optional[tuple[User, Optional[Contact]]]:
        """
        Get user with their contact information in a single query.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            Tuple of (User, Contact) or None if user not found
        """
        result = db.query(User, Contact).outerjoin(Contact, User.contact_id == Contact.id).filter(User.id == user_id).first()

        return result

    def get_multi_with_contacts(self, db: Session, *, skip: int = 0, limit: int = 100, user_ids: Optional[List[int]] = None) -> List[tuple[User, Optional[Contact]]]:
        """
        Get multiple users with their contact information (batch query).

        More efficient than multiple get_with_contact() calls.

        Args:
            db: Database session
            skip: Number of records to skip
            limit: Maximum number of records
            user_ids: Optional list of specific user IDs to fetch

        Returns:
            List of (User, Contact) tuples
        """
        query = db.query(User, Contact).outerjoin(Contact, User.contact_id == Contact.id)

        if user_ids:
            query = query.filter(User.id.in_(user_ids))

        return query.offset(skip).limit(limit).all()

    def get_display_name(self, db: Session, user_id: int) -> str:
        """
        Get user's display name (username or contact name or fallback).

        Args:
            db: Database session
            user_id: User ID

        Returns:
            Display name string
        """
        result = self.get_with_contact(db, user_id)
        if not result:
            return f"Usuario #{user_id}"

        user, contact = result

        # Priority: username > contact_name > fallback
        if user.username:
            return user.username
        if contact and contact.name:
            return contact.name

        return f"Usuario #{user_id}"

    def get_public_users(self, db: Session, *, skip: int = 0, limit: int = 100) -> List[User]:
        """
        Get users with public profiles.

        Args:
            db: Database session
            skip: Number of records to skip
            limit: Maximum number of records

        Returns:
            List of public users
        """
        # TODO: Add 'is_public' field to User model
        # For now, return all users
        return self.get_multi(db, skip=skip, limit=limit)


# Singleton instance
user = CRUDUser(User)
