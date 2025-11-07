# Flutter Compatibility Test Results

**Fecha:** 2025-11-06
**Test Suite:** `func_tests/test_flutter_compatibility.py`

## Resumen Ejecutivo

Este test automático valida que las respuestas del backend sean compatibles con los modelos de Flutter, verificando:
1. Presencia de campos requeridos
2. Tipos de datos correctos
3. Estructura de respuestas JSON

**Resultado General:** 3 tests pasados ✅ | 4 tests fallidos ❌

---

## Tests Exitosos ✅

### 1. User Endpoints
**Status:** PASSED ✅

Todos los endpoints de usuarios son compatibles con Flutter:
- `GET /api/v1/users` - Compatible
- `GET /api/v1/users/{id}` - Compatible
- `GET /api/v1/users?enriched=true` - Compatible
- `GET /api/v1/users/1/subscriptions` - Compatible

**Campos validados:**
- ✅ `id` (int, required)
- ✅ `is_public` (bool, required)
- ✅ `contact_id`, `username`, `auth_provider`, `auth_id` (optional)
- ✅ `is_admin`, `profile_picture`, `created_at`, `updated_at` (optional)
- ✅ `contact_name`, `contact_phone` (enriched fields)
- ✅ `new_events_count`, `total_events_count`, `subscribers_count` (stats)

### 2. Calendar Endpoints
**Status:** PASSED ✅

Todos los endpoints de calendarios son compatibles:
- `GET /api/v1/calendars` - Compatible
- `GET /api/v1/calendars/{id}` - Compatible

**Campos validados:**
- ✅ `id`, `owner_id`, `name`, `created_at`, `updated_at` (required)
- ✅ `description`, `is_public`, `is_discoverable`, `share_hash`, `category`, `subscriber_count` (optional)

### 3. Group Endpoints
**Status:** PASSED ✅

Todos los endpoints de grupos son compatibles:
- `GET /api/v1/groups` - Compatible
- `GET /api/v1/groups/{id}` - Compatible
- Nested User objects in `members`, `admins`, `owner` - Compatible

**Campos validados:**
- ✅ `id`, `name`, `owner_id`, `created_at` (required)
- ✅ `description`, `updated_at`, `owner`, `members`, `admins` (optional)

---

## Tests Fallidos ❌

### 1. Event Endpoints
**Status:** FAILED ❌
**Severidad:** CRITICAL 🔴

**Error:**
```
fastapi.exceptions.ResponseValidationError: 1 validation errors:
{'type': 'dict_type', 'loc': ('response', 0, 'interactions', 0),
 'msg': 'Input should be a valid dictionary',
 'input': <EventInteraction(id=1, event_id=1, user_id=2, type='invited')>}
```

**Problema:**
El backend está devolviendo objetos SQLAlchemy `EventInteraction` en el campo `interactions` en lugar de diccionarios JSON. Esto causa un error de serialización Pydantic.

**Ubicación:** `GET /api/v1/events`

**Impacto en Flutter:**
- Flutter no puede deserializar la respuesta
- Runtime crash al intentar parsear eventos con interactions

**Solución requerida:**
El backend debe convertir objetos `EventInteraction` a dicts antes de incluirlos en la respuesta. Revisar `routers/events.py` y `schemas.py` para asegurar correcta serialización.

**Archivo a revisar:** `backend/routers/events.py`

### 2. Event Interaction Endpoints
**Status:** FAILED ❌
**Severidad:** CRITICAL 🔴

**Error:**
```
assert 404 == 200
```

**Problema:**
El endpoint `GET /api/v1/event_interactions` no existe (404 Not Found).

**Impacto en Flutter:**
- Flutter no puede obtener listado de interacciones de eventos
- Funcionalidad de invitaciones/suscripciones no disponible via API directa

**Solución requerida:**
1. Implementar endpoint `GET /api/v1/event_interactions` en `routers/`
2. O documentar que este endpoint no existe y Flutter debe usar rutas alternativas

**Archivos a revisar:**
- `backend/main.py` - ¿Está el router registrado?
- `backend/routers/` - ¿Existe router para event_interactions?

### 3. Nested Models
**Status:** FAILED ❌
**Severidad:** MEDIUM 🟡

**Error:**
Mismo que Test #1 - el test no pudo completarse debido al error de serialización de `interactions`.

**Problema:**
El test valida que modelos anidados (User en Event, User en Group) sean válidos, pero falla debido al error de Event endpoints.

**Solución requerida:**
Resolver el problema de serialización de Event endpoints (Test #1).

### 4. Critical Type Mismatches
**Status:** FAILED ❌
**Severidad:** MEDIUM 🟡

**Error:**
Mismo que Test #1 - el test no pudo ejecutarse completamente debido al error anterior.

**Problema:**
Este test está diseñado para detectar inconsistencias de tipos documentadas en `MODEL_INCONSISTENCIES_REPORT.md` (como Calendar ID siendo String en vez de int), pero no pudo ejecutarse.

**Nota:**
Según `MODEL_INCONSISTENCIES_REPORT.md`, existe una inconsistencia conocida:
- Calendar ID en Flutter: `int`
- Calendar ID en algunos lugares del backend: puede ser `String`

**Solución requerida:**
1. Resolver el problema de Event endpoints primero
2. Re-ejecutar este test para verificar si existen type mismatches

---

## Problemas Críticos Detectados 🔴

### 1. Event Interactions Serialization Error
**Prioridad:** P0 - URGENTE

El backend está devolviendo objetos SQLAlchemy sin serializar en el campo `interactions` de eventos. Esto rompe la compatibilidad con Flutter.

**Ejemplo del error:**
```python
# ❌ INCORRECTO - Backend devuelve:
{
  "id": 1,
  "name": "Test Event",
  "interactions": [<EventInteraction(id=1, ...)>]  # Objeto Python, no JSON
}

# ✅ CORRECTO - Debería devolver:
{
  "id": 1,
  "name": "Test Event",
  "interactions": [
    {
      "id": 1,
      "user_id": 2,
      "event_id": 1,
      "interaction_type": "invited",
      "status": "pending"
    }
  ]
}
```

**Archivos afectados:**
- `backend/routers/events.py` - Endpoint que devuelve eventos
- `backend/schemas.py` - Schema EventResponse
- `backend/crud/crud_event.py` - Queries que obtienen interactions

### 2. Missing EventInteraction Endpoint
**Prioridad:** P1 - ALTA

No existe el endpoint `GET /api/v1/event_interactions` que Flutter podría estar esperando.

**Opciones:**
1. Implementar el endpoint si Flutter lo necesita
2. Documentar que no existe y Flutter debe usar rutas alternativas (ej: `GET /api/v1/events/{id}/interactions`)

---

## Campos Validados por Modelo

### User Model
| Campo | Tipo | Required | Status |
|-------|------|----------|--------|
| `id` | int | ✅ | ✅ Compatible |
| `is_public` | bool | ✅ | ✅ Compatible |
| `contact_id` | int? | ❌ | ✅ Compatible |
| `username` | string? | ❌ | ✅ Compatible |
| `auth_provider` | string? | ❌ | ✅ Compatible |
| `auth_id` | string? | ❌ | ✅ Compatible |
| `is_admin` | bool? | ❌ | ✅ Compatible |
| `profile_picture` | string? | ❌ | ✅ Compatible |
| `created_at` | string? | ❌ | ✅ Compatible |
| `updated_at` | string? | ❌ | ✅ Compatible |
| `contact_name` | string? | ❌ (enriched) | ✅ Compatible |
| `contact_phone` | string? | ❌ (enriched) | ✅ Compatible |

### Event Model
| Campo | Tipo | Required | Status |
|-------|------|----------|--------|
| `name` | string | ✅ | ⏸️ Not tested (endpoint error) |
| `start_date` | string | ✅ | ⏸️ Not tested (endpoint error) |
| `owner_id` | int | ✅ | ⏸️ Not tested (endpoint error) |
| `id` | int? | ❌ | ⏸️ Not tested |
| `description` | string? | ❌ | ⏸️ Not tested |
| `calendar_id` | int? | ❌ | ⏸️ Not tested |
| `interaction` | dict? | ❌ | ❌ **SERIALIZATION ERROR** |
| `interactions` | dict? | ❌ | ❌ **SERIALIZATION ERROR** |

### Calendar Model
| Campo | Tipo | Required | Status |
|-------|------|----------|--------|
| `id` | int | ✅ | ✅ Compatible |
| `owner_id` | int | ✅ | ✅ Compatible |
| `name` | string | ✅ | ✅ Compatible |
| `created_at` | string | ✅ | ✅ Compatible |
| `updated_at` | string | ✅ | ✅ Compatible |
| `description` | string? | ❌ | ✅ Compatible |
| `is_public` | bool? | ❌ | ✅ Compatible |

### Group Model
| Campo | Tipo | Required | Status |
|-------|------|----------|--------|
| `id` | int | ✅ | ✅ Compatible |
| `name` | string | ✅ | ✅ Compatible |
| `owner_id` | int | ✅ | ✅ Compatible |
| `created_at` | string | ✅ | ✅ Compatible |
| `description` | string? | ❌ | ✅ Compatible |
| `owner` | User? | ❌ | ✅ Compatible |
| `members` | User[]? | ❌ | ✅ Compatible |
| `admins` | User[]? | ❌ | ✅ Compatible |

---

## Recomendaciones

### Inmediatas (P0)
1. ✅ **Implementado:** Test automatizado para validación continua
2. ❌ **Pendiente:** Arreglar serialización de EventInteraction en eventos
3. ❌ **Pendiente:** Decidir si implementar `GET /api/v1/event_interactions`

### Corto Plazo (P1)
1. Integrar este test en CI/CD para ejecutarse automáticamente
2. Expandir validaciones para incluir RecurringEventConfig
3. Validar tipos de datos complejos (fechas, enums)

### Largo Plazo (P2)
1. Generar modelos Flutter automáticamente desde schemas Pydantic
2. Implementar versionado de API para cambios breaking
3. Documentar todos los endpoints con OpenAPI/Swagger completo

---

## Cómo Ejecutar los Tests

```bash
# Ejecutar todos los tests de compatibilidad
cd backend
python -m pytest func_tests/test_flutter_compatibility.py -v

# Ejecutar un test específico
python -m pytest func_tests/test_flutter_compatibility.py::TestFlutterCompatibility::test_user_endpoints -v

# Ver output detallado
python -m pytest func_tests/test_flutter_compatibility.py -v -s
```

---

## Próximos Pasos

1. [ ] Arreglar serialización de `interactions` en Event endpoints
2. [ ] Decidir sobre endpoint `/api/v1/event_interactions`
3. [ ] Re-ejecutar tests después de los fixes
4. [ ] Integrar en CI/CD pipeline
5. [ ] Expandir cobertura a RecurringEventConfig, Subscription, etc.

---

**Generado por:** `test_flutter_compatibility.py`
**Última actualización:** 2025-11-06
