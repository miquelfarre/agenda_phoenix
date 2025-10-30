"""
Test que verifica que los eventos de usuarios públicos incluyen
correctamente al owner en attendees y owner_name en /users/{id}/events

Este test detecta el bug donde los owners públicos (restaurantes, gimnasios, etc.)
no aparecían en la lista de attendees del endpoint /users/{id}/events
"""

import os
import pytest
import requests
from datetime import datetime, timedelta

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


def test_user_events_includes_public_owner_in_attendees():
    """
    Test que verifica que cuando un usuario está suscrito a eventos de un usuario público,
    el endpoint /users/{id}/events incluye:
    1. Al owner público en la lista de attendees
    2. Los campos owner_name, is_owner_public con los valores correctos

    Este test hubiera detectado el bug donde el owner público no aparecía
    al actualizar el evento vía realtime.
    """
    # Create contact for public user
    contact_data = {
        "name": "Test Restaurant",
        "phone": f"+1000{int(datetime.now().timestamp())}",
    }
    contact_response = api_request("POST", "/contacts", json=contact_data)
    assert contact_response.status_code == 201
    contact = contact_response.json()

    # Create public user (restaurant/gym/etc.)
    public_user_data = {
        "contact_id": contact["id"],
        "username": f"restaurant_{datetime.now().timestamp()}",
        "auth_provider": "instagram",
        "auth_id": f"ig_restaurant_{datetime.now().timestamp()}",
        "is_public": True,
    }
    public_user_response = api_request("POST", "/users", json=public_user_data)
    assert public_user_response.status_code == 201
    public_user = public_user_response.json()

    # Create private user (subscriber)
    private_user_data = {
        "full_name": "Test Subscriber",
        "username": None,
        "phone_number": f"+2000{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+2000{int(datetime.now().timestamp())}",
        "is_public": False,
    }
    private_user_response = api_request("POST", "/users", json=private_user_data)
    assert private_user_response.status_code == 201
    private_user = private_user_response.json()

    # Create event as public user
    event_data = {
        "name": "Wine Tasting Event",
        "description": "Special wine tasting with pairing",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": public_user["id"],
    }
    event_response = api_request("POST", "/events", user_id=public_user["id"], json=event_data)
    assert event_response.status_code == 201
    event = event_response.json()

    # Create owner interaction (this is not automatic in API but done in init_db.py)
    owner_interaction_data = {
        "user_id": public_user["id"],
        "event_id": event["id"],
        "interaction_type": "joined",
        "status": "accepted",
        "role": "owner",
    }
    api_request("POST", "/interactions", user_id=public_user["id"], json=owner_interaction_data)

    # Private user subscribes to event
    subscription_data = {
        "user_id": private_user["id"],
        "event_id": event["id"],
        "interaction_type": "subscribed",
        "status": "accepted",
    }
    sub_response = api_request("POST", "/interactions", user_id=private_user["id"], json=subscription_data)
    assert sub_response.status_code == 201

    import time
    time.sleep(1)  # Allow realtime to propagate

    # Get events for private user using /users/{id}/events endpoint
    user_events_response = api_request("GET", f"/users/{private_user['id']}/events", user_id=private_user["id"])
    assert user_events_response.status_code == 200
    user_events = user_events_response.json()

    # Find the subscribed event
    subscribed_event = next((e for e in user_events if e["id"] == event["id"]), None)
    assert subscribed_event is not None, "Subscribed event should appear in user's events"

    # CRITICAL CHECKS - These would have failed before the fix

    # 1. Check owner_name is present
    assert "owner_name" in subscribed_event, "owner_name field must be present"
    assert subscribed_event["owner_name"] == contact_data["name"], \
        f"owner_name should be '{contact_data['name']}', got '{subscribed_event.get('owner_name')}'"

    # 2. Check is_owner_public is correct
    assert "is_owner_public" in subscribed_event, "is_owner_public field must be present"
    assert subscribed_event["is_owner_public"] is True, \
        "is_owner_public should be True for public owner"

    # 3. Check attendees does NOT include the public owner (public users are not physical attendees)
    assert "attendees" in subscribed_event, "attendees field must be present"
    assert subscribed_event["attendees"] is not None, "attendees should not be None"

    # Public owner should NOT be in attendees (they are organizations, not physical people)
    owner_in_attendees = next(
        (a for a in subscribed_event["attendees"] if a["id"] == public_user["id"]),
        None
    )
    assert owner_in_attendees is None, \
        f"Public owner (id={public_user['id']}) should NOT be in attendees list. " \
        f"Public users (restaurants, gyms) are not physical attendees."

    # 4. Check that subscriber IS in attendees
    subscriber_in_attendees = next(
        (a for a in subscribed_event["attendees"] if a["id"] == private_user["id"]),
        None
    )
    assert subscriber_in_attendees is not None, \
        "Subscriber should also be in attendees"

    print("✅ All checks passed: Public owner info correctly provided in /users/{id}/events")
    print(f"   - owner_name: {subscribed_event['owner_name']}")
    print(f"   - is_owner_public: {subscribed_event['is_owner_public']}")
    print(f"   - Attendees count: {len(subscribed_event['attendees'])}")
    print(f"   - Public owner NOT in attendees (correct): ✓")


def test_user_events_preserves_owner_info_across_updates():
    """
    Test que verifica que la información del owner no se pierde
    después de actualizaciones del evento.

    Simula el escenario donde:
    1. Usuario ve el evento (carga datos completos)
    2. Evento se actualiza (vía realtime o manual)
    3. Usuario vuelve a consultar -> owner info debe seguir presente
    """
    # Setup: Create contact and public user
    contact_data = {
        "name": "Test Gym",
        "phone": f"+3000{int(datetime.now().timestamp())}",
    }
    contact = api_request("POST", "/contacts", json=contact_data).json()

    public_user_data = {
        "contact_id": contact["id"],
        "username": f"gym_{datetime.now().timestamp()}",
        "auth_provider": "instagram",
        "auth_id": f"ig_gym_{datetime.now().timestamp()}",
        "is_public": True,
    }
    public_user = api_request("POST", "/users", json=public_user_data).json()

    private_user_data = {
        "full_name": "Test Member",
        "phone_number": f"+4000{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+4000{int(datetime.now().timestamp())}",
    }
    private_user = api_request("POST", "/users", json=private_user_data).json()

    event_data = {
        "name": "Spinning Class",
        "description": "High intensity spinning",
        "start_date": (datetime.now() + timedelta(days=2)).isoformat(),
        "owner_id": public_user["id"],
    }
    event = api_request("POST", "/events", user_id=public_user["id"], json=event_data).json()

    # Create owner interaction
    owner_interaction_data = {
        "user_id": public_user["id"],
        "event_id": event["id"],
        "interaction_type": "joined",
        "status": "accepted",
        "role": "owner",
    }
    api_request("POST", "/interactions", user_id=public_user["id"], json=owner_interaction_data)

    subscription_data = {
        "user_id": private_user["id"],
        "event_id": event["id"],
        "interaction_type": "subscribed",
        "status": "accepted",
    }
    api_request("POST", "/interactions", user_id=private_user["id"], json=subscription_data)

    import time
    time.sleep(0.5)

    # First fetch - should have owner info
    first_fetch = api_request("GET", f"/users/{private_user['id']}/events", user_id=private_user["id"]).json()
    first_event = next((e for e in first_fetch if e["id"] == event["id"]), None)

    assert first_event is not None
    assert first_event["owner_name"] == contact_data["name"]
    assert first_event["is_owner_public"] is True

    # Simulate an update (change event description)
    update_data = {"description": "Updated: High intensity spinning with music"}
    api_request("PATCH", f"/events/{event['id']}", user_id=public_user["id"], json=update_data)

    time.sleep(1)

    # Second fetch - owner info MUST still be present
    second_fetch = api_request("GET", f"/users/{private_user['id']}/events", user_id=private_user["id"]).json()
    second_event = next((e for e in second_fetch if e["id"] == event["id"]), None)

    assert second_event is not None, "Event should still be in user's events after update"

    # CRITICAL: Owner info must not be lost after update
    assert second_event["owner_name"] == contact_data["name"], \
        "owner_name must be preserved after event update"
    assert second_event["is_owner_public"] is True, \
        "is_owner_public must be preserved after event update"

    # Check attendees still does NOT include public owner (they are not physical attendees)
    owner_still_in_attendees = any(
        a["id"] == public_user["id"]
        for a in second_event.get("attendees", [])
    )
    assert not owner_still_in_attendees, \
        "Public owner should NOT be in attendees (they are organizations, not physical people)"

    print("✅ Owner info preserved across updates")
