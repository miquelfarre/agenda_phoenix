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
            member_calendar_ids = db.query(CalendarMembership.calendar_id).filter(CalendarMembership.user_id == user_id, CalendarMembership.status == "accepted").subquery()
            conditions.append(Calendar.id.in_(member_calendar_ids))
        if conditions:
            query = query.filter(or_(*conditions))
        return query.offset(skip).limit(limit).all()


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
        Check if a membership exists for calendar-user pair.

        Args:
            db: Database session
            calendar_id: Calendar ID
            user_id: User ID

        Returns:
            True if exists, False otherwise
        """
        return db.query(db.query(CalendarMembership).filter(CalendarMembership.calendar_id == calendar_id, CalendarMembership.user_id == user_id).exists()).scalar()

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


# Singleton instances
calendar = CRUDCalendar(Calendar)
calendar_membership = CRUDCalendarMembership(CalendarMembership)
