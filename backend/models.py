from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, UniqueConstraint, Boolean, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy import func
from database import Base


class Contact(Base):
    """
    Contact model - Phone contacts from user's device.
    """
    __tablename__ = "contacts"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    phone = Column(String(50), unique=True, nullable=False, index=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationship
    user = relationship("User", back_populates="contact", uselist=False)

    def __repr__(self):
        return f"<Contact(id={self.id}, name='{self.name}', phone='{self.phone}')>"

    def to_dict(self):
        return {
            "id": self.id,
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
    username = Column(String(100), nullable=True, index=True)  # For Instagram users
    auth_provider = Column(String(20), nullable=False)  # 'phone' or 'instagram'
    auth_id = Column(String(255), nullable=False, unique=True, index=True)  # Phone number or Instagram user ID
    profile_picture_url = Column(String(500), nullable=True)
    last_login = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    contact = relationship("Contact", back_populates="user")
    calendars = relationship("Calendar", back_populates="user", cascade="all, delete-orphan")
    calendar_memberships = relationship("CalendarMembership", foreign_keys="CalendarMembership.user_id", back_populates="user", cascade="all, delete-orphan")
    created_groups = relationship("Group", back_populates="creator", cascade="all, delete-orphan")
    group_memberships = relationship("GroupMembership", back_populates="user", cascade="all, delete-orphan")
    events = relationship("Event", foreign_keys="Event.owner_id", back_populates="owner", cascade="all, delete-orphan")
    interactions = relationship("EventInteraction", foreign_keys="EventInteraction.user_id", back_populates="user", cascade="all, delete-orphan")
    blocked_users = relationship("UserBlock", foreign_keys="UserBlock.blocker_user_id", back_populates="blocker", cascade="all, delete-orphan")
    blocked_by_users = relationship("UserBlock", foreign_keys="UserBlock.blocked_user_id", back_populates="blocked", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, auth_provider='{self.auth_provider}', username='{self.username}')>"

    def to_dict(self):
        return {
            "id": self.id,
            "contact_id": self.contact_id,
            "username": self.username,
            "auth_provider": self.auth_provider,
            "auth_id": self.auth_id,
            "profile_picture_url": self.profile_picture_url,
            "last_login": self.last_login.isoformat() if self.last_login else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Calendar(Base):
    """
    Calendar model - Users can have multiple calendars to organize events.
    """
    __tablename__ = "calendars"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)  # Owner principal del calendar
    name = Column(String(255), nullable=False)
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
    role = Column(String(50), nullable=False, default='member')  # 'owner', 'admin', 'member'
    status = Column(String(50), nullable=False, default='pending')  # 'pending', 'accepted', 'rejected'
    invited_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: un usuario solo puede tener una membresía por calendar
    __table_args__ = (
        UniqueConstraint('calendar_id', 'user_id', name='uq_calendar_user_membership'),
    )

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


class Group(Base):
    """
    Group model - Users can be organized into groups for mass invitations.
    """
    __tablename__ = "groups"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    creator = relationship("User", back_populates="created_groups")
    memberships = relationship("GroupMembership", back_populates="group", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Group(id={self.id}, name='{self.name}', created_by={self.created_by})>"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "created_by": self.created_by,
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
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: one user per group
    __table_args__ = (
        UniqueConstraint('group_id', 'user_id', name='uq_group_user'),
    )

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
    end_date = Column(TIMESTAMP(timezone=True), nullable=True)
    event_type = Column(String(50), nullable=False, default='regular')  # 'regular' or 'recurring'
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    calendar_id = Column(Integer, ForeignKey("calendars.id"), nullable=True, index=True)
    parent_recurring_event_id = Column(Integer, ForeignKey("recurring_event_configs.id"), nullable=True, index=True)  # Evento recurrente padre
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
            "end_date": self.end_date.isoformat() if self.end_date else None,
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
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Unique constraint: one active interaction per user per event
    __table_args__ = (
        UniqueConstraint('event_id', 'user_id', name='uq_event_user_interaction'),
    )

    # Relationships
    event = relationship("Event", back_populates="interactions")
    user = relationship("User", foreign_keys=[user_id], back_populates="interactions")
    invited_by = relationship("User", foreign_keys=[invited_by_user_id])
    invited_via_group = relationship("Group")

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
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class RecurringEventConfig(Base):
    """
    RecurringEventConfig model - Configuration for recurring events.
    """
    __tablename__ = "recurring_event_configs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False, unique=True, index=True)
    days_of_week = Column(JSON, nullable=True)  # [0,1,2,3,4,5,6] for Mon-Sun
    time_slots = Column(JSON, nullable=True)  # [{"start": "09:00", "end": "10:00"}]
    recurrence_end_date = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    event = relationship("Event", foreign_keys=[event_id], back_populates="recurring_config")

    def __repr__(self):
        return f"<RecurringEventConfig(id={self.id}, event_id={self.event_id})>"

    def to_dict(self):
        return {
            "id": self.id,
            "event_id": self.event_id,
            "days_of_week": self.days_of_week,
            "time_slots": self.time_slots,
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
    __table_args__ = (
        UniqueConstraint('event_id', 'user_id', name='uq_event_user_ban'),
    )

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
    __table_args__ = (
        UniqueConstraint('blocker_user_id', 'blocked_user_id', name='uq_blocker_blocked'),
    )

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
