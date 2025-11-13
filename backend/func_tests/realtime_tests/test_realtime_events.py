"""
Tests de integración Realtime para eventos

OBJETIVO: Verificar que el flujo completo funciona end-to-end:
1. Mutación via API (POST/PATCH/DELETE)
2. Realtime notifica cambios (Supabase Realtime)
3. Endpoints GET reflejan los cambios inmediatamente

IMPORTANTE: Estos tests requieren PostgreSQL + Supabase Realtime corriendo.
Ejecutar con: pytest backend/func_tests/test_realtime_events.py -v -s
"""

import os
import time
import pytest
import requests
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import List, Dict, Optional
import threading
import queue

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
    """Crea conexión directa a PostgreSQL"""
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)


def api_request(method: str, path: str, json_data=None, user_id: int = 1):
    """Realiza request a la API con autenticación de test"""
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
    """Obtiene eventos de un usuario via API"""
    response = api_request("GET", f"/users/{user_id}/events", user_id=user_id)
    assert response.status_code == 200, f"Failed to get user events: {response.text}"
    return response.json()


def wait_for_realtime_propagation(max_wait: float = 2.0):
    """
    Espera a que Realtime propague cambios

    En producción, Realtime es casi instantáneo, pero en tests
    puede haber pequeños delays de red/procesamiento.
    """
    time.sleep(max_wait)


class TestEventRealtimeFlow:
    """Tests de flujo completo para operaciones de eventos"""

    def test_create_event_appears_in_user_events(self):
        """
        FLUJO COMPLETO: Crear evento

        1. GET /users/1/events -> estado inicial
        2. POST /events -> crear evento
        3. Esperar propagación Realtime
        4. GET /users/1/events -> verificar que aparece el nuevo evento
        """
        user_id = 1

        # 1. Estado inicial
        initial_events = get_user_events(user_id)
        initial_event_ids = {e["id"] for e in initial_events}
        initial_count = len(initial_events)

        print(f"\n📊 Initial state: {initial_count} events")

        # 2. Crear evento
        event_data = {
            "name": "Realtime Test Event",
            "description": "Testing end-to-end flow",
            "start_date": "2025-12-01T10:00:00Z",
            "timezone": "Europe/Madrid",
            "event_type": "regular",
            "owner_id": user_id,
        }

        create_response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        assert create_response.status_code == 201, f"Event creation failed: {create_response.text}"
        event_id = create_response.json()["id"]

        print(f"✅ Created event ID: {event_id}")

        # 3. Esperar propagación Realtime
        wait_for_realtime_propagation()

        # 4. Verificar que aparece en GET /users/1/events
        final_events = get_user_events(user_id)
        final_event_ids = {e["id"] for e in final_events}
        final_count = len(final_events)

        print(f"📊 Final state: {final_count} events")

        # ASSERTIONS
        assert event_id in final_event_ids, f"Event {event_id} NOT FOUND in user events after creation! " f"Expected in {final_event_ids}, but missing."

        assert final_count == initial_count + 1, f"Expected {initial_count + 1} events, got {final_count}"

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)

    def test_delete_event_removes_from_user_events(self):
        """
        FLUJO COMPLETO: Eliminar evento (owner)

        1. POST /events -> crear evento temporal
        2. GET /users/1/events -> verificar que existe
        3. DELETE /events/{id} -> eliminar
        4. Esperar propagación Realtime
        5. GET /users/1/events -> verificar que NO aparece
        """
        user_id = 1

        # 1. Crear evento temporal
        event_data = {
            "name": "Event to Delete",
            "description": "Will be deleted",
            "start_date": "2025-12-01T10:00:00Z",
            "timezone": "Europe/Madrid",
            "event_type": "regular",
            "owner_id": user_id,
        }

        create_response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        assert create_response.status_code == 201
        event_id = create_response.json()["id"]

        print(f"\n✅ Created temporary event ID: {event_id}")

        # 2. Esperar y verificar que existe
        wait_for_realtime_propagation()
        events_before = get_user_events(user_id)
        event_ids_before = {e["id"] for e in events_before}

        assert event_id in event_ids_before, f"Event {event_id} should exist before deletion"

        print(f"✅ Event {event_id} confirmed in user events")

        # 3. Eliminar evento
        delete_response = api_request("DELETE", f"/events/{event_id}", user_id=user_id)
        assert delete_response.status_code == 200, f"Delete failed: {delete_response.text}"

        print(f"✅ DELETE request returned 200")

        # 4. Esperar propagación Realtime
        wait_for_realtime_propagation()

        # 5. Verificar que NO aparece
        events_after = get_user_events(user_id)
        event_ids_after = {e["id"] for e in events_after}

        print(f"📊 Events before: {len(events_before)}, after: {len(events_after)}")

        # CRITICAL ASSERTION
        assert event_id not in event_ids_after, f"❌ FATAL: Event {event_id} STILL EXISTS after deletion! " f"Found in: {event_ids_after}"

        assert len(events_after) == len(events_before) - 1, f"Expected {len(events_before) - 1} events after deletion, got {len(events_after)}"

        print(f"✅ Event {event_id} successfully removed from user events")

    def test_update_event_reflects_in_user_events(self):
        """
        FLUJO COMPLETO: Actualizar evento

        1. POST /events -> crear evento
        2. PUT /events/{id} -> actualizar nombre
        3. Esperar propagación Realtime
        4. GET /users/1/events -> verificar cambios reflejados
        """
        user_id = 1

        # 1. Crear evento
        event_data = {
            "name": "Original Name",
            "description": "Original description",
            "start_date": "2025-12-01T10:00:00Z",
            "timezone": "Europe/Madrid",
            "event_type": "regular",
            "owner_id": user_id,
        }

        create_response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        assert create_response.status_code == 201
        event_id = create_response.json()["id"]

        print(f"\n✅ Created event ID: {event_id}")

        # 2. Actualizar evento
        update_data = {"name": "Updated Name"}
        update_response = api_request("PUT", f"/events/{event_id}", json_data=update_data, user_id=user_id)
        assert update_response.status_code == 200, f"Update failed: {update_response.text}"

        print(f"✅ Updated event name")

        # 3. Esperar propagación Realtime
        wait_for_realtime_propagation()

        # 4. Verificar cambios en GET /users/1/events
        events = get_user_events(user_id)
        updated_event = next((e for e in events if e["id"] == event_id), None)

        assert updated_event is not None, f"Event {event_id} not found after update"

        assert updated_event["name"] == "Updated Name", f"Expected name='Updated Name', got '{updated_event['name']}'"

        print(f"✅ Event name updated correctly in user events")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)

    def test_leave_event_removes_from_non_owner_user_events(self):
        """
        FLUJO COMPLETO: Usuario NO-OWNER abandona evento

        1. User 1 crea evento
        2. User 2 recibe invitación
        3. User 2 acepta invitación
        4. GET /users/2/events -> verificar que aparece
        5. User 2 DELETE /events/{id}/interaction -> abandonar
        6. Esperar propagación Realtime
        7. GET /users/2/events -> verificar que NO aparece
        8. GET /users/1/events -> verificar que SIGUE apareciendo (owner)
        """
        owner_id = 1
        invitee_id = 2

        # 1. Owner crea evento
        event_data = {
            "name": "Event to Leave",
            "description": "Testing leave flow",
            "start_date": "2025-12-01T10:00:00Z",
            "timezone": "Europe/Madrid",
            "event_type": "regular",
            "owner_id": owner_id,
        }

        create_response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        assert create_response.status_code == 201
        event_id = create_response.json()["id"]

        print(f"\n✅ Owner (user {owner_id}) created event ID: {event_id}")

        # 2. Invitar a user 2
        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "pending",
        }

        invite_response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        assert invite_response.status_code == 201
        interaction_id = invite_response.json()["id"]

        print(f"✅ User {invitee_id} invited (interaction {interaction_id})")

        # 3. User 2 acepta
        accept_data = {"status": "accepted"}
        accept_response = api_request("PATCH", f"/interactions/{interaction_id}", json_data=accept_data, user_id=invitee_id)
        assert accept_response.status_code == 200

        print(f"✅ User {invitee_id} accepted invitation")

        # 4. Esperar y verificar que aparece para user 2
        wait_for_realtime_propagation()
        invitee_events_before = get_user_events(invitee_id)
        invitee_event_ids_before = {e["id"] for e in invitee_events_before}

        assert event_id in invitee_event_ids_before, f"Event {event_id} should appear in user {invitee_id} events after accepting"

        print(f"✅ Event {event_id} confirmed in user {invitee_id} events")

        # 5. User 2 abandona evento
        leave_response = api_request("DELETE", f"/events/{event_id}/interaction", user_id=invitee_id)
        assert leave_response.status_code == 200, f"Leave failed: {leave_response.text}"

        print(f"✅ User {invitee_id} left event {event_id}")

        # 6. Esperar propagación
        wait_for_realtime_propagation()

        # 7. Verificar que NO aparece para user 2
        invitee_events_after = get_user_events(invitee_id)
        invitee_event_ids_after = {e["id"] for e in invitee_events_after}

        assert event_id not in invitee_event_ids_after, f"❌ FATAL: Event {event_id} STILL in user {invitee_id} events after leaving!"

        print(f"✅ Event {event_id} removed from user {invitee_id} events")

        # 8. Verificar que SIGUE apareciendo para owner
        owner_events = get_user_events(owner_id)
        owner_event_ids = {e["id"] for e in owner_events}

        assert event_id in owner_event_ids, f"Event {event_id} should STILL appear in owner (user {owner_id}) events"

        print(f"✅ Event {event_id} still exists for owner (user {owner_id})")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)

    def test_reject_invitation_removes_from_user_events(self):
        """
        FLUJO COMPLETO: Usuario rechaza invitación

        1. User 1 crea evento e invita a user 2
        2. GET /users/2/events -> verificar que aparece (pending)
        3. User 2 rechaza invitación
        4. Esperar propagación Realtime
        5. GET /users/2/events -> verificar que NO aparece
        """
        owner_id = 1
        invitee_id = 2

        # 1. Crear evento e invitar
        event_data = {
            "name": "Event to Reject",
            "description": "Testing rejection flow",
            "start_date": "2025-12-01T10:00:00Z",
            "timezone": "Europe/Madrid",
            "event_type": "regular",
            "owner_id": owner_id,
        }

        create_response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        assert create_response.status_code == 201
        event_id = create_response.json()["id"]

        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "pending",
        }

        invite_response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        assert invite_response.status_code == 201
        interaction_id = invite_response.json()["id"]

        print(f"\n✅ Event {event_id} created and user {invitee_id} invited")

        # 2. Verificar que aparece como pending para user 2
        wait_for_realtime_propagation()
        invitee_events_before = get_user_events(invitee_id)
        invitee_event_ids_before = {e["id"] for e in invitee_events_before}

        assert event_id in invitee_event_ids_before, f"Event {event_id} should appear in user {invitee_id} events (pending)"

        print(f"✅ Event {event_id} visible to user {invitee_id} (pending)")

        # 3. User 2 rechaza
        reject_data = {"status": "rejected"}
        reject_response = api_request("PATCH", f"/interactions/{interaction_id}", json_data=reject_data, user_id=invitee_id)
        assert reject_response.status_code == 200

        print(f"✅ User {invitee_id} rejected invitation")

        # 4. Esperar propagación
        wait_for_realtime_propagation()

        # 5. Verificar que NO aparece
        invitee_events_after = get_user_events(invitee_id)
        invitee_event_ids_after = {e["id"] for e in invitee_events_after}

        assert event_id not in invitee_event_ids_after, f"❌ FATAL: Event {event_id} STILL in user {invitee_id} events after rejection!"

        print(f"✅ Event {event_id} removed from user {invitee_id} events after rejection")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)


class TestEventInteractionRealtimeFlow:
    """Tests de flujo completo para interacciones de eventos"""

    def test_accept_invitation_updates_interaction_data(self):
        """
        FLUJO: Aceptar invitación actualiza interaction_data en el evento

        1. User 1 crea evento e invita a user 2
        2. GET /users/2/events -> verificar status=pending
        3. User 2 acepta
        4. Esperar propagación
        5. GET /users/2/events -> verificar status=accepted
        """
        owner_id = 1
        invitee_id = 2

        # 1. Crear e invitar
        event_data = {
            "name": "Event to Accept",
            "start_date": "2025-12-01T10:00:00Z",
            "timezone": "Europe/Madrid",
            "event_type": "regular",
            "owner_id": owner_id,
        }

        create_response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        event_id = create_response.json()["id"]

        invitation_data = {
            "event_id": event_id,
            "user_id": invitee_id,
            "interaction_type": "invited",
            "status": "pending",
        }

        invite_response = api_request("POST", "/interactions", json_data=invitation_data, user_id=owner_id)
        interaction_id = invite_response.json()["id"]

        print(f"\n✅ Event {event_id} created, user {invitee_id} invited")

        # 2. Verificar status inicial = pending
        wait_for_realtime_propagation()
        events_before = get_user_events(invitee_id)
        event_before = next((e for e in events_before if e["id"] == event_id), None)

        assert event_before is not None
        assert event_before.get("interaction", {}).get("status") == "pending"

        print(f"✅ Initial status: pending")

        # 3. Aceptar
        accept_data = {"status": "accepted"}
        api_request("PATCH", f"/interactions/{interaction_id}", json_data=accept_data, user_id=invitee_id)

        # 4. Esperar propagación
        wait_for_realtime_propagation()

        # 5. Verificar status = accepted
        events_after = get_user_events(invitee_id)
        event_after = next((e for e in events_after if e["id"] == event_id), None)

        assert event_after is not None
        assert event_after.get("interaction", {}).get("status") == "accepted", f"Expected status='accepted', got '{event_after.get('interaction', {}).get('status')}'"

        print(f"✅ Status updated to: accepted")

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
