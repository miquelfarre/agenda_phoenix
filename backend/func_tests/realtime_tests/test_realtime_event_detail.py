"""
Realtime CDC tests for Event Detail interactions and attendees

Tests that changes to event interactions trigger realtime updates
with correct interactions and attendees data.
"""

import os
import pytest
import asyncio
from datetime import datetime, timedelta
import requests

# Database config (same as other realtime tests)
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "database": os.getenv("POSTGRES_DB", "postgres"),
    "user": os.getenv("POSTGRES_USER", "postgres"),
    "password": os.getenv("POSTGRES_PASSWORD", "your-super-secret-and-long-postgres-password"),
}

API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8001/api/v1")


def api_request(method, endpoint, user_id=None, json=None, params=None):
    """Make API request with optional X-Test-User-Id header"""
    url = f"{API_BASE_URL}{endpoint}"
    headers = {}
    if user_id is not None:
        headers["X-Test-User-Id"] = str(user_id)

    if method == "GET":
        response = requests.get(url, headers=headers, params=params)
    elif method == "POST":
        response = requests.post(url, headers=headers, json=json)
    elif method == "PATCH":
        response = requests.patch(url, headers=headers, json=json)
    elif method == "DELETE":
        response = requests.delete(url, headers=headers)
    else:
        raise ValueError(f"Unsupported method: {method}")

    return response


def test_realtime_new_invitation_triggers_update():
    """
    Nueva invitación debe disparar evento realtime con interactions actualizadas
    """
    # Create users
    user1_data = {
        "display_name": "Event Owner",
        "username": f"owner_{datetime.now().timestamp()}",
        "phone": f"+1{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_owner_{datetime.now().timestamp()}",
    }
    user2_data = {
        "display_name": "New Invitee",
        "username": f"invitee_{datetime.now().timestamp()}",
        "phone": f"+2{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_invitee_{datetime.now().timestamp()}",
    }

    user1_response = api_request("POST", "/users", json=user1_data)
    user2_response = api_request("POST", "/users", json=user2_data)

    assert user1_response.status_code == 201
    assert user2_response.status_code == 201

    user1 = user1_response.json()
    user2 = user2_response.json()

    # Create event as user1
    event_data = {
        "name": "Event for invitation test",
        "description": "Testing new invitation",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": user1["id"],
    }

    event_response = api_request("POST", "/events", user_id=user1["id"], json=event_data)
    assert event_response.status_code == 201
    event = event_response.json()

    # Get event before invitation
    before_response = api_request("GET", f"/events/{event['id']}", user_id=user1["id"])
    assert before_response.status_code == 200
    before_data = before_response.json()

    # Interactions should be empty or None initially
    initial_interactions = before_data.get("interactions", []) or []
    initial_count = len(initial_interactions)

    # Invite user2
    invitation_data = {
        "user_id": user2["id"],
        "event_id": event["id"],
        "interaction_type": "invited",
        "status": "pending",
        "invited_by_user_id": user1["id"],
    }

    invite_response = api_request("POST", "/interactions", user_id=user1["id"], json=invitation_data)
    assert invite_response.status_code == 201

    # Give realtime a moment to propagate
    import time

    time.sleep(1)

    # Get event after invitation (as owner)
    after_response = api_request("GET", f"/events/{event['id']}", user_id=user1["id"])
    assert after_response.status_code == 200
    after_data = after_response.json()

    # Should have interactions field with new invitation
    assert "interactions" in after_data
    assert after_data["interactions"] is not None
    assert len(after_data["interactions"]) == initial_count + 1

    # Find the new invitation
    new_invitation = next((i for i in after_data["interactions"] if i["user_id"] == user2["id"]), None)

    assert new_invitation is not None
    assert new_invitation["status"] == "pending"
    # Check that user info is present (backend may return username or contact_name depending on data)
    assert "user" in new_invitation
    assert new_invitation["user"]["id"] == user2["id"]
    assert new_invitation["inviter"]["id"] == user1["id"]


def test_realtime_accept_invitation_updates_interactions():
    """
    Aceptar invitación actualiza interactions y attendees en realtime
    """
    # Create users
    user1_data = {
        "display_name": "Owner Accept Test",
        "username": f"owner_accept_{datetime.now().timestamp()}",
        "phone": f"+3{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_owner_accept_{datetime.now().timestamp()}",
    }
    user2_data = {
        "display_name": "Invitee Accept Test",
        "username": f"invitee_accept_{datetime.now().timestamp()}",
        "phone": f"+4{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_invitee_accept_{datetime.now().timestamp()}",
    }

    user1 = api_request("POST", "/users", json=user1_data).json()
    user2 = api_request("POST", "/users", json=user2_data).json()

    # Create event and invite user2
    event_data = {
        "name": "Event for accept test",
        "description": "Testing accept invitation",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": user1["id"],
    }
    event = api_request("POST", "/events", user_id=user1["id"], json=event_data).json()

    invitation_data = {
        "user_id": user2["id"],
        "event_id": event["id"],
        "interaction_type": "invited",
        "status": "pending",
        "invited_by_user_id": user1["id"],
    }
    interaction = api_request("POST", "/interactions", user_id=user1["id"], json=invitation_data).json()

    # Accept invitation
    update_data = {"status": "accepted"}
    api_request("PATCH", f"/interactions/{interaction['id']}", user_id=user2["id"], json=update_data)

    import time

    time.sleep(1)

    # Get event as owner - should see updated status
    event_response = api_request("GET", f"/events/{event['id']}", user_id=user1["id"])
    event_data = event_response.json()

    # Check interactions updated
    assert "interactions" in event_data
    user2_interaction = next((i for i in event_data["interactions"] if i["user_id"] == user2["id"]), None)
    assert user2_interaction is not None
    assert user2_interaction["status"] == "accepted"

    # Check attendees includes user2
    assert "attendees" in event_data
    assert event_data["attendees"] is not None
    user2_attendee = next((a for a in event_data["attendees"] if a["id"] == user2["id"]), None)
    assert user2_attendee is not None
    # Backend returns new fields (display_name, instagram_username)
    assert "display_name" in user2_attendee
    assert user2_attendee["display_name"] == user2_data["display_name"]


def test_realtime_reject_invitation_updates_interactions():
    """
    Rechazar invitación actualiza status en realtime
    """
    # Create users
    user1_data = {
        "display_name": "Owner Reject Test",
        "username": f"owner_reject_{datetime.now().timestamp()}",
        "phone": f"+5{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_owner_reject_{datetime.now().timestamp()}",
    }
    user2_data = {
        "display_name": "Invitee Reject Test",
        "username": f"invitee_reject_{datetime.now().timestamp()}",
        "phone": f"+6{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_invitee_reject_{datetime.now().timestamp()}",
    }

    user1 = api_request("POST", "/users", json=user1_data).json()
    user2 = api_request("POST", "/users", json=user2_data).json()

    # Create event and invite user2
    event_data = {
        "name": "Event for reject test",
        "description": "Testing reject invitation",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": user1["id"],
    }
    event = api_request("POST", "/events", user_id=user1["id"], json=event_data).json()

    invitation_data = {
        "user_id": user2["id"],
        "event_id": event["id"],
        "interaction_type": "invited",
        "status": "pending",
        "invited_by_user_id": user1["id"],
    }
    interaction = api_request("POST", "/interactions", user_id=user1["id"], json=invitation_data).json()

    # Reject invitation
    update_data = {"status": "rejected"}
    api_request("PATCH", f"/interactions/{interaction['id']}", user_id=user2["id"], json=update_data)

    import time

    time.sleep(1)

    # Get event as owner - should see rejected status
    event_response = api_request("GET", f"/events/{event['id']}", user_id=user1["id"])
    event_data = event_response.json()

    # Check interactions updated
    user2_interaction = next((i for i in event_data["interactions"] if i["user_id"] == user2["id"]), None)
    assert user2_interaction is not None
    assert user2_interaction["status"] == "rejected"

    # Check user2 NOT in attendees
    attendees = event_data.get("attendees", []) or []
    user2_in_attendees = any(a["id"] == user2["id"] for a in attendees)
    assert not user2_in_attendees


def test_realtime_leave_event_removes_from_interactions():
    """
    Abandonar evento elimina la interacción en realtime
    """
    # Create users
    user1_data = {
        "display_name": "Owner Leave Test",
        "username": f"owner_leave_{datetime.now().timestamp()}",
        "phone": f"+7{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_owner_leave_{datetime.now().timestamp()}",
    }
    user2_data = {
        "display_name": "Invitee Leave Test",
        "username": f"invitee_leave_{datetime.now().timestamp()}",
        "phone": f"+8{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_invitee_leave_{datetime.now().timestamp()}",
    }

    user1 = api_request("POST", "/users", json=user1_data).json()
    user2 = api_request("POST", "/users", json=user2_data).json()

    # Create event and invite user2
    event_data = {
        "name": "Event for leave test",
        "description": "Testing leave event",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": user1["id"],
    }
    event = api_request("POST", "/events", user_id=user1["id"], json=event_data).json()

    invitation_data = {
        "user_id": user2["id"],
        "event_id": event["id"],
        "interaction_type": "invited",
        "status": "accepted",
        "invited_by_user_id": user1["id"],
    }
    api_request("POST", "/interactions", user_id=user1["id"], json=invitation_data)

    import time

    time.sleep(0.5)

    # User2 leaves event
    api_request("DELETE", f"/events/{event['id']}/interaction", user_id=user2["id"])

    time.sleep(1)

    # Get event as owner - user2 should be gone
    event_response = api_request("GET", f"/events/{event['id']}", user_id=user1["id"])
    event_data = event_response.json()

    # Check user2 NOT in interactions
    interactions = event_data.get("interactions", []) or []
    user2_in_interactions = any(i["user_id"] == user2["id"] for i in interactions)
    assert not user2_in_interactions

    # Check user2 NOT in attendees
    attendees = event_data.get("attendees", []) or []
    user2_in_attendees = any(a["id"] == user2["id"] for a in attendees)
    assert not user2_in_attendees


def test_realtime_update_note_reflects_in_interactions():
    """
    Actualizar nota personal se refleja en realtime
    """
    # Create users
    user1_data = {
        "display_name": "Owner Note Test",
        "username": f"owner_note_{datetime.now().timestamp()}",
        "phone": f"+9{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_owner_note_{datetime.now().timestamp()}",
    }
    user2_data = {
        "display_name": "Invitee Note Test",
        "username": f"invitee_note_{datetime.now().timestamp()}",
        "phone": f"+10{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_invitee_note_{datetime.now().timestamp()}",
    }

    user1 = api_request("POST", "/users", json=user1_data).json()
    user2 = api_request("POST", "/users", json=user2_data).json()

    # Create event and invite user2
    event_data = {
        "name": "Event for note test",
        "description": "Testing note update",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": user1["id"],
    }
    event = api_request("POST", "/events", user_id=user1["id"], json=event_data).json()

    invitation_data = {
        "user_id": user2["id"],
        "event_id": event["id"],
        "interaction_type": "invited",
        "status": "accepted",
        "invited_by_user_id": user1["id"],
    }
    api_request("POST", "/interactions", user_id=user1["id"], json=invitation_data)

    # User2 adds a personal note
    note_data = {"personal_note": "My personal reminder for this event"}
    api_request("PATCH", f"/events/{event['id']}/interaction", user_id=user2["id"], json=note_data)

    import time

    time.sleep(1)

    # Get event as user2 - should see note in their interaction
    event_response = api_request("GET", f"/events/{event['id']}", user_id=user2["id"])
    event_data = event_response.json()

    # Check note is present
    assert "interactions" in event_data
    assert len(event_data["interactions"]) == 1
    assert event_data["interactions"][0]["personal_note"] == "My personal reminder for this event"


def test_realtime_mark_read_updates_read_at():
    """
    Marcar como leído actualiza read_at en realtime
    """
    # Create users
    user1_data = {
        "display_name": "Owner Read Test",
        "username": f"owner_read_{datetime.now().timestamp()}",
        "phone": f"+11{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_owner_read_{datetime.now().timestamp()}",
    }
    user2_data = {
        "display_name": "Invitee Read Test",
        "username": f"invitee_read_{datetime.now().timestamp()}",
        "phone": f"+12{int(datetime.now().timestamp())}",
        "auth_provider": "test",
        "auth_id": f"test_invitee_read_{datetime.now().timestamp()}",
    }

    user1 = api_request("POST", "/users", json=user1_data).json()
    user2 = api_request("POST", "/users", json=user2_data).json()

    # Create event and invite user2
    event_data = {
        "name": "Event for read test",
        "description": "Testing mark as read",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": user1["id"],
    }
    event = api_request("POST", "/events", user_id=user1["id"], json=event_data).json()

    invitation_data = {
        "user_id": user2["id"],
        "event_id": event["id"],
        "interaction_type": "invited",
        "status": "pending",
        "invited_by_user_id": user1["id"],
    }
    interaction = api_request("POST", "/interactions", user_id=user1["id"], json=invitation_data).json()

    # User2 marks invitation as read
    api_request("POST", f"/interactions/{interaction['id']}/mark-read", user_id=user2["id"])

    import time

    time.sleep(1)

    # Get event as user2 - read_at should be set
    event_response = api_request("GET", f"/events/{event['id']}", user_id=user2["id"])
    event_data = event_response.json()

    assert "interactions" in event_data
    assert len(event_data["interactions"]) == 1
    assert event_data["interactions"][0]["read_at"] is not None
    # Verify it's a valid timestamp
    read_at = event_data["interactions"][0]["read_at"]
    assert isinstance(read_at, str)
    assert "T" in read_at  # ISO format timestamp
