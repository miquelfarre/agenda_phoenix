"""
Tests de integración Realtime para suscripciones

OBJETIVO: Verificar flujo completo de suscripciones:
1. POST /users/{user_id}/subscribe -> crear suscripción
2. DELETE /users/{user_id}/subscribe -> eliminar suscripción
3. Verificar que GET /users/{user_id}/subscriptions refleja cambios
4. Verificar que user_subscription_stats se actualiza

Ejecutar con: pytest backend/func_tests/test_realtime_subscriptions.py -v -s
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
    elif method == "PATCH":
        response = requests.patch(url, json=json_data, headers=headers)
    else:
        raise ValueError(f"Unsupported method: {method}")

    return response


def get_user_subscriptions(user_id: int) -> List[Dict]:
    """Obtiene suscripciones de un usuario via API"""
    response = api_request("GET", f"/users/{user_id}/subscriptions", user_id=user_id)
    assert response.status_code == 200, f"Failed to get subscriptions: {response.text}"
    return response.json()


def wait_for_realtime_propagation(max_wait: float = 2.0):
    """Espera a que Realtime propague cambios"""
    time.sleep(max_wait)


def get_user_stats(user_id: int) -> Dict:
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


class TestSubscriptionRealtimeFlow:
    """Tests de flujo completo para suscripciones"""

    def test_subscribe_appears_in_subscriptions_list(self):
        """
        FLUJO COMPLETO: Suscribirse a usuario

        1. GET /users/1/subscriptions -> estado inicial
        2. POST /users/7/subscribe -> suscribirse a user 7 (public user: fcbarcelona)
        3. Esperar propagación Realtime
        4. GET /users/1/subscriptions -> verificar que aparece user 7
        """
        subscriber_id = 1
        target_user_id = 7  # fcbarcelona (public user)

        # 1. Estado inicial
        initial_subscriptions = get_user_subscriptions(subscriber_id)
        initial_subscription_ids = {s["id"] for s in initial_subscriptions}
        initial_count = len(initial_subscriptions)

        print(f"\n📊 Initial subscriptions: {initial_count}")

        # 2. Suscribirse a user 2
        subscribe_response = api_request("POST", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)
        assert subscribe_response.status_code == 201, f"Subscribe failed: {subscribe_response.text}"

        print(f"✅ User {subscriber_id} subscribed to user {target_user_id}")

        # 3. Esperar propagación Realtime
        wait_for_realtime_propagation()

        # 4. Verificar que aparece en la lista
        final_subscriptions = get_user_subscriptions(subscriber_id)
        final_subscription_ids = {s["id"] for s in final_subscriptions}
        final_count = len(final_subscriptions)

        print(f"📊 Final subscriptions: {final_count}")

        # ASSERTIONS
        assert target_user_id in final_subscription_ids, f"User {target_user_id} NOT FOUND in subscriptions after subscribing! " f"Expected in {final_subscription_ids}"

        assert final_count == initial_count + 1, f"Expected {initial_count + 1} subscriptions, got {final_count}"

        print(f"✅ User {target_user_id} appears in subscriptions list")

        # Cleanup
        api_request("DELETE", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)

    def test_unsubscribe_removes_from_subscriptions_list(self):
        """
        FLUJO COMPLETO: Desuscribirse de usuario

        1. POST /users/7/subscribe -> suscribirse primero (public user: fcbarcelona)
        2. GET /users/1/subscriptions -> verificar que existe
        3. DELETE /users/7/subscribe -> desuscribirse
        4. Esperar propagación Realtime
        5. GET /users/1/subscriptions -> verificar que NO aparece
        """
        subscriber_id = 1
        target_user_id = 7  # fcbarcelona (public user)

        # 1. Suscribirse primero
        subscribe_response = api_request("POST", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)
        assert subscribe_response.status_code == 201

        print(f"\n✅ User {subscriber_id} subscribed to user {target_user_id}")

        # 2. Esperar y verificar que existe
        wait_for_realtime_propagation()
        subscriptions_before = get_user_subscriptions(subscriber_id)
        subscription_ids_before = {s["id"] for s in subscriptions_before}

        assert target_user_id in subscription_ids_before, f"User {target_user_id} should exist before unsubscribe"

        print(f"✅ User {target_user_id} confirmed in subscriptions")

        # 3. Desuscribirse
        unsubscribe_response = api_request("DELETE", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)
        assert unsubscribe_response.status_code == 200, f"Unsubscribe failed: {unsubscribe_response.text}"

        print(f"✅ DELETE request returned 200")

        # 4. Esperar propagación Realtime
        wait_for_realtime_propagation()

        # 5. Verificar que NO aparece
        subscriptions_after = get_user_subscriptions(subscriber_id)
        subscription_ids_after = {s["id"] for s in subscriptions_after}

        print(f"📊 Subscriptions before: {len(subscriptions_before)}, after: {len(subscriptions_after)}")

        # CRITICAL ASSERTION
        assert target_user_id not in subscription_ids_after, f"❌ FATAL: User {target_user_id} STILL in subscriptions after unsubscribe! " f"Found in: {subscription_ids_after}"

        assert len(subscriptions_after) == len(subscriptions_before) - 1, f"Expected {len(subscriptions_before) - 1} subscriptions, got {len(subscriptions_after)}"

        print(f"✅ User {target_user_id} successfully removed from subscriptions")

    def test_subscription_increments_subscribers_count(self):
        """
        FLUJO COMPLETO: Suscripción incrementa subscribers_count

        1. GET user_subscription_stats de user 7 -> estado inicial
        2. User 1 se suscribe a user 7 (public user: fcbarcelona)
        3. Esperar propagación (triggers CDC)
        4. GET user_subscription_stats de user 7 -> verificar incremento
        """
        subscriber_id = 1
        target_user_id = 7  # fcbarcelona (public user)

        # 1. Estado inicial de stats
        initial_stats = get_user_stats(target_user_id)
        assert initial_stats is not None, f"User {target_user_id} should have stats"
        initial_subscribers = initial_stats["subscribers_count"]

        print(f"\n📊 User {target_user_id} initial subscribers: {initial_subscribers}")

        # 2. Suscribirse
        subscribe_response = api_request("POST", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)
        assert subscribe_response.status_code == 201

        print(f"✅ User {subscriber_id} subscribed to user {target_user_id}")

        # 3. Esperar propagación de triggers
        wait_for_realtime_propagation()

        # 4. Verificar incremento en stats
        final_stats = get_user_stats(target_user_id)
        final_subscribers = final_stats["subscribers_count"]

        print(f"📊 User {target_user_id} final subscribers: {final_subscribers}")

        # ASSERTION
        assert final_subscribers == initial_subscribers + 1, f"Expected subscribers_count={initial_subscribers + 1}, got {final_subscribers}"

        print(f"✅ subscribers_count incremented correctly")

        # Cleanup
        api_request("DELETE", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)

    def test_unsubscription_decrements_subscribers_count(self):
        """
        FLUJO COMPLETO: Desuscripción decrementa subscribers_count

        1. User 1 se suscribe a user 7 (public user: fcbarcelona)
        2. GET user_subscription_stats -> estado después de suscribirse
        3. User 1 se desuscribe
        4. GET user_subscription_stats -> verificar decremento
        """
        subscriber_id = 1
        target_user_id = 7  # fcbarcelona (public user)

        # 1. Suscribirse
        subscribe_response = api_request("POST", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)
        assert subscribe_response.status_code == 201
        wait_for_realtime_propagation()

        print(f"\n✅ User {subscriber_id} subscribed to user {target_user_id}")

        # 2. Estado después de suscribirse
        stats_after_subscribe = get_user_stats(target_user_id)
        subscribers_after_subscribe = stats_after_subscribe["subscribers_count"]

        print(f"📊 Subscribers after subscribe: {subscribers_after_subscribe}")

        # 3. Desuscribirse
        unsubscribe_response = api_request("DELETE", f"/users/{target_user_id}/subscribe", user_id=subscriber_id)
        assert unsubscribe_response.status_code == 200
        wait_for_realtime_propagation()

        print(f"✅ User {subscriber_id} unsubscribed from user {target_user_id}")

        # 4. Verificar decremento
        stats_after_unsubscribe = get_user_stats(target_user_id)
        subscribers_after_unsubscribe = stats_after_unsubscribe["subscribers_count"]

        print(f"📊 Subscribers after unsubscribe: {subscribers_after_unsubscribe}")

        # ASSERTION
        assert subscribers_after_unsubscribe == subscribers_after_subscribe - 1, f"Expected subscribers_count={subscribers_after_subscribe - 1}, got {subscribers_after_unsubscribe}"

        print(f"✅ subscribers_count decremented correctly")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
