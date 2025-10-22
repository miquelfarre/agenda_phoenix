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

    def get_multi_with_optional_enrichment(
        self,
        db: Session,
        *,
        public: Optional[bool] = None,
        enriched: bool = False,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "id",
        order_dir: str = "asc"
    ) -> List:
        """
        Get users with optional public filter and optional contact enrichment.

        Args:
            db: Database session
            public: Filter by public status (True=has username, False=no username, None=all)
            enriched: Return enriched data with contact information
            skip: Number of records to skip
            limit: Maximum number of records
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)

        Returns:
            List of User objects or enriched dicts
        """
        query = db.query(User)

        if public is not None:
            if public:
                # Public users have a username
                query = query.filter(User.username.isnot(None))
            else:
                # Private users don't have a username
                query = query.filter(User.username.is_(None))

        # Apply ordering and pagination
        order_col = getattr(User, order_by) if order_by and hasattr(User, order_by) else User.id
        if order_dir and order_dir.lower() == "desc":
            query = query.order_by(order_col.desc())
        else:
            query = query.order_by(order_col.asc())

        query = query.offset(max(0, skip)).limit(max(1, min(200, limit)))

        users = query.all()

        # If enriched, add contact information
        if enriched:
            # Use JOIN to get contact data efficiently
            results = db.query(User, Contact).outerjoin(Contact, User.contact_id == Contact.id)

            if public is not None:
                if public:
                    results = results.filter(User.username.isnot(None))
                else:
                    results = results.filter(User.username.is_(None))

            # Apply ordering and pagination consistently on enriched path
            order_col = getattr(User, order_by) if order_by and hasattr(User, order_by) else User.id
            if order_dir and order_dir.lower() == "desc":
                results = results.order_by(order_col.desc())
            else:
                results = results.order_by(order_col.asc())

            results = results.offset(max(0, skip)).limit(max(1, min(200, limit))).all()

            enriched_users = []
            for user, contact in results:
                contact_name = contact.name if contact else None
                contact_phone = contact.phone if contact else None

                # Build display name
                username = user.username
                if username and contact_name:
                    display_name = f"{username} ({contact_name})"
                elif username:
                    display_name = username
                elif contact_name:
                    display_name = contact_name
                else:
                    display_name = f"Usuario #{user.id}"

                enriched_users.append({
                    "id": user.id,
                    "username": user.username,
                    "auth_provider": user.auth_provider,
                    "auth_id": user.auth_id,
                    "profile_picture_url": user.profile_picture_url,
                    "contact_id": user.contact_id,
                    "contact_name": contact_name,
                    "contact_phone": contact_phone,
                    "display_name": display_name,
                    "last_login": user.last_login,
                    "created_at": user.created_at,
                    "updated_at": user.updated_at,
                })
            return enriched_users

        return users


# Singleton instance
user = CRUDUser(User)
