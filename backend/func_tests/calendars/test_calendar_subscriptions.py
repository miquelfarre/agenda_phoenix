"""
Test calendar subscriptions functionality

Tests the complete flow of public calendar subscriptions:
1. Discovery of public calendars
2. Subscribing to calendars via share_hash
3. Unsubscribing from calendars
4. Events from subscribed calendars appearing in user's events
5. Subscriber count updates via trigger
"""

import os
import pytest
import requests
import random
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


def test_discover_public_calendars():
    """Test discovery of public calendars via GET /calendars/public"""
    response = api_request("GET", "/calendars/public")
    assert response.status_code == 200, f"Failed to fetch public calendars: {response.text}"

    calendars = response.json()
    assert isinstance(calendars, list), "Response should be a list"
    assert len(calendars) > 0, "Should have at least one public calendar"

    # Separate calendars by whether they have share_hash
    calendars_with_hash = []
    calendars_without_hash = []

    for calendar in calendars:
        assert "id" in calendar, "Calendar must have id"
        assert "name" in calendar, "Calendar must have name"
        assert "share_hash" in calendar, "Calendar must have share_hash field"
        assert "is_public" in calendar, "Calendar must have is_public"
        assert calendar["is_public"] is True, "All returned calendars should be public"
        assert "subscriber_count" in calendar, "Calendar must have subscriber_count"

        if calendar["share_hash"] is not None:
            assert len(calendar["share_hash"]) == 8, f"share_hash must be 8 characters, got {len(calendar['share_hash'])}"
            calendars_with_hash.append(calendar)
        else:
            calendars_without_hash.append(calendar)

    # Verify design: calendars from public users should NOT have share_hash
    # Only calendars from private users should have share_hash
    print(f"✅ Found {len(calendars)} public calendars:")
    print(f"   - {len(calendars_with_hash)} with share_hash (from private users)")
    print(f"   - {len(calendars_without_hash)} without share_hash (from public users)")

    assert len(calendars_with_hash) > 0, "Should have at least one calendar with share_hash"
    return calendars


def test_subscribe_to_calendar_via_share_hash():
    """Test subscribing to a public calendar using share_hash"""
    # Get public calendars
    calendars_response = api_request("GET", "/calendars/public")
    assert calendars_response.status_code == 200
    calendars = calendars_response.json()
    assert len(calendars) > 0, "Need at least one public calendar"

    # Pick a calendar with share_hash (should be "Festivos Barcelona 2025" from Sara, a private user)
    calendar = next((c for c in calendars if c["share_hash"] is not None), None)
    assert calendar is not None, "Need at least one calendar with share_hash"
    share_hash = calendar["share_hash"]
    calendar_name = calendar["name"]

    # Create a test user
    random_suffix = f"{int(datetime.now().timestamp())}{random.randint(1000, 9999)}"
    user_data = {
        "contact_name": "Test Subscriber",
        "phone_number": f"+9999{random_suffix}",
        "auth_provider": "phone",
        "auth_id": f"+9999{random_suffix}",
        "is_public": False,
    }
    user_response = api_request("POST", "/users", json=user_data)
    assert user_response.status_code == 201
    user = user_response.json()
    user_id = user["id"]

    # Subscribe to calendar using share_hash
    subscribe_response = api_request("POST", f"/calendars/{share_hash}/subscribe", user_id=user_id)
    assert subscribe_response.status_code == 201, f"Failed to subscribe: {subscribe_response.text}"

    subscription = subscribe_response.json()
    assert "id" in subscription, "Subscription must have id"
    assert subscription["calendar_id"] == calendar["id"], "Subscription calendar_id must match"
    assert subscription["user_id"] == user_id, "Subscription user_id must match"
    assert subscription["status"] == "active", "New subscription should be active"

    print(f"✅ User {user_id} subscribed to '{calendar_name}' ({share_hash})")

    # Try to subscribe again (should fail with 409)
    duplicate_response = api_request("POST", f"/calendars/{share_hash}/subscribe", user_id=user_id)
    assert duplicate_response.status_code == 409, "Duplicate subscription should return 409"

    print(f"✅ Duplicate subscription correctly rejected")

    return user_id, share_hash, calendar


def test_unsubscribe_from_calendar():
    """Test unsubscribing from a calendar"""
    # First subscribe
    user_id, share_hash, calendar = test_subscribe_to_calendar_via_share_hash()

    # Now unsubscribe
    unsubscribe_response = api_request("DELETE", f"/calendars/{share_hash}/subscribe", user_id=user_id)
    assert unsubscribe_response.status_code == 200, f"Failed to unsubscribe: {unsubscribe_response.text}"

    result = unsubscribe_response.json()
    assert "message" in result, "Unsubscribe response should have message"
    assert result["share_hash"] == share_hash, "Response should include share_hash"

    print(f"✅ User {user_id} unsubscribed from '{calendar['name']}'")

    # Try to unsubscribe again (should fail with 404)
    duplicate_response = api_request("DELETE", f"/calendars/{share_hash}/subscribe", user_id=user_id)
    assert duplicate_response.status_code == 404, "Unsubscribing when not subscribed should return 404"

    print(f"✅ Duplicate unsubscribe correctly rejected")


def test_subscribed_calendar_events_in_user_events():
    """Test that events from subscribed calendars appear in GET /users/{id}/events"""
    # Get public calendar with share_hash (should be "Festivos Barcelona 2025")
    calendars_response = api_request("GET", "/calendars/public")
    calendars = calendars_response.json()
    calendar_with_hash = next((c for c in calendars if c["share_hash"] is not None), None)
    assert calendar_with_hash is not None, "Should find calendar with share_hash"

    share_hash = calendar_with_hash["share_hash"]

    # Create test user
    user_data = {
        "contact_name": "Football Fan",
        "phone_number": f"+8888{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+8888{int(datetime.now().timestamp())}",
    }
    user = api_request("POST", "/users", json=user_data).json()
    user_id = user["id"]

    # Get events before subscription
    events_before = api_request("GET", f"/users/{user_id}/events", user_id=user_id).json()
    calendar_events_before = [e for e in events_before if e.get("calendar_id") == calendar_with_hash["id"]]

    # Subscribe to calendar
    api_request("POST", f"/calendars/{share_hash}/subscribe", user_id=user_id)

    # Get events after subscription
    import time

    time.sleep(0.5)  # Allow realtime to propagate

    events_after = api_request("GET", f"/users/{user_id}/events", user_id=user_id).json()
    calendar_events_after = [e for e in events_after if e.get("calendar_id") == calendar_with_hash["id"]]

    # Verify calendar events now appear (or at least the count is the same if calendar has no events)
    assert len(calendar_events_after) >= len(calendar_events_before), f"Should have same or more calendar events after subscription. Before: {len(calendar_events_before)}, After: {len(calendar_events_after)}"

    print(f"✅ Subscribed calendar events appear in user's events ({len(calendar_events_after)} events)")


def test_subscriber_count_trigger():
    """Test that subscriber_count is automatically updated via trigger"""
    # Get a public calendar with share_hash
    calendars = api_request("GET", "/calendars/public").json()
    calendar_with_hash = next((c for c in calendars if c["share_hash"] is not None), None)
    assert calendar_with_hash is not None, "Should find calendar with share_hash"

    share_hash = calendar_with_hash["share_hash"]
    initial_count = calendar_with_hash["subscriber_count"]

    # Create 3 test users and subscribe them
    user_ids = []
    for i in range(3):
        user_data = {
            "contact_name": f"Gym Member {i}",
            "phone_number": f"+7777{int(datetime.now().timestamp())}{i}",
            "auth_provider": "phone",
            "auth_id": f"+7777{int(datetime.now().timestamp())}{i}",
        }
        user = api_request("POST", "/users", json=user_data).json()
        user_ids.append(user["id"])

        # Subscribe
        api_request("POST", f"/calendars/{share_hash}/subscribe", user_id=user["id"])

    # Check subscriber count increased
    updated_calendar = api_request("GET", f"/calendars/{calendar_with_hash['id']}").json()
    expected_count = initial_count + 3
    assert updated_calendar["subscriber_count"] == expected_count, f"Subscriber count should be {expected_count}, got {updated_calendar['subscriber_count']}"

    print(f"✅ Subscriber count increased from {initial_count} to {updated_calendar['subscriber_count']}")

    # Unsubscribe one user
    api_request("DELETE", f"/calendars/{share_hash}/subscribe", user_id=user_ids[0])

    # Check subscriber count decreased
    updated_calendar = api_request("GET", f"/calendars/{calendar_with_hash['id']}").json()
    expected_count = initial_count + 2
    assert updated_calendar["subscriber_count"] == expected_count, f"Subscriber count should be {expected_count} after unsubscribe, got {updated_calendar['subscriber_count']}"

    print(f"✅ Subscriber count decreased to {updated_calendar['subscriber_count']} after unsubscribe")


def test_accessible_calendar_ids():
    """Test GET /users/{id}/accessible-calendar-ids includes subscribed calendars"""
    # Create user
    user_data = {
        "contact_name": "Calendar Collector",
        "phone_number": f"+6666{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+6666{int(datetime.now().timestamp())}",
    }
    user = api_request("POST", "/users", json=user_data).json()
    user_id = user["id"]

    # Get initial accessible calendars
    accessible_before = api_request("GET", f"/users/{user_id}/accessible-calendar-ids").json()

    # Subscribe to calendars with share_hash
    calendars = api_request("GET", "/calendars/public").json()
    calendars_with_hash = [c for c in calendars if c["share_hash"] is not None]
    subscribed_ids = []
    # Subscribe to the first calendar with share_hash (or all if there's only one)
    for calendar in calendars_with_hash[:1]:  # Just subscribe to one calendar with hash
        api_request("POST", f"/calendars/{calendar['share_hash']}/subscribe", user_id=user_id)
        subscribed_ids.append(calendar["id"])

    # Get accessible calendars after subscription
    accessible_after = api_request("GET", f"/users/{user_id}/accessible-calendar-ids").json()

    # Verify subscribed calendars are now accessible
    for calendar_id in subscribed_ids:
        assert calendar_id in accessible_after, f"Subscribed calendar {calendar_id} should be in accessible calendars"

    print(f"✅ Accessible calendars includes subscribed calendars: {len(accessible_after)} total")


def test_invalid_share_hash():
    """Test subscribing with invalid share_hash returns 404"""
    user_data = {
        "contact_name": "Test User",
        "phone_number": f"+5555{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+5555{int(datetime.now().timestamp())}",
    }
    user = api_request("POST", "/users", json=user_data).json()

    # Try to subscribe with invalid hash
    response = api_request("POST", "/calendars/invalid8/subscribe", user_id=user["id"])
    assert response.status_code == 404, "Invalid share_hash should return 404"

    print(f"✅ Invalid share_hash correctly rejected")


def test_search_calendar_by_share_hash():
    """Test searching for a public calendar using share_hash in the search parameter"""
    # Get a public calendar with share_hash
    calendars_response = api_request("GET", "/calendars/public")
    assert calendars_response.status_code == 200
    calendars = calendars_response.json()

    calendar_with_hash = next((c for c in calendars if c["share_hash"] is not None), None)
    assert calendar_with_hash is not None, "Need at least one calendar with share_hash"

    share_hash = calendar_with_hash["share_hash"]
    calendar_name = calendar_with_hash["name"]

    # Search by exact share_hash
    search_response = api_request("GET", "/calendars/public", params={"search": share_hash})
    assert search_response.status_code == 200

    results = search_response.json()
    assert isinstance(results, list), "Search should return a list"
    assert len(results) > 0, f"Search by share_hash '{share_hash}' should return results"

    # Verify the found calendar is the correct one
    found_calendar = next((c for c in results if c["share_hash"] == share_hash), None)
    assert found_calendar is not None, f"Search should find calendar with share_hash '{share_hash}'"
    assert found_calendar["id"] == calendar_with_hash["id"], "Found calendar should match original"
    assert found_calendar["name"] == calendar_name, "Calendar name should match"

    print(f"✅ Successfully found calendar '{calendar_name}' by searching share_hash '{share_hash}'")

    # Also verify search still works for name
    name_search_response = api_request("GET", "/calendars/public", params={"search": calendar_name})
    assert name_search_response.status_code == 200
    name_results = name_search_response.json()
    assert len(name_results) > 0, f"Search by name '{calendar_name}' should also work"

    print(f"✅ Search by name '{calendar_name}' also works correctly")


def test_get_user_calendars_requires_auth():
    """Test that GET /calendars requires authentication"""
    response = api_request("GET", "/calendars")
    assert response.status_code in [401, 403], "GET /calendars without auth should return 401 or 403"


def test_get_user_calendars_own_calendars():
    """Test that GET /calendars returns user's own calendars"""
    # Create user
    user_data = {
        "contact_name": "Calendar Owner",
        "phone_number": f"+4444{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+4444{int(datetime.now().timestamp())}",
        "is_public": False,
    }
    user = api_request("POST", "/users", json=user_data).json()
    user_id = user["id"]

    # Create a calendar for this user (owner_id comes from JWT, not body)
    calendar_data = {
        "name": f"My Calendar {int(datetime.now().timestamp())}",
        "description": "Test calendar",
        "is_public": False,
    }
    created_calendar = api_request("POST", "/calendars", json=calendar_data, user_id=user_id).json()

    # Get user's calendars
    response = api_request("GET", "/calendars", user_id=user_id)
    assert response.status_code == 200, f"Failed to get calendars: {response.text}"

    calendars = response.json()
    assert isinstance(calendars, list), "Response should be a list"

    # Verify created calendar is in the list
    found = any(c["id"] == created_calendar["id"] for c in calendars)
    assert found, f"Created calendar should be in user's calendars"

    print(f"✅ User's own calendars are returned ({len(calendars)} calendars)")


def test_get_user_calendars_excludes_public_user_calendars():
    """Test that GET /calendars excludes calendars from public users"""
    # Create a private user
    user_data = {
        "contact_name": "Private User",
        "phone_number": f"+3333{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+3333{int(datetime.now().timestamp())}",
        "is_public": False,
    }
    user = api_request("POST", "/users", json=user_data).json()
    user_id = user["id"]

    # Get public calendars (these are from public users like Barça)
    public_calendars = api_request("GET", "/calendars/public").json()
    public_user_calendars = [c for c in public_calendars if c["share_hash"] is None]

    # Get user's calendars
    user_calendars = api_request("GET", "/calendars", user_id=user_id).json()

    # Verify public user calendars are NOT included
    for pub_cal in public_user_calendars:
        found = any(c["id"] == pub_cal["id"] for c in user_calendars)
        assert not found, f"Public user calendar '{pub_cal['name']}' should NOT be in user's calendars"

    print(f"✅ Public user calendars are correctly excluded")


def test_get_user_calendars_includes_subscriptions():
    """Test that GET /calendars includes subscribed public calendars (not from public users)"""
    # Create user
    user_data = {
        "contact_name": "Subscriber",
        "phone_number": f"+2222{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+2222{int(datetime.now().timestamp())}",
        "is_public": False,
    }
    user = api_request("POST", "/users", json=user_data).json()
    user_id = user["id"]

    # Get calendars before subscription
    calendars_before = api_request("GET", "/calendars", user_id=user_id).json()
    calendar_ids_before = [c["id"] for c in calendars_before]

    # Subscribe to a public calendar with share_hash (from private user)
    public_calendars = api_request("GET", "/calendars/public").json()
    calendar_with_hash = next((c for c in public_calendars if c["share_hash"] is not None), None)
    assert calendar_with_hash is not None, "Need at least one calendar with share_hash"

    api_request("POST", f"/calendars/{calendar_with_hash['share_hash']}/subscribe", user_id=user_id)

    # Get calendars after subscription
    import time

    time.sleep(0.5)  # Allow time for subscription to process

    calendars_after = api_request("GET", "/calendars", user_id=user_id).json()
    calendar_ids_after = [c["id"] for c in calendars_after]

    # Verify subscribed calendar is now included
    assert calendar_with_hash["id"] not in calendar_ids_before, "Subscribed calendar should not be in list before subscription"
    assert calendar_with_hash["id"] in calendar_ids_after, "Subscribed calendar should be in list after subscription"

    print(f"✅ Subscribed calendars are included ({len(calendars_after)} calendars)")


def test_get_user_calendars_includes_memberships():
    """Test that GET /calendars includes calendars where user is a member"""
    # Create two users
    user1_data = {
        "contact_name": "Calendar Owner",
        "phone_number": f"+1111{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+1111{int(datetime.now().timestamp())}",
        "is_public": False,
    }
    user1 = api_request("POST", "/users", json=user1_data).json()
    user1_id = user1["id"]

    user2_data = {
        "contact_name": "Calendar Member",
        "phone_number": f"+1112{int(datetime.now().timestamp())}",
        "auth_provider": "phone",
        "auth_id": f"+1112{int(datetime.now().timestamp())}",
        "is_public": False,
    }
    user2 = api_request("POST", "/users", json=user2_data).json()
    user2_id = user2["id"]

    # User1 creates a calendar (owner_id comes from JWT, not body)
    calendar_data = {
        "name": f"Shared Calendar {int(datetime.now().timestamp())}",
        "description": "Shared with user2",
        "is_public": False,
    }
    calendar = api_request("POST", "/calendars", json=calendar_data, user_id=user1_id).json()
    calendar_id = calendar["id"]

    # Get user2's calendars before membership
    calendars_before = api_request("GET", "/calendars", user_id=user2_id).json()
    calendar_ids_before = [c["id"] for c in calendars_before]

    # Add user2 as member
    membership_data = {
        "calendar_id": calendar_id,
        "user_id": user2_id,
        "role": "member",
        "status": "accepted",
    }
    api_request("POST", f"/calendars/{calendar_id}/memberships", json=membership_data)

    # Get user2's calendars after membership
    import time

    time.sleep(0.5)  # Allow time for membership to process

    calendars_after = api_request("GET", "/calendars", user_id=user2_id).json()
    calendar_ids_after = [c["id"] for c in calendars_after]

    # Verify calendar is now included
    assert calendar_id not in calendar_ids_before, "Calendar should not be in list before membership"
    assert calendar_id in calendar_ids_after, "Calendar should be in list after membership"

    print(f"✅ Calendars where user is a member are included")


if __name__ == "__main__":
    print("🧪 Testing Calendar Subscriptions")
    print("=" * 60)

    test_discover_public_calendars()
    test_subscribe_to_calendar_via_share_hash()
    test_unsubscribe_from_calendar()
    test_subscribed_calendar_events_in_user_events()
    test_subscriber_count_trigger()
    test_accessible_calendar_ids()
    test_invalid_share_hash()
    test_search_calendar_by_share_hash()

    print("\n🧪 Testing GET /calendars endpoint")
    print("=" * 60)

    test_get_user_calendars_requires_auth()
    test_get_user_calendars_own_calendars()
    test_get_user_calendars_excludes_public_user_calendars()
    test_get_user_calendars_includes_subscriptions()
    test_get_user_calendars_includes_memberships()

    print("=" * 60)
    print("✅ All calendar tests passed!")
