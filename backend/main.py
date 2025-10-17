from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import logging
from init_db import init_database
from database import SessionLocal
from models import (
    Contact, User, Calendar, CalendarMembership, Group, GroupMembership,
    Event, EventInteraction, RecurringEventConfig,
    EventBan, UserBlock
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Agenda Phoenix API", version="2.0.0")


@app.on_event("startup")
async def startup_event():
    """
    Execute on application startup.
    Initialize database: drop all tables, recreate them, and insert sample data.
    """
    logger.info("🚀 FastAPI application starting up...")
    try:
        init_database()
        logger.info("✅ Database initialization completed")
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")


# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============================================================================
# PYDANTIC SCHEMAS
# ============================================================================

# Contact schemas
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


# User schemas
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


# Event schemas
class EventBase(BaseModel):
    name: str
    description: Optional[str] = None
    start_date: datetime
    end_date: Optional[datetime] = None
    event_type: str = 'regular'  # 'regular', 'birthday', 'recurring'


class EventCreate(EventBase):
    owner_id: int
    calendar_id: Optional[int] = None
    birthday_user_id: Optional[int] = None
    parent_calendar_id: Optional[int] = None
    parent_recurring_event_id: Optional[int] = None


class EventResponse(EventBase):
    id: int
    owner_id: int
    calendar_id: Optional[int]
    birthday_user_id: Optional[int]
    parent_calendar_id: Optional[int]
    parent_recurring_event_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# EventInteraction schemas
class EventInteractionBase(BaseModel):
    interaction_type: str
    status: Optional[str] = None
    role: Optional[str] = None


class EventInteractionCreate(EventInteractionBase):
    event_id: int
    user_id: int
    invited_by_user_id: Optional[int] = None
    invited_via_group_id: Optional[int] = None


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


# Calendar schemas
class CalendarBase(BaseModel):
    name: str
    color: Optional[str] = "#3498db"
    is_default: bool = False
    is_private_birthdays: bool = False


class CalendarCreate(CalendarBase):
    user_id: int


class CalendarResponse(CalendarBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# CalendarMembership schemas
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


# Group schemas
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


# GroupMembership schemas
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


# RecurringEventConfig schemas
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


# EventBan schemas
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


# UserBlock schemas
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
# ROOT & HEALTH
# ============================================================================

@app.get("/")
async def root():
    return {
        "message": "Agenda Phoenix API",
        "version": "2.0.0",
        "endpoints": {
            "contacts": "/contacts",
            "users": "/users",
            "events": "/events",
            "interactions": "/interactions",
            "health": "/health"
        }
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


# ============================================================================
# CONTACTS ENDPOINTS
# ============================================================================

@app.get("/contacts", response_model=List[ContactResponse])
async def get_contacts(db: Session = Depends(get_db)):
    """Get all contacts"""
    contacts = db.query(Contact).all()
    return contacts


@app.get("/contacts/{contact_id}", response_model=ContactResponse)
async def get_contact(contact_id: int, db: Session = Depends(get_db)):
    """Get a single contact by ID"""
    contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    return contact


@app.post("/contacts", response_model=ContactResponse, status_code=201)
async def create_contact(contact: ContactCreate, db: Session = Depends(get_db)):
    """Create a new contact"""
    # Check if phone already exists
    existing = db.query(Contact).filter(Contact.phone == contact.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already exists")

    db_contact = Contact(**contact.dict())
    db.add(db_contact)
    db.commit()
    db.refresh(db_contact)
    return db_contact


@app.put("/contacts/{contact_id}", response_model=ContactResponse)
async def update_contact(contact_id: int, contact: ContactCreate, db: Session = Depends(get_db)):
    """Update an existing contact"""
    db_contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    # Check if phone already exists for another contact
    existing = db.query(Contact).filter(
        Contact.phone == contact.phone,
        Contact.id != contact_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already exists")

    for key, value in contact.dict().items():
        setattr(db_contact, key, value)

    db.commit()
    db.refresh(db_contact)
    return db_contact


@app.delete("/contacts/{contact_id}")
async def delete_contact(contact_id: int, db: Session = Depends(get_db)):
    """Delete a contact"""
    db_contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    db.delete(db_contact)
    db.commit()
    return {"message": "Contact deleted successfully", "id": contact_id}


# ============================================================================
# USERS ENDPOINTS
# ============================================================================

@app.get("/users", response_model=List[UserResponse])
async def get_users(db: Session = Depends(get_db)):
    """Get all users"""
    users = db.query(User).all()
    return users


@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get a single user by ID"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@app.post("/users", response_model=UserResponse, status_code=201)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """Create a new user"""
    # Check if auth_id already exists
    existing = db.query(User).filter(User.auth_id == user.auth_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="User with this auth_id already exists")

    # If contact_id provided, verify it exists
    if user.contact_id:
        contact = db.query(Contact).filter(Contact.id == user.contact_id).first()
        if not contact:
            raise HTTPException(status_code=404, detail="Contact not found")

    db_user = User(**user.dict(), last_login=datetime.now())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@app.put("/users/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, user: UserCreate, db: Session = Depends(get_db)):
    """Update an existing user"""
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if auth_id already exists for another user
    existing = db.query(User).filter(
        User.auth_id == user.auth_id,
        User.id != user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User with this auth_id already exists")

    for key, value in user.dict().items():
        setattr(db_user, key, value)

    db.commit()
    db.refresh(db_user)
    return db_user


@app.delete("/users/{user_id}")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    """Delete a user"""
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(db_user)
    db.commit()
    return {"message": "User deleted successfully", "id": user_id}


@app.get("/users/{user_id}/events", response_model=List[EventResponse])
async def get_user_events(
    user_id: int,
    include_past: bool = False,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    db: Session = Depends(get_db)
):
    """
    Get all events for a user including:
    - Own events (where user is owner)
    - Events from subscribed users
    - Events where user has been invited

    By default shows events from today 00:00 for the next 30 months.
    Times are rounded to 5-minute intervals.
    """
    # Verify user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Set default date range
    if from_date is None:
        from_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    if to_date is None:
        to_date = from_date + timedelta(days=30*30)  # 30 months

    # If not including past events, ensure from_date is not in the past
    if not include_past:
        now_midnight = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        if from_date < now_midnight:
            from_date = now_midnight

    # Get all relevant event IDs
    event_ids = set()

    # 1. Own events
    own_events = db.query(Event.id).filter(Event.owner_id == user_id).all()
    event_ids.update([e[0] for e in own_events])

    # 2. Events from subscribed users (through EventInteraction with type 'subscribed')
    subscribed_events = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'subscribed'
    ).all()
    event_ids.update([e[0] for e in subscribed_events])

    # 3. Events where user has been invited
    invited_events = db.query(EventInteraction.event_id).filter(
        EventInteraction.user_id == user_id,
        EventInteraction.interaction_type == 'invited'
    ).all()
    event_ids.update([e[0] for e in invited_events])

    # Query events with date filtering
    if event_ids:
        events = db.query(Event).filter(
            Event.id.in_(event_ids),
            Event.start_date >= from_date,
            Event.start_date <= to_date
        ).order_by(Event.start_date).all()
    else:
        events = []

    # Round times to 5-minute intervals
    for event in events:
        # Round start_date
        minute = (event.start_date.minute // 5) * 5
        event.start_date = event.start_date.replace(minute=minute, second=0, microsecond=0)

        # Round end_date if exists
        if event.end_date:
            minute = (event.end_date.minute // 5) * 5
            event.end_date = event.end_date.replace(minute=minute, second=0, microsecond=0)

    return events


# ============================================================================
# EVENTS ENDPOINTS
# ============================================================================

@app.get("/events", response_model=List[EventResponse])
async def get_events(owner_id: Optional[int] = None, db: Session = Depends(get_db)):
    """Get all events, optionally filtered by owner_id"""
    query = db.query(Event)
    if owner_id:
        query = query.filter(Event.owner_id == owner_id)
    events = query.all()
    return events


@app.get("/events/{event_id}", response_model=EventResponse)
async def get_event(event_id: int, db: Session = Depends(get_db)):
    """Get a single event by ID"""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event


@app.post("/events", response_model=EventResponse, status_code=201)
async def create_event(event: EventCreate, db: Session = Depends(get_db)):
    """Create a new event"""
    # Verify owner exists
    owner = db.query(User).filter(User.id == event.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner user not found")

    db_event = Event(**event.dict())
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event


@app.put("/events/{event_id}", response_model=EventResponse)
async def update_event(event_id: int, event: EventCreate, db: Session = Depends(get_db)):
    """Update an existing event"""
    db_event = db.query(Event).filter(Event.id == event_id).first()
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Verify new owner exists if owner_id is changing
    if event.owner_id != db_event.owner_id:
        owner = db.query(User).filter(User.id == event.owner_id).first()
        if not owner:
            raise HTTPException(status_code=404, detail="Owner user not found")

    for key, value in event.dict().items():
        setattr(db_event, key, value)

    db.commit()
    db.refresh(db_event)
    return db_event


@app.delete("/events/{event_id}")
async def delete_event(event_id: int, db: Session = Depends(get_db)):
    """Delete an event"""
    db_event = db.query(Event).filter(Event.id == event_id).first()
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    db.delete(db_event)
    db.commit()
    return {"message": "Event deleted successfully", "id": event_id}


# ============================================================================
# EVENT INTERACTIONS ENDPOINTS
# ============================================================================

@app.get("/interactions", response_model=List[EventInteractionResponse])
async def get_interactions(
    event_id: Optional[int] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get all interactions, optionally filtered by event_id and/or user_id"""
    query = db.query(EventInteraction)
    if event_id:
        query = query.filter(EventInteraction.event_id == event_id)
    if user_id:
        query = query.filter(EventInteraction.user_id == user_id)
    interactions = query.all()
    return interactions


@app.get("/interactions/{interaction_id}", response_model=EventInteractionResponse)
async def get_interaction(interaction_id: int, db: Session = Depends(get_db)):
    """Get a single interaction by ID"""
    interaction = db.query(EventInteraction).filter(EventInteraction.id == interaction_id).first()
    if not interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")
    return interaction


@app.post("/interactions", response_model=EventInteractionResponse, status_code=201)
async def create_interaction(interaction: EventInteractionCreate, db: Session = Depends(get_db)):
    """Create a new event interaction"""
    # Verify event exists
    event = db.query(Event).filter(Event.id == interaction.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Verify user exists
    user = db.query(User).filter(User.id == interaction.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if interaction already exists (unique constraint)
    existing = db.query(EventInteraction).filter(
        EventInteraction.event_id == interaction.event_id,
        EventInteraction.user_id == interaction.user_id
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail="User already has an interaction with this event"
        )

    db_interaction = EventInteraction(**interaction.dict())
    db.add(db_interaction)
    db.commit()
    db.refresh(db_interaction)
    return db_interaction


@app.put("/interactions/{interaction_id}", response_model=EventInteractionResponse)
async def update_interaction(
    interaction_id: int,
    interaction: EventInteractionBase,
    db: Session = Depends(get_db)
):
    """Update an existing interaction (typically to change type or status)"""
    db_interaction = db.query(EventInteraction).filter(
        EventInteraction.id == interaction_id
    ).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    for key, value in interaction.dict().items():
        setattr(db_interaction, key, value)

    db.commit()
    db.refresh(db_interaction)
    return db_interaction


@app.delete("/interactions/{interaction_id}")
async def delete_interaction(interaction_id: int, db: Session = Depends(get_db)):
    """Delete an interaction"""
    db_interaction = db.query(EventInteraction).filter(
        EventInteraction.id == interaction_id
    ).first()
    if not db_interaction:
        raise HTTPException(status_code=404, detail="Interaction not found")

    db.delete(db_interaction)
    db.commit()
    return {"message": "Interaction deleted successfully", "id": interaction_id}


# ============================================================================
# CALENDARS ENDPOINTS
# ============================================================================

@app.get("/calendars", response_model=List[CalendarResponse])
async def get_calendars(user_id: Optional[int] = None, db: Session = Depends(get_db)):
    """Get all calendars, optionally filtered by user_id"""
    query = db.query(Calendar)
    if user_id:
        query = query.filter(Calendar.user_id == user_id)
    calendars = query.all()
    return calendars


@app.get("/calendars/{calendar_id}", response_model=CalendarResponse)
async def get_calendar(calendar_id: int, db: Session = Depends(get_db)):
    """Get a single calendar by ID"""
    calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")
    return calendar


@app.post("/calendars", response_model=CalendarResponse, status_code=201)
async def create_calendar(calendar: CalendarCreate, db: Session = Depends(get_db)):
    """Create a new calendar"""
    # Verify user exists
    user = db.query(User).filter(User.id == calendar.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db_calendar = Calendar(**calendar.dict())
    db.add(db_calendar)
    db.commit()
    db.refresh(db_calendar)
    return db_calendar


@app.put("/calendars/{calendar_id}", response_model=CalendarResponse)
async def update_calendar(calendar_id: int, calendar: CalendarBase, db: Session = Depends(get_db)):
    """Update an existing calendar"""
    db_calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    for key, value in calendar.dict().items():
        setattr(db_calendar, key, value)

    db.commit()
    db.refresh(db_calendar)
    return db_calendar


@app.delete("/calendars/{calendar_id}")
async def delete_calendar(calendar_id: int, db: Session = Depends(get_db)):
    """Delete a calendar"""
    db_calendar = db.query(Calendar).filter(Calendar.id == calendar_id).first()
    if not db_calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    db.delete(db_calendar)
    db.commit()
    return {"message": "Calendar deleted successfully", "id": calendar_id}


# ============================================================================
# CALENDAR MEMBERSHIPS ENDPOINTS
# ============================================================================

@app.get("/calendar_memberships", response_model=List[CalendarMembershipResponse])
async def get_calendar_memberships(
    calendar_id: Optional[int] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get all calendar memberships, optionally filtered by calendar_id and/or user_id"""
    query = db.query(CalendarMembership)
    if calendar_id:
        query = query.filter(CalendarMembership.calendar_id == calendar_id)
    if user_id:
        query = query.filter(CalendarMembership.user_id == user_id)
    memberships = query.all()
    return memberships


@app.get("/calendar_memberships/{membership_id}", response_model=CalendarMembershipResponse)
async def get_calendar_membership(membership_id: int, db: Session = Depends(get_db)):
    """Get a single calendar membership by ID"""
    membership = db.query(CalendarMembership).filter(CalendarMembership.id == membership_id).first()
    if not membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")
    return membership


@app.post("/calendar_memberships", response_model=CalendarMembershipResponse, status_code=201)
async def create_calendar_membership(membership: CalendarMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a calendar (invite or add directly)"""
    # Verify calendar exists
    calendar = db.query(Calendar).filter(Calendar.id == membership.calendar_id).first()
    if not calendar:
        raise HTTPException(status_code=404, detail="Calendar not found")

    # Verify user exists
    user = db.query(User).filter(User.id == membership.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if membership already exists
    existing = db.query(CalendarMembership).filter(
        CalendarMembership.calendar_id == membership.calendar_id,
        CalendarMembership.user_id == membership.user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already has a membership in this calendar")

    db_membership = CalendarMembership(**membership.dict())
    db.add(db_membership)
    db.commit()
    db.refresh(db_membership)
    return db_membership


@app.put("/calendar_memberships/{membership_id}", response_model=CalendarMembershipResponse)
async def update_calendar_membership(
    membership_id: int,
    membership: CalendarMembershipBase,
    db: Session = Depends(get_db)
):
    """Update a calendar membership (e.g., change status from pending to accepted, or change role)"""
    db_membership = db.query(CalendarMembership).filter(CalendarMembership.id == membership_id).first()
    if not db_membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")

    for key, value in membership.dict().items():
        setattr(db_membership, key, value)

    db.commit()
    db.refresh(db_membership)
    return db_membership


@app.delete("/calendar_memberships/{membership_id}")
async def delete_calendar_membership(membership_id: int, db: Session = Depends(get_db)):
    """Remove a user from a calendar"""
    db_membership = db.query(CalendarMembership).filter(CalendarMembership.id == membership_id).first()
    if not db_membership:
        raise HTTPException(status_code=404, detail="Calendar membership not found")

    db.delete(db_membership)
    db.commit()
    return {"message": "Calendar membership deleted successfully", "id": membership_id}


# ============================================================================
# GROUPS ENDPOINTS
# ============================================================================

@app.get("/groups", response_model=List[GroupResponse])
async def get_groups(created_by: Optional[int] = None, db: Session = Depends(get_db)):
    """Get all groups, optionally filtered by creator"""
    query = db.query(Group)
    if created_by:
        query = query.filter(Group.created_by == created_by)
    groups = query.all()
    return groups


@app.get("/groups/{group_id}", response_model=GroupResponse)
async def get_group(group_id: int, db: Session = Depends(get_db)):
    """Get a single group by ID"""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
    return group


@app.post("/groups", response_model=GroupResponse, status_code=201)
async def create_group(group: GroupCreate, db: Session = Depends(get_db)):
    """Create a new group"""
    # Verify creator exists
    creator = db.query(User).filter(User.id == group.created_by).first()
    if not creator:
        raise HTTPException(status_code=404, detail="Creator user not found")

    db_group = Group(**group.dict())
    db.add(db_group)
    db.commit()
    db.refresh(db_group)
    return db_group


@app.put("/groups/{group_id}", response_model=GroupResponse)
async def update_group(group_id: int, group: GroupBase, db: Session = Depends(get_db)):
    """Update an existing group"""
    db_group = db.query(Group).filter(Group.id == group_id).first()
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    for key, value in group.dict().items():
        setattr(db_group, key, value)

    db.commit()
    db.refresh(db_group)
    return db_group


@app.delete("/groups/{group_id}")
async def delete_group(group_id: int, db: Session = Depends(get_db)):
    """Delete a group"""
    db_group = db.query(Group).filter(Group.id == group_id).first()
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    db.delete(db_group)
    db.commit()
    return {"message": "Group deleted successfully", "id": group_id}


# ============================================================================
# GROUP MEMBERSHIPS ENDPOINTS
# ============================================================================

@app.get("/group_memberships", response_model=List[GroupMembershipResponse])
async def get_group_memberships(
    group_id: Optional[int] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get all group memberships, optionally filtered by group_id and/or user_id"""
    query = db.query(GroupMembership)
    if group_id:
        query = query.filter(GroupMembership.group_id == group_id)
    if user_id:
        query = query.filter(GroupMembership.user_id == user_id)
    memberships = query.all()
    return memberships


@app.get("/group_memberships/{membership_id}", response_model=GroupMembershipResponse)
async def get_group_membership(membership_id: int, db: Session = Depends(get_db)):
    """Get a single group membership by ID"""
    membership = db.query(GroupMembership).filter(GroupMembership.id == membership_id).first()
    if not membership:
        raise HTTPException(status_code=404, detail="Group membership not found")
    return membership


@app.post("/group_memberships", response_model=GroupMembershipResponse, status_code=201)
async def create_group_membership(membership: GroupMembershipCreate, db: Session = Depends(get_db)):
    """Add a user to a group"""
    # Verify group exists
    group = db.query(Group).filter(Group.id == membership.group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Verify user exists
    user = db.query(User).filter(User.id == membership.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if membership already exists
    existing = db.query(GroupMembership).filter(
        GroupMembership.group_id == membership.group_id,
        GroupMembership.user_id == membership.user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User is already a member of this group")

    db_membership = GroupMembership(**membership.dict())
    db.add(db_membership)
    db.commit()
    db.refresh(db_membership)
    return db_membership


@app.delete("/group_memberships/{membership_id}")
async def delete_group_membership(membership_id: int, db: Session = Depends(get_db)):
    """Remove a user from a group"""
    db_membership = db.query(GroupMembership).filter(GroupMembership.id == membership_id).first()
    if not db_membership:
        raise HTTPException(status_code=404, detail="Group membership not found")

    db.delete(db_membership)
    db.commit()
    return {"message": "Group membership deleted successfully", "id": membership_id}


# ============================================================================
# RECURRING EVENT CONFIGS ENDPOINTS
# ============================================================================

@app.get("/recurring_configs", response_model=List[RecurringEventConfigResponse])
async def get_recurring_configs(event_id: Optional[int] = None, db: Session = Depends(get_db)):
    """Get all recurring event configs, optionally filtered by event_id"""
    query = db.query(RecurringEventConfig)
    if event_id:
        query = query.filter(RecurringEventConfig.event_id == event_id)
    configs = query.all()
    return configs


@app.get("/recurring_configs/{config_id}", response_model=RecurringEventConfigResponse)
async def get_recurring_config(config_id: int, db: Session = Depends(get_db)):
    """Get a single recurring config by ID"""
    config = db.query(RecurringEventConfig).filter(RecurringEventConfig.id == config_id).first()
    if not config:
        raise HTTPException(status_code=404, detail="Recurring config not found")
    return config


@app.post("/recurring_configs", response_model=RecurringEventConfigResponse, status_code=201)
async def create_recurring_config(config: RecurringEventConfigCreate, db: Session = Depends(get_db)):
    """Create a new recurring event config"""
    # Verify event exists
    event = db.query(Event).filter(Event.id == config.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Check if config already exists for this event
    existing = db.query(RecurringEventConfig).filter(
        RecurringEventConfig.event_id == config.event_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Event already has a recurring config")

    db_config = RecurringEventConfig(**config.dict())
    db.add(db_config)
    db.commit()
    db.refresh(db_config)
    return db_config


@app.put("/recurring_configs/{config_id}", response_model=RecurringEventConfigResponse)
async def update_recurring_config(config_id: int, config: RecurringEventConfigBase, db: Session = Depends(get_db)):
    """Update an existing recurring config"""
    db_config = db.query(RecurringEventConfig).filter(RecurringEventConfig.id == config_id).first()
    if not db_config:
        raise HTTPException(status_code=404, detail="Recurring config not found")

    for key, value in config.dict().items():
        setattr(db_config, key, value)

    db.commit()
    db.refresh(db_config)
    return db_config


@app.delete("/recurring_configs/{config_id}")
async def delete_recurring_config(config_id: int, db: Session = Depends(get_db)):
    """Delete a recurring config"""
    db_config = db.query(RecurringEventConfig).filter(RecurringEventConfig.id == config_id).first()
    if not db_config:
        raise HTTPException(status_code=404, detail="Recurring config not found")

    db.delete(db_config)
    db.commit()
    return {"message": "Recurring config deleted successfully", "id": config_id}


# ============================================================================
# EVENT BANS ENDPOINTS
# ============================================================================

@app.get("/event_bans", response_model=List[EventBanResponse])
async def get_event_bans(
    event_id: Optional[int] = None,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get all event bans, optionally filtered by event_id and/or user_id"""
    query = db.query(EventBan)
    if event_id:
        query = query.filter(EventBan.event_id == event_id)
    if user_id:
        query = query.filter(EventBan.user_id == user_id)
    bans = query.all()
    return bans


@app.get("/event_bans/{ban_id}", response_model=EventBanResponse)
async def get_event_ban(ban_id: int, db: Session = Depends(get_db)):
    """Get a single event ban by ID"""
    ban = db.query(EventBan).filter(EventBan.id == ban_id).first()
    if not ban:
        raise HTTPException(status_code=404, detail="Event ban not found")
    return ban


@app.post("/event_bans", response_model=EventBanResponse, status_code=201)
async def create_event_ban(ban: EventBanCreate, db: Session = Depends(get_db)):
    """Ban a user from an event"""
    # Verify event exists
    event = db.query(Event).filter(Event.id == ban.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # Verify banned user exists
    user = db.query(User).filter(User.id == ban.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Verify banner exists
    banner = db.query(User).filter(User.id == ban.banned_by).first()
    if not banner:
        raise HTTPException(status_code=404, detail="Banner user not found")

    # Check if ban already exists
    existing = db.query(EventBan).filter(
        EventBan.event_id == ban.event_id,
        EventBan.user_id == ban.user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User is already banned from this event")

    db_ban = EventBan(**ban.dict())
    db.add(db_ban)
    db.commit()
    db.refresh(db_ban)
    return db_ban


@app.delete("/event_bans/{ban_id}")
async def delete_event_ban(ban_id: int, db: Session = Depends(get_db)):
    """Unban a user from an event"""
    db_ban = db.query(EventBan).filter(EventBan.id == ban_id).first()
    if not db_ban:
        raise HTTPException(status_code=404, detail="Event ban not found")

    db.delete(db_ban)
    db.commit()
    return {"message": "Event ban deleted successfully", "id": ban_id}


# ============================================================================
# USER BLOCKS ENDPOINTS
# ============================================================================

@app.get("/user_blocks", response_model=List[UserBlockResponse])
async def get_user_blocks(
    blocker_user_id: Optional[int] = None,
    blocked_user_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get all user blocks, optionally filtered by blocker or blocked user"""
    query = db.query(UserBlock)
    if blocker_user_id:
        query = query.filter(UserBlock.blocker_user_id == blocker_user_id)
    if blocked_user_id:
        query = query.filter(UserBlock.blocked_user_id == blocked_user_id)
    blocks = query.all()
    return blocks


@app.get("/user_blocks/{block_id}", response_model=UserBlockResponse)
async def get_user_block(block_id: int, db: Session = Depends(get_db)):
    """Get a single user block by ID"""
    block = db.query(UserBlock).filter(UserBlock.id == block_id).first()
    if not block:
        raise HTTPException(status_code=404, detail="User block not found")
    return block


@app.post("/user_blocks", response_model=UserBlockResponse, status_code=201)
async def create_user_block(block: UserBlockCreate, db: Session = Depends(get_db)):
    """Block a user"""
    # Verify blocker exists
    blocker = db.query(User).filter(User.id == block.blocker_user_id).first()
    if not blocker:
        raise HTTPException(status_code=404, detail="Blocker user not found")

    # Verify blocked user exists
    blocked = db.query(User).filter(User.id == block.blocked_user_id).first()
    if not blocked:
        raise HTTPException(status_code=404, detail="Blocked user not found")

    # Check if block already exists
    existing = db.query(UserBlock).filter(
        UserBlock.blocker_user_id == block.blocker_user_id,
        UserBlock.blocked_user_id == block.blocked_user_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="User is already blocked")

    db_block = UserBlock(**block.dict())
    db.add(db_block)
    db.commit()
    db.refresh(db_block)
    return db_block


@app.delete("/user_blocks/{block_id}")
async def delete_user_block(block_id: int, db: Session = Depends(get_db)):
    """Unblock a user"""
    db_block = db.query(UserBlock).filter(UserBlock.id == block_id).first()
    if not db_block:
        raise HTTPException(status_code=404, detail="User block not found")

    db.delete(db_block)
    db.commit()
    return {"message": "User block deleted successfully", "id": block_id}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
