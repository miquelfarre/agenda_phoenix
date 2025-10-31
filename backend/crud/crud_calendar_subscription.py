"""
CRUD operations for CalendarSubscription model
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from crud.base import CRUDBase
from models import CalendarSubscription, Calendar, Contact
from schemas import CalendarSubscriptionBase, CalendarSubscriptionCreate


class CRUDCalendarSubscription(CRUDBase[CalendarSubscription, CalendarSubscriptionCreate, CalendarSubscriptionBase]):
    """CRUD operations for CalendarSubscription model with specific methods"""

    def get_by_calendar(
        self,
        db: Session,
        *,
        calendar_id: int,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[CalendarSubscription]:
        """
        Get all subscriptions for a calendar.

        Args:
            db: Database session
            calendar_id: Calendar ID
            status: Optional status filter ('active', 'paused')
            skip: Records to skip
            limit: Max records

        Returns:
            List of subscriptions
        """
        filters = {"calendar_id": calendar_id}
        if status:
            filters["status"] = status
        return self.get_multi(db, skip=skip, limit=limit, filters=filters)

    def get_by_user(
        self,
        db: Session,
        *,
        user_id: int,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[CalendarSubscription]:
        """
        Get all subscriptions for a user.

        Args:
            db: Database session
            user_id: User ID
            status: Optional status filter ('active', 'paused')
            skip: Records to skip
            limit: Max records

        Returns:
            List of subscriptions
        """
        filters = {"user_id": user_id}
        if status:
            filters["status"] = status
        return self.get_multi(db, skip=skip, limit=limit, filters=filters)

    def get_subscription(
        self,
        db: Session,
        *,
        calendar_id: int,
        user_id: int
    ) -> Optional[CalendarSubscription]:
        """
        Get subscription for a specific calendar-user pair.

        Args:
            db: Database session
            calendar_id: Calendar ID
            user_id: User ID

        Returns:
            Subscription or None
        """
        return db.query(CalendarSubscription).filter(
            CalendarSubscription.calendar_id == calendar_id,
            CalendarSubscription.user_id == user_id
        ).first()

    def exists_subscription(
        self,
        db: Session,
        *,
        calendar_id: int,
        user_id: int
    ) -> bool:
        """
        Check if a subscription exists for calendar-user pair (optimized).

        Args:
            db: Database session
            calendar_id: Calendar ID
            user_id: User ID

        Returns:
            True if exists, False otherwise
        """
        return db.query(CalendarSubscription.id).filter(
            CalendarSubscription.calendar_id == calendar_id,
            CalendarSubscription.user_id == user_id
        ).first() is not None

    def get_multi_filtered(
        self,
        db: Session,
        *,
        calendar_id: Optional[int] = None,
        user_id: Optional[int] = None,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "subscribed_at",
        order_dir: str = "desc"
    ) -> List[CalendarSubscription]:
        """
        Get subscriptions with multiple filters and pagination.

        Args:
            calendar_id: Filter by calendar
            user_id: Filter by user
            status: Filter by status ('active', 'paused')
            skip: Records to skip
            limit: Max records
            order_by: Column to order by
            order_dir: Order direction (asc/desc)

        Returns:
            List of subscriptions
        """
        query = db.query(CalendarSubscription)

        # Apply filters
        if calendar_id:
            query = query.filter(CalendarSubscription.calendar_id == calendar_id)
        if user_id:
            query = query.filter(CalendarSubscription.user_id == user_id)
        if status:
            query = query.filter(CalendarSubscription.status == status)

        # Apply ordering
        order_col = getattr(CalendarSubscription, order_by, CalendarSubscription.subscribed_at)
        if order_dir.lower() == "asc":
            query = query.order_by(order_col.asc())
        else:
            query = query.order_by(order_col.desc())

        # Apply pagination
        return query.offset(skip).limit(limit).all()

    def get_enriched(
        self,
        db: Session,
        *,
        calendar_id: Optional[int] = None,
        user_id: Optional[int] = None,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "subscribed_at",
        order_dir: str = "desc"
    ) -> List[tuple[CalendarSubscription, Calendar, Optional[str]]]:
        """
        Get subscriptions with calendar and owner info (enriched) using JOIN.

        Args:
            calendar_id: Filter by calendar
            user_id: Filter by user
            status: Filter by status
            skip: Records to skip
            limit: Max records
            order_by: Column to order by
            order_dir: Order direction

        Returns:
            List of (CalendarSubscription, Calendar, owner_name) tuples
        """
        from models import User  # Import here to avoid circular dependency

        # Build JOIN query to get calendar and owner info
        query = db.query(
            CalendarSubscription,
            Calendar,
            Contact.name.label("owner_name")
        ).join(
            Calendar, CalendarSubscription.calendar_id == Calendar.id
        ).join(
            User, Calendar.owner_id == User.id
        ).outerjoin(
            Contact, User.contact_id == Contact.id
        )

        # Apply filters
        if calendar_id:
            query = query.filter(CalendarSubscription.calendar_id == calendar_id)
        if user_id:
            query = query.filter(CalendarSubscription.user_id == user_id)
        if status:
            query = query.filter(CalendarSubscription.status == status)

        # Apply ordering
        order_col = getattr(CalendarSubscription, order_by, CalendarSubscription.subscribed_at)
        if order_dir.lower() == "asc":
            query = query.order_by(order_col.asc())
        else:
            query = query.order_by(order_col.desc())

        # Apply pagination
        return query.offset(skip).limit(limit).all()

    def create_with_validation(
        self,
        db: Session,
        *,
        obj_in: CalendarSubscriptionCreate
    ) -> tuple[Optional[CalendarSubscription], Optional[str]]:
        """
        Create subscription with validation.

        Validates:
        - Calendar exists and is public
        - User exists
        - No duplicate subscription

        Returns:
            (CalendarSubscription, None) if successful
            (None, error_message) if validation fails
        """
        from models import User  # Import here to avoid circular dependency

        # Check if calendar exists and is public (optimized single query)
        calendar = db.query(Calendar.id, Calendar.is_public).filter(
            Calendar.id == obj_in.calendar_id
        ).first()

        if not calendar:
            return None, "Calendar not found"

        if not calendar.is_public:
            return None, "Cannot subscribe to private calendars"

        # Check if user exists (optimized)
        user_exists = db.query(User.id).filter(User.id == obj_in.user_id).first() is not None
        if not user_exists:
            return None, "User not found"

        # Check if subscription already exists
        if self.exists_subscription(db, calendar_id=obj_in.calendar_id, user_id=obj_in.user_id):
            return None, "User is already subscribed to this calendar"

        # Create subscription
        db_subscription = self.create(db, obj_in=obj_in)
        return db_subscription, None

    def get_calendar_ids_by_user(
        self,
        db: Session,
        *,
        user_id: int,
        status: Optional[str] = "active"
    ) -> List[int]:
        """
        Get list of calendar IDs that a user is subscribed to.

        Args:
            db: Database session
            user_id: User ID
            status: Optional status filter ('active', 'paused'). Defaults to 'active'.

        Returns:
            List of calendar IDs
        """
        query = db.query(CalendarSubscription.calendar_id).filter(
            CalendarSubscription.user_id == user_id
        )

        if status:
            query = query.filter(CalendarSubscription.status == status)

        results = query.all()
        return [cid for (cid,) in results]

    def get_public_calendars(
        self,
        db: Session,
        *,
        category: Optional[str] = None,
        search: Optional[str] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Calendar]:
        """
        Get public calendars that are discoverable.

        Args:
            db: Database session
            category: Optional category filter
            search: Optional search term (matches name or description)
            skip: Records to skip
            limit: Max records

        Returns:
            List of public calendars
        """
        query = db.query(Calendar).filter(
            Calendar.is_public == True,
            Calendar.is_discoverable == True
        )

        if category:
            query = query.filter(Calendar.category == category)

        if search:
            search_pattern = f"%{search}%"
            query = query.filter(
                (Calendar.name.ilike(search_pattern)) |
                (Calendar.description.ilike(search_pattern))
            )

        return query.offset(skip).limit(limit).all()


# Singleton instance
calendar_subscription = CRUDCalendarSubscription(CalendarSubscription)
