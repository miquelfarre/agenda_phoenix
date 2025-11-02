"""
Pydantic Schemas for Agenda Phoenix API

All request/response models defined here.
"""

from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, ConfigDict

# ============================================================================
# CONTACT SCHEMAS
# ============================================================================


class ContactBase(BaseModel):
    name: str
    phone: str


class ContactCreate(ContactBase):
    owner_id: Optional[int] = None


class ContactResponse(ContactBase):
    id: int
    owner_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# USER SCHEMAS
# ============================================================================


class UserBase(BaseModel):
    username: Optional[str] = None
    auth_provider: str
    auth_id: str
    is_public: bool = False
    is_admin: bool = False
    profile_picture_url: Optional[str] = None


class UserCreate(UserBase):
    contact_id: Optional[int] = None


class UserResponse(UserBase):
    id: int
    contact_id: Optional[int]
    last_login: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserEnrichedResponse(UserBase):
    """User response with enriched contact information"""

    id: int
    contact_id: Optional[int]
    contact_name: Optional[str]  # From Contact table
    contact_phone: Optional[str]  # From Contact table
    display_name: str  # Computed display name
    last_login: Optional[datetime]
    created_at: datetime
    updated_at: datetime


class UserSubscriptionResponse(UserBase):
    """User response with subscription statistics"""

    id: int
    contact_id: Optional[int]
    last_login: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    # Subscription statistics
    new_events_count: int  # Events created in last 7 days
    total_events_count: int  # Total events owned by this user
    subscribers_count: int  # Total unique subscribers to this user's events

    model_config = ConfigDict(from_attributes=True)


class EventStats(BaseModel):
    """Statistics for a single event of a public user"""

    event_id: int
    event_name: str
    event_start_date: datetime
    total_joined: int  # Number of users who joined this event


class UserPublicStats(BaseModel):
    """Statistics for a public user"""

    user_id: int
    username: Optional[str]
    total_subscribers: int  # Total number of subscribers
    total_events: int  # Total number of events created
    events_stats: List[EventStats]  # Stats for each event


# ============================================================================
# EVENT SCHEMAS
# ============================================================================


class EventBase(BaseModel):
    name: str
    description: Optional[str] = None
    start_date: datetime
    event_type: str = "regular"  # 'regular' or 'recurring'


class EventCreate(EventBase):
    owner_id: int
    calendar_id: Optional[int] = None
    parent_recurring_event_id: Optional[int] = None


class UpcomingEventSummary(BaseModel):
    """Simplified event schema for upcoming events list"""

    id: int
    name: str
    start_date: datetime
    event_type: str

    model_config = ConfigDict(from_attributes=True)


class InvitationStats(BaseModel):
    """Statistics for event invitations"""

    total_invited: int  # Total number of users invited
    accepted: int  # Number of accepted invitations
    pending: int  # Number of pending invitations
    rejected: int  # Number of rejected invitations


class EventResponse(EventBase):
    id: int
    owner_id: int
    calendar_id: Optional[int]
    parent_recurring_event_id: Optional[int]
    created_at: datetime
    updated_at: datetime
    interaction: Optional[dict] = None  # User's interaction with this event (type, status, role) - only for /users/{id}/events
    interactions: Optional[List[dict]] = None  # All interactions for this event with enriched user data - only for /events/{id}
    # Owner info
    owner_name: Optional[str] = None  # Full name of event owner
    owner_profile_picture: Optional[str] = None  # Profile picture URL of owner
    is_owner_public: Optional[bool] = None  # True if event owner is a public user
    can_subscribe_to_owner: Optional[bool] = None  # True if current user can subscribe to owner
    is_subscribed_to_owner: Optional[bool] = None  # True if current user is already subscribed to owner
    owner_upcoming_events: Optional[List[UpcomingEventSummary]] = None  # Next 10 events from public owner
    # Calendar info
    calendar_name: Optional[str] = None  # Name of calendar this event belongs to
    calendar_color: Optional[str] = None  # Color hex code for calendar
    # Event characteristics
    is_birthday: Optional[bool] = None  # True if this is a birthday event
    # Attendees (users who accepted invitation or are members/admins)
    attendees: Optional[List[dict]] = None  # List of attendee user objects
    # Invitation stats (only when current user is owner/admin)
    invitation_stats: Optional[InvitationStats] = None  # Statistics about invitations to this event

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# EVENT INTERACTION SCHEMAS
# ============================================================================


class EventInteractionBase(BaseModel):
    interaction_type: str
    status: Optional[str] = None
    role: Optional[str] = None
    note: Optional[str] = None
    rejection_message: Optional[str] = None
    is_attending: Optional[bool] = None


class EventInteractionCreate(EventInteractionBase):
    event_id: int
    user_id: int
    invited_by_user_id: Optional[int] = None
    invited_via_group_id: Optional[int] = None


class EventInteractionUpdate(BaseModel):
    """Schema for updating an event interaction (all fields optional)"""

    interaction_type: Optional[str] = None
    status: Optional[str] = None
    role: Optional[str] = None
    note: Optional[str] = None
    rejection_message: Optional[str] = None
    is_attending: Optional[bool] = None


class EventInteractionResponse(EventInteractionBase):
    id: int
    event_id: int
    user_id: int
    invited_by_user_id: Optional[int]
    invited_via_group_id: Optional[int]
    read_at: Optional[datetime]
    is_new: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class EventInteractionEnrichedResponse(EventInteractionBase):
    """Enriched interaction response with user information"""

    id: int
    event_id: int
    user_id: int
    user_name: str  # Display name (username or contact name)
    user_username: Optional[str]
    user_contact_name: Optional[str]
    invited_by_user_id: Optional[int]
    invited_via_group_id: Optional[int]
    read_at: Optional[datetime]
    is_new: bool
    created_at: datetime
    updated_at: datetime


class AvailableInviteeResponse(BaseModel):
    """User available to be invited to an event"""

    id: int
    username: Optional[str]
    contact_name: Optional[str]
    display_name: str  # Computed display name


class EventInteractionWithEventResponse(EventInteractionBase):
    """Interaction response with event information included"""

    id: int
    event_id: int
    user_id: int
    invited_by_user_id: Optional[int]
    invited_via_group_id: Optional[int]
    read_at: Optional[datetime]
    is_new: bool
    created_at: datetime
    updated_at: datetime
    # Event information
    event_name: str
    event_start_date: datetime
    event_type: str
    event_start_date_formatted: Optional[str] = None


# ============================================================================
# CALENDAR SCHEMAS
# ============================================================================


class CalendarBase(BaseModel):
    name: str
    description: Optional[str] = None
    is_discoverable: Optional[bool] = None


class CalendarCreate(CalendarBase):
    owner_id: int


class CalendarResponse(CalendarBase):
    id: int
    owner_id: int
    is_public: bool = False
    category: Optional[str] = None
    share_hash: Optional[str] = None
    subscriber_count: int = 0
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CalendarEnrichedResponse(CalendarBase):
    """Calendar response with enriched display fields"""

    id: int
    owner_id: int
    created_at: datetime
    updated_at: datetime


# ============================================================================
# CALENDAR MEMBERSHIP SCHEMAS
# ============================================================================


class CalendarMembershipBase(BaseModel):
    role: str = "member"  # 'owner', 'admin', 'member'
    status: str = "pending"  # 'pending', 'accepted', 'rejected'


class CalendarMembershipCreate(CalendarMembershipBase):
    calendar_id: int
    user_id: int
    invited_by_user_id: Optional[int] = None


class CalendarMembershipResponse(CalendarMembershipBase):
    id: int
    calendar_id: int
    user_id: int
    invited_by_user_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CalendarMembershipEnrichedResponse(CalendarMembershipBase):
    """Calendar membership with enriched calendar information"""

    id: int
    calendar_id: int
    user_id: int
    invited_by_user_id: Optional[int]
    created_at: datetime
    updated_at: datetime
    # Calendar information
    calendar_name: str
    calendar_owner_id: int  # Calendar owner


# ============================================================================
# CALENDAR SUBSCRIPTION SCHEMAS
# ============================================================================


class CalendarSubscriptionBase(BaseModel):
    status: str = "active"  # 'active', 'paused'


class CalendarSubscriptionCreate(CalendarSubscriptionBase):
    calendar_id: int
    user_id: int


class CalendarSubscriptionResponse(CalendarSubscriptionBase):
    id: int
    calendar_id: int
    user_id: int
    subscribed_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CalendarSubscriptionEnrichedResponse(CalendarSubscriptionBase):
    """Calendar subscription with enriched calendar information"""

    id: int
    calendar_id: int
    user_id: int
    subscribed_at: datetime
    updated_at: datetime
    # Calendar information
    calendar_name: str
    calendar_description: Optional[str]
    calendar_category: Optional[str]
    calendar_owner_id: int
    calendar_owner_name: str  # Display name of calendar owner
    calendar_subscriber_count: int


# ============================================================================
# GROUP SCHEMAS
# ============================================================================


class GroupBase(BaseModel):
    name: str
    description: Optional[str] = None


class GroupCreate(GroupBase):
    created_by: int


class GroupResponse(GroupBase):
    id: int
    created_by: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# GROUP MEMBERSHIP SCHEMAS
# ============================================================================


class GroupMembershipBase(BaseModel):
    pass


class GroupMembershipCreate(GroupMembershipBase):
    group_id: int
    user_id: int


class GroupMembershipUpdate(BaseModel):
    """Schema for updating group membership (currently only role)"""
    role: Optional[str] = None  # "admin" or "member"


class GroupMembershipResponse(GroupMembershipBase):
    id: int
    group_id: int
    user_id: int
    role: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# RECURRING EVENT CONFIG SCHEMAS
# ============================================================================


class RecurringEventConfigBase(BaseModel):
    recurrence_type: str = "weekly"  # 'daily', 'weekly', 'monthly', 'yearly'
    schedule: Optional[List[Dict[str, str]]] = None  # Type-specific configuration
    recurrence_end_date: Optional[datetime] = None  # NULL = perpetual/infinite


class RecurringEventConfigCreate(RecurringEventConfigBase):
    event_id: int


class RecurringEventConfigResponse(RecurringEventConfigBase):
    id: int
    event_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# EVENT BAN SCHEMAS
# ============================================================================


class EventBanBase(BaseModel):
    reason: Optional[str] = None


class EventBanCreate(EventBanBase):
    event_id: int
    user_id: int
    banned_by: int


class EventBanResponse(EventBanBase):
    id: int
    event_id: int
    user_id: int
    banned_by: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# USER BLOCK SCHEMAS
# ============================================================================


class UserBlockBase(BaseModel):
    pass


class UserBlockCreate(UserBlockBase):
    blocker_user_id: int
    blocked_user_id: int


class UserBlockResponse(UserBlockBase):
    id: int
    blocker_user_id: int
    blocked_user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# APP BAN SCHEMAS
# ============================================================================


class AppBanBase(BaseModel):
    reason: Optional[str] = None


class AppBanCreate(AppBanBase):
    user_id: int
    banned_by: int


class AppBanResponse(AppBanBase):
    id: int
    user_id: int
    banned_by: int
    banned_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# EVENT CANCELLATION SCHEMAS
# ============================================================================


class EventCancellationBase(BaseModel):
    message: Optional[str] = None


class EventDeleteRequest(BaseModel):
    """Request body for deleting an event with optional cancellation message"""

    cancelled_by_user_id: int
    cancellation_message: Optional[str] = None


class EventCancellationCreate(EventCancellationBase):
    event_id: int
    event_name: str
    cancelled_by_user_id: int


class EventCancellationResponse(EventCancellationBase):
    id: int
    event_id: int
    event_name: str
    cancelled_by_user_id: int
    cancelled_at: datetime

    model_config = ConfigDict(from_attributes=True)


class EventCancellationViewCreate(BaseModel):
    cancellation_id: int
    user_id: int


class EventCancellationViewResponse(BaseModel):
    id: int
    cancellation_id: int
    user_id: int
    viewed_at: datetime

    model_config = ConfigDict(from_attributes=True)
