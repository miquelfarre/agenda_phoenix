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
        if user.instagram_name:
            return user.instagram_name
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
            List of public users (users with is_public=True)
        """
        return db.query(User).filter(User.is_public == True).offset(skip).limit(limit).all()

    def get_multi_with_optional_enrichment(
        self,
        db: Session,
        *,
        public: Optional[bool] = None,
        enriched: bool = False,
        search: Optional[str] = None,
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
            search: Case-insensitive search in username and contact name
            skip: Number of records to skip
            limit: Maximum number of records
            order_by: Column name to order by
            order_dir: Order direction (asc/desc)

        Returns:
            List of User objects or enriched dicts
        """
        from sqlalchemy import or_

        query = db.query(User)

        # Apply search filter if provided
        if search:
            search_term = f"%{search}%"
            # Join with Contact to search in both instagram_name and contact name
            query = query.outerjoin(Contact, User.contact_id == Contact.id)
            query = query.filter(
                or_(
                    User.instagram_name.ilike(search_term),
                    Contact.name.ilike(search_term)
                )
            )

        if public is not None:
            if public:
                # Public users have an instagram_name
                query = query.filter(User.instagram_name.isnot(None))
            else:
                # Private users don't have an instagram_name
                query = query.filter(User.instagram_name.is_(None))

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

            # Apply search filter if provided
            if search:
                search_term = f"%{search}%"
                results = results.filter(
                    or_(
                        User.instagram_name.ilike(search_term),
                        Contact.name.ilike(search_term)
                    )
                )

            if public is not None:
                if public:
                    results = results.filter(User.instagram_name.isnot(None))
                else:
                    results = results.filter(User.instagram_name.is_(None))

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
                instagram_name = user.instagram_name
                if instagram_name and contact_name:
                    display_name = f"{instagram_name} ({contact_name})"
                elif instagram_name:
                    display_name = instagram_name
                elif contact_name:
                    display_name = contact_name
                else:
                    display_name = f"Usuario #{user.id}"

                enriched_users.append({
                    "id": user.id,
                    "instagram_name": user.instagram_name,
                    "auth_provider": user.auth_provider,
                    "auth_id": user.auth_id,
                    "is_public": user.is_public,
                    "is_admin": user.is_admin,
                    "profile_picture": user.profile_picture,
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

    def get_public_user_stats(self, db: Session, *, user_id: int) -> Optional[dict]:
        """
        Get statistics for a public user.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            Dictionary with statistics or None if user doesn't exist or isn't public:
            - user_id: User ID
            - username: Username
            - total_subscribers: Number of subscribers
            - total_events: Total number of events created
            - events_stats: List of event statistics (event_id, event_name, event_start_date, total_joined)
        """
        from models import Event, EventInteraction

        # Get user and verify it's public
        db_user = self.get(db, id=user_id)
        if not db_user or not db_user.is_public:
            return None

        # Count total subscribers (users with "subscribed" interaction to any event from this user)
        from sqlalchemy import func
        total_subscribers = db.query(func.count(func.distinct(EventInteraction.user_id))).join(
            Event, EventInteraction.event_id == Event.id
        ).filter(
            Event.owner_id == user_id,
            EventInteraction.interaction_type == "subscribed"
        ).scalar()

        # Get all events created by this user
        events = db.query(Event).filter(Event.owner_id == user_id).all()
        total_events = len(events)

        # Get stats for each event (number of "joined" users)
        events_stats = []
        for event in events:
            total_joined = db.query(EventInteraction).filter(
                EventInteraction.event_id == event.id,
                EventInteraction.interaction_type == "joined"
            ).count()

            events_stats.append({
                "event_id": event.id,
                "event_name": event.name,
                "event_start_date": event.start_date,
                "total_joined": total_joined
            })

        return {
            "user_id": user_id,
            "instagram_name": db_user.instagram_name,
            "total_subscribers": total_subscribers,
            "total_events": total_events,
            "events_stats": events_stats
        }


# Singleton instance
user = CRUDUser(User)
