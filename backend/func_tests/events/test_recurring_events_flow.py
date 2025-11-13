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

    # === PASO 3: Eliminar evento padre ===
    response = client.delete(f"/api/v1/events/{parent_event_id}", headers={"X-Test-User-Id": "1"})
    assert response.status_code == 200

    print(f"\n✅ PASO 3: Evento padre eliminado")

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
    print(f"✅ Eliminar evento padre + hijos: OK")
    print("=" * 80)


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


def test_recurring_event_with_end_date(client, test_db):
    """
    Test: Crear evento recurrente con fecha fin
    Verifica que solo se generan eventos hasta recurrence_end_date
    """

    # === PASO 0: Crear usuario de prueba ===
    from models import User
    from datetime import timedelta

    test_user = User(id=1, auth_provider="phone", auth_id="+34600000001", display_name="Test User", phone="+34600000001", is_public=False)
    test_db.add(test_user)
    test_db.commit()
    test_db.refresh(test_user)

    # === PASO 1: Crear evento recurrente con fecha fin (4 semanas) ===
    start_date = datetime.now(timezone.utc)
    end_date = start_date + timedelta(weeks=4)  # Solo 4 semanas

    event_data = {
        "name": "Entrenamiento Temporal",
        "description": "Entrenamiento que termina en 4 semanas",
        "start_date": start_date.isoformat(),
        "event_type": "recurring",
        "owner_id": 1,
        "recurrence_end_date": end_date.isoformat(),
        "patterns": [
            {"dayOfWeek": 1, "time": "18:00:00"},  # Lunes 18:00
            {"dayOfWeek": 3, "time": "19:00:00"},  # Miércoles 19:00
        ],
    }

    response = client.post("/api/v1/events", json=event_data)
    assert response.status_code == 201

    parent_event = response.json()
    parent_event_id = parent_event["id"]

    print(f"\n✅ PASO 1: Evento recurrente con fecha fin creado (id={parent_event_id})")
    print(f"   - start_date: {start_date.isoformat()}")
    print(f"   - recurrence_end_date: {end_date.isoformat()}")
    print(f"   - duración: 4 semanas")

    # === PASO 2: Verificar que se generaron los eventos correctos ===
    from models import Event

    child_events_db = test_db.query(Event).filter(Event.parent_recurring_event_id == parent_event_id).all()

    print(f"\n✅ PASO 2: Eventos hijos generados: {len(child_events_db)}")
    print(f"   - Se esperan ~8 eventos (4 semanas × 2 días/semana)")

    # Verificar que hay aproximadamente 8 eventos (puede variar según el día de inicio)
    assert len(child_events_db) <= 10, "No deberían generarse más de 10 eventos para 4 semanas con 2 patterns"
    assert len(child_events_db) >= 6, "Deberían generarse al menos 6 eventos para 4 semanas con 2 patterns"

    # === PASO 3: Verificar que ningún evento excede la fecha fin ===
    for child in child_events_db:
        # Make timezone aware for comparison
        child_start = child.start_date
        if child_start.tzinfo is None:
            child_start = child_start.replace(tzinfo=timezone.utc)
        assert child_start <= end_date, f"Evento {child.id} excede la fecha fin: {child_start} > {end_date}"
        print(f"   - Hijo: {child.start_date.isoformat()} ✓")

    print(f"\n✅ PASO 3: Todos los eventos están dentro del rango de fechas")

    # === PASO 4: Crear evento sin fecha fin y comparar ===
    event_data_no_end = {
        "name": "Entrenamiento Infinito",
        "description": "Entrenamiento sin fecha fin",
        "start_date": start_date.isoformat(),
        "event_type": "recurring",
        "owner_id": 1,
        "patterns": [
            {"dayOfWeek": 1, "time": "18:00:00"},
            {"dayOfWeek": 3, "time": "19:00:00"},
        ],
    }

    response = client.post("/api/v1/events", json=event_data_no_end)
    assert response.status_code == 201

    parent_event_no_end = response.json()
    parent_event_no_end_id = parent_event_no_end["id"]

    child_events_no_end_db = test_db.query(Event).filter(Event.parent_recurring_event_id == parent_event_no_end_id).all()

    print(f"\n✅ PASO 4: Comparación con evento sin fecha fin")
    print(f"   - Con fecha fin (4 semanas): {len(child_events_db)} eventos")
    print(f"   - Sin fecha fin (52 semanas): {len(child_events_no_end_db)} eventos")

    # El evento sin fecha fin debería tener muchos más eventos
    assert len(child_events_no_end_db) > len(child_events_db) * 10, "El evento sin fecha fin debería tener muchos más eventos"

    # === RESUMEN ===
    print("\n" + "=" * 80)
    print("RESUMEN DEL TEST:")
    print("=" * 80)
    print(f"✅ Crear evento recurrente con fecha fin: OK")
    print(f"✅ Limitar eventos hasta fecha fin: OK ({len(child_events_db)} eventos)")
    print(f"✅ Ningún evento excede fecha fin: OK")
    print(f"✅ Diferencia con evento sin fecha fin: OK")
    print("=" * 80)
