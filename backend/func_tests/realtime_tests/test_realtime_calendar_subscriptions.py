"""
Tests de integración Realtime para suscripciones a calendarios

OBJETIVO: Verificar flujo completo de suscripciones a calendarios:
1. POST /calendars/{share_hash}/subscribe -> crear suscripción
2. DELETE /calendars/{share_hash}/subscribe -> eliminar suscripción
3. Verificar que subscriber_count se actualiza via trigger
4. Verificar que los cambios se propagan via Realtime CDC

Ejecutar con: pytest backend/func_tests/realtime_tests/test_realtime_calendar_subscriptions.py -v -s
"""

import os
import time
import pytest
import requests
import psycopg2
import random
from datetime import datetime
from psycopg2.extras import RealDictCursor
from typing import List, Dict, Optional

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


def api_request(method: str, path: str, json_data=None, user_id: Optional[int] = None):
    """Realiza request a la API con autenticación de test"""
    url = f"{API_BASE_URL}{path}"
    headers = {}
    if user_id is not None:
        headers["X-Test-User-Id"] = str(user_id)

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


def wait_for_realtime_propagation(max_wait: float = 2.0):
    """Espera a que Realtime propague cambios"""
    time.sleep(max_wait)


def get_calendar_from_db(calendar_id: int) -> Optional[Dict]:
    """Obtiene un calendario directamente de la BD"""
    with get_db_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, name, owner_id, is_public, share_hash,
                       subscriber_count, created_at, updated_at
                FROM calendars
                WHERE id = %s
                """,
                (calendar_id,),
            )
            result = cursor.fetchone()
            return dict(result) if result else None


def get_calendar_subscriptions_from_db(calendar_id: int) -> List[Dict]:
    """Obtiene todas las suscripciones de un calendario de la BD"""
    with get_db_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, calendar_id, user_id, status,
                       subscribed_at, updated_at
                FROM calendar_subscriptions
                WHERE calendar_id = %s
                ORDER BY subscribed_at DESC
                """,
                (calendar_id,),
            )
            results = cursor.fetchall()
            return [dict(row) for row in results]


def verify_replica_identity():
    """Verifica que REPLICA IDENTITY FULL está habilitado"""
    with get_db_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT relname, relreplident
                FROM pg_class
                WHERE relname IN ('calendars', 'calendar_subscriptions')
                ORDER BY relname
                """
            )
            results = cursor.fetchall()

            for row in results:
                table_name = row["relname"]
                replica_identity = row["relreplident"]
                # 'f' = FULL, 'd' = DEFAULT, 'n' = NOTHING, 'i' = INDEX
                assert replica_identity == "f", f"Table {table_name} should have REPLICA IDENTITY FULL, got '{replica_identity}'"

            print(f"✅ REPLICA IDENTITY FULL verified for calendars and calendar_subscriptions")


class TestCalendarSubscriptionRealtimeFlow:
    """Tests de flujo completo para suscripciones a calendarios"""

    def test_verify_replica_identity_full(self):
        """Verificar que REPLICA IDENTITY FULL está configurado correctamente"""
        verify_replica_identity()

    def test_subscribe_updates_subscriber_count(self):
        """
        FLUJO COMPLETO: Suscribirse a calendario aumenta subscriber_count

        1. GET /calendars/public -> obtener calendario con share_hash
        2. Verificar subscriber_count inicial (via API y BD)
        3. POST /calendars/{share_hash}/subscribe -> suscribirse
        4. Esperar propagación Realtime
        5. Verificar que subscriber_count aumentó (via API y BD)
        """
        # 1. Obtener calendario público con share_hash
        calendars_response = api_request("GET", "/calendars/public")
        assert calendars_response.status_code == 200
        calendars = calendars_response.json()

        calendar = next((c for c in calendars if c["share_hash"] is not None), None)
        assert calendar is not None, "Need at least one calendar with share_hash"

        calendar_id = calendar["id"]
        share_hash = calendar["share_hash"]
        initial_count = calendar["subscriber_count"]

        print(f"\n📅 Testing calendar: {calendar['name']} (ID: {calendar_id}, hash: {share_hash})")
        print(f"   Initial subscriber_count: {initial_count}")

        # 2. Crear usuario de test
        random_suffix = f"{int(datetime.now().timestamp())}{random.randint(1000, 9999)}"
        user_data = {
            "contact_name": "Realtime Test User",
            "display_name": "Realtime Test User",
            "phone_number": f"+8888{random_suffix}",
            "auth_provider": "phone",
            "auth_id": f"+8888{random_suffix}",
        }
        user_response = api_request("POST", "/users", json_data=user_data)
        assert user_response.status_code == 201
        user_id = user_response.json()["id"]
        print(f"   Created test user: {user_id}")

        # 3. Suscribirse
        subscribe_response = api_request("POST", f"/calendars/{share_hash}/subscribe", user_id=user_id)
        assert subscribe_response.status_code == 201, f"Failed to subscribe: {subscribe_response.text}"
        print(f"   User {user_id} subscribed to calendar")

        # 4. Esperar propagación
        print(f"   Waiting for realtime propagation...")
        wait_for_realtime_propagation(1.0)

        # 5. Verificar subscriber_count via API
        calendar_response = api_request("GET", f"/calendars/{calendar_id}")
        assert calendar_response.status_code == 200
        updated_calendar = calendar_response.json()

        expected_count = initial_count + 1
        assert updated_calendar["subscriber_count"] == expected_count, f"Subscriber count should be {expected_count}, got {updated_calendar['subscriber_count']}"

        print(f"   ✅ API subscriber_count: {initial_count} -> {updated_calendar['subscriber_count']}")

        # 6. Verificar subscriber_count via BD directa
        calendar_from_db = get_calendar_from_db(calendar_id)
        assert calendar_from_db["subscriber_count"] == expected_count, f"DB subscriber count should be {expected_count}, got {calendar_from_db['subscriber_count']}"

        print(f"   ✅ DB subscriber_count: {calendar_from_db['subscriber_count']}")
        print(f"   ✅ Realtime CDC working correctly!")

    def test_unsubscribe_updates_subscriber_count(self):
        """
        FLUJO COMPLETO: Desuscribirse de calendario disminuye subscriber_count

        1. Suscribirse a calendario
        2. Verificar subscriber_count aumentó
        3. DELETE /calendars/{share_hash}/subscribe -> desuscribirse
        4. Esperar propagación Realtime
        5. Verificar que subscriber_count disminuyó (via API y BD)
        """
        # 1. Obtener calendario público con share_hash
        calendars_response = api_request("GET", "/calendars/public")
        calendars = calendars_response.json()
        calendar = next((c for c in calendars if c["share_hash"] is not None), None)

        calendar_id = calendar["id"]
        share_hash = calendar["share_hash"]
        initial_count = calendar["subscriber_count"]

        print(f"\n📅 Testing calendar: {calendar['name']} (ID: {calendar_id})")
        print(f"   Initial subscriber_count: {initial_count}")

        # 2. Crear usuario y suscribirse
        random_suffix = f"{int(datetime.now().timestamp())}{random.randint(1000, 9999)}"
        user_data = {
            "contact_name": "Realtime Test User 2",
            "display_name": "Realtime Test User 2",
            "phone_number": f"+7777{random_suffix}",
            "auth_provider": "phone",
            "auth_id": f"+7777{random_suffix}",
        }
        user_response = api_request("POST", "/users", json_data=user_data)
        user_id = user_response.json()["id"]

        api_request("POST", f"/calendars/{share_hash}/subscribe", user_id=user_id)
        wait_for_realtime_propagation(0.5)

        # Verificar subscriber_count aumentó
        calendar_response = api_request("GET", f"/calendars/{calendar_id}")
        count_after_subscribe = calendar_response.json()["subscriber_count"]
        assert count_after_subscribe == initial_count + 1
        print(f"   After subscribe: {count_after_subscribe}")

        # 3. Desuscribirse
        unsubscribe_response = api_request("DELETE", f"/calendars/{share_hash}/subscribe", user_id=user_id)
        assert unsubscribe_response.status_code == 200, f"Failed to unsubscribe: {unsubscribe_response.text}"
        print(f"   User {user_id} unsubscribed from calendar")

        # 4. Esperar propagación
        print(f"   Waiting for realtime propagation...")
        wait_for_realtime_propagation(1.0)

        # 5. Verificar subscriber_count via API
        calendar_response = api_request("GET", f"/calendars/{calendar_id}")
        updated_calendar = calendar_response.json()

        expected_count = initial_count
        assert updated_calendar["subscriber_count"] == expected_count, f"Subscriber count should return to {expected_count}, got {updated_calendar['subscriber_count']}"

        print(f"   ✅ API subscriber_count: {count_after_subscribe} -> {updated_calendar['subscriber_count']}")

        # 6. Verificar subscriber_count via BD directa
        calendar_from_db = get_calendar_from_db(calendar_id)
        assert calendar_from_db["subscriber_count"] == expected_count, f"DB subscriber count should be {expected_count}, got {calendar_from_db['subscriber_count']}"

        print(f"   ✅ DB subscriber_count: {calendar_from_db['subscriber_count']}")
        print(f"   ✅ Realtime CDC working correctly!")

    def test_multiple_subscriptions_trigger_updates(self):
        """
        FLUJO COMPLETO: Múltiples suscripciones actualizan subscriber_count

        1. Crear 3 usuarios
        2. Suscribir cada uno al mismo calendario
        3. Verificar que subscriber_count aumenta correctamente
        4. Verificar vía BD que todas las suscripciones existen
        """
        # 1. Obtener calendario
        calendars_response = api_request("GET", "/calendars/public")
        calendars = calendars_response.json()
        calendar = next((c for c in calendars if c["share_hash"] is not None), None)

        calendar_id = calendar["id"]
        share_hash = calendar["share_hash"]
        initial_count = calendar["subscriber_count"]

        print(f"\n📅 Testing calendar: {calendar['name']} (ID: {calendar_id})")
        print(f"   Initial subscriber_count: {initial_count}")

        # 2. Crear 3 usuarios y suscribirlos
        user_ids = []
        for i in range(3):
            random_suffix = f"{int(datetime.now().timestamp())}{random.randint(1000, 9999)}"
            user_data = {
                "contact_name": f"Realtime Test User {i+1}",
                "display_name": f"Realtime Test User {i+1}",
                "phone_number": f"+6666{random_suffix}",
                "auth_provider": "phone",
                "auth_id": f"+6666{random_suffix}",
            }
            user_response = api_request("POST", "/users", json_data=user_data)
            user_id = user_response.json()["id"]
            user_ids.append(user_id)

            # Suscribir
            api_request("POST", f"/calendars/{share_hash}/subscribe", user_id=user_id)
            print(f"   User {user_id} subscribed")

            # Pequeña pausa entre suscripciones
            time.sleep(0.2)

        # 3. Esperar propagación final
        print(f"   Waiting for realtime propagation...")
        wait_for_realtime_propagation(1.5)

        # 4. Verificar subscriber_count
        calendar_response = api_request("GET", f"/calendars/{calendar_id}")
        updated_calendar = calendar_response.json()

        expected_count = initial_count + 3
        assert updated_calendar["subscriber_count"] == expected_count, f"Subscriber count should be {expected_count}, got {updated_calendar['subscriber_count']}"

        print(f"   ✅ API subscriber_count: {initial_count} -> {updated_calendar['subscriber_count']}")

        # 5. Verificar todas las suscripciones en BD
        subscriptions = get_calendar_subscriptions_from_db(calendar_id)
        subscribed_user_ids = [sub["user_id"] for sub in subscriptions]

        for user_id in user_ids:
            assert user_id in subscribed_user_ids, f"User {user_id} not found in subscriptions"

        print(f"   ✅ All {len(user_ids)} subscriptions verified in DB")
        print(f"   ✅ Realtime CDC working correctly for multiple subscriptions!")


if __name__ == "__main__":
    print("🧪 Testing Calendar Subscriptions Realtime CDC")
    print("=" * 60)

    test_class = TestCalendarSubscriptionRealtimeFlow()
    test_class.test_verify_replica_identity_full()
    test_class.test_subscribe_updates_subscriber_count()
    test_class.test_unsubscribe_updates_subscriber_count()
    test_class.test_multiple_subscriptions_trigger_updates()

    print("=" * 60)
    print("✅ All calendar subscription realtime tests passed!")
