"""
CRUD operations for Calendar and CalendarMembership models
"""

from typing import List, Optional
from sqlalchemy import or_
from sqlalchemy.orm import Session
from crud.base import CRUDBase
from models import Calendar, CalendarMembership
from schemas import CalendarBase, CalendarCreate, CalendarMembershipBase, CalendarMembershipCreate


class CRUDCalendar(CRUDBase[Calendar, CalendarCreate, CalendarBase]):
    """CRUD operations for Calendar model with specific methods"""

    def get_by_owner(self, db: Session, *, owner_id: int, skip: int = 0, limit: int = 100) -> List[Calendar]:
        """
        Get calendars owned by a specific user.

        Args:
            db: Database session
            owner_id: User ID of the owner
            skip: Number of records to skip
            limit: Maximum number of records

        Returns:
            List of calendars
        """
        return self.get_multi(db, skip=skip, limit=limit, filters={"owner_id": owner_id})

    def get_multi_filtered(
        self,
        db: Session,
        *,
        owner_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "id",
        order_dir: str = "asc"
    ) -> List[Calendar]:
        """
        Get calendars with filters and pagination.

        Args:
            owner_id: Filter by owner user ID
            skip: Records to skip
            limit: Max records
            order_by: Column to order by
            order_dir: Order direction (asc/desc)

        Returns:
            List of calendars
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

    def get_user_calendars(self, db: Session, user_id: int, *, include_owned: bool = True, include_member: bool = True, skip: int = 0, limit: int = 100) -> List[Calendar]:
        """
        Get all calendars accessible to a user (owned + member).

        Args:
            db: Database session
            user_id: User ID
            include_owned: Include calendars owned by user
            include_member: Include calendars where user is member
            skip: Number of records to skip
            limit: Maximum number of records

        Returns:
            List of calendars
        """
        query = db.query(Calendar)
        conditions = []
        if include_owned:
            conditions.append(Calendar.owner_id == user_id)
        if include_member:
            # Calendars where user has membership
            member_calendar_ids = db.query(CalendarMembership.calendar_id).filter(CalendarMembership.user_id == user_id, CalendarMembership.status == "accepted").scalar_subquery()
            conditions.append(Calendar.id.in_(member_calendar_ids))
        if conditions:
            query = query.filter(or_(*conditions))
        return query.offset(skip).limit(limit).all()

    def create_with_validation(
        self,
        db: Session,
        *,
        obj_in: CalendarCreate
    ) -> tuple[Optional[Calendar], Optional[str]]:
        """
        Create calendar with validation.

        Returns:
            (Calendar, None) if successful
            (None, error_message) if validation fails
        """
        from models import User  # Import here to avoid circular dependency

        # Optimized: only check if user exists (don't load full object)
        user_exists = db.query(User.id).filter(User.id == obj_in.owner_id).first() is not None
        if not user_exists:
            return None, "User not found"

        # Create calendar
        db_calendar = self.create(db, obj_in=obj_in)
        return db_calendar, None

    def get_members(
        self,
        db: Session,
        *,
        calendar_id: int,
        skip: int = 0,
        limit: int = 100
    ) -> Optional[List[CalendarMembership]]:
        """
        Get all members of a calendar.

        Args:
            db: Database session
            calendar_id: Calendar ID
            skip: Records to skip
            limit: Max records

        Returns:
            List of memberships or None if calendar not found
        """
        # Check if calendar exists (optimized)
        calendar_exists = db.query(Calendar.id).filter(Calendar.id == calendar_id).first() is not None
        if not calendar_exists:
            return None

        return db.query(CalendarMembership).filter(
            CalendarMembership.calendar_id == calendar_id
        ).offset(skip).limit(limit).all()


class CRUDCalendarMembership(CRUDBase[CalendarMembership, CalendarMembershipCreate, CalendarMembershipBase]):
    """CRUD operations for CalendarMembership model with specific methods"""

    def get_by_calendar(self, db: Session, *, calendar_id: int, status: Optional[str] = None) -> List[CalendarMembership]:
        """
        Get all memberships for a calendar.

        Args:
            db: Database session
            calendar_id: Calendar ID
            status: Optional status filter ('pending', 'accepted', 'rejected')

        Returns:
            List of memberships
        """
        filters = {"calendar_id": calendar_id}
        if status:
            filters["status"] = status
        return self.get_multi(db, filters=filters)

    def get_by_user(self, db: Session, *, user_id: int, status: Optional[str] = None) -> List[CalendarMembership]:
        """
        Get all memberships for a user.

        Args:
            db: Database session
            user_id: User ID
            status: Optional status filter

        Returns:
            List of memberships
        """
        filters = {"user_id": user_id}
        if status:
            filters["status"] = status
        return self.get_multi(db, filters=filters)

    def get_membership(self, db: Session, *, calendar_id: int, user_id: int) -> Optional[CalendarMembership]:
        """
        Get membership for a specific calendar-user pair.

        Args:
            db: Database session
            calendar_id: Calendar ID
            user_id: User ID

        Returns:
            Membership or None
        """
        return db.query(CalendarMembership).filter(CalendarMembership.calendar_id == calendar_id, CalendarMembership.user_id == user_id).first()

    def exists_membership(self, db: Session, *, calendar_id: int, user_id: int) -> bool:
        """
        Check if a membership exists for calendar-user pair (optimized).

        Args:
            db: Database session
            calendar_id: Calendar ID
            user_id: User ID

        Returns:
            True if exists, False otherwise
        """
        return db.query(CalendarMembership.id).filter(
            CalendarMembership.calendar_id == calendar_id,
            CalendarMembership.user_id == user_id
        ).first() is not None

    def get_multi_filtered(
        self,
        db: Session,
        *,
        calendar_id: Optional[int] = None,
        user_id: Optional[int] = None,
        status: Optional[str] = None,
        exclude_owned: bool = False,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "created_at",
        order_dir: str = "desc"
    ) -> List[CalendarMembership]:
        """
        Get memberships with multiple filters and pagination.

        Args:
            calendar_id: Filter by calendar
            user_id: Filter by user
            status: Filter by status
            exclude_owned: If True and user_id provided, exclude calendars owned by user
            skip: Records to skip
            limit: Max records
            order_by: Column to order by
            order_dir: Order direction (asc/desc)

        Returns:
            List of memberships
        """
        # Build base query
        if exclude_owned and user_id:
            # Need JOIN to filter out owned calendars
            query = db.query(CalendarMembership).join(
                Calendar, CalendarMembership.calendar_id == Calendar.id
            )
        else:
            query = db.query(CalendarMembership)

        # Apply filters
        if calendar_id:
            query = query.filter(CalendarMembership.calendar_id == calendar_id)
        if user_id:
            query = query.filter(CalendarMembership.user_id == user_id)
        if status:
            query = query.filter(CalendarMembership.status == status)
        if exclude_owned and user_id:
            query = query.filter(Calendar.owner_id != user_id)

        # Apply ordering
        order_col = getattr(CalendarMembership, order_by, CalendarMembership.created_at)
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
        exclude_owned: bool = False,
        skip: int = 0,
        limit: int = 50,
        order_by: str = "created_at",
        order_dir: str = "desc"
    ) -> List[tuple[CalendarMembership, Calendar]]:
        """
        Get memberships with calendar info (enriched) using JOIN.

        Args:
            calendar_id: Filter by calendar
            user_id: Filter by user
            status: Filter by status
            exclude_owned: If True and user_id provided, exclude owned calendars
            skip: Records to skip
            limit: Max records
            order_by: Column to order by
            order_dir: Order direction

        Returns:
            List of (CalendarMembership, Calendar) tuples
        """
        # Build JOIN query
        query = db.query(CalendarMembership, Calendar).join(
            Calendar, CalendarMembership.calendar_id == Calendar.id
        )

        # Apply filters
        if calendar_id:
            query = query.filter(CalendarMembership.calendar_id == calendar_id)
        if user_id:
            query = query.filter(CalendarMembership.user_id == user_id)
        if status:
            query = query.filter(CalendarMembership.status == status)
        if exclude_owned and user_id:
            query = query.filter(Calendar.owner_id != user_id)

        # Apply ordering
        order_col = getattr(CalendarMembership, order_by, CalendarMembership.created_at)
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
        obj_in: CalendarMembershipCreate
    ) -> tuple[Optional[CalendarMembership], Optional[str]]:
        """
        Create membership with validation (optimized).

        Returns:
            (CalendarMembership, None) if successful
            (None, error_message) if validation fails
        """
        from models import User  # Import here to avoid circular dependency

        # Batch query: verify both calendar and user exist in single query
        calendar_ids = [obj_in.calendar_id]
        user_ids = [obj_in.user_id]

        existing_calendars = db.query(Calendar.id).filter(Calendar.id.in_(calendar_ids)).all()
        existing_users = db.query(User.id).filter(User.id.in_(user_ids)).all()

        calendar_ids_found = {c.id for c in existing_calendars}
        user_ids_found = {u.id for u in existing_users}

        # Validate calendar exists
        if obj_in.calendar_id not in calendar_ids_found:
            return None, "Calendar not found"

        # Validate user exists
        if obj_in.user_id not in user_ids_found:
            return None, "User not found"

        # Check if membership already exists (optimized)
        if self.exists_membership(db, calendar_id=obj_in.calendar_id, user_id=obj_in.user_id):
            return None, "User already has a membership in this calendar"

        # Create membership
        db_membership = self.create(db, obj_in=obj_in)
        return db_membership, None

    def get_with_calendar_info(self, db: Session, *, user_id: int, skip: int = 0, limit: int = 100) -> List[tuple[CalendarMembership, Calendar]]:
        """
        Get user's memberships with calendar information (enriched).

        Single JOIN query instead of N+1.

        Args:
            db: Database session
            user_id: User ID
            skip: Number of records to skip
            limit: Maximum number of records

        Returns:
            List of (CalendarMembership, Calendar) tuples
        """
        return db.query(CalendarMembership, Calendar).join(Calendar, CalendarMembership.calendar_id == Calendar.id).filter(CalendarMembership.user_id == user_id).offset(skip).limit(limit).all()

    def get_calendar_ids_by_user(
        self,
        db: Session,
        *,
        user_id: int,
        status: Optional[str] = None,
        roles: Optional[List[str]] = None
    ) -> List[int]:
        """
        Get list of calendar IDs for a user, filtered by status and roles.

        Args:
            db: Database session
            user_id: User ID
            status: Optional status filter ('accepted', 'pending', 'rejected')
            roles: Optional list of roles to filter by (['owner', 'admin'])

        Returns:
            List of calendar IDs
        """
        query = db.query(CalendarMembership.calendar_id).filter(
            CalendarMembership.user_id == user_id
        )

        if status:
            query = query.filter(CalendarMembership.status == status)

        if roles:
            query = query.filter(CalendarMembership.role.in_(roles))

        results = query.all()
        return [cid for (cid,) in results]


# Singleton instances
calendar = CRUDCalendar(Calendar)
calendar_membership = CRUDCalendarMembership(CalendarMembership)
