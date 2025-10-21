# Plan de Tests Funcionales - Agenda Phoenix Backend

## Estructura General

```
backend/
├── tests/
│   ├── __init__.py
│   ├── conftest.py                 # Fixtures comunes (cliente, BD test, datos)
│   ├── test_data.py                # Datos de test reutilizables
│   │
│   ├── test_users.py               # Tests de endpoints /users
│   ├── test_events.py              # Tests de endpoints /events
│   ├── test_calendars.py           # Tests de endpoints /calendars
│   ├── test_interactions.py        # Tests de endpoints /interactions
│   └── test_permissions.py         # Tests de permisos y roles
│
├── pytest.ini                      # Configuración de pytest
└── requirements-test.txt           # Dependencias de test
```

## Tecnologías

- **pytest**: Framework de testing
- **TestClient (FastAPI)**: Cliente HTTP incluido en FastAPI para tests
- **SQLAlchemy**: Para manipular datos de test

## Datos de Test

Los tests usarán una base de datos SQLite en memoria o PostgreSQL test. Los datos base serán similares a `init_db.py`:

### Usuarios de Test
```python
# Usuario 1: Sonia (owner de eventos)
sonia = {
    "id": 1,
    "contact": {"name": "Sonia", "phone": "+34606014680"},
    "auth_provider": "phone"
}

# Usuario 2: Miquel (admin de algunos eventos)
miquel = {
    "id": 2,
    "contact": {"name": "Miquel", "phone": "+34626034421"},
    "auth_provider": "phone"
}

# Usuario 3: Ada (invitado a eventos)
ada = {
    "id": 3,
    "contact": {"name": "Ada", "phone": "+34623949193"},
    "auth_provider": "phone"
}

# Usuario 7: fcbarcelona (usuario público)
fcbarcelona = {
    "id": 7,
    "username": "fcbarcelona",
    "auth_provider": "instagram"
}
```

### Eventos de Test
```python
# Evento 1: "Compra semanal sábado"
# - Owner: Sonia (user_id=1)
# - Admin: Miquel (user_id=2, role='admin', status='accepted')
# - Tipo: regular
# - Fecha: sábado próximo

# Evento 2: "Cumpleaños Ada"
# - Owner: Sonia (user_id=1)
# - Invitado: Ada (user_id=3, status='pending')
# - Calendar: "Cumpleaños Family" (calendar_id=2)
# - Tipo: regular

# Evento 3: "Sincro" (recurrente)
# - Owner: Sonia (user_id=1)
# - Tipo: recurring (weekly, todos los lunes)
# - Instancias generadas automáticamente
```

---

## POC: Ejemplo de Test Completo

### Test: Usuario admin puede invitar a otro usuario a un evento

**Archivo:** `tests/test_events.py`

```python
import pytest


class TestEventInvitations:
    """Tests para el sistema de invitaciones a eventos"""

    def test_admin_can_invite_user_to_event(self, client, test_data):
        """
        Test: Un usuario con rol 'admin' en un evento puede invitar a otros usuarios

        Escenario:
        - Sonia crea un evento "Compra semanal"
        - Sonia hace admin a Miquel
        - Miquel invita a Ada al evento
        - Ada debería recibir una invitación pendiente

        Expected:
        - Status 201 cuando Miquel invita
        - Ada tiene interaction_type='invited', status='pending'
        - Ada puede aceptar o rechazar la invitación
        """

        # ARRANGE: Preparar datos
        # Los datos ya están creados por el fixture test_data
        sonia_id = test_data["users"]["sonia"]["id"]
        miquel_id = test_data["users"]["miquel"]["id"]
        ada_id = test_data["users"]["ada"]["id"]

        # Evento "Compra semanal" donde Miquel es admin
        event_id = test_data["events"]["compra_semanal"]["id"]

        # ACT 1: Verificar que Miquel es admin del evento
        response = client.get(
            f"/interactions?event_id={event_id}&user_id={miquel_id}"
        )
        assert response.status_code == 200
        interactions = response.json()

        miquel_interaction = next(
            (i for i in interactions if i["user_id"] == miquel_id),
            None
        )
        assert miquel_interaction is not None
        assert miquel_interaction["interaction_type"] == "joined"
        assert miquel_interaction["role"] == "admin"
        assert miquel_interaction["status"] == "accepted"

        # ACT 2: Miquel invita a Ada
        invitation_data = {
            "event_id": event_id,
            "user_id": ada_id,
            "interaction_type": "invited",
            "invited_by_user_id": miquel_id
        }

        response = client.post("/interactions", json=invitation_data)

        # ASSERT: Verificar que la invitación se creó correctamente
        assert response.status_code == 201, f"Expected 201, got {response.status_code}: {response.text}"
        invitation = response.json()

        assert invitation["event_id"] == event_id
        assert invitation["user_id"] == ada_id
        assert invitation["interaction_type"] == "invited"
        assert invitation["status"] == "pending"
        assert invitation["invited_by_user_id"] == miquel_id

        # ACT 3: Verificar que Ada ve la invitación en su lista de eventos
        response = client.get(f"/users/{ada_id}/events?enriched=true")
        assert response.status_code == 200

        ada_events = response.json()
        invited_events = [
            e for e in ada_events
            if e["id"] == event_id and e.get("source") == "invited"
        ]

        assert len(invited_events) == 1
        invited_event = invited_events[0]

        # Verificar que el evento tiene la información de interacción
        assert invited_event["interaction"] is not None
        assert invited_event["interaction"]["interaction_type"] == "invited"
        assert invited_event["interaction"]["status"] == "pending"
        assert invited_event["interaction"]["invited_by_user_id"] == miquel_id

        # ACT 4: Ada acepta la invitación
        interaction_id = invitation["id"]
        update_data = {
            "status": "accepted"
        }

        response = client.patch(
            f"/interactions/{interaction_id}",
            json=update_data
        )
        assert response.status_code == 200

        updated_interaction = response.json()
        assert updated_interaction["status"] == "accepted"

        # ASSERT FINAL: Verificar que Ada ahora tiene el evento con status 'accepted'
        response = client.get(f"/users/{ada_id}/events?enriched=true")
        assert response.status_code == 200

        ada_events = response.json()
        accepted_events = [
            e for e in ada_events
            if e["id"] == event_id and e.get("interaction", {}).get("status") == "accepted"
        ]

        assert len(accepted_events) == 1
        assert accepted_events[0]["interaction"]["interaction_type"] == "invited"


    def test_regular_member_cannot_invite_users(self, client, test_data):
        """
        Test: Un usuario con rol 'member' (no admin, no owner) NO puede invitar

        Expected:
        - Status 403 Forbidden
        - Mensaje de error indicando falta de permisos
        """
        # TODO: Implementar
        pass


    def test_owner_can_invite_users(self, client, test_data):
        """
        Test: El owner de un evento siempre puede invitar usuarios

        Expected:
        - Status 201
        - Invitación creada correctamente
        """
        # TODO: Implementar
        pass
```

### Fixtures de Test

**Archivo:** `tests/conftest.py`

```python
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime, timedelta

from database import Base, get_db
from main import app
from models import Contact, User, Event, EventInteraction


# Base de datos de test (SQLite en memoria)
TEST_DATABASE_URL = "sqlite:///./test.db"


@pytest.fixture(scope="session")
def test_engine():
    """Crear engine de BD para tests"""
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False}
    )
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def test_db(test_engine):
    """Crear sesión de BD limpia para cada test"""
    TestingSessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=test_engine
    )

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.rollback()
        db.close()


@pytest.fixture
def client(test_db):
    """Cliente HTTP de test con TestClient de FastAPI"""

    # Override dependency
    def override_get_db():
        try:
            yield test_db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def test_data(test_db):
    """
    Fixture que crea datos de test básicos para todos los tests
    Similar a init_db.py pero simplificado
    """

    # 1. Crear contactos
    contact_sonia = Contact(name="Sonia", phone="+34606014680")
    contact_miquel = Contact(name="Miquel", phone="+34626034421")
    contact_ada = Contact(name="Ada", phone="+34623949193")

    test_db.add_all([contact_sonia, contact_miquel, contact_ada])
    test_db.flush()

    # 2. Crear usuarios
    sonia = User(
        contact_id=contact_sonia.id,
        auth_provider="phone",
        auth_id=contact_sonia.phone,
    )
    miquel = User(
        contact_id=contact_miquel.id,
        auth_provider="phone",
        auth_id=contact_miquel.phone,
    )
    ada = User(
        contact_id=contact_ada.id,
        auth_provider="phone",
        auth_id=contact_ada.phone,
    )

    test_db.add_all([sonia, miquel, ada])
    test_db.flush()

    # 3. Crear evento de test: "Compra semanal"
    next_saturday = datetime.now() + timedelta(days=(5 - datetime.now().weekday() + 7) % 7)

    event_compra = Event(
        name="Compra semanal sábado",
        description="Compra semanal en el supermercado",
        start_date=next_saturday.replace(hour=10, minute=0),
        event_type="regular",
        owner_id=sonia.id
    )

    test_db.add(event_compra)
    test_db.flush()

    # 4. Crear interacciones
    # Sonia es owner
    interaction_sonia = EventInteraction(
        event_id=event_compra.id,
        user_id=sonia.id,
        interaction_type="joined",
        status="accepted",
        role="owner"
    )

    # Miquel es admin
    interaction_miquel = EventInteraction(
        event_id=event_compra.id,
        user_id=miquel.id,
        interaction_type="joined",
        status="accepted",
        role="admin",
        invited_by_user_id=sonia.id
    )

    test_db.add_all([interaction_sonia, interaction_miquel])
    test_db.commit()

    # Retornar datos estructurados para fácil acceso en tests
    return {
        "users": {
            "sonia": {"id": sonia.id, "name": "Sonia"},
            "miquel": {"id": miquel.id, "name": "Miquel"},
            "ada": {"id": ada.id, "name": "Ada"}
        },
        "events": {
            "compra_semanal": {
                "id": event_compra.id,
                "name": "Compra semanal sábado",
                "owner_id": sonia.id
            }
        }
    }
```

---

## Otros Tests a Implementar

### `test_users.py`
- ✅ GET /users - Listar usuarios
- ✅ GET /users/{id} - Obtener usuario específico
- ✅ GET /users/{id}/events - Eventos del usuario
- ✅ Verificar que eventos 'joined' con role='admin' aparecen
- ✅ POST /users/{id}/subscribe/{target_id} - Suscribirse a usuario

### `test_events.py`
- ✅ POST /events - Crear evento
- ✅ GET /events/{id} - Obtener evento
- ✅ PUT /events/{id} - Actualizar evento (solo owner/admin)
- ✅ DELETE /events/{id} - Eliminar evento (solo owner)
- ✅ Eventos recurrentes y sus instancias
- ✅ Filtros por fecha (today, next_7_days, this_month)

### `test_calendars.py`
- ✅ POST /calendars - Crear calendario
- ✅ GET /calendars/{id} - Obtener calendario
- ✅ PUT /calendars/{id} - Actualizar calendario (solo owner/admin)
- ✅ POST /calendars/{id}/members - Agregar miembro
- ✅ Calendario temporal vs permanente

### `test_interactions.py`
- ✅ POST /interactions - Crear invitación
- ✅ PATCH /interactions/{id} - Actualizar status (aceptar/rechazar)
- ✅ DELETE /interactions/{id} - Eliminar interacción
- ✅ Tipos: invited, joined, subscribed
- ✅ Roles: owner, admin, member

### `test_permissions.py`
- ✅ Admin puede invitar usuarios
- ✅ Member NO puede invitar usuarios
- ✅ Owner puede editar evento
- ✅ Admin puede editar evento
- ✅ Member NO puede editar evento
- ✅ Usuarios bloqueados no pueden interactuar
- ✅ Usuarios baneados de evento no pueden unirse

### `test_blocks_bans.py`
- ✅ POST /user-blocks - Bloquear usuario
- ✅ DELETE /user-blocks/{id} - Desbloquear usuario
- ✅ POST /event-bans - Banear usuario de evento
- ✅ Verificar que usuarios bloqueados no aparecen en listas

---

## Configuración de pytest

**Archivo:** `pytest.ini`

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
asyncio_mode = auto
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    unit: marks tests as unit tests
```

**Archivo:** `requirements-test.txt`

```txt
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.27.2
factory-boy==3.3.0  # Opcional, para crear datos dinámicos
```

---

## Ejecución de Tests

```bash
# Ejecutar todos los tests
pytest

# Ejecutar tests específicos
pytest tests/test_events.py

# Ejecutar un test específico
pytest tests/test_events.py::TestEventInvitations::test_admin_can_invite_user_to_event

# Con verbose
pytest -v

# Con coverage
pytest --cov=. --cov-report=html

# Solo tests rápidos (excluir slow)
pytest -m "not slow"
```

---

## Próximos Pasos

1. ✅ Revisar y aprobar esta estructura
2. ⬜ Crear archivos base (`conftest.py`, `pytest.ini`)
3. ⬜ Implementar fixtures de datos de test
4. ⬜ Implementar primer test completo (POC)
5. ⬜ Implementar resto de tests por módulo
6. ⬜ Configurar CI/CD para ejecutar tests automáticamente
7. ⬜ Agregar coverage mínimo requerido (ej: 80%)

---

## Notas

- Los tests usan **datos aislados** en cada ejecución (rollback después de cada test)
- Los tests son **determinísticos** - mismo resultado cada vez
- Los tests son **rápidos** - usan BD en memoria cuando es posible
- Los tests son **independientes** - pueden ejecutarse en cualquier orden
- Los tests documentan el **comportamiento esperado** del sistema
