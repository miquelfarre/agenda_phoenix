"""
Pydantic Schemas for Agenda Phoenix API

All request/response models defined here.
"""
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime


# ============================================================================
# CONTACT SCHEMAS
# ============================================================================

class ContactBase(BaseModel):
    name: str
    phone: str


class ContactCreate(ContactBase):
    pass


class ContactResponse(ContactBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# USER SCHEMAS
# ============================================================================

class UserBase(BaseModel):
    username: Optional[str] = None
    auth_provider: str
    auth_id: str
    profile_picture_url: Optional[str] = None


class UserCreate(UserBase):
    contact_id: Optional[int] = None


class UserResponse(UserBase):
    id: int
    contact_id: Optional[int]
    last_login: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


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


# ============================================================================
# EVENT SCHEMAS
# ============================================================================

class EventBase(BaseModel):
    name: str
    description: Optional[str] = None
    start_date: datetime
    end_date: Optional[datetime] = None
    event_type: str = 'regular'  # 'regular' or 'recurring'


class EventCreate(EventBase):
    owner_id: int
    calendar_id: Optional[int] = None
    parent_recurring_event_id: Optional[int] = None


class EventResponse(EventBase):
    id: int
    owner_id: int
    calendar_id: Optional[int]
    parent_recurring_event_id: Optional[int]
    created_at: datetime
    updated_at: datetime
    source: Optional[str] = None  # For /users/{user_id}/events endpoint
    start_date_formatted: Optional[str] = None  # Pre-formatted date for UI
    end_date_formatted: Optional[str] = None  # Pre-formatted date for UI
    is_owner: Optional[bool] = None  # Whether current user is owner
    owner_display: Optional[str] = None  # "Yo" or "Usuario #X"

    class Config:
        from_attributes = True


# ============================================================================
# EVENT INTERACTION SCHEMAS
# ============================================================================

class EventInteractionBase(BaseModel):
    interaction_type: str
    status: Optional[str] = None
    role: Optional[str] = None


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


class EventInteractionResponse(EventInteractionBase):
    id: int
    event_id: int
    user_id: int
    invited_by_user_id: Optional[int]
    invited_via_group_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


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
    created_at: datetime
    updated_at: datetime
    # Event information
    event_name: str
    event_start_date: datetime
    event_end_date: Optional[datetime]
    event_type: str
    event_start_date_formatted: Optional[str] = None
    event_end_date_formatted: Optional[str] = None


# ============================================================================
# CALENDAR SCHEMAS
# ============================================================================

class CalendarBase(BaseModel):
    name: str


class CalendarCreate(CalendarBase):
    owner_id: int


class CalendarResponse(CalendarBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


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
    role: str = 'member'  # 'owner', 'admin', 'member'
    status: str = 'pending'  # 'pending', 'accepted', 'rejected'


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

    class Config:
        from_attributes = True


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

    class Config:
        from_attributes = True


# ============================================================================
# GROUP MEMBERSHIP SCHEMAS
# ============================================================================

class GroupMembershipBase(BaseModel):
    pass


class GroupMembershipCreate(GroupMembershipBase):
    group_id: int
    user_id: int


class GroupMembershipResponse(GroupMembershipBase):
    id: int
    group_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# RECURRING EVENT CONFIG SCHEMAS
# ============================================================================

class RecurringEventConfigBase(BaseModel):
    days_of_week: Optional[List[int]] = None
    time_slots: Optional[List[Dict[str, str]]] = None
    recurrence_end_date: Optional[datetime] = None


class RecurringEventConfigCreate(RecurringEventConfigBase):
    event_id: int


class RecurringEventConfigResponse(RecurringEventConfigBase):
    id: int
    event_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


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

    class Config:
        from_attributes = True


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

    class Config:
        from_attributes = True


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

    class Config:
        from_attributes = True
