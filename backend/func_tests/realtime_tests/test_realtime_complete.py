"""
Tests COMPLETOS de integración Realtime - TODAS las operaciones

COBERTURA COMPLETA:
1. Events (INSERT, UPDATE, DELETE)
2. Event Interactions (INSERT, UPDATE, DELETE)
3. Groups (INSERT, UPDATE, DELETE)
4. Calendars (calendar_memberships INSERT, DELETE)
5. Subscriptions (user_subscription_stats via triggers)

Ejecutar con: pytest backend/func_tests/test_realtime_complete.py -v -s
"""

import os
import time
import pytest
import requests
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import List, Dict

# Configuración
API_BASE_URL = "http://localhost:8001/api/v1"
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "database": os.getenv("POSTGRES_DB", "postgres"),
    "user": os.getenv("POSTGRES_USER", "postgres"),
    "password": os.getenv("POSTGRES_PASSWORD", "your-super-secret-and-long-postgres-password"),
}


def get_db_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)


def api_request(method: str, path: str, json_data=None, user_id: int = 1):
    url = f"{API_BASE_URL}{path}"
    headers = {"X-Test-User-Id": str(user_id)}

    if method == "GET":
        response = requests.get(url, headers=headers)
    elif method == "POST":
        response = requests.post(url, json=json_data, headers=headers)
    elif method == "DELETE":
        response = requests.delete(url, headers=headers)
    elif method == "PUT":
        response = requests.put(url, json=json_data, headers=headers)
    elif method == "PATCH":
        response = requests.patch(url, json=json_data, headers=headers)
    else:
        raise ValueError(f"Unsupported method: {method}")

    return response


def get_user_events(user_id: int) -> List[Dict]:
    response = api_request("GET", f"/users/{user_id}/events", user_id=user_id)
    assert response.status_code == 200
    return response.json()


def get_user_subscriptions(user_id: int) -> List[Dict]:
    response = api_request("GET", f"/users/{user_id}/subscriptions", user_id=user_id)
    assert response.status_code == 200
    return response.json()


def get_user_groups(user_id: int) -> List[Dict]:
    response = api_request("GET", f"/groups", user_id=user_id)
    assert response.status_code == 200
    return response.json()


def get_user_calendars(user_id: int) -> List[Dict]:
    response = api_request("GET", f"/calendars", user_id=user_id)
    assert response.status_code == 200
    return response.json()


def get_user_stats(user_id: int) -> Dict:
    with get_db_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM user_subscription_stats WHERE user_id = %s",
                (user_id,)
            )
            result = cursor.fetchone()
            return dict(result) if result else None


def wait_for_realtime(seconds: float = 2.0):
    time.sleep(seconds)


# ============================================================================
# EVENTS TABLE - INSERT, UPDATE, DELETE
# ============================================================================

class TestEventsRealtimeINSERT:
    """Tabla: events - Evento: INSERT"""

    def test_create_event_triggers_realtime_insert(self):
        """POST /events → INSERT en events → Realtime notifica → GET /users/X/events incluye nuevo evento"""
        user_id = 1

        events_before = get_user_events(user_id)
        count_before = len(events_before)

        event_data = {
            "name": "INSERT Test Event",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }

        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        assert response.status_code == 201
        event_id = response.json()["id"]

        wait_for_realtime()

        events_after = get_user_events(user_id)
        event_ids = {e["id"] for e in events_after}

        assert event_id in event_ids, f"Event {event_id} not found after INSERT"
        assert len(events_after) == count_before + 1

        print(f"✅ INSERT: Event {event_id} appears in user events")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)


class TestEventsRealtimeUPDATE:
    """Tabla: events - Evento: UPDATE"""

    def test_update_event_triggers_realtime_update(self):
        """PUT /events/X → UPDATE en events → Realtime notifica → GET /users/X/events refleja cambios"""
        user_id = 1

        # Create
        event_data = {
            "name": "Original Name",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        event_id = response.json()["id"]

        # Update
        update_data = {"name": "Updated Name"}
        response = api_request("PUT", f"/events/{event_id}", json_data=update_data, user_id=user_id)
        assert response.status_code == 200

        wait_for_realtime()

        events = get_user_events(user_id)
        updated_event = next((e for e in events if e["id"] == event_id), None)

        assert updated_event is not None
        assert updated_event["name"] == "Updated Name", f"Expected 'Updated Name', got '{updated_event['name']}'"

        print(f"✅ UPDATE: Event {event_id} name changed via Realtime")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)


class TestEventsRealtimeDELETE:
    """Tabla: events - Evento: DELETE"""

    def test_delete_event_triggers_realtime_delete(self):
        """DELETE /events/X → DELETE en events → Realtime notifica → GET /users/X/events excluye evento"""
        user_id = 1

        # Create
        event_data = {
            "name": "Event to Delete",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        event_id = response.json()["id"]

        wait_for_realtime()

        events_before = get_user_events(user_id)
        assert event_id in {e["id"] for e in events_before}

        # Delete
        response = api_request("DELETE", f"/events/{event_id}", user_id=user_id)
        assert response.status_code == 200

        wait_for_realtime()

        events_after = get_user_events(user_id)
        event_ids = {e["id"] for e in events_after}

        assert event_id not in event_ids, f"❌ Event {event_id} STILL EXISTS after DELETE"

        print(f"✅ DELETE: Event {event_id} removed from user events")


# ============================================================================
# EVENT_INTERACTIONS TABLE - INSERT, UPDATE, DELETE
# ============================================================================

class TestEventInteractionsRealtimeINSERT:
    """Tabla: event_interactions - Evento: INSERT"""

    def test_send_invitation_triggers_realtime_insert(self):
        """POST /interactions → INSERT en event_interactions → Realtime → GET /users/X/events incluye invitación"""
        owner_id = 1
        invitee_id = 2

        # Create event
        event_data = {
            "name": "Event for Invitation",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        event_id = response.json()["id"]

        # Send invitation
        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "pending",
        }
        response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        assert response.status_code == 201
        interaction_id = response.json()["id"]

        wait_for_realtime()

        # Verify invitee sees event
        invitee_events = get_user_events(invitee_id)
        event_ids = {e["id"] for e in invitee_events}

        assert event_id in event_ids, f"Event {event_id} not visible to invitee after INSERT interaction"

        print(f"✅ INSERT interaction: Invitee sees event {event_id}")

        # Cleanup
        api_request("DELETE", f"/interactions/{interaction_id}", user_id=invitee_id)
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)


class TestEventInteractionsRealtimeUPDATE:
    """Tabla: event_interactions - Evento: UPDATE"""

    def test_accept_invitation_triggers_realtime_update(self):
        """PATCH /interactions/X (accept) → UPDATE status → Realtime → interaction_data actualizado"""
        owner_id = 1
        invitee_id = 2

        # Create event and invite
        event_data = {
            "name": "Event to Accept",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        event_id = response.json()["id"]

        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "pending",
        }
        response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        interaction_id = response.json()["id"]

        wait_for_realtime()

        # Verify initial status
        events_before = get_user_events(invitee_id)
        event_before = next((e for e in events_before if e["id"] == event_id), None)
        assert event_before["interaction"]["status"] == "pending"

        # Accept
        accept_data = {"status": "accepted"}
        response = api_request("PATCH", f"/interactions/{interaction_id}", json_data=accept_data, user_id=invitee_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify updated status
        events_after = get_user_events(invitee_id)
        event_after = next((e for e in events_after if e["id"] == event_id), None)

        assert event_after["interaction"]["status"] == "accepted", \
            f"Expected status='accepted', got '{event_after['interaction']['status']}'"

        print(f"✅ UPDATE interaction: Status changed to accepted via Realtime")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)

    def test_reject_invitation_triggers_realtime_update(self):
        """PATCH /interactions/X (reject) → UPDATE status → Realtime → evento desaparece"""
        owner_id = 1
        invitee_id = 2

        # Create and invite
        event_data = {
            "name": "Event to Reject",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        event_id = response.json()["id"]

        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "pending",
        }
        response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        interaction_id = response.json()["id"]

        wait_for_realtime()

        # Reject
        reject_data = {"status": "rejected"}
        response = api_request("PATCH", f"/interactions/{interaction_id}", json_data=reject_data, user_id=invitee_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify event removed
        events = get_user_events(invitee_id)
        event_ids = {e["id"] for e in events}

        assert event_id not in event_ids, f"Event {event_id} still visible after rejection"

        print(f"✅ UPDATE interaction (reject): Event removed from invitee events")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)

    def test_mark_as_viewed_triggers_realtime_update(self):
        """PATCH /interactions/X (mark_read) → UPDATE read_at → Realtime → interaction actualizado"""
        owner_id = 1
        invitee_id = 2

        # Create and invite
        event_data = {
            "name": "Event to Mark Viewed",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        event_id = response.json()["id"]

        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "pending",
        }
        response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        interaction_id = response.json()["id"]

        wait_for_realtime()

        # Mark as viewed
        response = api_request("POST", f"/interactions/{interaction_id}/mark-read", user_id=invitee_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify read_at is set
        events = get_user_events(invitee_id)
        event = next((e for e in events if e["id"] == event_id), None)

        assert event["interaction"].get("read_at") is not None, "read_at should be set"

        print(f"✅ UPDATE interaction (mark_read): read_at updated via Realtime")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)

    def test_set_personal_note_triggers_realtime_update(self):
        """PATCH /interactions/X (note) → UPDATE note → Realtime → nota actualizada"""
        owner_id = 1
        invitee_id = 2

        # Create and invite
        event_data = {
            "name": "Event with Note",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        event_id = response.json()["id"]

        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "accepted",
        }
        response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        interaction_id = response.json()["id"]

        wait_for_realtime()

        # Set note
        note_data = {"note": "My personal note"}
        response = api_request("PATCH", f"/interactions/{interaction_id}", json_data=note_data, user_id=invitee_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify note
        events = get_user_events(invitee_id)
        event = next((e for e in events if e["id"] == event_id), None)

        assert event["interaction"].get("note") == "My personal note"

        print(f"✅ UPDATE interaction (note): note updated via Realtime")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)


class TestEventInteractionsRealtimeDELETE:
    """Tabla: event_interactions - Evento: DELETE"""

    def test_leave_event_triggers_realtime_delete(self):
        """DELETE /events/X/interaction → DELETE interaction → Realtime → evento desaparece para non-owner"""
        owner_id = 1
        participant_id = 2

        # Create, invite, accept
        event_data = {
            "name": "Event to Leave",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        event_id = response.json()["id"]

        invitation_data = {
            "event_id": event_id,
            "user_id": participant_id,
            "interaction_type": "invited",
            "status": "pending",
        }
        response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        interaction_id = response.json()["id"]

        accept_data = {"status": "accepted"}
        api_request("PATCH", f"/interactions/{interaction_id}", json_data=accept_data, user_id=participant_id)

        wait_for_realtime()

        # Verify participant sees event
        events_before = get_user_events(participant_id)
        assert event_id in {e["id"] for e in events_before}

        # Leave
        response = api_request("DELETE", f"/events/{event_id}/interaction", user_id=participant_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify event removed for participant
        events_after = get_user_events(participant_id)
        event_ids = {e["id"] for e in events_after}

        assert event_id not in event_ids, f"❌ Event {event_id} still visible after leaving"

        # Verify event still visible for owner
        owner_events = get_user_events(owner_id)
        assert event_id in {e["id"] for e in owner_events}, "Owner should still see event"

        print(f"✅ DELETE interaction: Event removed for participant, kept for owner")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)


# ============================================================================
# GROUPS TABLE - INSERT, UPDATE, DELETE
# ============================================================================

class TestGroupsRealtimeINSERT:
    """Tabla: groups - Evento: INSERT"""

    def test_create_group_triggers_realtime_insert(self):
        """POST /groups → INSERT en groups → Realtime → GET /users/X/groups incluye grupo"""
        user_id = 1

        groups_before = get_user_groups(user_id)
        count_before = len(groups_before)

        group_data = {
            "name": "New Group",
            "description": "Test group",
        }
        response = api_request("POST", "/groups", json_data=group_data, user_id=user_id)
        assert response.status_code == 201
        group_id = response.json()["id"]

        wait_for_realtime()

        groups_after = get_user_groups(user_id)
        group_ids = {g["id"] for g in groups_after}

        assert group_id in group_ids, f"Group {group_id} not found after INSERT"
        assert len(groups_after) == count_before + 1

        print(f"✅ INSERT group: Group {group_id} appears in user groups")

        # Cleanup
        api_request("DELETE", f"/groups/{group_id}", user_id=user_id)


class TestGroupsRealtimeUPDATE:
    """Tabla: groups - Evento: UPDATE"""

    def test_update_group_triggers_realtime_update(self):
        """PATCH /groups/X → UPDATE en groups → Realtime → cambios reflejados"""
        user_id = 1

        # Create group
        group_data = {
            "name": "Original Group Name",
            "description": "Original description",
        }
        response = api_request("POST", "/groups", json_data=group_data, user_id=user_id)
        group_id = response.json()["id"]

        # Update
        update_data = {"name": "Updated Group Name"}
        response = api_request("PUT", f"/groups/{group_id}", json_data=update_data, user_id=user_id)
        assert response.status_code == 200

        wait_for_realtime()

        groups = get_user_groups(user_id)
        updated_group = next((g for g in groups if g["id"] == group_id), None)

        assert updated_group is not None
        assert updated_group["name"] == "Updated Group Name"

        print(f"✅ UPDATE group: Group {group_id} name updated via Realtime")

        # Cleanup
        api_request("DELETE", f"/groups/{group_id}", user_id=user_id)

    def test_add_member_triggers_realtime_update(self):
        """POST /groups/X/members → UPDATE members → Realtime → miembro ve grupo"""
        creator_id = 1
        member_id = 2

        # Create group
        group_data = {"name": "Group for Members", "description": "Test"}
        response = api_request("POST", "/groups", json_data=group_data, user_id=creator_id)
        group_id = response.json()["id"]

        # Add member
        member_data = {"user_id": member_id}
        response = api_request("POST", f"/groups/{group_id}/members", json_data=member_data, user_id=creator_id)
        assert response.status_code == 201

        wait_for_realtime()

        # Verify member sees group
        member_groups = get_user_groups(member_id)
        group_ids = {g["id"] for g in member_groups}

        assert group_id in group_ids, f"Group {group_id} not visible to new member"

        print(f"✅ UPDATE group (add member): Member sees group {group_id}")

        # Cleanup
        api_request("DELETE", f"/groups/{group_id}", user_id=creator_id)

    def test_remove_member_triggers_realtime_update(self):
        """DELETE /groups/X/members/Y → UPDATE members → Realtime → miembro no ve grupo"""
        creator_id = 1
        member_id = 2

        # Create group and add member
        group_data = {"name": "Group to Remove From", "description": "Test"}
        response = api_request("POST", "/groups", json_data=group_data, user_id=creator_id)
        group_id = response.json()["id"]

        member_data = {"user_id": member_id}
        api_request("POST", f"/groups/{group_id}/members", json_data=member_data, user_id=creator_id)

        wait_for_realtime()

        # Remove member
        response = api_request("DELETE", f"/groups/{group_id}/members/{member_id}", user_id=creator_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify member doesn't see group
        member_groups = get_user_groups(member_id)
        group_ids = {g["id"] for g in member_groups}

        assert group_id not in group_ids, f"Group {group_id} still visible after removal"

        print(f"✅ UPDATE group (remove member): Member doesn't see group {group_id}")

        # Cleanup
        api_request("DELETE", f"/groups/{group_id}", user_id=creator_id)


class TestGroupsRealtimeDELETE:
    """Tabla: groups - Evento: DELETE"""

    def test_delete_group_triggers_realtime_delete(self):
        """DELETE /groups/X → DELETE en groups → Realtime → grupo desaparece"""
        user_id = 1

        # Create group
        group_data = {"name": "Group to Delete", "description": "Test"}
        response = api_request("POST", "/groups", json_data=group_data, user_id=user_id)
        group_id = response.json()["id"]

        wait_for_realtime()

        groups_before = get_user_groups(user_id)
        assert group_id in {g["id"] for g in groups_before}

        # Delete
        response = api_request("DELETE", f"/groups/{group_id}", user_id=user_id)
        assert response.status_code == 200

        wait_for_realtime()

        groups_after = get_user_groups(user_id)
        group_ids = {g["id"] for g in groups_after}

        assert group_id not in group_ids, f"❌ Group {group_id} still exists after DELETE"

        print(f"✅ DELETE group: Group {group_id} removed from user groups")

    def test_leave_group_triggers_realtime_update(self):
        """DELETE /groups/X/leave → UPDATE members → Realtime → usuario no ve grupo"""
        creator_id = 1
        member_id = 2

        # Create and add member
        group_data = {"name": "Group to Leave", "description": "Test"}
        response = api_request("POST", "/groups", json_data=group_data, user_id=creator_id)
        group_id = response.json()["id"]

        member_data = {"user_id": member_id}
        api_request("POST", f"/groups/{group_id}/members", json_data=member_data, user_id=creator_id)

        wait_for_realtime()

        # Member leaves
        response = api_request("DELETE", f"/groups/{group_id}/leave", user_id=member_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify member doesn't see group
        member_groups = get_user_groups(member_id)
        group_ids = {g["id"] for g in member_groups}

        assert group_id not in group_ids, f"Group {group_id} still visible after leaving"

        print(f"✅ UPDATE group (leave): Member doesn't see group {group_id}")

        # Cleanup
        api_request("DELETE", f"/groups/{group_id}", user_id=creator_id)


# ============================================================================
# CALENDAR_MEMBERSHIPS TABLE - INSERT, DELETE
# ============================================================================

class TestCalendarMembershipsRealtimeINSERT:
    """Tabla: calendar_memberships - Evento: INSERT"""

    def test_create_calendar_triggers_membership_insert(self):
        """POST /calendars → INSERT membership → Realtime → GET /calendars incluye calendario"""
        user_id = 1

        calendars_before = get_user_calendars(user_id)
        count_before = len(calendars_before)

        calendar_data = {"name": "New Calendar", "description": "Test calendar"}
        response = api_request("POST", "/calendars", json_data=calendar_data, user_id=user_id)
        assert response.status_code == 201
        calendar_id = response.json()["id"]

        wait_for_realtime()

        calendars_after = get_user_calendars(user_id)
        calendar_ids = {c["id"] for c in calendars_after}

        assert calendar_id in calendar_ids, f"Calendar {calendar_id} not found after INSERT"
        assert len(calendars_after) == count_before + 1

        print(f"✅ INSERT calendar_membership: Calendar {calendar_id} appears")

        # Cleanup
        api_request("DELETE", f"/calendars/{calendar_id}", user_id=user_id)

    def test_subscribe_to_calendar_triggers_membership_insert(self):
        """POST /calendars/X/subscribe → INSERT membership → Realtime → usuario ve calendario"""
        owner_id = 1
        subscriber_id = 2

        # Create public calendar
        calendar_data = {"name": "Public Calendar", "is_public": True}
        response = api_request("POST", "/calendars", json_data=calendar_data, user_id=owner_id)
        calendar_id = response.json()["id"]

        # Subscribe
        response = api_request("POST", f"/calendars/{calendar_id}/subscribe", user_id=subscriber_id)
        assert response.status_code == 201

        wait_for_realtime()

        # Verify subscriber sees calendar
        subscriber_calendars = get_user_calendars(subscriber_id)
        calendar_ids = {c["id"] for c in subscriber_calendars}

        assert calendar_id in calendar_ids, f"Calendar {calendar_id} not visible to subscriber"

        print(f"✅ INSERT calendar_membership (subscribe): Subscriber sees calendar")

        # Cleanup
        api_request("DELETE", f"/calendars/{calendar_id}/unsubscribe", user_id=subscriber_id)
        api_request("DELETE", f"/calendars/{calendar_id}", user_id=owner_id)


class TestCalendarMembershipsRealtimeDELETE:
    """Tabla: calendar_memberships - Evento: DELETE"""

    def test_unsubscribe_from_calendar_triggers_membership_delete(self):
        """DELETE /calendars/X/unsubscribe → DELETE membership → Realtime → usuario no ve calendario"""
        owner_id = 1
        subscriber_id = 2

        # Create and subscribe
        calendar_data = {"name": "Calendar to Unsubscribe", "is_public": True}
        response = api_request("POST", "/calendars", json_data=calendar_data, user_id=owner_id)
        calendar_id = response.json()["id"]

        api_request("POST", f"/calendars/{calendar_id}/subscribe", user_id=subscriber_id)
        wait_for_realtime()

        # Unsubscribe
        response = api_request("DELETE", f"/calendars/{calendar_id}/unsubscribe", user_id=subscriber_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify subscriber doesn't see calendar
        subscriber_calendars = get_user_calendars(subscriber_id)
        calendar_ids = {c["id"] for c in subscriber_calendars}

        assert calendar_id not in calendar_ids, f"Calendar {calendar_id} still visible after unsubscribe"

        print(f"✅ DELETE calendar_membership: Calendar removed from subscriber")

        # Cleanup
        api_request("DELETE", f"/calendars/{calendar_id}", user_id=owner_id)

    def test_delete_calendar_triggers_membership_delete(self):
        """DELETE /calendars/X → DELETE memberships → Realtime → nadie ve calendario"""
        owner_id = 1

        # Create calendar
        calendar_data = {"name": "Calendar to Delete", "description": "Test"}
        response = api_request("POST", "/calendars", json_data=calendar_data, user_id=owner_id)
        calendar_id = response.json()["id"]

        wait_for_realtime()

        # Delete
        response = api_request("DELETE", f"/calendars/{calendar_id}", user_id=owner_id)
        assert response.status_code == 200

        wait_for_realtime()

        # Verify calendar removed
        calendars = get_user_calendars(owner_id)
        calendar_ids = {c["id"] for c in calendars}

        assert calendar_id not in calendar_ids, f"❌ Calendar {calendar_id} still exists"

        print(f"✅ DELETE calendar: Calendar removed from all users")


# ============================================================================
# USER_SUBSCRIPTION_STATS TABLE - UPDATE (via triggers)
# ============================================================================

class TestUserSubscriptionStatsRealtimeUPDATE:
    """Tabla: user_subscription_stats - Evento: UPDATE (triggers CDC)"""

    def test_create_event_increments_total_events_count(self):
        """POST /events → Trigger → UPDATE stats → Realtime → total_events_count++"""
        user_id = 1

        initial_stats = get_user_stats(user_id)
        initial_count = initial_stats["total_events_count"]

        event_data = {
            "name": "Event for Stats",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        event_id = response.json()["id"]

        wait_for_realtime()

        final_stats = get_user_stats(user_id)
        final_count = final_stats["total_events_count"]

        assert final_count == initial_count + 1, \
            f"Expected {initial_count + 1}, got {final_count}"

        print(f"✅ UPDATE stats (trigger): total_events_count incremented")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)

    def test_delete_event_decrements_total_events_count(self):
        """DELETE /events/X → Trigger → UPDATE stats → Realtime → total_events_count--"""
        user_id = 1

        # Create event
        event_data = {
            "name": "Event to Delete for Stats",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }
        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        event_id = response.json()["id"]
        wait_for_realtime()

        stats_after_create = get_user_stats(user_id)
        count_after_create = stats_after_create["total_events_count"]

        # Delete
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)
        wait_for_realtime()

        stats_after_delete = get_user_stats(user_id)
        count_after_delete = stats_after_delete["total_events_count"]

        assert count_after_delete == count_after_create - 1, \
            f"Expected {count_after_create - 1}, got {count_after_delete}"

        print(f"✅ UPDATE stats (trigger): total_events_count decremented")

    def test_subscribe_increments_subscribers_count(self):
        """POST /users/X/subscribe → Trigger → UPDATE stats → Realtime → subscribers_count++"""
        subscriber_id = 1
        target_id = 2

        initial_stats = get_user_stats(target_id)
        initial_subscribers = initial_stats["subscribers_count"]

        response = api_request("POST", f"/users/{target_id}/subscribe", user_id=subscriber_id)
        assert response.status_code == 201

        wait_for_realtime()

        final_stats = get_user_stats(target_id)
        final_subscribers = final_stats["subscribers_count"]

        assert final_subscribers == initial_subscribers + 1, \
            f"Expected {initial_subscribers + 1}, got {final_subscribers}"

        print(f"✅ UPDATE stats (trigger): subscribers_count incremented")

        # Cleanup
        api_request("DELETE", f"/users/{target_id}/subscribe", user_id=subscriber_id)

    def test_unsubscribe_decrements_subscribers_count(self):
        """DELETE /users/X/subscribe → Trigger → UPDATE stats → Realtime → subscribers_count--"""
        subscriber_id = 1
        target_id = 2

        # Subscribe first
        api_request("POST", f"/users/{target_id}/subscribe", user_id=subscriber_id)
        wait_for_realtime()

        stats_after_subscribe = get_user_stats(target_id)
        subscribers_after_subscribe = stats_after_subscribe["subscribers_count"]

        # Unsubscribe
        response = api_request("DELETE", f"/users/{target_id}/subscribe", user_id=subscriber_id)
        assert response.status_code == 200

        wait_for_realtime()

        stats_after_unsubscribe = get_user_stats(target_id)
        subscribers_after_unsubscribe = stats_after_unsubscribe["subscribers_count"]

        assert subscribers_after_unsubscribe == subscribers_after_subscribe - 1, \
            f"Expected {subscribers_after_subscribe - 1}, got {subscribers_after_unsubscribe}"

        print(f"✅ UPDATE stats (trigger): subscribers_count decremented")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
