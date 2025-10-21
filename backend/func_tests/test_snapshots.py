"""
Test Runner con Snapshots - Detecta diferencias en outputs

Similar a Jest snapshots: guarda el output real la primera vez,
y en ejecuciones futuras compara para detectar cambios.

Uso:
    # Ejecutar normalmente
    pytest func_tests/test_snapshots.py -v

    # Actualizar snapshots (cuando el cambio es intencional)
    pytest func_tests/test_snapshots.py -v --update-snapshots
"""

import difflib
import json
import os
from pathlib import Path
from typing import Any, Dict

import pytest


def setup_test_data(db, setup_config: Dict):
    """
    Crea los datos de setup necesarios para el test
    """
    from datetime import datetime, timezone

    from models import AppBan, Calendar, CalendarMembership, Contact, Event, EventBan, EventInteraction, Group, GroupMembership, RecurringEventConfig, User, UserBlock

    created_objects = {}

    # Crear usuarios
    if "users" in setup_config:
        for user_config in setup_config["users"]:
            contact = Contact(name=user_config["name"], phone=user_config.get("phone"))
            db.add(contact)
            db.flush()

            user = User(id=user_config.get("id"), contact_id=contact.id, auth_provider="phone", auth_id=contact.phone)
            db.add(user)
            db.flush()

            created_objects[f"user_{user.id}"] = user

    # Crear grupos
    if "groups" in setup_config:
        for group_config in setup_config["groups"]:
            group = Group(id=group_config.get("id"), name=group_config["name"], description=group_config.get("description"), created_by=group_config["created_by"])
            db.add(group)
            db.flush()
            created_objects[f"group_{group.id}"] = group

    # Crear calendarios
    if "calendars" in setup_config:
        for calendar_config in setup_config["calendars"]:
            calendar = Calendar(id=calendar_config.get("id"), owner_id=calendar_config["owner_id"], name=calendar_config["name"])
            db.add(calendar)
            db.flush()
            created_objects[f"calendar_{calendar.id}"] = calendar

    # Crear eventos
    if "events" in setup_config:
        for event_config in setup_config["events"]:
            # Parse dates
            start_date = datetime.fromisoformat(event_config["start_date"])
            if start_date.tzinfo is None:
                start_date = start_date.replace(tzinfo=timezone.utc)

            end_date = None
            if event_config.get("end_date"):
                end_date = datetime.fromisoformat(event_config["end_date"])
                if end_date.tzinfo is None:
                    end_date = end_date.replace(tzinfo=timezone.utc)

            event = Event(id=event_config.get("id"), name=event_config["name"], description=event_config.get("description"), start_date=start_date, end_date=end_date, event_type=event_config.get("event_type", "regular"), owner_id=event_config["owner_id"], calendar_id=event_config.get("calendar_id"))
            db.add(event)
            db.flush()
            created_objects[f"event_{event.id}"] = event

    # Crear interacciones de eventos
    if "event_interactions" in setup_config:
        for interaction_config in setup_config["event_interactions"]:
            interaction = EventInteraction(
                event_id=interaction_config["event_id"],
                user_id=interaction_config["user_id"],
                interaction_type=interaction_config["interaction_type"],
                status=interaction_config.get("status"),
                role=interaction_config.get("role"),
                invited_by_user_id=interaction_config.get("invited_by_user_id"),
                invited_via_group_id=interaction_config.get("invited_via_group_id"),
            )
            db.add(interaction)
            db.flush()

    # Crear bans de usuarios
    if "app_bans" in setup_config:
        for ban_config in setup_config["app_bans"]:
            app_ban = AppBan(user_id=ban_config["user_id"], banned_by=ban_config["banned_by"], reason=ban_config.get("reason"))
            db.add(app_ban)
            db.flush()

    # Crear configuraciones de recurrencia
    if "recurring_configs" in setup_config:
        for config in setup_config["recurring_configs"]:
            # Parse recurrence_end_date if present
            recurrence_end_date = None
            if config.get("recurrence_end_date"):
                recurrence_end_date = datetime.fromisoformat(config["recurrence_end_date"])
                if recurrence_end_date.tzinfo is None:
                    recurrence_end_date = recurrence_end_date.replace(tzinfo=timezone.utc)

            recurring_config = RecurringEventConfig(event_id=config["event_id"], recurrence_type=config["recurrence_type"], schedule=config.get("schedule"), recurrence_end_date=recurrence_end_date)
            db.add(recurring_config)
            db.flush()

    # Crear memberships de calendario
    if "calendar_memberships" in setup_config:
        for membership_config in setup_config["calendar_memberships"]:
            membership = CalendarMembership(calendar_id=membership_config["calendar_id"], user_id=membership_config["user_id"], role=membership_config.get("role", "member"), status=membership_config.get("status", "pending"), invited_by_user_id=membership_config.get("invited_by_user_id"))
            db.add(membership)
            db.flush()

    # Crear memberships de grupo
    if "group_memberships" in setup_config:
        for membership_config in setup_config["group_memberships"]:
            membership = GroupMembership(id=membership_config.get("id"), group_id=membership_config["group_id"], user_id=membership_config["user_id"])
            db.add(membership)
            db.flush()

    # Crear user blocks
    if "user_blocks" in setup_config:
        for block_config in setup_config["user_blocks"]:
            block = UserBlock(id=block_config.get("id"), blocker_user_id=block_config["blocker_user_id"], blocked_user_id=block_config["blocked_user_id"])
            db.add(block)
            db.flush()

    # Crear event bans
    if "event_bans" in setup_config:
        for ban_config in setup_config["event_bans"]:
            ban = EventBan(id=ban_config.get("id"), event_id=ban_config["event_id"], user_id=ban_config["user_id"], banned_by=ban_config["banned_by"], reason=ban_config.get("reason"))
            db.add(ban)
            db.flush()

    db.commit()
    return created_objects


def discover_test_cases(base_path: str = "func_tests") -> list:
    """Descubre todos los archivos JSON en func_tests/"""
    test_cases = []
    base = Path(base_path)

    for json_file in base.rglob("*.json"):
        # Ignorar .output.json y .snapshot.json
        if json_file.name.endswith(".output.json") or json_file.name.endswith(".snapshot.json"):
            continue

        with open(json_file, "r", encoding="utf-8") as f:
            test_data = json.load(f)
            test_id = str(json_file.relative_to(base)).replace(".json", "").replace("/", "::")
            test_cases.append((test_id, json_file, test_data))

    return test_cases


def get_snapshot_path(test_case_path: Path) -> Path:
    """Retorna la ruta del archivo snapshot"""
    return test_case_path.parent / f"{test_case_path.stem}.snapshot.json"


def normalize_response(data):
    """
    Normaliza campos dinámicos para comparación
    Reemplaza IDs y timestamps con placeholders
    Soporta tanto dict como list
    """
    # Si es una lista, normalizar cada elemento
    if isinstance(data, list):
        return [normalize_response(item) for item in data]

    # Si no es un dict, devolver tal cual
    if not isinstance(data, dict):
        return data

    normalized = {}
    for key, value in data.items():
        # IDs: reemplazar con placeholder
        if key in ["id", "user_id", "event_id", "calendar_id", "interaction_id"]:
            normalized[key] = "{{ID}}"
        # Timestamps: reemplazar con placeholder
        elif key in ["created_at", "updated_at", "last_login", "banned_at"]:
            normalized[key] = "{{TIMESTAMP}}"
        # Recursivo para objetos y arrays
        elif isinstance(value, (dict, list)):
            normalized[key] = normalize_response(value)
        # Otros valores: mantener como están
        else:
            normalized[key] = value

    return normalized


def save_snapshot(snapshot_path: Path, response_data: Dict):
    """Guarda el snapshot normalizado"""
    normalized = normalize_response(response_data)

    snapshot = {"status_code": response_data.get("_status_code"), "body": normalized, "note": "Auto-generated snapshot. Update with --update-snapshots flag."}

    with open(snapshot_path, "w", encoding="utf-8") as f:
        json.dump(snapshot, f, indent=2, ensure_ascii=False)


def load_snapshot(snapshot_path: Path) -> Dict:
    """Carga el snapshot guardado"""
    if not snapshot_path.exists():
        return None

    with open(snapshot_path, "r", encoding="utf-8") as f:
        return json.load(f)


def compare_with_snapshot(actual_response, snapshot_path: Path, update_snapshots: bool = False) -> tuple[bool, str]:
    """
    Compara la respuesta actual con el snapshot

    Returns:
        (success: bool, diff_message: str)
    """
    # Preparar datos actuales
    try:
        actual_body = actual_response.json()
    except:
        actual_body = {"_raw_text": actual_response.text}

    # Estructura consistente: siempre {status_code, body}
    actual_data = {"_status_code": actual_response.status_code, "body": actual_body}

    # Cargar snapshot existente
    snapshot = load_snapshot(snapshot_path)

    # Si no existe snapshot, crear uno nuevo
    if snapshot is None:
        save_snapshot(snapshot_path, actual_data)
        return True, f"✨ Snapshot created: {snapshot_path.name}"

    # Si --update-snapshots, actualizar
    if update_snapshots:
        save_snapshot(snapshot_path, actual_data)
        return True, f"📝 Snapshot updated: {snapshot_path.name}"

    # Normalizar respuesta actual
    normalized_actual = normalize_response(actual_data)

    # Comparar
    expected_body = snapshot.get("body", {})
    expected_status = snapshot.get("status_code")

    # Verificar status code
    if actual_response.status_code != expected_status:
        return False, f"❌ Status code changed: {expected_status} → {actual_response.status_code}"

    # Comparar JSONs como strings para detectar diferencias
    expected_str = json.dumps(expected_body, sort_keys=True, indent=2)
    actual_str = json.dumps(normalized_actual, sort_keys=True, indent=2)

    # Si son iguales, success
    if expected_str == actual_str:
        return True, "✅ Matches snapshot"

    # Si hay diferencias, generar diff
    diff_lines = difflib.unified_diff(expected_str.splitlines(keepends=True), actual_str.splitlines(keepends=True), fromfile="snapshot (expected)", tofile="actual response", lineterm="")

    diff_message = f"❌ Response differs from snapshot:\n\n"
    diff_message += "".join(diff_lines)
    diff_message += f"\n\nTo update snapshot: pytest func_tests/test_snapshots.py --update-snapshots"

    return False, diff_message


# Descubrir casos de test
TEST_CASES = discover_test_cases()


@pytest.mark.parametrize("test_id,test_path,test_data", TEST_CASES, ids=[tc[0] for tc in TEST_CASES])
def test_snapshot_match(test_id, test_path, test_data, client, test_db, request):
    """
    Ejecuta el test y compara con snapshot
    """
    # Setup
    if "setup" in test_data:
        setup_test_data(test_db, test_data["setup"])

    # Execute request
    req = test_data["request"]
    method = req["method"].lower()
    endpoint = req["endpoint"]
    body = req.get("body")

    if method == "post":
        response = client.post(endpoint, json=body)
    elif method == "get":
        response = client.get(endpoint)
    elif method == "put":
        response = client.put(endpoint, json=body)
    elif method == "patch":
        response = client.patch(endpoint, json=body)
    elif method == "delete":
        response = client.delete(endpoint)
    else:
        pytest.fail(f"Unsupported method: {method}")

    # Compare with snapshot
    snapshot_path = get_snapshot_path(test_path)
    update_snapshots = request.config.getoption("--update-snapshots")

    success, message = compare_with_snapshot(response, snapshot_path, update_snapshots)

    print(f"\n{message}")

    if not success:
        pytest.fail(message)
