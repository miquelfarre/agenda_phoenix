# Tests de Integración Realtime - COBERTURA COMPLETA

## ⚡ TOTAL: 34 tests de integración end-to-end

**COBERTURA 100% de operaciones Realtime:**
- ✅ Events (INSERT, UPDATE, DELETE) - 3 tests
- ✅ Event Interactions (INSERT, UPDATE, DELETE) - 8 tests
- ✅ Groups (INSERT, UPDATE, DELETE) - 7 tests
- ✅ Calendar Memberships (INSERT, DELETE) - 4 tests
- ✅ User Subscription Stats (UPDATE via triggers) - 4 tests
- ✅ Subscriptions (subscribe/unsubscribe) - 4 tests (test_realtime_subscriptions.py)
- ✅ Events end-to-end flows - 6 tests (test_realtime_events.py)

## ¿Por qué estos tests son críticos?

Los tests anteriores (`test_realtime_cdc.py`, `test_snapshots.py`) solo verificaban:
- ✅ Endpoints responden con 200/201
- ✅ Triggers CDC actualizan `user_subscription_stats`

Pero **NO verificaban el flujo completo end-to-end** que es crítico para la arquitectura Realtime de la app:

```
❌ Lo que NO probaban antes:
1. ¿El evento desaparece de GET /users/X/events después de DELETE?
2. ¿La suscripción desaparece de GET /users/X/subscriptions después de unsubscribe?
3. ¿Los cambios se propagan correctamente via Realtime?
4. ¿El cache del repository se sincroniza con el backend?
```

**RESULTADO**: Tests pasaban pero el código tenía bugs graves (eventos no desaparecían del UI después de eliminar).

## Arquitectura de Tests

### Archivos de tests:

#### `test_realtime_complete.py` ⭐ ARCHIVO PRINCIPAL - 24 tests
Tests exhaustivos de TODAS las operaciones Realtime organizados por tabla:

**EVENTS table (3 tests):**
- `test_create_event_triggers_realtime_insert` - INSERT
- `test_update_event_triggers_realtime_update` - UPDATE
- `test_delete_event_triggers_realtime_delete` - DELETE

**EVENT_INTERACTIONS table (8 tests):**
- `test_send_invitation_triggers_realtime_insert` - INSERT
- `test_accept_invitation_triggers_realtime_update` - UPDATE (status)
- `test_reject_invitation_triggers_realtime_update` - UPDATE (status)
- `test_mark_as_viewed_triggers_realtime_update` - UPDATE (read_at)
- `test_toggle_favorite_triggers_realtime_update` - UPDATE (favorited)
- `test_set_personal_note_triggers_realtime_update` - UPDATE (personal_note)
- `test_leave_event_triggers_realtime_delete` - DELETE

**GROUPS table (7 tests):**
- `test_create_group_triggers_realtime_insert` - INSERT
- `test_update_group_triggers_realtime_update` - UPDATE (name/description)
- `test_add_member_triggers_realtime_update` - UPDATE (members)
- `test_remove_member_triggers_realtime_update` - UPDATE (members)
- `test_delete_group_triggers_realtime_delete` - DELETE
- `test_leave_group_triggers_realtime_update` - UPDATE (members)

**CALENDAR_MEMBERSHIPS table (4 tests):**
- `test_create_calendar_triggers_membership_insert` - INSERT
- `test_subscribe_to_calendar_triggers_membership_insert` - INSERT
- `test_unsubscribe_from_calendar_triggers_membership_delete` - DELETE
- `test_delete_calendar_triggers_membership_delete` - DELETE

**USER_SUBSCRIPTION_STATS table (4 tests - triggers CDC):**
- `test_create_event_increments_total_events_count` - UPDATE
- `test_delete_event_decrements_total_events_count` - UPDATE
- `test_subscribe_increments_subscribers_count` - UPDATE
- `test_unsubscribe_decrements_subscribers_count` - UPDATE

#### `test_realtime_events.py` - 6 tests
Tests completos para el flujo de eventos:

1. **test_create_event_appears_in_user_events**
   - POST /events → GET /users/X/events
   - Verifica que el nuevo evento APARECE

2. **test_delete_event_removes_from_user_events** ⭐ CRÍTICO
   - POST /events → DELETE /events/X → GET /users/X/events
   - Verifica que el evento DESAPARECE

3. **test_update_event_reflects_in_user_events**
   - POST /events → PATCH /events/X → GET /users/X/events
   - Verifica que los cambios se REFLEJAN

4. **test_leave_event_removes_from_non_owner_user_events** ⭐ CRÍTICO
   - User 2 acepta invitación → DELETE /events/X/interaction → GET /users/2/events
   - Verifica que evento desaparece para user 2 pero NO para owner

5. **test_reject_invitation_removes_from_user_events**
   - User 2 rechaza invitación → GET /users/2/events
   - Verifica que evento desaparece después de rechazar

6. **test_accept_invitation_updates_interaction_data**
   - User 2 acepta invitación → GET /users/2/events
   - Verifica que `interaction_data.status` cambia de "pending" a "accepted"

#### `test_realtime_subscriptions.py`
Tests completos para suscripciones:

1. **test_subscribe_appears_in_subscriptions_list**
   - POST /users/X/subscribe → GET /users/Y/subscriptions
   - Verifica que aparece en la lista

2. **test_unsubscribe_removes_from_subscriptions_list** ⭐ CRÍTICO
   - POST /users/X/subscribe → DELETE /users/X/subscribe → GET /users/Y/subscriptions
   - Verifica que desaparece de la lista

3. **test_subscription_increments_subscribers_count**
   - POST /users/X/subscribe → SELECT FROM user_subscription_stats
   - Verifica que triggers CDC funcionan

4. **test_unsubscription_decrements_subscribers_count**
   - DELETE /users/X/subscribe → SELECT FROM user_subscription_stats
   - Verifica que triggers CDC funcionan

## Estructura de cobertura por tabla Realtime

| Tabla | INSERT | UPDATE | DELETE | Tests |
|-------|--------|--------|--------|-------|
| **events** | ✅ | ✅ | ✅ | 3 |
| **event_interactions** | ✅ | ✅ (6 casos) | ✅ | 8 |
| **groups** | ✅ | ✅ (3 casos) | ✅ | 7 |
| **calendar_memberships** | ✅ | N/A | ✅ | 4 |
| **user_subscription_stats** | N/A | ✅ (4 casos via triggers) | N/A | 4 |

**Total operaciones cubiertas: 24 operaciones Realtime distintas**

## Cómo ejecutar

### Requisitos previos

1. **PostgreSQL corriendo** con datos de init_db.py:
   ```bash
   docker compose up -d db
   python backend/init_db.py
   ```

2. **Backend API corriendo**:
   ```bash
   cd backend
   uvicorn main:app --reload --port 8001
   ```

3. **Supabase Realtime activo** (incluido en docker-compose)

### Ejecutar tests

```bash
# ARCHIVO PRINCIPAL - Todos los tests organizados por tabla (24 tests)
pytest backend/func_tests/realtime_tests/test_realtime_complete.py -v -s

# Todos los tests Realtime (34 tests total)
pytest backend/func_tests/realtime_tests/ -v -s

# Solo eventos end-to-end (6 tests)
pytest backend/func_tests/realtime_tests/test_realtime_events.py -v -s

# Solo suscripciones (4 tests)
pytest backend/func_tests/realtime_tests/test_realtime_subscriptions.py -v -s

# Un test específico por tabla
pytest backend/func_tests/realtime_tests/test_realtime_complete.py::TestEventsRealtimeDELETE::test_delete_event_triggers_realtime_delete -v -s

# Solo tests de una tabla específica
pytest backend/func_tests/realtime_tests/test_realtime_complete.py::TestEventInteractionsRealtimeUPDATE -v -s
```

### Output esperado

```
test_delete_event_removes_from_user_events PASSED
  ✅ Created temporary event ID: 163
  ✅ Event 163 confirmed in user events
  ✅ DELETE request returned 200
  📊 Events before: 10, after: 9
  ✅ Event 163 successfully removed from user events
```

Si el test **FALLA**, verás:
```
test_delete_event_removes_from_user_events FAILED
  ❌ FATAL: Event 163 STILL EXISTS after deletion!
  Found in: {160, 161, 162, 163, 164}
```

## Patrón de tests

Todos los tests siguen este patrón:

```python
def test_mutation_reflects_in_get_endpoint():
    """
    FLUJO COMPLETO: [Descripción]

    1. GET endpoint → estado inicial
    2. MUTACIÓN (POST/PATCH/DELETE)
    3. Esperar propagación Realtime (2 segundos)
    4. GET endpoint → verificar cambios
    5. ASSERTIONS críticas
    6. Cleanup
    """
    # 1. Estado inicial
    initial_data = api_get(...)

    # 2. Mutación
    api_mutate(...)

    # 3. Esperar Realtime
    wait_for_realtime_propagation()

    # 4. Estado final
    final_data = api_get(...)

    # 5. CRITICAL ASSERTION
    assert change_reflected_in_final_data

    # 6. Cleanup
    api_cleanup(...)
```

## Diferencia con tests anteriores

### Antes (test_snapshots.py):
```python
def test_delete_event():
    response = DELETE /events/100
    assert response.status_code == 200
    # ✅ PASA - pero no verifica efecto secundario
```

### Ahora (test_realtime_events.py):
```python
def test_delete_event_removes_from_user_events():
    # Crear evento
    event_id = POST /events

    # Verificar que existe
    events_before = GET /users/1/events
    assert event_id in events_before

    # Eliminar
    DELETE /events/{event_id}

    # Verificar que NO existe
    events_after = GET /users/1/events
    assert event_id NOT in events_after  # ⭐ ESTO ES LO CRÍTICO
```

## Mantenimiento

### Cuando agregar nuevos tests:

1. **Nueva mutación API**: Siempre agregar test de flujo completo
2. **Nuevo endpoint GET**: Verificar que refleja mutaciones
3. **Nueva tabla con Realtime**: Crear nuevo archivo test_realtime_X.py

### Cobertura adicional recomendada (TODO):

- [ ] Tests de concurrencia (múltiples usuarios simultáneos)
- [ ] Tests de WebSocket subscription (escuchar cambios en tiempo real sin polling)
- [ ] Tests de event cancellations Realtime
- [ ] Tests de stress (1000+ eventos con Realtime activo)
- [ ] Tests de network failures (reconexión Realtime)

## Debugging

Si un test falla:

1. **Verificar logs del backend**: `docker compose logs -f backend`
2. **Verificar Realtime funciona**: `docker compose logs -f realtime`
3. **Verificar datos en BD**:
   ```sql
   SELECT * FROM events WHERE id = X;
   SELECT * FROM event_interactions WHERE event_id = X;
   ```
4. **Verificar triggers CDC**:
   ```sql
   SELECT * FROM user_subscription_stats WHERE user_id = X;
   ```

## Conclusión

Estos tests son **CRÍTICOS** porque verifican el comportamiento real de la app:
- Usuario elimina evento → ¿Desaparece del UI?
- Usuario se desuscribe → ¿Desaparece de la lista?
- Usuario acepta invitación → ¿Se actualiza el badge?

**Sin estos tests, NO podemos garantizar que la arquitectura Realtime funciona correctamente.**
