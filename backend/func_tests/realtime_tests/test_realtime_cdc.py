"""
Tests de Realtime/CDC - Verifican que triggers actualizan user_subscription_stats

IMPORTANTE: Estos tests requieren PostgreSQL corriendo (no SQLite).
Ejecutar con: pytest backend/func_tests/test_realtime_cdc.py -v

Objetivo: Demostrar que la arquitectura CDC funciona correctamente:
1. API call crea/modifica datos
2. Triggers PostgreSQL actualizan user_subscription_stats automáticamente
3. Realtime puede notificar cambios (verificado indirectamente vía stats)
"""

import os
import pytest
import requests
import psycopg2
from psycopg2.extras import RealDictCursor

# Configuración de conexión
API_BASE_URL = "http://localhost:8001/api/v1"

# Lee configuración desde variables de entorno o usa defaults
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


def get_user_stats(user_id: int) -> dict:
    """Obtiene estadísticas de un usuario directamente de la BD"""
    with get_db_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT user_id, total_events_count, new_events_count,
                       subscribers_count, last_event_date, updated_at
                FROM user_subscription_stats
                WHERE user_id = %s
                """,
                (user_id,),
            )
            result = cursor.fetchone()
            return dict(result) if result else None


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
    elif method == "PATCH":
        response = requests.patch(url, json=json_data, headers=headers)
    else:
        raise ValueError(f"Unsupported method: {method}")

    return response


class TestRealtimeCDC:
    """Suite de tests para verificar arquitectura Realtime/CDC"""

    def test_create_event_updates_stats_via_trigger(self):
        """
        PRUEBA: Crear evento incrementa total_events_count automáticamente

        Flujo:
        1. GET stats iniciales del usuario
        2. POST crear nuevo evento
        3. GET stats finales
        4. VERIFICAR que total_events_count incrementó en 1
        """
        user_id = 1

        # 1. Estado inicial
        initial_stats = get_user_stats(user_id)
        assert initial_stats is not None, f"User {user_id} debe tener stats iniciales"
        initial_count = initial_stats["total_events_count"]

        # 2. Crear evento via API
        event_data = {
            "name": "CDC Test Event",
            "description": "Testing CDC triggers",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }

        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        assert response.status_code == 201, f"Event creation failed: {response.text}"
        event_id = response.json()["id"]

        # 3. Verificar stats se actualizaron automáticamente
        final_stats = get_user_stats(user_id)
        assert final_stats["total_events_count"] == initial_count + 1, f"Expected total_events_count={initial_count + 1}, got {final_stats['total_events_count']}"

        # Cleanup: eliminar evento de test
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)

    def test_delete_event_decrements_stats_via_trigger(self):
        """
        PRUEBA: Eliminar evento decrementa total_events_count automáticamente

        Flujo:
        1. POST crear evento temporal
        2. GET stats después de crear
        3. DELETE evento
        4. VERIFICAR que total_events_count decrementó en 1
        """
        user_id = 1

        # 1. Crear evento temporal
        event_data = {
            "name": "Temporary Event for Delete Test",
            "description": "Will be deleted",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }

        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        assert response.status_code == 201
        event_id = response.json()["id"]

        # 2. Stats después de crear
        stats_after_create = get_user_stats(user_id)
        count_after_create = stats_after_create["total_events_count"]

        # 3. Eliminar evento
        response = api_request("DELETE", f"/events/{event_id}", user_id=user_id)
        assert response.status_code in [200, 204], f"Expected 200 or 204, got {response.status_code}"

        # 4. Verificar stats se actualizaron
        stats_after_delete = get_user_stats(user_id)
        assert stats_after_delete["total_events_count"] == count_after_create - 1, f"Expected total_events_count={count_after_create - 1}, got {stats_after_delete['total_events_count']}"

    def test_subscription_increments_subscribers_count(self):
        """
        PRUEBA: Suscribirse a evento incrementa subscribers_count del owner

        Flujo:
        1. User 1 crea evento
        2. GET stats iniciales de user 1
        3. User 2 se suscribe al evento (POST interaction)
        4. VERIFICAR que subscribers_count de user 1 incrementó
        """
        owner_id = 1
        subscriber_id = 2

        # 1. Crear evento como user 1
        event_data = {
            "name": "Event for Subscription Test",
            "description": "Testing subscription triggers",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }

        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        assert response.status_code == 201
        event_id = response.json()["id"]

        # 2. Stats iniciales del owner
        initial_stats = get_user_stats(owner_id)
        initial_subscribers = initial_stats["subscribers_count"]

        # 3. User 2 se suscribe
        interaction_data = {
            "event_id": event_id,
            "user_id": subscriber_id,
            "interaction_type": "subscribed",
            "status": "accepted",
        }

        response = api_request("POST", "/interactions", json_data=interaction_data, user_id=subscriber_id)
        assert response.status_code == 201, f"Subscription failed: {response.text}"
        interaction_id = response.json()["id"]

        # 4. Verificar subscribers_count incrementó
        final_stats = get_user_stats(owner_id)
        assert final_stats["subscribers_count"] == initial_subscribers + 1, f"Expected subscribers_count={initial_subscribers + 1}, got {final_stats['subscribers_count']}"

        # Cleanup
        api_request("DELETE", f"/interactions/{interaction_id}", user_id=subscriber_id)
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)

    def test_unsubscription_decrements_subscribers_count(self):
        """
        PRUEBA: Desuscribirse de evento decrementa subscribers_count del owner

        Flujo:
        1. User 1 crea evento
        2. User 2 se suscribe
        3. GET stats de user 1
        4. User 2 se desuscribe (DELETE interaction)
        5. VERIFICAR que subscribers_count de user 1 decrementó
        """
        owner_id = 1
        subscriber_id = 2

        # 1. Crear evento
        event_data = {
            "name": "Event for Unsubscription Test",
            "description": "Testing unsubscription triggers",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": owner_id,
        }

        response = api_request("POST", "/events", json_data=event_data, user_id=owner_id)
        assert response.status_code == 201
        event_id = response.json()["id"]

        # 2. User 2 se suscribe
        interaction_data = {
            "event_id": event_id,
            "user_id": subscriber_id,
            "interaction_type": "subscribed",
            "status": "accepted",
        }

        response = api_request("POST", "/interactions", json_data=interaction_data, user_id=subscriber_id)
        assert response.status_code == 201
        interaction_id = response.json()["id"]

        # 3. Stats después de suscribirse
        stats_after_sub = get_user_stats(owner_id)
        subscribers_after_sub = stats_after_sub["subscribers_count"]

        # 4. User 2 se desuscribe
        response = api_request("DELETE", f"/interactions/{interaction_id}", user_id=subscriber_id)
        assert response.status_code in [200, 204], f"Expected 200 or 204, got {response.status_code}"

        # 5. Verificar subscribers_count decrementó
        stats_after_unsub = get_user_stats(owner_id)
        assert stats_after_unsub["subscribers_count"] == subscribers_after_sub - 1, f"Expected subscribers_count={subscribers_after_sub - 1}, got {stats_after_unsub['subscribers_count']}"

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=owner_id)

    def test_new_events_count_tracks_recent_events(self):
        """
        PRUEBA: new_events_count solo cuenta eventos de últimos 7 días

        Flujo:
        1. Crear evento con fecha reciente (< 7 días)
        2. VERIFICAR que new_events_count y total_events_count incrementan

        Nota: Para probar eventos antiguos (> 7 días) necesitaríamos
        crear eventos con created_at en el pasado, lo cual requiere
        manipulación directa de BD o endpoints especiales.
        """
        user_id = 1

        # 1. Estado inicial
        initial_stats = get_user_stats(user_id)
        initial_new_count = initial_stats["new_events_count"]
        initial_total_count = initial_stats["total_events_count"]

        # 2. Crear evento reciente (fecha en futuro, created_at será NOW())
        event_data = {
            "name": "Recent Event Test",
            "description": "Should increment new_events_count",
            "start_date": "2025-12-01T10:00:00Z",
            "event_type": "regular",
            "owner_id": user_id,
        }

        response = api_request("POST", "/events", json_data=event_data, user_id=user_id)
        assert response.status_code == 201
        event_id = response.json()["id"]

        # 3. Verificar ambos contadores incrementaron
        final_stats = get_user_stats(user_id)
        assert final_stats["new_events_count"] == initial_new_count + 1, f"Expected new_events_count={initial_new_count + 1}, got {final_stats['new_events_count']}"
        assert final_stats["total_events_count"] == initial_total_count + 1, f"Expected total_events_count={initial_total_count + 1}, got {final_stats['total_events_count']}"

        # Cleanup
        api_request("DELETE", f"/events/{event_id}", user_id=user_id)

    def test_stats_table_has_correct_structure(self):
        """
        PRUEBA: Verificar estructura de tabla user_subscription_stats

        Verifica que la tabla tiene todas las columnas esperadas y
        que está configurada para Realtime (REPLICA IDENTITY FULL)
        """
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # Verificar columnas
                cursor.execute(
                    """
                    SELECT column_name, data_type, is_nullable
                    FROM information_schema.columns
                    WHERE table_name = 'user_subscription_stats'
                    ORDER BY ordinal_position
                """
                )
                columns = cursor.fetchall()

                expected_columns = {
                    "user_id": "integer",
                    "new_events_count": "integer",
                    "total_events_count": "integer",
                    "subscribers_count": "integer",
                    "last_event_date": "timestamp with time zone",
                    "updated_at": "timestamp with time zone",
                }

                actual_columns = {col["column_name"]: col["data_type"] for col in columns}

                for col_name, expected_type in expected_columns.items():
                    assert col_name in actual_columns, f"Missing column: {col_name}"
                    assert actual_columns[col_name] == expected_type, f"Column {col_name} has type {actual_columns[col_name]}, expected {expected_type}"

                # Verificar REPLICA IDENTITY para Realtime
                cursor.execute(
                    """
                    SELECT relreplident
                    FROM pg_class
                    WHERE relname = 'user_subscription_stats'
                """
                )
                result = cursor.fetchone()
                assert result is not None, "Table user_subscription_stats not found"
                assert result["relreplident"] == "f", "Table must have REPLICA IDENTITY FULL for Realtime (expected 'f', got '{result['relreplident']}')"

    def test_triggers_exist_on_events_and_interactions(self):
        """
        PRUEBA: Verificar que todos los triggers CDC están creados

        Verifica que existen los 4 triggers:
        1. event_insert_stats_trigger
        2. event_delete_stats_trigger
        3. subscription_insert_stats_trigger
        4. subscription_delete_stats_trigger
        """
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT tgname, tgrelid::regclass::text as table_name
                    FROM pg_trigger
                    WHERE tgname LIKE '%stats%'
                    ORDER BY tgname
                """
                )
                triggers = cursor.fetchall()

                expected_triggers = {
                    "event_insert_stats_trigger": "events",
                    "event_delete_stats_trigger": "events",
                    "subscription_insert_stats_trigger": "event_interactions",
                    "subscription_delete_stats_trigger": "event_interactions",
                }

                actual_triggers = {t["tgname"]: t["table_name"] for t in triggers}

                for trigger_name, expected_table in expected_triggers.items():
                    assert trigger_name in actual_triggers, f"Missing trigger: {trigger_name}"
                    assert actual_triggers[trigger_name] == expected_table, f"Trigger {trigger_name} is on table {actual_triggers[trigger_name]}, expected {expected_table}"


if __name__ == "__main__":
    # Permitir ejecución directa para debugging
    pytest.main([__file__, "-v", "-s"])
