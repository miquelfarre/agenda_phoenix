from datetime import datetime, timedelta, timezone

from sqlalchemy import JSON, TIMESTAMP, Boolean, Column, ForeignKey, Index, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.orm import relationship

from database import Base


class Contact(Base):
    """
    Contact model - Phone contacts from user's device.
    Each user has their own contact list.
    """

    __tablename__ = "contacts"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    owner_id = Column(Integer, ForeignKey("users.id", use_alter=True, name="fk_contact_owner"), nullable=True, index=True)  # Owner of this contact (NULL for contacts that represent registered users)
    name = Column(String(255), nullable=False)
    phone = Column(String(50), unique=True, nullable=False, index=True)  # Keep phone unique globally
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    owner = relationship("User", foreign_keys=[owner_id], back_populates="owned_contacts")
    user = relationship("User", foreign_keys="User.contact_id", back_populates="contact", uselist=False)

    def __repr__(self):
        return f"<Contact(id={self.id}, name='{self.name}', phone='{self.phone}')>"

    def to_dict(self):
        return {
            "id": self.id,
            "owner_id": self.owner_id,
            "name": self.name,
            "phone": self.phone,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class User(Base):
    """
    User model - Users who have logged in.
    Two types: private (phone auth) and public (instagram auth).
    """

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    contact_id = Column(Integer, ForeignKey("contacts.id"), nullable=True, unique=True, index=True)
    name = Column(String(200), nullable=True)  # Display name for both types
    instagram_name = Column(String(100), nullable=True, index=True)  # For Instagram users (public)
    phone = Column(String(20), nullable=True, index=True)  # For phone users (private)
    auth_provider = Column(String(20), nullable=False)  # 'phone' or 'instagram'
    auth_id = Column(String(255), nullable=False, unique=True, index=True)  # Phone number or Instagram user ID
    is_public = Column(Boolean, nullable=False, default=False, index=True)  # True for instagram users, False for phone users
    is_admin = Column(Boolean, nullable=False, default=False, index=True)  # True for super admins
    profile_picture = Column(String(500), nullable=True)
    last_login = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    contact = relationship("Contact", foreign_keys=[contact_id], back_populates="user")
    owned_contacts = relationship("Contact", foreign_keys="Contact.owner_id", back_populates="owner", cascade="all, delete-orphan")
    calendars = relationship("Calendar", back_populates="user", cascade="all, delete-orphan")
    calendar_memberships = relationship("CalendarMembership", foreign_keys="CalendarMembership.user_id", back_populates="user", cascade="all, delete-orphan")
    owned_groups = relationship("Group", back_populates="owner", cascade="all, delete-orphan")
    group_memberships = relationship("GroupMembership", back_populates="user", cascade="all, delete-orphan")
    events = relationship("Event", foreign_keys="Event.owner_id", back_populates="owner", cascade="all, delete-orphan")
    interactions = relationship("EventInteraction", foreign_keys="EventInteraction.user_id", back_populates="user", cascade="all, delete-orphan")
    blocked_users = relationship("UserBlock", foreign_keys="UserBlock.blocker_user_id", back_populates="blocker", cascade="all, delete-orphan")
    blocked_by_users = relationship("UserBlock", foreign_keys="UserBlock.blocked_user_id", back_populates="blocked", cascade="all, delete-orphan")
    subscription_stats = relationship("UserSubscriptionStats", back_populates="user", uselist=False, cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, auth_provider='{self.auth_provider}', instagram_name='{self.instagram_name}')>"

    def to_dict(self):
        return {
            "id": self.id,
            "contact_id": self.contact_id,
            "name": self.name,
            "instagram_name": self.instagram_name,
            "phone": self.phone,
            "auth_provider": self.auth_provider,
            "auth_id": self.auth_id,
            "is_public": self.is_public,
            "is_admin": self.is_admin,
            "profile_picture": self.profile_picture,
            "last_login": self.last_login.isoformat() if self.last_login else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Calendar(Base):
    """
    Calendar model - Users can have multiple calendars to organize events.

    Calendars can be:
    - Permanent (no start_date/end_date): e.g., "Personal", "Work"
    - Temporal (with start_date/end_date): e.g., "Summer Course 2025", "Project Q1 2025"
    - Private (shared via CalendarMembership): e.g., "Family Birthdays"
    - Public (discoverable via search): e.g., "Festivos Barcelona", "FC Barcelona Matches"
    """

    __tablename__ = "calendars"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)  # Owner principal del calendar
    name = Column(String(255), nullable=False)
    start_date = Column(TIMESTAMP(timezone=True), nullable=True)  # Optional: for temporal calendars
    end_date = Column(TIMESTAMP(timezone=True), nullable=True)  # Optional: for temporal calendars

    # Public calendar fields
    is_public = Column(Boolean, default=False, nullable=False, index=True)  # If True, calendar is discoverable
    is_discoverable = Column(Boolean, default=True, nullable=False)  # If False, public but not in search results
    description = Column(Text, nullable=True)  # Description for search/discovery
    category = Column(String(100), nullable=True, index=True)  # "holidays", "sports", "cultural", etc.
    share_hash = Column(String(8), unique=True, nullable=True, index=True)  # Unique 8-char hash for sharing public calendars
    subscriber_count = Column(Integer, default=0, nullable=False)  # Cached count of subscriptions

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="calendars")
    events = relationship("Event", foreign_keys="Event.calendar_id", back_populates="calendar")
    memberships = relationship("CalendarMembership", back_populates="calendar", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Calendar(id={self.id}, name='{self.name}', owner_id={self.owner_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "owner_id": self.owner_id,
            "name": self.name,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "is_public": self.is_public,
            "is_discoverable": self.is_discoverable,
            "share_hash": self.share_hash,
            "description": self.description,
            "category": self.category,
            "subscriber_count": self.subscriber_count,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class CalendarMembership(Base):
    """
    CalendarMembership model - Membresías de usuarios en calendarios.
    Permite tener owners, admins y members de un calendar.
    """

    __tablename__ = "calendar_memberships"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    calendar_id = Column(Integer, ForeignKey("calendars.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    role = Column(String(50), nullable=False, default="member")  # 'owner', 'admin', 'member'
    status = Column(String(50), nullable=False, default="pending")  # 'pending', 'accepted', 'rejected'
    invited_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: un usuario solo puede tener una membresía por calendar
    __table_args__ = (UniqueConstraint("calendar_id", "user_id", name="uq_calendar_user_membership"),)

    # Relationships
    calendar = relationship("Calendar", back_populates="memberships")
    user = relationship("User", foreign_keys=[user_id], back_populates="calendar_memberships")
    invited_by = relationship("User", foreign_keys=[invited_by_user_id])

    def __repr__(self):
        return f"<CalendarMembership(id={self.id}, calendar_id={self.calendar_id}, user_id={self.user_id}, role='{self.role}')>"

    def to_dict(self):
        return {
            "id": self.id,
            "calendar_id": self.calendar_id,
            "user_id": self.user_id,
            "role": self.role,
            "status": self.status,
            "invited_by_user_id": self.invited_by_user_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class CalendarSubscription(Base):
    """
    CalendarSubscription model - Suscripciones a calendarios públicos.

    A diferencia de CalendarMembership (calendarios privados compartidos via invitación),
    CalendarSubscription permite a cualquier usuario suscribirse a calendarios públicos
    sin necesidad de invitación o aprobación del owner.

    Ejemplos:
    - "Festivos Barcelona 2025-2026" (owner: RandomUser, suscriptores: miles de usuarios)
    - "FC Barcelona - Primera División" (owner: FCBarcelona, suscriptores: fans)
    """

    __tablename__ = "calendar_subscriptions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    calendar_id = Column(Integer, ForeignKey("calendars.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    status = Column(String(50), nullable=False, default="active")  # 'active', 'paused'
    subscribed_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: un usuario solo puede tener una suscripción por calendar
    __table_args__ = (
        UniqueConstraint("calendar_id", "user_id", name="uq_calendar_user_subscription"),
        Index("idx_calendar_subscriptions_calendar", "calendar_id"),
        Index("idx_calendar_subscriptions_user", "user_id"),
        Index("idx_calendar_subscriptions_status", "status"),
    )

    # Relationships
    calendar = relationship("Calendar")
    user = relationship("User")

    def __repr__(self):
        return f"<CalendarSubscription(id={self.id}, calendar_id={self.calendar_id}, user_id={self.user_id}, status='{self.status}')>"

    def to_dict(self):
        return {
            "id": self.id,
            "calendar_id": self.calendar_id,
            "user_id": self.user_id,
            "status": self.status,
            "subscribed_at": self.subscribed_at.isoformat() if self.subscribed_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Group(Base):
    """
    Group model - Users can be organized into groups for mass invitations.
    """

    __tablename__ = "groups"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    owner = relationship("User", back_populates="owned_groups")
    memberships = relationship("GroupMembership", back_populates="group", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Group(id={self.id}, name='{self.name}', owner_id={self.owner_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "owner_id": self.owner_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class GroupMembership(Base):
    """
    GroupMembership model - Junction table for users and groups.
    """

    __tablename__ = "group_memberships"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    group_id = Column(Integer, ForeignKey("groups.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    role = Column(String, nullable=True)  # "admin" or "member" (null = member)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: one user per group
    __table_args__ = (UniqueConstraint("group_id", "user_id", name="uq_group_user"),)

    # Relationships
    group = relationship("Group", back_populates="memberships")
    user = relationship("User", back_populates="group_memberships")

    def __repr__(self):
        return f"<GroupMembership(id={self.id}, group_id={self.group_id}, user_id={self.user_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "group_id": self.group_id,
            "user_id": self.user_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Event(Base):
    """
    Event model for storing calendar events.
    """

    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    start_date = Column(TIMESTAMP(timezone=True), nullable=False)
    event_type = Column(String(50), nullable=False, default="regular")  # 'regular' or 'recurring'
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    calendar_id = Column(Integer, ForeignKey("calendars.id"), nullable=True, index=True)
    parent_recurring_event_id = Column(Integer, ForeignKey("recurring_event_configs.id", use_alter=True, name="fk_event_parent_recurring"), nullable=True, index=True)  # Evento recurrente padre
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    owner = relationship("User", foreign_keys=[owner_id], back_populates="events")
    calendar = relationship("Calendar", foreign_keys=[calendar_id], back_populates="events")
    parent_recurring_event = relationship("RecurringEventConfig", foreign_keys=[parent_recurring_event_id])
    interactions = relationship("EventInteraction", back_populates="event", cascade="all, delete-orphan")
    recurring_config = relationship("RecurringEventConfig", foreign_keys="RecurringEventConfig.event_id", back_populates="event", uselist=False, cascade="all, delete-orphan")
    bans = relationship("EventBan", back_populates="event", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Event(id={self.id}, name='{self.name}', owner_id={self.owner_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "event_type": self.event_type,
            "owner_id": self.owner_id,
            "calendar_id": self.calendar_id,
            "parent_recurring_event_id": self.parent_recurring_event_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class EventInteraction(Base):
    """
    EventInteraction model - Tracks user interactions with events.
    """

    __tablename__ = "event_interactions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    interaction_type = Column(String(50), nullable=False)  # 'invited', 'requested', 'joined', 'subscribed'
    status = Column(String(50), nullable=True)  # 'pending', 'accepted', 'rejected', 'rejected_invitation_accepted_event'
    role = Column(String(50), nullable=True)  # 'owner', 'admin', null (member)
    invited_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    invited_via_group_id = Column(Integer, ForeignKey("groups.id"), nullable=True, index=True)
    personal_note = Column(Text, nullable=True)  # Personal reminder note ("bring skates to skating class")
    cancellation_note = Column(Text, nullable=True)  # Cancellation/rejection note ("canceling the event because it's too late")
    is_attending = Column(Boolean, default=False, nullable=True)  # Whether user is attending despite rejecting invitation (for public events)
    read_at = Column(TIMESTAMP(timezone=True), nullable=True)  # Timestamp when interaction was marked as read
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: one active interaction per user per event
    __table_args__ = (UniqueConstraint("event_id", "user_id", name="uq_event_user_interaction"),)

    # Relationships
    event = relationship("Event", back_populates="interactions")
    user = relationship("User", foreign_keys=[user_id], back_populates="interactions")
    invited_by = relationship("User", foreign_keys=[invited_by_user_id])
    invited_via_group = relationship("Group")

    @property
    def is_new(self) -> bool:
        """
        Determine if this interaction is "new" (unread and created within last 24 hours).

        Returns True if:
        - read_at is NULL (not yet read) AND
        - created_at is within the last 24 hours AND
        - user is NOT the owner of the event (own events should never be "new")
        """
        if self.read_at is not None:
            # Already read
            return False

        if self.created_at is None:
            return False

        # If the user is the event owner, it's never "new" (own events don't count as new)
        if self.event and self.event.owner_id == self.user_id:
            return False

        # Check if created within last 24 hours
        # Handle both timezone-aware and naive datetimes
        if self.created_at.tzinfo is None:
            # Naive datetime - assume UTC
            now = datetime.now()
            created_at = self.created_at
        else:
            # Aware datetime
            now = datetime.now(timezone.utc)
            created_at = self.created_at

        time_diff = now - created_at
        return time_diff < timedelta(hours=24)

    def __repr__(self):
        return f"<EventInteraction(id={self.id}, event_id={self.event_id}, user_id={self.user_id}, type='{self.interaction_type}')>"

    def to_dict(self):
        return {
            "id": self.id,
            "event_id": self.event_id,
            "user_id": self.user_id,
            "interaction_type": self.interaction_type,
            "status": self.status,
            "role": self.role,
            "invited_by_user_id": self.invited_by_user_id,
            "invited_via_group_id": self.invited_via_group_id,
            "personal_note": self.personal_note,
            "cancellation_note": self.cancellation_note,
            "read_at": self.read_at.isoformat() if self.read_at else None,
            "is_new": self.is_new,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class RecurringEventConfig(Base):
    """
    RecurringEventConfig model - Configuration for recurring events.

    Supports multiple recurrence types:
    - 'daily': Repeats every day or every X days
    - 'weekly': Repeats on specific days of the week (e.g., Mon, Wed, Fri)
    - 'monthly': Repeats on specific days of the month (e.g., 1st, 15th, last day)
    - 'yearly': Repeats on a specific date each year (e.g., birthdays, holidays)

    Perpetual events:
    - If recurrence_end_date is NULL, the event repeats indefinitely
    - Common for birthdays, annual holidays, etc.
    """

    __tablename__ = "recurring_event_configs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False, unique=True, index=True)
    recurrence_type = Column(String(20), nullable=False, default="weekly")  # 'daily', 'weekly', 'monthly', 'yearly'
    schedule = Column(JSON, nullable=True)  # Type-specific configuration (format varies by recurrence_type)
    recurrence_end_date = Column(TIMESTAMP(timezone=True), nullable=True)  # NULL = perpetual/infinite recurrence
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    event = relationship("Event", foreign_keys=[event_id], back_populates="recurring_config")

    def __repr__(self):
        return f"<RecurringEventConfig(id={self.id}, event_id={self.event_id}, type={self.recurrence_type})>"

    def to_dict(self):
        return {
            "id": self.id,
            "event_id": self.event_id,
            "recurrence_type": self.recurrence_type,
            "schedule": self.schedule,
            "recurrence_end_date": self.recurrence_end_date.isoformat() if self.recurrence_end_date else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class EventBan(Base):
    """
    EventBan model - Track users banned from specific events.
    """

    __tablename__ = "event_bans"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    banned_by = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    reason = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: one ban per user per event
    __table_args__ = (UniqueConstraint("event_id", "user_id", name="uq_event_user_ban"),)

    # Relationships
    event = relationship("Event", back_populates="bans")
    banned_user = relationship("User", foreign_keys=[user_id])
    banner = relationship("User", foreign_keys=[banned_by])

    def __repr__(self):
        return f"<EventBan(id={self.id}, event_id={self.event_id}, user_id={self.user_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "event_id": self.event_id,
            "user_id": self.user_id,
            "banned_by": self.banned_by,
            "reason": self.reason,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class UserBlock(Base):
    """
    UserBlock model - Track users blocking other users.
    """

    __tablename__ = "user_blocks"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    blocker_user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    blocked_user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: one block per user pair
    __table_args__ = (UniqueConstraint("blocker_user_id", "blocked_user_id", name="uq_blocker_blocked"),)

    # Relationships
    blocker = relationship("User", foreign_keys=[blocker_user_id], back_populates="blocked_users")
    blocked = relationship("User", foreign_keys=[blocked_user_id], back_populates="blocked_by_users")

    def __repr__(self):
        return f"<UserBlock(id={self.id}, blocker={self.blocker_user_id}, blocked={self.blocked_user_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "blocker_user_id": self.blocker_user_id,
            "blocked_user_id": self.blocked_user_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class AppBan(Base):
    """
    AppBan model - Admin bans for entire application access.
    When a user is banned here, they cannot use the application at all.
    """

    __tablename__ = "app_bans"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    banned_by = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    reason = Column(Text, nullable=True)
    banned_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user = relationship("User", foreign_keys=[user_id], backref="app_ban")
    banner = relationship("User", foreign_keys=[banned_by])

    def __repr__(self):
        return f"<AppBan(id={self.id}, user_id={self.user_id}, banned_by={self.banned_by})>"

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "banned_by": self.banned_by,
            "reason": self.reason,
            "banned_at": self.banned_at.isoformat() if self.banned_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class EventCancellation(Base):
    """
    EventCancellation model - Tracks cancelled events with optional message.
    When an event is deleted/cancelled, a cancellation record is created.
    """

    __tablename__ = "event_cancellations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    event_id = Column(Integer, nullable=False, index=True)  # Not FK because event might be deleted
    event_name = Column(String(255), nullable=False)  # Store name for reference
    cancelled_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    message = Column(Text, nullable=True)  # Optional cancellation message
    cancelled_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    cancelled_by = relationship("User", foreign_keys=[cancelled_by_user_id])

    def __repr__(self):
        return f"<EventCancellation(id={self.id}, event_id={self.event_id}, cancelled_by={self.cancelled_by_user_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "event_id": self.event_id,
            "event_name": self.event_name,
            "cancelled_by_user_id": self.cancelled_by_user_id,
            "message": self.message,
            "cancelled_at": self.cancelled_at.isoformat() if self.cancelled_at else None,
        }


class EventCancellationView(Base):
    """
    EventCancellationView model - Tracks which users have viewed a cancellation.
    After viewing, the cancellation message disappears for that user.
    """

    __tablename__ = "event_cancellation_views"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    cancellation_id = Column(Integer, ForeignKey("event_cancellations.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    viewed_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    # Unique constraint: one view per user per cancellation
    __table_args__ = (UniqueConstraint("cancellation_id", "user_id", name="uq_cancellation_user_view"),)

    # Relationships
    cancellation = relationship("EventCancellation")
    user = relationship("User")

    def __repr__(self):
        return f"<EventCancellationView(id={self.id}, cancellation_id={self.cancellation_id}, user_id={self.user_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "cancellation_id": self.cancellation_id,
            "user_id": self.user_id,
            "viewed_at": self.viewed_at.isoformat() if self.viewed_at else None,
        }


class UserSubscriptionStats(Base):
    """
    Statistics table for user subscriptions.

    This table is populated and maintained by database triggers:
    - event_insert_stats_trigger: Updates when events are created
    - event_delete_stats_trigger: Updates when events are deleted
    - subscription_insert_stats_trigger: Updates when users subscribe
    - subscription_delete_stats_trigger: Updates when users unsubscribe

    Fields:
        user_id: Foreign key to users table
        new_events_count: Number of events created in last 7 days
        total_events_count: Total number of events created by user
        subscribers_count: Number of unique subscribers to user's events
        last_event_date: Timestamp of most recent event creation
        updated_at: Last update timestamp (auto-updated by trigger)
    """

    __tablename__ = "user_subscription_stats"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True, doc="User ID (FK)")
    new_events_count = Column(Integer, default=0, nullable=False, doc="Events in last 7 days")
    total_events_count = Column(Integer, default=0, nullable=False, doc="Total events created")
    subscribers_count = Column(Integer, default=0, nullable=False, doc="Number of subscribers")
    last_event_date = Column(TIMESTAMP(timezone=True), nullable=True, doc="Last event creation timestamp")
    updated_at = Column(TIMESTAMP(timezone=True), nullable=False, doc="Last stats update")

    # Relationship to User
    user = relationship("User", back_populates="subscription_stats")

    def __repr__(self):
        return f"<UserSubscriptionStats(user_id={self.user_id}, events={self.total_events_count}, subscribers={self.subscribers_count})>"

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "new_events_count": self.new_events_count,
            "total_events_count": self.total_events_count,
            "subscribers_count": self.subscribers_count,
            "last_event_date": self.last_event_date.isoformat() if self.last_event_date else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
