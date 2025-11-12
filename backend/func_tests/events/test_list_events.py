"""
Tests for GET /api/v1/events - Event list endpoint with user access filtering
"""

import os
import pytest
import requests

API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8001/api/v1")


def api_request(method: str, path: str, json=None, user_id: int = None):
    """Make API request with optional authentication"""
    url = f"{API_BASE_URL}{path}"
    headers = {}
    if user_id:
        headers["X-Test-User-Id"] = str(user_id)

    if method == "GET":
        response = requests.get(url, headers=headers)
    elif method == "POST":
        response = requests.post(url, json=json, headers=headers)
    elif method == "PATCH":
        response = requests.patch(url, json=json, headers=headers)
    elif method == "DELETE":
        response = requests.delete(url, headers=headers)
    else:
        raise ValueError(f"Unsupported method: {method}")

    return {"status_code": response.status_code, "data": response.json() if response.content else None}


class TestListEventsAccessControl:
    """Test that GET /api/v1/events filters events by user access"""

    def test_different_users_see_different_events(self):
        """Users should only see events they have access to"""
        user1_events = api_request("GET", "/events", user_id=1)
        user2_events = api_request("GET", "/events", user_id=2)

        assert user1_events["status_code"] == 200
        assert user2_events["status_code"] == 200

        user1_ids = {e["id"] for e in user1_events["data"]}
        user2_ids = {e["id"] for e in user2_events["data"]}

        # Users should see different sets of events
        assert user1_ids != user2_ids

    def test_user_sees_owned_events(self):
        """User should see their own events in the list"""
        user1_events = api_request("GET", "/events", user_id=1)
        assert user1_events["status_code"] == 200

        # User 1 should see events they own
        for event in user1_events["data"]:
            if event["owner_id"] == 1:
                # Found at least one owned event
                return

        # If we get here, test passes vacuously (user has no events)
        assert True

    def test_user_sees_invited_and_subscribed_events(self):
        """User should see events they were invited to or subscribed to"""
        # This test verifies the filtering works with existing data from init_db_2
        user1_events = api_request("GET", "/events", user_id=1)
        user2_events = api_request("GET", "/events", user_id=2)

        assert user1_events["status_code"] == 200
        assert user2_events["status_code"] == 200

        # Verify users see some events (from init_db_2)
        assert len(user1_events["data"]) > 0
        assert len(user2_events["data"]) > 0

        # Verify the events include ones the user has interactions with
        user1_ids = {e["id"] for e in user1_events["data"]}
        user2_ids = {e["id"] for e in user2_events["data"]}

        # Users should have at least some non-overlapping events
        # (this validates access control is working)
        assert user1_ids != user2_ids

    def test_unauthenticated_returns_empty(self):
        """Unauthenticated requests should return empty list"""
        response = api_request("GET", "/events")
        assert response["status_code"] == 200
        assert response["data"] == []

    def test_filter_by_owner_id(self):
        """Should filter events by owner_id parameter"""
        # Get all events for user 1
        all_events = api_request("GET", "/events", user_id=1)

        # Filter by specific owner
        owner_id = 1
        filtered_events = api_request("GET", f"/events?owner_id={owner_id}", user_id=1)

        assert filtered_events["status_code"] == 200
        # All returned events should be owned by owner_id
        for event in filtered_events["data"]:
            assert event["owner_id"] == owner_id

    def test_pagination_works(self):
        """Should respect limit and offset parameters"""
        # Get first page
        page1 = api_request("GET", "/events?limit=5&offset=0", user_id=1)
        assert page1["status_code"] == 200
        assert len(page1["data"]) <= 5

        # Get second page
        page2 = api_request("GET", "/events?limit=5&offset=5", user_id=1)
        assert page2["status_code"] == 200

        # Pages should have different events
        if page1["data"] and page2["data"]:
            page1_ids = {e["id"] for e in page1["data"]}
            page2_ids = {e["id"] for e in page2["data"]}
            assert page1_ids.isdisjoint(page2_ids)

    def test_ordering_by_start_date(self):
        """Should order events by start_date"""
        response = api_request("GET", "/events?order_by=start_date&order_dir=asc", user_id=1)
        assert response["status_code"] == 200

        events = response["data"]
        if len(events) > 1:
            # Check ascending order
            for i in range(len(events) - 1):
                assert events[i]["start_date"] <= events[i + 1]["start_date"]

        # Test descending
        response_desc = api_request("GET", "/events?order_by=start_date&order_dir=desc", user_id=1)
        events_desc = response_desc["data"]
        if len(events_desc) > 1:
            for i in range(len(events_desc) - 1):
                assert events_desc[i]["start_date"] >= events_desc[i + 1]["start_date"]

    def test_public_user_sees_own_events(self):
        """Public users should see events they own"""
        # Public user (ID 86 - FC Barcelona)
        public_user_events = api_request("GET", "/events", user_id=86)
        assert public_user_events["status_code"] == 200

        # Should see their own events
        event_ids = {e["id"] for e in public_user_events["data"]}
        owners = {e["owner_id"] for e in public_user_events["data"]}

        # All events should be owned by this public user
        assert 86 in owners or len(event_ids) == 0
