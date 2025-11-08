"""
Test suite to validate backend API responses are compatible with Flutter models.

This test validates that:
1. All required fields expected by Flutter models are present in backend responses
2. Field types match between backend and Flutter
3. Field naming conventions are consistent (snake_case in API, matches Flutter fromJson)
"""

import pytest
from typing import Dict, List, Any, Optional
from datetime import datetime
from models import User, Event, Calendar, Group, Contact, EventInteraction


# Flutter model field definitions extracted from lib/models/*.dart
FLUTTER_MODELS = {
    "User": {
        "required_fields": {
            "id": int,
            "is_public": bool,
        },
        "optional_fields": {
            "contact_id": (int, type(None)),
            "instagram_name": (str, type(None)),  # For private users or public users
            "auth_provider": (str, type(None)),
            "auth_id": (str, type(None)),
            "is_admin": (bool, type(None)),
            "profile_picture": (str, type(None)),
            "last_login": (str, type(None)),
            "created_at": (str, type(None)),
            "updated_at": (str, type(None)),
            # Enriched fields (only when enriched=true)
            "contact_name": (str, type(None)),
            "contact_phone": (str, type(None)),
            # Stats fields (only in /users/{id}/subscriptions)
            "new_events_count": (int, type(None)),
            "total_events_count": (int, type(None)),
            "subscribers_count": (int, type(None)),
        },
    },
    "Event": {
        "required_fields": {
            "name": str,
            "start_date": str,
            "owner_id": int,
        },
        "optional_fields": {
            "id": (int, type(None)),
            "description": (str, type(None)),
            "event_type": (str, type(None)),
            "calendar_id": (int, type(None)),
            "parent_recurring_event_id": (int, type(None)),
            "created_at": (str, type(None)),
            "updated_at": (str, type(None)),
            # Enriched fields
            "owner_name": (str, type(None)),
            "owner_profile_picture": (str, type(None)),
            "is_owner_public": (bool, type(None)),
            "calendar_name": (str, type(None)),
            "calendar_color": (str, type(None)),
            "is_birthday": (bool, type(None)),
            "attendees": (list, type(None)),
            # Interaction fields
            "interaction": (dict, type(None)),
            "interactions": (list, type(None)),
            # Subscription enrichment
            "can_subscribe_to_owner": (bool, type(None)),
            "is_subscribed_to_owner": (bool, type(None)),
            "owner_upcoming_events": (int, type(None)),
            # Invitation stats
            "invitation_stats": (dict, type(None)),
        },
    },
    "Calendar": {
        "required_fields": {
            "id": int,
            "owner_id": int,
            "name": str,
            "created_at": str,
            "updated_at": str,
        },
        "optional_fields": {
            "description": (str, type(None)),
            "delete_associated_events": (bool, type(None)),
            "is_public": (bool, type(None)),
            "is_discoverable": (bool, type(None)),
            "share_hash": (str, type(None)),
            "category": (str, type(None)),
            "subscriber_count": (int, type(None)),
            "start_date": (str, type(None)),  # For temporal calendars
            "end_date": (str, type(None)),    # For temporal calendars
        },
    },
    "Group": {
        "required_fields": {
            "id": int,
            "name": str,
            "owner_id": int,
            "created_at": str,
        },
        "optional_fields": {
            "description": (str, type(None)),
            "updated_at": (str, type(None)),
            "owner": (dict, type(None)),
            "members": (list, type(None)),
            "admins": (list, type(None)),
        },
    },
    "EventInteraction": {
        "required_fields": {
            "id": int,
            "user_id": int,
            "event_id": int,
            "interaction_type": str,
        },
        "optional_fields": {
            "status": (str, type(None)),
            "role": (str, type(None)),
            "invited_by_user_id": (int, type(None)),
            "invited_via_group_id": (int, type(None)),
            "personal_note": (str, type(None)),
            "cancellation_note": (str, type(None)),
            "is_attending": (bool, type(None)),
            "read_at": (str, type(None)),
            "is_new": (bool, type(None)),
            "created_at": (str, type(None)),
            "updated_at": (str, type(None)),
        },
    },
}


def validate_field_type(value: Any, expected_types: tuple) -> bool:
    """Check if value matches one of the expected types."""
    return isinstance(value, expected_types)


def validate_model_fields(
    data: Dict[str, Any],
    model_name: str,
    path: str = "root"
) -> List[str]:
    """
    Validate that data contains all required fields and correct types for a Flutter model.

    Returns list of error messages (empty if valid).
    """
    errors = []

    if model_name not in FLUTTER_MODELS:
        return [f"Unknown model: {model_name}"]

    model_spec = FLUTTER_MODELS[model_name]

    # Check required fields
    for field_name, expected_type in model_spec["required_fields"].items():
        if field_name not in data:
            errors.append(
                f"{path}.{field_name}: MISSING required field for {model_name}"
            )
        elif not isinstance(data[field_name], expected_type):
            errors.append(
                f"{path}.{field_name}: WRONG TYPE - expected {expected_type.__name__}, "
                f"got {type(data[field_name]).__name__} (value: {data[field_name]})"
            )

    # Check optional field types (if present)
    for field_name, expected_types in model_spec["optional_fields"].items():
        if field_name in data:
            if not validate_field_type(data[field_name], expected_types):
                errors.append(
                    f"{path}.{field_name}: WRONG TYPE - expected one of "
                    f"{[t.__name__ for t in expected_types]}, "
                    f"got {type(data[field_name]).__name__} (value: {data[field_name]})"
                )

    return errors


def validate_list_of_models(
    data_list: List[Dict[str, Any]],
    model_name: str,
    path: str = "root"
) -> List[str]:
    """Validate a list of model instances."""
    errors = []
    for idx, item in enumerate(data_list):
        item_errors = validate_model_fields(item, model_name, f"{path}[{idx}]")
        errors.extend(item_errors)
    return errors


@pytest.fixture
def sample_data(test_db):
    """Create sample data for testing."""
    # Create contacts
    contact1 = Contact(id=1, name="Alice Contact", phone="+1234567890")
    contact2 = Contact(id=2, name="Bob Contact", phone="+0987654321")
    test_db.add_all([contact1, contact2])
    test_db.flush()

    # Create users
    user1 = User(
        id=1,
        contact_id=1,
        instagram_name="Alice",
        auth_provider="phone",
        auth_id="+1234567890",
        is_public=False,
        is_admin=False,
        created_at=datetime(2025, 12, 1, 10, 0, 0),
        updated_at=datetime(2025, 12, 1, 10, 0, 0),
    )
    user2 = User(
        id=2,
        contact_id=2,
        instagram_name="bob_insta",
        auth_provider="instagram",
        auth_id="12345",
        is_public=True,
        is_admin=False,
        created_at=datetime(2025, 12, 1, 10, 0, 0),
        updated_at=datetime(2025, 12, 1, 10, 0, 0),
    )
    test_db.add_all([user1, user2])
    test_db.flush()

    # Create calendar
    calendar1 = Calendar(
        id=1,
        owner_id=1,
        name="My Calendar",
        description="Test calendar",
        is_public=False,
        created_at=datetime(2025, 12, 1, 10, 0, 0),
        updated_at=datetime(2025, 12, 1, 10, 0, 0),
    )
    test_db.add(calendar1)
    test_db.flush()

    # Create events
    event1 = Event(
        id=1,
        name="Test Event",
        description="Test description",
        start_date=datetime(2026, 1, 15, 10, 0, 0),
        owner_id=1,
        calendar_id=1,
        event_type="regular",
        created_at=datetime(2025, 12, 1, 10, 0, 0),
        updated_at=datetime(2025, 12, 1, 10, 0, 0),
    )
    test_db.add(event1)
    test_db.flush()

    # Create group
    group1 = Group(
        id=1,
        name="Test Group",
        description="Test group description",
        owner_id=1,
        created_at=datetime(2025, 12, 1, 10, 0, 0),
        updated_at=datetime(2025, 12, 1, 10, 0, 0),
    )
    test_db.add(group1)
    test_db.flush()

    # Create event interaction
    interaction1 = EventInteraction(
        id=1,
        user_id=2,
        event_id=1,
        interaction_type="invited",
        status="pending",
        role="guest",
        created_at=datetime(2025, 12, 1, 10, 0, 0),
        updated_at=datetime(2025, 12, 1, 10, 0, 0),
    )
    test_db.add(interaction1)

    test_db.commit()
    return {
        "users": [user1, user2],
        "events": [event1],
        "calendars": [calendar1],
        "groups": [group1],
        "interactions": [interaction1],
    }


class TestFlutterCompatibility:
    """Test that backend responses are compatible with Flutter models."""

    def test_user_endpoints(self, client, sample_data):
        """Test User model compatibility across all user endpoints."""
        errors = []

        # GET /api/v1/users
        response = client.get("/api/v1/users")
        assert response.status_code == 200
        users = response.json()
        errors.extend(validate_list_of_models(users, "User", "GET /api/v1/users"))

        # GET /api/v1/users/{id}
        response = client.get("/api/v1/users/1")
        assert response.status_code == 200
        user = response.json()
        errors.extend(validate_model_fields(user, "User", "GET /api/v1/users/1"))

        # GET /api/v1/users with enriched=true
        response = client.get("/api/v1/users?enriched=true")
        assert response.status_code == 200
        users = response.json()
        errors.extend(validate_list_of_models(users, "User", "GET /api/v1/users?enriched=true"))

        # GET /api/v1/users/{id}/subscriptions
        response = client.get("/api/v1/users/1/subscriptions")
        assert response.status_code == 200
        subscriptions = response.json()
        errors.extend(validate_list_of_models(subscriptions, "User", "GET /api/v1/users/1/subscriptions"))

        if errors:
            pytest.fail(f"User model validation errors:\n" + "\n".join(errors))

    def test_event_endpoints(self, client, sample_data):
        """Test Event model compatibility across all event endpoints."""
        errors = []

        # GET /api/v1/events
        response = client.get("/api/v1/events")
        assert response.status_code == 200
        events = response.json()
        errors.extend(validate_list_of_models(events, "Event", "GET /api/v1/events"))

        # GET /api/v1/events/{id}
        response = client.get("/api/v1/events/1")
        assert response.status_code == 200
        event = response.json()
        errors.extend(validate_model_fields(event, "Event", "GET /api/v1/events/1"))

        # GET /api/v1/users/{id}/events
        response = client.get("/api/v1/users/1/events")
        assert response.status_code == 200
        events = response.json()
        errors.extend(validate_list_of_models(events, "Event", "GET /api/v1/users/1/events"))

        if errors:
            pytest.fail(f"Event model validation errors:\n" + "\n".join(errors))

    def test_calendar_endpoints(self, client, sample_data):
        """Test Calendar model compatibility across all calendar endpoints."""
        errors = []

        # GET /api/v1/calendars
        response = client.get("/api/v1/calendars")
        assert response.status_code == 200
        calendars = response.json()
        errors.extend(validate_list_of_models(calendars, "Calendar", "GET /api/v1/calendars"))

        # GET /api/v1/calendars/{id}
        response = client.get("/api/v1/calendars/1")
        assert response.status_code == 200
        calendar = response.json()
        errors.extend(validate_model_fields(calendar, "Calendar", "GET /api/v1/calendars/1"))

        if errors:
            pytest.fail(f"Calendar model validation errors:\n" + "\n".join(errors))

    def test_group_endpoints(self, client, sample_data):
        """Test Group model compatibility across all group endpoints."""
        errors = []

        # GET /api/v1/groups
        response = client.get("/api/v1/groups")
        assert response.status_code == 200
        groups = response.json()
        errors.extend(validate_list_of_models(groups, "Group", "GET /api/v1/groups"))

        # GET /api/v1/groups/{id}
        response = client.get("/api/v1/groups/1")
        assert response.status_code == 200
        group = response.json()
        errors.extend(validate_model_fields(group, "Group", "GET /api/v1/groups/1"))

        # Validate nested User objects in groups
        if "members" in group and group["members"]:
            errors.extend(validate_list_of_models(
                group["members"], "User", "GET /api/v1/groups/1 -> members"
            ))
        if "admins" in group and group["admins"]:
            errors.extend(validate_list_of_models(
                group["admins"], "User", "GET /api/v1/groups/1 -> admins"
            ))
        if "owner" in group and group["owner"]:
            errors.extend(validate_model_fields(
                group["owner"], "User", "GET /api/v1/groups/1 -> owner"
            ))

        if errors:
            pytest.fail(f"Group model validation errors:\n" + "\n".join(errors))

    def test_event_interaction_endpoints(self, client, sample_data):
        """Test EventInteraction model compatibility."""
        errors = []

        # GET /api/v1/interactions
        response = client.get("/api/v1/interactions")
        assert response.status_code == 200
        interactions = response.json()
        errors.extend(validate_list_of_models(
            interactions, "EventInteraction", "GET /api/v1/interactions"
        ))

        if errors:
            pytest.fail(f"EventInteraction model validation errors:\n" + "\n".join(errors))

    def test_nested_models(self, client, sample_data):
        """Test that nested models (e.g., User in Event, User in Group) are valid."""
        errors = []

        # Check events with enriched owner data
        response = client.get("/api/v1/events")
        assert response.status_code == 200
        events = response.json()

        for idx, event in enumerate(events):
            # If event has interaction data, validate it's a dict (Flutter expects Map)
            if "interaction" in event and event["interaction"] is not None:
                if not isinstance(event["interaction"], dict):
                    errors.append(
                        f"GET /api/v1/events[{idx}].interaction: expected dict, "
                        f"got {type(event['interaction']).__name__}"
                    )

        if errors:
            pytest.fail(f"Nested model validation errors:\n" + "\n".join(errors))

    def test_critical_type_mismatches(self, client, sample_data):
        """Test for known critical type mismatches documented in MODEL_INCONSISTENCIES_REPORT.md"""
        errors = []

        # CRITICAL: Calendar ID should be int, not String (documented issue)
        response = client.get("/api/v1/calendars")
        assert response.status_code == 200
        calendars = response.json()

        for idx, calendar in enumerate(calendars):
            if "id" in calendar and isinstance(calendar["id"], str):
                errors.append(
                    f"CRITICAL: GET /api/v1/calendars[{idx}].id is String, "
                    f"Flutter expects int. This is a KNOWN issue from MODEL_INCONSISTENCIES_REPORT.md"
                )

        # Check calendar_id in events should be int
        response = client.get("/api/v1/events")
        assert response.status_code == 200
        events = response.json()

        for idx, event in enumerate(events):
            if "calendar_id" in event and event["calendar_id"] is not None:
                if isinstance(event["calendar_id"], str):
                    errors.append(
                        f"CRITICAL: GET /api/v1/events[{idx}].calendar_id is String, "
                        f"Flutter expects int"
                    )

        if errors:
            pytest.fail(
                f"Critical type mismatch errors:\n" + "\n".join(errors) +
                f"\n\nThese errors indicate type incompatibilities that will cause "
                f"Flutter runtime errors. Please review MODEL_INCONSISTENCIES_REPORT.md"
            )
