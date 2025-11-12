"""
Functional tests for Event Detail endpoint (GET /events/{id})

Tests the interactions and attendees fields added to support
Flutter event detail screen functionality.
"""

import pytest
from datetime import datetime, timedelta
from crud import user as user_crud, event as event_crud, event_interaction as interaction_crud
from schemas import UserCreate, EventCreate, EventInteractionCreate


@pytest.fixture
def test_users(test_db):
    """Create test users with new fields (no legacy Contact)"""
    # Create users directly with new fields (display_name, phone, instagram_username)
    user1_data = UserCreate(
        display_name="Owner User",
        phone="+1234567890",
        instagram_username="owner",
        auth_provider="test",
        auth_id="test_owner_123",
        is_public=False
    )
    user2_data = UserCreate(
        display_name="Invitee One",
        phone="+1234567891",
        instagram_username="invitee1",
        auth_provider="test",
        auth_id="test_invitee1_456",
        is_public=False
    )
    user3_data = UserCreate(
        display_name="Invitee Two",
        phone="+1234567892",
        instagram_username="invitee2",
        auth_provider="test",
        auth_id="test_invitee2_789",
        is_public=False
    )

    user1 = user_crud.create(test_db, obj_in=user1_data)
    user2 = user_crud.create(test_db, obj_in=user2_data)
    user3 = user_crud.create(test_db, obj_in=user3_data)

    test_db.commit()

    return user1, user2, user3


@pytest.fixture
def test_event_with_invitations(test_db, test_users):
    """Create event with invitations"""
    owner, invitee1, invitee2 = test_users

    # Create event
    event_data = EventCreate(name="Test Event", description="Event with invitations", start_date=datetime.now() + timedelta(days=1), owner_id=owner.id)
    event = event_crud.create(test_db, obj_in=event_data)

    # Create invitations
    # Invitee 1 - pending
    interaction1 = interaction_crud.create(test_db, obj_in=EventInteractionCreate(user_id=invitee1.id, event_id=event.id, interaction_type="invited", status="pending", invited_by_user_id=owner.id))

    # Invitee 2 - accepted
    interaction2 = interaction_crud.create(test_db, obj_in=EventInteractionCreate(user_id=invitee2.id, event_id=event.id, interaction_type="invited", status="accepted", invited_by_user_id=owner.id))

    test_db.commit()

    return event, owner, invitee1, invitee2, interaction1, interaction2


def test_get_event_as_owner_includes_all_interactions(client, test_event_with_invitations):
    """
    Owner debe ver todas las interacciones del evento con datos enriquecidos
    """
    event, owner, invitee1, invitee2, interaction1, interaction2 = test_event_with_invitations

    # Set auth context to owner
    client._auth_context["user_id"] = owner.id

    # Get event as owner
    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should have interactions field
    assert "interactions" in data
    assert data["interactions"] is not None
    assert len(data["interactions"]) == 2

    # Check first interaction (invitee1 - pending)
    interaction_data = next((i for i in data["interactions"] if i["user_id"] == invitee1.id), None)
    assert interaction_data is not None
    assert interaction_data["status"] == "pending"

    # Check user object is complete
    assert "user" in interaction_data
    assert interaction_data["user"]["id"] == invitee1.id
    assert interaction_data["user"]["display_name"] == "Invitee One"
    assert interaction_data["user"]["instagram_username"] == "invitee1"
    assert interaction_data["user"]["phone_number"] == "+1234567891"

    # Check inviter object is complete
    assert "inviter" in interaction_data
    assert interaction_data["inviter"]["id"] == owner.id
    assert interaction_data["inviter"]["display_name"] == "Owner User"
    assert interaction_data["inviter"]["instagram_username"] == "owner"

    # Check second interaction (invitee2 - accepted)
    interaction_data2 = next((i for i in data["interactions"] if i["user_id"] == invitee2.id), None)
    assert interaction_data2 is not None
    assert interaction_data2["status"] == "accepted"


def test_get_event_as_invitee_includes_only_own_interaction(client, test_event_with_invitations):
    """
    Invitado solo debe ver SU interacción, no la de otros
    """
    event, owner, invitee1, invitee2, interaction1, interaction2 = test_event_with_invitations

    # Set auth context to invitee1
    client._auth_context["user_id"] = invitee1.id

    # Get event as invitee1
    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should have interactions field with only ONE interaction
    assert "interactions" in data
    assert data["interactions"] is not None
    assert len(data["interactions"]) == 1

    # Should be invitee1's interaction
    interaction_data = data["interactions"][0]
    assert interaction_data["user_id"] == invitee1.id
    assert interaction_data["status"] == "pending"

    # Inviter should be present and complete
    assert "inviter" in interaction_data
    assert interaction_data["inviter"]["id"] == owner.id
    assert interaction_data["inviter"]["display_name"] == "Owner User"
    assert interaction_data["inviter"]["instagram_username"] == "owner"


def test_get_event_attendees_populated(client, test_db, test_users):
    """
    Campo attendees debe incluir usuarios que aceptaron la invitación
    """
    owner, invitee1, invitee2 = test_users

    # Create event
    event_data = EventCreate(name="Event with Attendees", description="Some accept, some reject", start_date=datetime.now() + timedelta(days=1), owner_id=owner.id)
    event = event_crud.create(test_db, obj_in=event_data)

    # Invitee 1 - accepts
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(user_id=invitee1.id, event_id=event.id, interaction_type="invited", status="accepted", invited_by_user_id=owner.id))

    # Invitee 2 - rejects
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(user_id=invitee2.id, event_id=event.id, interaction_type="invited", status="rejected", invited_by_user_id=owner.id))

    test_db.commit()

    # Set auth context to owner
    client._auth_context["user_id"] = owner.id

    # Get event
    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should have attendees field
    assert "attendees" in data
    assert data["attendees"] is not None

    # Should have only 1 attendee (invitee1 who accepted)
    assert len(data["attendees"]) == 1

    attendee = data["attendees"][0]
    assert attendee["id"] == invitee1.id
    assert attendee["display_name"] == "Invitee One"
    assert attendee["instagram_username"] == "invitee1"
    assert "profile_picture_url" in attendee
    assert attendee["phone"] == "+1234567891"


def test_get_event_inviter_object_complete(client, test_db, test_users):
    """
    Objeto inviter debe venir completo con todos los campos
    """
    owner, invitee1, invitee2 = test_users

    # Create event
    event_data = EventCreate(name="Event to test inviter", description="Testing inviter object", start_date=datetime.now() + timedelta(days=1), owner_id=owner.id)
    event = event_crud.create(test_db, obj_in=event_data)

    # Owner invites invitee1
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(user_id=invitee1.id, event_id=event.id, interaction_type="invited", status="pending", invited_by_user_id=owner.id))

    test_db.commit()

    # Get event as invitee1
    client._auth_context["user_id"] = invitee1.id

    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should have interactions with inviter
    assert "interactions" in data
    assert len(data["interactions"]) == 1

    interaction = data["interactions"][0]

    # Inviter should be complete
    assert "inviter" in interaction
    assert interaction["inviter"] is not None
    assert interaction["inviter"]["id"] == owner.id
    assert interaction["inviter"]["display_name"] == "Owner User"
    assert interaction["inviter"]["instagram_username"] == "owner"


def test_get_event_unauthenticated_no_interactions(client, test_db, test_users):
    """
    Usuario no autenticado NO debe ver campo interactions
    """
    owner, invitee1, invitee2 = test_users

    # Create public event
    event_data = EventCreate(name="Public Event", description="Should not show interactions to unauthenticated users", start_date=datetime.now() + timedelta(days=1), owner_id=owner.id)
    event = event_crud.create(test_db, obj_in=event_data)
    test_db.commit()

    # Clear auth context (unauthenticated)
    client._auth_context["user_id"] = None

    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should NOT have interactions field or it should be None
    if "interactions" in data:
        assert data["interactions"] is None

    # Should NOT have attendees field or it should be None
    if "attendees" in data:
        assert data["attendees"] is None


def test_get_event_admin_sees_all_interactions(client, test_db, test_users):
    """
    Admin de calendario ve todas las interacciones igual que owner
    """
    owner, invitee1, invitee2 = test_users

    # Import necessary modules
    from crud import calendar as calendar_crud, calendar_membership as membership_crud
    from schemas import CalendarCreate, CalendarMembershipCreate

    # Create a calendar
    calendar_data = CalendarCreate(name="Team Calendar", description="Shared team calendar", owner_id=owner.id)
    db_calendar, error = calendar_crud.create_with_validation(test_db, obj_in=calendar_data)
    assert error is None
    assert db_calendar is not None

    # Add invitee1 as admin of the calendar
    membership_data = CalendarMembershipCreate(calendar_id=db_calendar.id, user_id=invitee1.id, role="admin", status="accepted")
    db_membership, error = membership_crud.create_with_validation(test_db, obj_in=membership_data)
    assert error is None

    # Create event in the calendar (owned by owner, not invitee1)
    event_data = EventCreate(name="Calendar Event", description="Event in shared calendar", start_date=datetime.now() + timedelta(days=1), owner_id=owner.id, calendar_id=db_calendar.id)
    event = event_crud.create(test_db, obj_in=event_data)

    # Create interactions - invite invitee2
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(user_id=invitee2.id, event_id=event.id, interaction_type="invited", status="pending", invited_by_user_id=owner.id))

    test_db.commit()

    # Get event as invitee1 (who is admin of calendar, but not owner of event)
    client._auth_context["user_id"] = invitee1.id

    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # invitee1 is admin of calendar, so should see ALL interactions like owner
    assert "interactions" in data
    assert data["interactions"] is not None
    assert len(data["interactions"]) == 1  # Should see invitee2's interaction

    # Check interaction data
    interaction_data = data["interactions"][0]
    assert interaction_data["user_id"] == invitee2.id
    assert interaction_data["status"] == "pending"

    # Should also have invitation_stats
    assert "invitation_stats" in data


def test_get_event_attendees_filtered_by_invitation_relationship(client, test_db, test_users):
    """
    Test new smart filtering: When user was invited and accepted,
    should only see attendees related by the same inviter.

    Scenario:
    - Owner creates event
    - Owner invites: invitee1 (accepts), invitee2 (accepts)
    - invitee1 views event -> should see: owner + invitee2 (both related via owner's invitation)
    """
    owner, invitee1, invitee2 = test_users

    # Create additional user to act as independent subscriber
    user4_data = UserCreate(
        display_name="Independent User",
        phone="+1234567893",
        instagram_username="independent",
        auth_provider="test",
        auth_id="test_independent_999",
        is_public=False
    )
    independent_user = user_crud.create(test_db, obj_in=user4_data)

    # Create event
    event_data = EventCreate(
        name="Event with Invitation Groups",
        description="Testing attendee filtering by invitation relationship",
        start_date=datetime.now() + timedelta(days=1),
        owner_id=owner.id
    )
    event = event_crud.create(test_db, obj_in=event_data)

    # Owner has a "joined" interaction (as event owner)
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=owner.id,
        event_id=event.id,
        interaction_type="joined",
        status="accepted"
    ))

    # Owner invites invitee1 (accepts)
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=invitee1.id,
        event_id=event.id,
        interaction_type="invited",
        status="accepted",
        invited_by_user_id=owner.id
    ))

    # Owner invites invitee2 (accepts)
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=invitee2.id,
        event_id=event.id,
        interaction_type="invited",
        status="accepted",
        invited_by_user_id=owner.id
    ))

    # Independent user subscribes (not invited by anyone)
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=independent_user.id,
        event_id=event.id,
        interaction_type="subscribed",
        status="accepted"
    ))

    test_db.commit()

    # Get event as invitee1 (who was invited by owner and accepted)
    client._auth_context["user_id"] = invitee1.id

    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should have attendees field
    assert "attendees" in data
    assert data["attendees"] is not None

    # SMART FILTERING: Should only see attendees related by invitation:
    # - owner (the inviter)
    # - invitee2 (invited by same person - owner)
    # Should NOT see:
    # - independent_user (not related by invitation)
    # - invitee1 itself
    attendee_ids = [a["id"] for a in data["attendees"]]

    assert owner.id in attendee_ids, "Should see the inviter (owner)"
    assert invitee2.id in attendee_ids, "Should see other invitee who accepted (invitee2)"
    assert independent_user.id not in attendee_ids, "Should NOT see independent subscriber"
    assert invitee1.id not in attendee_ids, "Should NOT see self"
    assert len(data["attendees"]) == 2, "Should see exactly 2 attendees (owner + invitee2)"


def test_get_event_attendees_all_when_not_invited(client, test_db, test_users):
    """
    Test that when user was NOT invited (subscribed/joined/owner),
    they see ALL attendees (original behavior).

    Scenario:
    - Owner creates event
    - invitee1 subscribes (not invited)
    - invitee2 is invited and accepts
    - independent user subscribes
    - invitee1 views event -> should see ALL attendees
    """
    owner, invitee1, invitee2 = test_users

    # Create independent user
    user4_data = UserCreate(
        display_name="Independent User",
        phone="+1234567893",
        instagram_username="independent",
        auth_provider="test",
        auth_id="test_independent_998",
        is_public=False
    )
    independent_user = user_crud.create(test_db, obj_in=user4_data)

    # Create event
    event_data = EventCreate(
        name="Event with Mixed Attendees",
        description="Testing attendee filtering when user subscribed (not invited)",
        start_date=datetime.now() + timedelta(days=1),
        owner_id=owner.id
    )
    event = event_crud.create(test_db, obj_in=event_data)

    # Owner has joined interaction
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=owner.id,
        event_id=event.id,
        interaction_type="joined",
        status="accepted"
    ))

    # invitee1 subscribes (NOT invited)
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=invitee1.id,
        event_id=event.id,
        interaction_type="subscribed",
        status="accepted"
    ))

    # invitee2 is invited by owner and accepts
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=invitee2.id,
        event_id=event.id,
        interaction_type="invited",
        status="accepted",
        invited_by_user_id=owner.id
    ))

    # Independent user subscribes
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=independent_user.id,
        event_id=event.id,
        interaction_type="subscribed",
        status="accepted"
    ))

    test_db.commit()

    # Get event as invitee1 (who subscribed, was NOT invited)
    client._auth_context["user_id"] = invitee1.id

    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should have attendees field
    assert "attendees" in data
    assert data["attendees"] is not None

    # NO FILTERING: Should see ALL attendees since invitee1 was not invited
    attendee_ids = [a["id"] for a in data["attendees"]]

    assert owner.id in attendee_ids, "Should see owner"
    assert invitee2.id in attendee_ids, "Should see invited user"
    assert independent_user.id in attendee_ids, "Should see independent subscriber"
    # invitee1 should not see themselves
    assert invitee1.id not in attendee_ids
    assert len(data["attendees"]) == 3, "Should see 3 attendees (owner + invitee2 + independent)"


def test_get_event_attendees_excludes_rejected(client, test_db, test_users):
    """
    Test that rejected invitations don't appear in attendees,
    even when using smart filtering.

    Scenario:
    - Owner invites: invitee1 (accepts), invitee2 (rejects)
    - invitee1 views event -> should only see owner (not invitee2)
    """
    owner, invitee1, invitee2 = test_users

    # Create event
    event_data = EventCreate(
        name="Event with Rejected Invitation",
        description="Testing that rejected invitations are excluded",
        start_date=datetime.now() + timedelta(days=1),
        owner_id=owner.id
    )
    event = event_crud.create(test_db, obj_in=event_data)

    # Owner joined
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=owner.id,
        event_id=event.id,
        interaction_type="joined",
        status="accepted"
    ))

    # Owner invites invitee1 (accepts)
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=invitee1.id,
        event_id=event.id,
        interaction_type="invited",
        status="accepted",
        invited_by_user_id=owner.id
    ))

    # Owner invites invitee2 (REJECTS)
    interaction_crud.create(test_db, obj_in=EventInteractionCreate(
        user_id=invitee2.id,
        event_id=event.id,
        interaction_type="invited",
        status="rejected",
        invited_by_user_id=owner.id
    ))

    test_db.commit()

    # Get event as invitee1
    client._auth_context["user_id"] = invitee1.id

    response = client.get(f"/api/v1/events/{event.id}")

    assert response.status_code == 200
    data = response.json()

    # Should have attendees field
    assert "attendees" in data
    attendee_ids = [a["id"] for a in data["attendees"]]

    # Should see owner, but NOT invitee2 (who rejected)
    assert owner.id in attendee_ids
    assert invitee2.id not in attendee_ids, "Should NOT see user who rejected invitation"
    assert len(data["attendees"]) == 1, "Should only see owner"
