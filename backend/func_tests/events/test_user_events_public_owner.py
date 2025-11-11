"""
Test que verifica que los eventos de usuarios públicos incluyen
correctamente al owner en attendees y owner_name en /users/{id}/events

Este test detecta el bug donde los owners públicos (restaurantes, gimnasios, etc.)
no aparecían en la lista de attendees del endpoint /users/{id}/events
"""

import pytest
from datetime import datetime, timedelta


def test_user_events_includes_public_owner_in_attendees(client):
    """
    Test que verifica que cuando un usuario está suscrito a eventos de un usuario público,
    el endpoint /users/{id}/events incluye:
    1. Al owner público en la lista de attendees
    2. Los campos owner_name, is_owner_public con los valores correctos

    Este test hubiera detectado el bug donde el owner público no aparecía
    al actualizar el evento vía realtime.
    """
    # Create public user (restaurant/gym/etc.)
    public_user_data = {
        "instagram_username": f"restaurant_{datetime.now().timestamp()}",
        "display_name": f"restaurant_{datetime.now().timestamp()}",
        "auth_provider": "instagram",
        "auth_id": f"ig_restaurant_{datetime.now().timestamp()}",
        "is_public": True,
    }
    public_user_response = client.post("/api/v1/users", json=public_user_data)
    assert public_user_response.status_code == 201
    public_user = public_user_response.json()

    # Create private user (subscriber)
    private_user_data = {
        "display_name": "Test Subscriber",
        "instagram_username": None,
        "phone": f"+2000{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+2000{int(datetime.now().timestamp())}",
        "is_public": False,
    }
    private_user_response = client.post("/api/v1/users", json=private_user_data)
    assert private_user_response.status_code == 201
    private_user = private_user_response.json()

    # Create event as public user
    event_data = {
        "name": "Wine Tasting Event",
        "description": "Special wine tasting with pairing",
        "start_date": (datetime.now() + timedelta(days=1)).isoformat(),
        "owner_id": public_user["id"],
    }
    client._auth_context["user_id"] = public_user["id"]
    event_response = client.post("/api/v1/events", json=event_data)
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
    client._auth_context["user_id"] = public_user["id"]
    client.post("/api/v1/interactions", json=owner_interaction_data)

    # Private user subscribes to event
    subscription_data = {
        "user_id": private_user["id"],
        "event_id": event["id"],
        "interaction_type": "subscribed",
        "status": "accepted",
    }
    client._auth_context["user_id"] = private_user["id"]
    sub_response = client.post("/api/v1/interactions", json=subscription_data)
    assert sub_response.status_code == 201

    import time

    time.sleep(1)  # Allow realtime to propagate

    # Get events for private user using /users/{id}/events endpoint
    client._auth_context["user_id"] = private_user["id"]
    user_events_response = client.get(f"/api/v1/users/{private_user['id']}/events")
    assert user_events_response.status_code == 200
    user_events = user_events_response.json()

    # Find the subscribed event
    subscribed_event = next((e for e in user_events if e["id"] == event["id"]), None)
    assert subscribed_event is not None, "Subscribed event should appear in user's events"

    # CRITICAL CHECKS - These would have failed before the fix

    # 1. Check owner_name is present
    assert "owner_name" in subscribed_event, "owner_name field must be present"
    assert subscribed_event["owner_name"] == public_user_data["display_name"], f"owner_name should be '{public_user_data['display_name']}', got '{subscribed_event.get('owner_name')}'"

    # 2. Check is_owner_public is correct
    assert "is_owner_public" in subscribed_event, "is_owner_public field must be present"
    assert subscribed_event["is_owner_public"] is True, "is_owner_public should be True for public owner"

    # 3. Check attendees does NOT include the public owner (public users are not physical attendees)
    assert "attendees" in subscribed_event, "attendees field must be present"
    assert subscribed_event["attendees"] is not None, "attendees should not be None"

    # Public owner should NOT be in attendees (they are organizations, not physical people)
    owner_in_attendees = next((a for a in subscribed_event["attendees"] if a["id"] == public_user["id"]), None)
    assert owner_in_attendees is None, f"Public owner (id={public_user['id']}) should NOT be in attendees list. " f"Public users (restaurants, gyms) are not physical attendees."

    # 4. Check that subscriber IS in attendees
    subscriber_in_attendees = next((a for a in subscribed_event["attendees"] if a["id"] == private_user["id"]), None)
    assert subscriber_in_attendees is not None, "Subscriber should also be in attendees"

    print("✅ All checks passed: Public owner info correctly provided in /users/{id}/events")
    print(f"   - owner_name: {subscribed_event['owner_name']}")
    print(f"   - is_owner_public: {subscribed_event['is_owner_public']}")
    print(f"   - Attendees count: {len(subscribed_event['attendees'])}")
    print(f"   - Public owner NOT in attendees (correct): ✓")


def test_user_events_preserves_owner_info_across_updates(client):
    """
    Test que verifica que la información del owner no se pierde
    después de actualizaciones del evento.

    Simula el escenario donde:
    1. Usuario ve el evento (carga datos completos)
    2. Evento se actualiza (vía realtime o manual)
    3. Usuario vuelve a consultar -> owner info debe seguir presente
    """
    # Setup: Create public user
    public_user_data = {
        "instagram_username": f"gym_{datetime.now().timestamp()}",
        "display_name": f"gym_{datetime.now().timestamp()}",
        "auth_provider": "instagram",
        "auth_id": f"ig_gym_{datetime.now().timestamp()}",
        "is_public": True,
    }
    public_user = client.post("/api/v1/users", json=public_user_data).json()

    private_user_data = {
        "display_name": "Test Member",
        "phone": f"+4000{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+4000{int(datetime.now().timestamp())}",
    }
    private_user = client.post("/api/v1/users", json=private_user_data).json()

    event_data = {
        "name": "Spinning Class",
        "description": "High intensity spinning",
        "start_date": (datetime.now() + timedelta(days=2)).isoformat(),
        "owner_id": public_user["id"],
    }
    client._auth_context["user_id"] = public_user["id"]
    event = client.post("/api/v1/events", json=event_data).json()

    # Create owner interaction
    owner_interaction_data = {
        "user_id": public_user["id"],
        "event_id": event["id"],
        "interaction_type": "joined",
        "status": "accepted",
        "role": "owner",
    }
    client._auth_context["user_id"] = public_user["id"]
    client.post("/api/v1/interactions", json=owner_interaction_data)

    subscription_data = {
        "user_id": private_user["id"],
        "event_id": event["id"],
        "interaction_type": "subscribed",
        "status": "accepted",
    }
    client._auth_context["user_id"] = private_user["id"]
    client.post("/api/v1/interactions", json=subscription_data)

    import time

    time.sleep(0.5)

    # First fetch - should have owner info
    client._auth_context["user_id"] = private_user["id"]
    first_fetch = client.get(f"/api/v1/users/{private_user['id']}/events").json()
    first_event = next((e for e in first_fetch if e["id"] == event["id"]), None)

    assert first_event is not None
    assert first_event["owner_name"] == public_user_data["display_name"]
    assert first_event["is_owner_public"] is True

    # Simulate an update (change event description)
    update_data = {"description": "Updated: High intensity spinning with music"}
    client._auth_context["user_id"] = public_user["id"]
    client.patch(f"/api/v1/events/{event['id']}", json=update_data)

    time.sleep(1)

    # Second fetch - owner info MUST still be present
    client._auth_context["user_id"] = private_user["id"]
    second_fetch = client.get(f"/api/v1/users/{private_user['id']}/events").json()
    second_event = next((e for e in second_fetch if e["id"] == event["id"]), None)

    assert second_event is not None, "Event should still be in user's events after update"

    # CRITICAL: Owner info must not be lost after update
    assert second_event["owner_name"] == public_user_data["display_name"], "owner_name must be preserved after event update"
    assert second_event["is_owner_public"] is True, "is_owner_public must be preserved after event update"

    # Check attendees still does NOT include public owner (they are not physical attendees)
    owner_still_in_attendees = any(a["id"] == public_user["id"] for a in second_event.get("attendees", []))
    assert not owner_still_in_attendees, "Public owner should NOT be in attendees (they are organizations, not physical people)"

    print("✅ Owner info preserved across updates")
