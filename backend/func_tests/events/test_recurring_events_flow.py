"""
Test del flujo completo de eventos recurrentes
Prueba: crear, leer recurring_configs, actualizar patterns, eliminar
"""

from datetime import datetime, timezone


def test_recurring_event_complete_flow(client, test_db):
    """
    Test del flujo completo:
    1. Crear evento recurrente con patterns
    2. Verificar que se generan eventos hijos
    3. Verificar si se guarda en recurring_event_configs
    4. Intentar obtener recurring_config
    5. Intentar actualizar patterns vía PUT /recurring_configs/{id}
    6. Eliminar evento padre y verificar que se eliminan hijos
    """

    # === PASO 0: Crear usuario de prueba ===
    from models import User

    test_user = User(id=1, auth_provider="phone", auth_id="+34600000001", display_name="Test User", phone="+34600000001", is_public=False)
    test_db.add(test_user)
    test_db.commit()
    test_db.refresh(test_user)

    # === PASO 1: Crear evento recurrente ===
    event_data = {
        "name": "Entrenamiento Semanal",
        "description": "Entrenamiento de fútbol",
        "start_date": datetime.now(timezone.utc).isoformat(),
        "event_type": "recurring",
        "owner_id": 1,
        "patterns": [
            {"dayOfWeek": 1, "time": "18:00:00"},  # Lunes 18:00
            {"dayOfWeek": 3, "time": "19:00:00"},  # Miércoles 19:00
            {"dayOfWeek": 5, "time": "18:30:00"},  # Viernes 18:30
        ],
    }

    response = client.post("/api/v1/events", json=event_data)
    assert response.status_code == 201

    parent_event = response.json()
    parent_event_id = parent_event["id"]

    print(f"\n✅ PASO 1: Evento padre creado (id={parent_event_id})")
    print(f"   - name: {parent_event['name']}")
    print(f"   - event_type: {parent_event['event_type']}")

    # === PASO 2: Verificar eventos hijos generados (vía query directo) ===
    from models import Event

    child_events_db = test_db.query(Event).filter(Event.parent_recurring_event_id == parent_event_id).all()

    print(f"\n✅ PASO 2: Eventos hijos generados: {len(child_events_db)}")
    print(f"   - Se esperan ~156 eventos (52 semanas × 3 días/semana)")

    assert len(child_events_db) > 0, "Deberían haberse generado eventos hijos"

    # Verificar que los hijos apuntan al padre
    for child in child_events_db[:3]:
        assert child.parent_recurring_event_id == parent_event_id
        assert child.event_type == "regular"
        print(f"   - Hijo: {child.start_date} (id={child.id})")

    child_events = [{"id": c.id, "start_date": c.start_date.isoformat(), "parent_recurring_event_id": c.parent_recurring_event_id} for c in child_events_db]

    # === PASO 3: Verificar si se guardó en recurring_event_configs ===
    from models import RecurringEventConfig

    db_config = test_db.query(RecurringEventConfig).filter(RecurringEventConfig.event_id == parent_event_id).first()

    if db_config:
        print(f"\n✅ PASO 3: recurring_event_config EXISTE en BD")
        print(f"   - id: {db_config.id}")
        print(f"   - event_id: {db_config.event_id}")
        print(f"   - recurrence_type: {db_config.recurrence_type}")
        print(f"   - schedule: {db_config.schedule}")
        config_exists = True
        config_id = db_config.id
    else:
        print(f"\n❌ PASO 3: recurring_event_config NO EXISTE en BD")
        print(f"   - Los patterns NO se guardaron")
        config_exists = False
        config_id = None

    # === PASO 4: Intentar obtener via GET /recurring_configs ===
    response = client.get(f"/api/v1/recurring_configs?event_id={parent_event_id}")

    if response.status_code == 200:
        configs = response.json()
        print(f"\n✅ PASO 4: GET /recurring_configs funciona ({len(configs)} configs)")
        if configs:
            print(f"   - Config: {configs[0]}")
    else:
        print(f"\n❌ PASO 4: GET /recurring_configs falló (status={response.status_code})")

    # === PASO 5: Intentar actualizar patterns (si existe config) ===
    if config_exists and config_id:
        update_data = {
            "recurrence_type": "weekly",
            "schedule": [
                {"dayOfWeek": 1, "time": "19:00:00"},  # Cambio: 18:00 -> 19:00
                {"dayOfWeek": 3, "time": "20:00:00"},  # Cambio: 19:00 -> 20:00
            ],
        }

        # Necesitamos auth para PUT
        response = client.put(f"/api/v1/recurring_configs/{config_id}", json=update_data, headers={"X-Test-User-Id": "1"})

        if response.status_code == 200:
            print(f"\n✅ PASO 5: PUT /recurring_configs funciona")
            updated_config = response.json()
            print(f"   - Actualizado: {updated_config}")
        else:
            print(f"\n❌ PASO 5: PUT /recurring_configs falló (status={response.status_code})")
            print(f"   - Error: {response.json()}")
    else:
        print(f"\n⏭️  PASO 5: Saltado (no hay config que actualizar)")

    # === PASO 6: Eliminar evento padre ===
    response = client.delete(f"/api/v1/events/{parent_event_id}", headers={"X-Test-User-Id": "1"})
    assert response.status_code == 200

    print(f"\n✅ PASO 6: Evento padre eliminado")

    # Verificar que los hijos también se eliminaron
    response = client.get(f"/api/v1/events?parent_recurring_event_id={parent_event_id}&limit=200")
    remaining_children = response.json()

    print(f"   - Eventos hijos restantes: {len(remaining_children)}")
    assert len(remaining_children) == 0, "Los eventos hijos deberían haberse eliminado"

    # === RESUMEN ===
    print("\n" + "=" * 80)
    print("RESUMEN DEL TEST:")
    print("=" * 80)
    print(f"✅ Crear evento recurrente: OK")
    print(f"✅ Generar eventos hijos: OK ({len(child_events)} eventos)")
    print(f"{'✅' if config_exists else '❌'} Guardar en recurring_event_configs: {'OK' if config_exists else 'NO IMPLEMENTADO'}")
    print(f"✅ Eliminar evento padre + hijos: OK")
    print("=" * 80)

    if not config_exists:
        print("\n⚠️  ADVERTENCIA: Los patterns NO se están guardando en BD")
        print("   Esto significa que NO puedes editar patterns después de crear el evento")
        print("   Solo puedes eliminar y recrear el evento completo")


def test_update_event_with_new_patterns(client, test_db):
    """
    Test: ¿Se pueden actualizar patterns vía PUT /events/{id}?
    """

    # Crear usuario de prueba
    from models import User

    test_user = User(id=1, auth_provider="phone", auth_id="+34600000001", display_name="Test User", phone="+34600000001", is_public=False)
    test_db.add(test_user)
    test_db.commit()

    # Crear evento recurrente
    event_data = {
        "name": "Test Pattern Update",
        "description": "Testing",
        "start_date": datetime.now(timezone.utc).isoformat(),
        "event_type": "recurring",
        "owner_id": 1,
        "patterns": [
            {"dayOfWeek": 1, "time": "18:00:00"},
        ],
    }

    response = client.post("/api/v1/events", json=event_data)
    assert response.status_code == 201
    parent_event_id = response.json()["id"]

    print(f"\n✅ Evento recurrente creado (id={parent_event_id})")

    # Intentar actualizar con nuevos patterns vía PUT /events
    update_data = {
        "name": "Updated Name",
        "patterns": [
            {"dayOfWeek": 2, "time": "19:00:00"},  # Cambio de día y hora
            {"dayOfWeek": 4, "time": "20:00:00"},  # Nuevo día
        ],
    }

    response = client.put(f"/api/v1/events/{parent_event_id}", json=update_data, headers={"X-Test-User-Id": "1"})

    print(f"\nPUT /events/{parent_event_id} con nuevos patterns:")
    print(f"   - Status: {response.status_code}")

    if response.status_code == 200:
        print(f"   - ✅ PUT acepta patterns")
        updated_event = response.json()
        print(f"   - Evento actualizado: {updated_event.get('name')}")
    else:
        print(f"   - ❌ PUT no acepta patterns o falló")
        print(f"   - Error: {response.json()}")

    # Verificar si los eventos hijos cambiaron
    response = client.get(f"/api/v1/events?parent_recurring_event_id={parent_event_id}&limit=10")
    child_events = response.json()

    print(f"   - Eventos hijos después de update: {len(child_events)}")
    if child_events:
        print(f"   - Primer hijo: {child_events[0]['start_date']}")
